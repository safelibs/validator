#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

ALLOWED_CATEGORIES = {
    "abi_layout",
    "intrusive_queue",
    "syscall_ffi",
    "ffi_callback",
}

SAFETY_RE = re.compile(r"^\s*//\s*SAFETY\((?P<category>[^)]+)\):")
UNSAFE_FN_DEF_RE = re.compile(
    r'^\s*(?:pub(?:\([^)]*\))?\s+)?unsafe\s+(?:extern\s+"C"\s+)?fn\b[^;]*\{'
)
UNSAFE_IMPL_RE = re.compile(r"^\s*unsafe impl\b")
FN_START_RE = re.compile(
    r'(?m)^(?P<indent>[ \t]*)(?P<prefix>(?:pub(?:\([^)]*\))?\s+)?'
    r'(?:(?:const|async)\s+)?(?:(?:extern\s+"C")\s+)?fn\s+[A-Za-z_][A-Za-z0-9_]*\b)'
)


@dataclass(frozen=True)
class Span:
    start_line: int
    end_line: int
    has_comment: bool


def usage() -> int:
    print(f"usage: {Path(sys.argv[0]).name} <safe-src-dir>", file=sys.stderr)
    return 64


def is_lifetime_or_label(text: str, index: int) -> bool:
    cursor = index + 1
    if cursor >= len(text):
        return False
    if not (text[cursor].isalpha() or text[cursor] == "_"):
        return False
    cursor += 1
    while cursor < len(text) and (text[cursor].isalnum() or text[cursor] == "_"):
        cursor += 1
    if cursor == index + 2 and cursor < len(text) and text[cursor] == "'":
        return False
    return True


def find_brace(text: str, start: int) -> int:
    depth = 0
    cursor = start
    in_line_comment = False
    block_comment_depth = 0
    in_string = False
    in_char = False
    raw_hashes: int | None = None
    escape = False

    while cursor < len(text):
        ch = text[cursor]
        nxt = text[cursor + 1] if cursor + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
        elif block_comment_depth:
            if ch == "/" and nxt == "*":
                block_comment_depth += 1
                cursor += 1
            elif ch == "*" and nxt == "/":
                block_comment_depth -= 1
                cursor += 1
        elif in_string:
            if raw_hashes is not None:
                if ch == '"' and text.startswith("#" * raw_hashes, cursor + 1):
                    cursor += raw_hashes
                    in_string = False
                    raw_hashes = None
            else:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
        elif in_char:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_char = False
        else:
            if ch == "/" and nxt == "/":
                in_line_comment = True
                cursor += 1
            elif ch == "/" and nxt == "*":
                block_comment_depth = 1
                cursor += 1
            elif ch == "r":
                probe = cursor + 1
                while probe < len(text) and text[probe] == "#":
                    probe += 1
                if probe < len(text) and text[probe] == '"':
                    in_string = True
                    raw_hashes = probe - (cursor + 1)
                    cursor = probe
            elif ch == '"':
                in_string = True
                raw_hashes = None
            elif ch == "'":
                if not is_lifetime_or_label(text, cursor):
                    in_char = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth = max(0, depth - 1)
            elif ch == "{" and depth == 0:
                return cursor
        cursor += 1

    return -1


def find_matching_brace(text: str, open_brace: int) -> int:
    depth = 1
    cursor = open_brace + 1
    in_line_comment = False
    block_comment_depth = 0
    in_string = False
    in_char = False
    raw_hashes: int | None = None
    escape = False

    while cursor < len(text):
        ch = text[cursor]
        nxt = text[cursor + 1] if cursor + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
        elif block_comment_depth:
            if ch == "/" and nxt == "*":
                block_comment_depth += 1
                cursor += 1
            elif ch == "*" and nxt == "/":
                block_comment_depth -= 1
                cursor += 1
        elif in_string:
            if raw_hashes is not None:
                if ch == '"' and text.startswith("#" * raw_hashes, cursor + 1):
                    cursor += raw_hashes
                    in_string = False
                    raw_hashes = None
            else:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
        elif in_char:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_char = False
        else:
            if ch == "/" and nxt == "/":
                in_line_comment = True
                cursor += 1
            elif ch == "/" and nxt == "*":
                block_comment_depth = 1
                cursor += 1
            elif ch == "r":
                probe = cursor + 1
                while probe < len(text) and text[probe] == "#":
                    probe += 1
                if probe < len(text) and text[probe] == '"':
                    in_string = True
                    raw_hashes = probe - (cursor + 1)
                    cursor = probe
            elif ch == '"':
                in_string = True
                raw_hashes = None
            elif ch == "'":
                if not is_lifetime_or_label(text, cursor):
                    in_char = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return cursor
        cursor += 1

    return -1


def line_number_at(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def previous_safety_comment(lines: list[str], line_index: int) -> tuple[bool, str | None]:
    probe = line_index - 1
    while probe >= 0 and not lines[probe].strip():
        probe -= 1
    if probe < 0:
        return False, None
    match = SAFETY_RE.match(lines[probe])
    if not match:
        return False, None
    category = match.group("category")
    return category in ALLOWED_CATEGORIES, category


def iter_function_spans(text: str, lines: list[str]) -> tuple[list[Span], list[str]]:
    spans: list[Span] = []
    errors: list[str] = []

    for match in FN_START_RE.finditer(text):
        brace = find_brace(text, match.end())
        if brace == -1:
            continue
        end = find_matching_brace(text, brace)
        if end == -1:
            continue

        start_line = line_number_at(text, match.start())
        end_line = line_number_at(text, end)
        body = text[brace + 1 : end]
        contains_unsafe = "unsafe" in body
        has_comment = False

        if contains_unsafe:
            valid, category = previous_safety_comment(lines, start_line - 1)
            has_comment = valid
            if not valid:
                if category is None:
                    errors.append(
                        f"{start_line}: function body contains unsafe without preceding SAFETY comment"
                    )
                else:
                    errors.append(
                        f"{start_line}: invalid SAFETY category {category!r} before function"
                    )

        spans.append(Span(start_line, end_line, has_comment))

    return spans, errors


def line_in_commented_function(spans: list[Span], line_number: int) -> bool:
    for span in spans:
        if span.has_comment and span.start_line <= line_number <= span.end_line:
            return True
    return False


def audit_file(path: Path) -> list[str]:
    if path.parts[-2:] == ("abi", "linux_x86_64.rs"):
        return []

    text = path.read_text()
    lines = text.splitlines()
    errors: list[str] = []

    spans, span_errors = iter_function_spans(text, lines)
    errors.extend(span_errors)

    for line_number, line in enumerate(lines, start=1):
        if UNSAFE_FN_DEF_RE.search(line):
            errors.append(f"{line_number}: unsafe fn definitions are forbidden")
            continue

        if "#[unsafe(" in line:
            continue

        if re.search(r'unsafe extern "C"\s*\{', line):
            continue

        if re.search(r'unsafe extern "C" fn\s*\(', line):
            continue

        if UNSAFE_IMPL_RE.search(line):
            valid, category = previous_safety_comment(lines, line_number - 1)
            if not valid:
                if category is None:
                    errors.append(f"{line_number}: unsafe impl lacks preceding SAFETY comment")
                else:
                    errors.append(
                        f"{line_number}: invalid SAFETY category {category!r} before unsafe impl"
                    )
            continue

        if "unsafe" not in line:
            continue

        if line_in_commented_function(spans, line_number):
            continue

        valid, _ = previous_safety_comment(lines, line_number - 1)
        if valid:
            continue

        errors.append(f"{line_number}: unsafe occurrence is not covered by a SAFETY comment")

    return [f"{path}:{message}" for message in errors]


def main() -> int:
    if len(sys.argv) != 2:
        return usage()

    src_root = Path(sys.argv[1]).resolve()
    if not src_root.is_dir():
        print(f"missing source directory: {src_root}", file=sys.stderr)
        return 66

    failures: list[str] = []
    for path in sorted(src_root.rglob("*.rs")):
        failures.extend(audit_file(path))

    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1

    print(f"unsafe audit passed for {src_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

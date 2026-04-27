"""Count unsafe blocks in a port's safe/ tree, classified by ABI shape and op.

A port lives at ``ports_root/port-{library}/safe/`` and contains the Rust
sources that ship in the safelibs override deb. For each library we walk
``*.rs`` under ``safe/`` (skipping ``target/``) and tally:

  * ``total``                — every ``unsafe { ... }`` expression block.
  * ``abi_shaped``           — block whose enclosing fn is shaped by the C
                               ABI (raw-pointer signature, ``extern``, or
                               ``unsafe fn``). Forced by drop-in compat.
  * ``voluntary``            — block whose enclosing fn has a fully safe Rust
                               signature (or no enclosing fn at all). The
                               block exists for reasons other than C-ABI
                               interop shape.
  * ``no_enclosing``         — subset of ``voluntary`` where the block sits
                               in a static initializer / module body.
  * ``abi_shaped_loc`` /
    ``voluntary_loc``        — line counts inside those blocks (incl braces).
  * ``blocks_with_any_op``   — blocks containing an op that would be unsafe
                               in any pure-Rust crate (transmute, asm!, raw
                               pointer assembly, ``MaybeUninit::assume_init``,
                               ``Pin::new_unchecked``, ``intrinsics::*``,
                               ``static mut`` access, etc.).
  * ``blocks_voluntary_with_any_op`` — intersection of ``voluntary`` and
                               ``blocks_with_any_op``.
  * ``op_buckets``           — per-category op counts (a block can hit
                               multiple).
  * ``rs_loc``               — total Rust LOC walked.

Counts are derived from a comment- and string-stripped view of each file
so attribute strings, doc comments, and string literals do not generate
false hits.
"""

from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path
from typing import Any

PORT_DIR_PREFIX = "port-"
SAFE_DIRNAME = "safe"
TARGET_DIRNAME = "target"

UNSAFE_BLOCK_FIELDS: tuple[str, ...] = (
    "total",
    "abi_shaped",
    "voluntary",
    "no_enclosing",
    "abi_shaped_loc",
    "voluntary_loc",
    "blocks_with_any_op",
    "blocks_voluntary_with_any_op",
    "rs_loc",
    "op_buckets",
)


_FN_HEADER_RE = re.compile(
    r'(?P<modifiers>(?:\b(?:pub(?:\s*\([^)]*\))?|const|async|extern(?:\s*"[^"]*")?|unsafe)\b\s*)*)'
    r'\bfn\b\s+[A-Za-z_][A-Za-z_0-9]*'
)
_UNSAFE_RE = re.compile(r'\bunsafe\b')
_RAW_PTR_IN_SIG_RE = re.compile(r'\*\s*(?:const|mut)\b')
_STATIC_MUT_RE = re.compile(r'\bstatic\s+mut\s+([A-Za-z_][A-Za-z_0-9]*)\b')

_OP_PATTERNS: dict[str, re.Pattern[str] | None] = {
    "transmute": re.compile(r'\btransmute(?:_copy|_unchecked)?\b'),
    "asm!": re.compile(r'\b(?:global_)?asm\s*!'),
    "static_mut": None,  # resolved per-file by name binding
    "from_raw": re.compile(r'\bfrom_raw(?:_parts(?:_mut)?)?\b'),
    "assume_init": re.compile(r'\bassume_init(?:_(?:mut|read|drop))?\b'),
    "new_unchecked": re.compile(r'\bnew_unchecked\b'),
    "unreachable_unchk": re.compile(r'\bunreachable_unchecked\b'),
    "get_unchecked": re.compile(r'\bget_unchecked(?:_mut)?\b'),
    "intrinsics": re.compile(r'\bintrinsics\s*::'),
    "core_arch_simd": re.compile(r'\b(?:core|std)::arch::'),
    "zeroed_uninit": re.compile(r'\b(?:zeroed|uninitialized)\s*\('),
    "set_len": re.compile(r'\.set_len\b'),
}


def strip_comments_and_strings(src: str) -> str:
    out: list[str] = []
    i = 0
    n = len(src)
    in_line_c = False
    in_block_c = 0
    in_str = False
    in_char = False
    in_raw = False
    raw_hashes = 0
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if in_line_c:
            if c == "\n":
                in_line_c = False
                out.append(c)
            else:
                out.append(" ")
            i += 1
            continue
        if in_block_c:
            if c == "/" and nxt == "*":
                in_block_c += 1
                out.append("  ")
                i += 2
                continue
            if c == "*" and nxt == "/":
                in_block_c -= 1
                out.append("  ")
                i += 2
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if in_str:
            if in_raw:
                if c == '"' and src[i + 1 : i + 1 + raw_hashes] == "#" * raw_hashes:
                    in_str = False
                    in_raw = False
                    out.append(" " + " " * raw_hashes)
                    i += 1 + raw_hashes
                    continue
                out.append("\n" if c == "\n" else " ")
                i += 1
                continue
            if c == "\\" and nxt:
                out.append("  ")
                i += 2
                continue
            if c == '"':
                in_str = False
                out.append(" ")
                i += 1
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if in_char:
            if c == "\\" and nxt:
                out.append("  ")
                i += 2
                continue
            if c == "'":
                in_char = False
                out.append(" ")
                i += 1
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if c == "/" and nxt == "/":
            in_line_c = True
            out.append("  ")
            i += 2
            continue
        if c == "/" and nxt == "*":
            in_block_c = 1
            out.append("  ")
            i += 2
            continue
        m = re.match(r'(?:b)?r(#*)"', src[i : i + 8])
        if m:
            in_str = True
            in_raw = True
            raw_hashes = len(m.group(1))
            consumed = m.end()
            out.append(" " * consumed)
            i += consumed
            continue
        if c == "b" and nxt == '"':
            in_str = True
            in_raw = False
            out.append("  ")
            i += 2
            continue
        if c == '"':
            in_str = True
            in_raw = False
            out.append(" ")
            i += 1
            continue
        if c == "'":
            m2 = re.match(r"'([A-Za-z_][A-Za-z0-9_]*)(?!')", src[i : i + 32])
            if m2:
                out.append(src[i : i + m2.end()])
                i += m2.end()
                continue
            in_char = True
            out.append(" ")
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _find_matching(s: str, open_idx: int, openc: str, closec: str) -> int:
    depth = 1
    p = open_idx + 1
    n = len(s)
    while p < n and depth > 0:
        ch = s[p]
        if ch == openc:
            depth += 1
        elif ch == closec:
            depth -= 1
        p += 1
    return p


def _find_matching_brace(s: str, open_idx: int) -> int:
    return _find_matching(s, open_idx, "{", "}")


def _fn_signature_text(clean: str, fn_match: re.Match[str]) -> tuple[str | None, int]:
    n = len(clean)
    p = fn_match.end()
    while p < n and clean[p].isspace():
        p += 1
    if p < n and clean[p] == "<":
        p = _find_matching(clean, p, "<", ">")
    while p < n and clean[p].isspace():
        p += 1
    if p >= n or clean[p] != "(":
        return None, -1
    paren_close = _find_matching(clean, p, "(", ")")
    sig_end = paren_close
    q = paren_close
    body_open = -1
    depth_lt = 0
    while q < n:
        ch = clean[q]
        if ch == "<":
            depth_lt += 1
        elif ch == ">" and depth_lt > 0:
            depth_lt -= 1
        elif depth_lt == 0:
            if ch == "{":
                body_open = q
                sig_end = q
                break
            if ch == ";":
                body_open = -1
                sig_end = q
                break
        q += 1
    return clean[fn_match.start() : sig_end], body_open


def analyze_file(src: str) -> dict[str, Any]:
    """Return per-file unsafe-block counts. ``op_buckets`` is a plain dict."""
    clean = strip_comments_and_strings(src)
    n = len(clean)
    static_muts = set(_STATIC_MUT_RE.findall(clean))

    fns: list[dict[str, Any]] = []
    for m in _FN_HEADER_RE.finditer(clean):
        modifiers = m.group("modifiers") or ""
        sig_text, body_open = _fn_signature_text(clean, m)
        if sig_text is None:
            continue
        body_close = _find_matching_brace(clean, body_open) if body_open != -1 else -1
        fns.append(
            {
                "body_open": body_open,
                "body_close": body_close,
                "unsafe_fn": bool(re.search(r"\bunsafe\b", modifiers)),
                "extern": bool(re.search(r"\bextern\b", modifiers)),
                "sig_raw_ptr": bool(_RAW_PTR_IN_SIG_RE.search(sig_text)),
            }
        )

    blocks: list[dict[str, Any]] = []
    for m in _UNSAFE_RE.finditer(clean):
        j = m.end()
        while j < n and clean[j].isspace():
            j += 1
        if j >= n or clean[j] != "{":
            continue
        body_open = j
        body_close = _find_matching_brace(clean, body_open)
        blocks.append(
            {
                "kw_pos": m.start(),
                "body_open": body_open,
                "body_close": body_close,
                "body": clean[body_open + 1 : body_close - 1],
            }
        )

    for b in blocks:
        enclosing: dict[str, Any] | None = None
        for fn in fns:
            if fn["body_open"] == -1 or fn["body_close"] == -1:
                continue
            if fn["body_open"] < b["kw_pos"] < fn["body_close"]:
                if enclosing is None or fn["body_open"] > enclosing["body_open"]:
                    enclosing = fn
        b["enclosing"] = enclosing

    blocks_total = len(blocks)
    abi_shaped = 0
    voluntary = 0
    no_enclosing = 0
    abi_shaped_loc = 0
    voluntary_loc = 0
    blocks_with_any_op = 0
    blocks_voluntary_with_any_op = 0
    op_buckets: dict[str, int] = defaultdict(int)

    for b in blocks:
        body = b["body"]
        block_lines = clean[b["body_open"] : b["body_close"]].count("\n") + 1
        any_op = False
        for name, pat in _OP_PATTERNS.items():
            if name == "static_mut":
                continue
            assert pat is not None
            if pat.search(body):
                any_op = True
                op_buckets[name] += 1
        if static_muts and any(re.search(rf"\b{re.escape(s)}\b", body) for s in static_muts):
            any_op = True
            op_buckets["static_mut"] += 1
        if any_op:
            blocks_with_any_op += 1

        encl = b["enclosing"]
        if encl is None:
            no_enclosing += 1
            voluntary += 1
            voluntary_loc += block_lines
            if any_op:
                blocks_voluntary_with_any_op += 1
            continue
        if encl["unsafe_fn"] or encl["extern"] or encl["sig_raw_ptr"]:
            abi_shaped += 1
            abi_shaped_loc += block_lines
        else:
            voluntary += 1
            voluntary_loc += block_lines
            if any_op:
                blocks_voluntary_with_any_op += 1

    return {
        "rs_loc": src.count("\n") + (0 if src.endswith("\n") else 1),
        "total": blocks_total,
        "abi_shaped": abi_shaped,
        "voluntary": voluntary,
        "no_enclosing": no_enclosing,
        "abi_shaped_loc": abi_shaped_loc,
        "voluntary_loc": voluntary_loc,
        "blocks_with_any_op": blocks_with_any_op,
        "blocks_voluntary_with_any_op": blocks_voluntary_with_any_op,
        "op_buckets": dict(op_buckets),
    }


def _empty_counts() -> dict[str, Any]:
    return {
        "rs_loc": 0,
        "total": 0,
        "abi_shaped": 0,
        "voluntary": 0,
        "no_enclosing": 0,
        "abi_shaped_loc": 0,
        "voluntary_loc": 0,
        "blocks_with_any_op": 0,
        "blocks_voluntary_with_any_op": 0,
        "op_buckets": {},
    }


def _add_counts(into: dict[str, Any], add: dict[str, Any]) -> None:
    for key in (
        "rs_loc",
        "total",
        "abi_shaped",
        "voluntary",
        "no_enclosing",
        "abi_shaped_loc",
        "voluntary_loc",
        "blocks_with_any_op",
        "blocks_voluntary_with_any_op",
    ):
        into[key] += add[key]
    bucket_into = into["op_buckets"]
    for name, value in add["op_buckets"].items():
        bucket_into[name] = bucket_into.get(name, 0) + value


def analyze_safe_dir(safe_dir: Path) -> dict[str, Any]:
    """Walk ``safe_dir`` and return aggregate per-port counts."""
    totals = _empty_counts()
    for path in sorted(safe_dir.rglob("*.rs")):
        if TARGET_DIRNAME in path.relative_to(safe_dir).parts:
            continue
        if not path.is_file():
            continue
        try:
            src = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        _add_counts(totals, analyze_file(src))
    return totals


def port_safe_dir(ports_root: Path, library: str) -> Path:
    return ports_root / f"{PORT_DIR_PREFIX}{library}" / SAFE_DIRNAME


def count_library(ports_root: Path, library: str) -> dict[str, Any] | None:
    """Counts for a single library, or ``None`` if its safe/ tree is missing."""
    safe_dir = port_safe_dir(ports_root, library)
    if not safe_dir.is_dir():
        return None
    return analyze_safe_dir(safe_dir)


def aggregate_counts(per_library: dict[str, dict[str, Any]]) -> dict[str, Any]:
    totals = _empty_counts()
    for counts in per_library.values():
        _add_counts(totals, counts)
    return totals

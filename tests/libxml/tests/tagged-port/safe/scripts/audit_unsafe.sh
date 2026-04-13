#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import re
import sys
from collections import Counter
from pathlib import Path

root = Path(sys.argv[1]).resolve()
src_root = root / "safe" / "src"
report_dir = root / "safe" / "target" / "audits"
report_dir.mkdir(parents=True, exist_ok=True)
report_path = report_dir / "unsafe-audit.tsv"

unsafe_re = re.compile(r"\bunsafe\b")

file_reasons = [
    ("safe/src/cli/", "handwritten CLI entrypoints still need direct FFI calls, raw C strings, FILE* handles, and parser-owned pointer lifetimes"),
    ("safe/src/debug/", "debug and shell support still cross libxml/libc FILE* and XPath callback boundaries with raw pointers"),
    ("safe/src/foundation/", "core foundational modules still implement the libxml C ABI with raw pointers, mutable globals, allocator callbacks, and layout-dependent state"),
    ("safe/src/parser/", "parser modules still mirror libxml parser contexts, callback entrypoints, and streaming state across the C ABI"),
    ("safe/src/schema/", "schema validation modules still depend on libxml ABI layouts, raw node pointers, and validator callback glue"),
    ("safe/src/tree_io/", "tree and I/O modules still cross libc/file-descriptor boundaries plus libxml-owned node and buffer pointers"),
    ("safe/src/xpath_valid/", "XPath, catalog, XInclude, pattern, and validation modules still manipulate libxml graph structures and callback state through raw pointers"),
    ("safe/src/abi/", "ABI mirrors still encode C layout and opaque-pointer contracts that Rust cannot express safely without `unsafe`"),
]


def reason_for(path: str) -> str:
    for prefix, reason in file_reasons:
        if path.startswith(prefix):
            return reason
    raise SystemExit(f"unsafe audit has no documented reason mapping for {path}")


def classify(line: str) -> str:
    stripped = line.strip()
    if re.search(r"\bunsafe\s+extern\b", stripped) and "fn" in stripped:
        return "unsafe extern fn"
    if re.search(r"\bunsafe\s+extern\b", stripped):
        return "unsafe extern block"
    if re.search(r"\bunsafe\s+fn\b", stripped):
        return "unsafe fn"
    if re.search(r"\bunsafe\s*\{", stripped):
        return "unsafe block"
    return "unsafe token"


rows: list[tuple[str, int, str, str, str]] = []
for path in sorted(src_root.rglob("*.rs")):
    rel = path.relative_to(root).as_posix()
    file_rows: list[tuple[str, int, str, str]] = []
    for line_no, raw_line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if unsafe_re.search(raw_line) is None:
            continue
        snippet = " ".join(raw_line.strip().split())
        file_rows.append((rel, line_no, classify(raw_line), snippet))
    if not file_rows:
        continue
    reason = reason_for(rel)
    for rel, line_no, kind, snippet in file_rows:
        rows.append((rel, line_no, kind, reason, snippet))

if not rows:
    raise SystemExit("unsafe audit found no unsafe occurrences; audit mapping is unexpectedly empty")

with report_path.open("w", encoding="utf-8") as report:
    report.write("path\tline\tkind\treason\tsnippet\n")
    for rel, line_no, kind, reason, snippet in rows:
        report.write(f"{rel}\t{line_no}\t{kind}\t{reason}\t{snippet}\n")

kind_counts = Counter(kind for _, _, kind, _, _ in rows)
reason_counts = Counter(reason for _, _, _, reason, _ in rows)

print(f"unsafe audit recorded {len(rows)} unsafe occurrences across {len({rel for rel, _, _, _, _ in rows})} files")
for kind, count in sorted(kind_counts.items()):
    print(f"  {kind}: {count}")
print("documented reason buckets:")
for reason, count in sorted(reason_counts.items()):
    print(f"  {count}: {reason}")
print(f"audit report: {report_path}")
PY

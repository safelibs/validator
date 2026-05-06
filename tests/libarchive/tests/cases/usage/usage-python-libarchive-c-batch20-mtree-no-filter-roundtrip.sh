#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-mtree-no-filter-roundtrip
# @title: python-libarchive-c mtree manifest without filter is plain text and roundtrips names
# @description: Writes an mtree manifest using libarchive.file_writer("...", "mtree") with no filter chain so the on-disk output is uncompressed text (must start with the "#mtree" sentinel). Reads the manifest back through libarchive.file_reader and verifies every entry name written is yielded after stripping the leading "./" mtree-convention prefix. Distinct from the existing mtree-gzip case which exercises the compressed variant.
# @timeout: 120
# @tags: usage, archive, mtree
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "out.mtree"
expected = {
    "first.txt": b"first body\n",
    "second.bin": b"second-bin\n",
    "nested/third.log": b"third nested log\n",
}

with libarchive.file_writer(str(arc), "mtree") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = arc.read_bytes()
# Plain mtree manifests start with the "#mtree" sentinel comment.
assert raw.startswith(b"#mtree"), raw[:32]

names_seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        names_seen.append(entry.pathname)
        b"".join(entry.get_blocks())

normalised = sorted(
    name[2:] if name.startswith("./") else name for name in names_seen
)
assert normalised == sorted(expected.keys()), (normalised, sorted(expected))
print("mtree-plain", len(raw), normalised)
PY

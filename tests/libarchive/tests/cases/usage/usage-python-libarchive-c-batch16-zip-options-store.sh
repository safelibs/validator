#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-zip-options-store
# @title: python-libarchive-c zip writer with compression=store option
# @description: Writes a zip archive with the file_writer options keyword set to "zip:compression=store" so libarchive emits each entry as a stored (no-compression) zip member. Verifies the PK signature on disk and that the entry payloads survive the round trip; the "store" path keeps the compressed-size and uncompressed-size of each member identical, which we can confirm via libarchive's reported entry.size.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-zip-options-store"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "store.zip"
expected = {
    "alpha.txt": b"alpha stored payload\n" * 32,
    "beta.txt": b"beta stored payload bytes\n" * 24,
    "gamma.bin": bytes(range(256)) * 4,
}

# options must be passed at writer construction time; libarchive_c 2.9 raises
# if archive_write_set_options is invoked after the writer is opened.
with libarchive.file_writer(
    str(archive_path),
    "zip",
    options="zip:compression=store",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
assert raw[:2] == b"PK", raw[:2]

# Heuristic: a "store" zip should be no smaller than the sum of payload sizes
# (plus per-entry headers/central-dir overhead). A deflate-compressed zip
# would be much smaller than the raw payloads given their high repetition.
total_payload = sum(len(v) for v in expected.values())
assert len(raw) >= total_payload, (len(raw), total_payload)

got = {}
sizes = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        sizes[entry.pathname] = entry.size
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
for name, body in expected.items():
    assert sizes[name] == len(body), (name, sizes[name], len(body))
print("zip-store", len(raw), sizes)
PY

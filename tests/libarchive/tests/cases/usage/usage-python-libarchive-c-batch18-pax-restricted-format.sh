#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-pax-restricted-format
# @title: python-libarchive-c pax_restricted format roundtrip
# @description: Writes an archive with format_name="pax_restricted" - libarchive's pax variant that emits ustar-compatible headers when the entry's metadata fits the ustar field widths and only falls back to a pax extended header for entries that require it. Verifies the file uses 512-byte tar block alignment, that a short-name entry stays inside ustar (no `PaxHeader/` global record needed), and that an entry with a 200-byte pathname forces the writer to emit a pax extended header. Reads everything back and confirms the payloads round trip.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-pax-restricted-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

short_only = tmpdir / "short.paxr"
mixed = tmpdir / "mixed.paxr"
short_entries = {
    "short.txt": b"short ascii payload\n",
    "alt.txt": b"alt ascii payload\n",
}
long_name = "deep/" + ("verbose-segment-" * 12) + "leaf.txt"  # ~200 chars
assert len(long_name) > 100, len(long_name)
mixed_entries = dict(short_entries)
mixed_entries[long_name] = b"long-name payload bytes\n"

for path, payload in [(short_only, short_entries), (mixed, mixed_entries)]:
    with libarchive.file_writer(str(path), "pax_restricted") as writer:
        for name, body in payload.items():
            writer.add_file_from_memory(name, len(body), body)

short_raw = short_only.read_bytes()
mixed_raw = mixed.read_bytes()

# pax/ustar block alignment is 512 bytes.
assert len(short_raw) % 512 == 0, len(short_raw)
assert len(mixed_raw) % 512 == 0, len(mixed_raw)

# Short-name-only archive must NOT carry a PaxHeader extended record because
# pax_restricted falls back to plain ustar when ustar can represent the entry.
assert b"PaxHeader" not in short_raw, "pax_restricted unexpectedly emitted PaxHeader"

# A 200-character path overflows ustar's name+prefix split, so pax_restricted
# is forced to emit an extended-header record for it.
assert b"PaxHeader" in mixed_raw, "expected PaxHeader for long-name entry"

# Both archives must read back to the original payloads.
for path, expected in [(short_only, short_entries), (mixed, mixed_entries)]:
    got = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            got[entry.pathname] = b"".join(entry.get_blocks())
    assert got == expected, (path, sorted(got.keys()), sorted(expected.keys()))

print("pax_restricted", len(short_raw), len(mixed_raw))
PY

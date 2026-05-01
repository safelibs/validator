#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-shar-write-roundtrip
# @title: python-libarchive-c shar format write
# @description: Writes a shar (shell archive) using libarchive.file_writer with format_name="shar". Asserts the produced file begins with the canonical `#!/bin/sh` shebang plus the libarchive shar comment banner, and contains an `echo x <name>` line and a `sed 's/^X//' > <name>` here-document opener for each member written. shar is a write-only format in libarchive, so the read-side check is on the shell-script structure itself rather than libarchive.file_reader.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-shar-write-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "out.shar"
expected = {
    "alpha.txt": b"alpha shar payload line\n",
    "beta.txt": b"beta shar payload line\n",
}

with libarchive.file_writer(str(archive_path), "shar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
text = raw.decode("ascii", errors="replace")
# shar archives are POSIX shell scripts; libarchive emits this exact banner.
assert text.startswith("#!/bin/sh\n"), text[:80]
assert "shell archive" in text, text[:200]
# Each member must produce the announce echo plus the sed-here-doc opener.
for name in expected:
    assert f"echo x {name}\n" in text, name
    assert f"sed 's/^X//' > {name}" in text, name
print("shar", len(raw), sorted(expected.keys()))
PY

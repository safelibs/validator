#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-tar-mode-0700-roundtrip
# @title: python-libarchive-c ustar entry mode 0o700 round-trips through file reader
# @description: Builds a ustar archive on disk where one entry is staged from a file chmod'd to 0o700, reads back via libarchive.file_reader, and asserts the recovered entry.mode masked with 0o777 equals 0o700, exercising the owner-only-permission round-trip distinct from the 0o644 and 0o755 mode cases.
# @timeout: 90
# @tags: usage, archive, ustar, mode-0700, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'r19-private\n' >"$stage/private.txt"
chmod 0700 "$stage/private.txt"

python3 - <<'PY' "$tmpdir" "$stage"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
stage = Path(sys.argv[2])
arc = tmpdir / "out.tar"

with libarchive.file_writer(str(arc), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(stage / "private.txt"))

found = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        if entry.pathname.endswith("private.txt"):
            found = entry.mode & 0o777
            b"".join(entry.get_blocks())

assert found == 0o700, oct(found) if found is not None else "no entry"
print("mode-0700-ok", oct(found))
PY

#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-mode-0755-roundtrip
# @title: python-libarchive-c ustar entry mode 0o755 round-trips through file reader
# @description: Builds a ustar archive on disk where one entry is added from a staged file chmod'd to 0o755, reads back via libarchive.file_reader, and asserts the recovered entry.mode masked with 0o777 equals 0o755, exercising the executable-permission round-trip distinct from the 0o644 mode case.
# @timeout: 90
# @tags: usage, archive, ustar, mode-0755, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf '#!/bin/sh\necho r18\n' >"$stage/script.sh"
chmod 0755 "$stage/script.sh"

python3 - <<'PY' "$tmpdir" "$stage"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
stage = Path(sys.argv[2])
arc = tmpdir / "out.tar"

with libarchive.file_writer(str(arc), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(stage / "script.sh"))

found = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        if entry.pathname.endswith("script.sh"):
            found = entry.mode & 0o777
            b"".join(entry.get_blocks())

assert found == 0o755, oct(found) if found is not None else "no entry"
print("mode-0755-ok", oct(found))
PY

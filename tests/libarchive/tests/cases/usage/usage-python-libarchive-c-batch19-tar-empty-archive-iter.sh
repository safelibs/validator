#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-empty-archive-iter
# @title: python-libarchive-c iterates an empty tar archive yielding zero entries
# @description: Writes a tar archive with zero entries via libarchive.file_writer and verifies file_reader iteration yields exactly zero entries.
# @timeout: 120
# @tags: usage, archive, edge
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "empty.tar"
with libarchive.file_writer(str(arc), "gnutar") as writer:
    pass

count = 0
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        count += 1
print("count", count)
assert count == 0, f"expected 0 entries, got {count}"
PY

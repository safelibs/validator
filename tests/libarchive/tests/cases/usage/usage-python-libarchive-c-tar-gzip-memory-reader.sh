#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-gzip-memory-reader
# @title: python-libarchive-c tar gzip memory reader
# @description: Reads a gzip-compressed tar archive from memory through python-libarchive-c and verifies the member order.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-python-libarchive-c-tar-gzip-memory-reader"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$workload" "$tmpdir"
from pathlib import Path
import sys
import libarchive

workload = sys.argv[1]
tmpdir = Path(sys.argv[2])

if workload.startswith("usage-python-libarchive-c-"):
    workload = workload[len("usage-python-libarchive-c-"):]
if workload.endswith("-entry"):
    workload = workload[: -len("-entry")]

def read_entries(path):
    entries = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            data = b"".join(entry.get_blocks())
            entries.append((entry.pathname, entry.size, data))
    return entries

raise SystemExit(f"unknown python-libarchive-c expanded workload: {workload}")
PYCASE

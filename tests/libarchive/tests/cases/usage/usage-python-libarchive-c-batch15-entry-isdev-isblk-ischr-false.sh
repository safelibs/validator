#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-entry-isdev-isblk-ischr-false
# @title: python-libarchive-c entry isdev/isblk/ischr return False on regular files
# @description: Writes a gnutar archive containing only regular file entries via python-libarchive-c, then reads each entry back and asserts entry.isdev, entry.isblk, and entry.ischr all evaluate False on every entry. entry.isreg is asserted True on the same entries to confirm the filetype check is wired up correctly. Pins the negative-side semantics of the device-type predicates that the existing positive-side tests don't cover.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-entry-isdev-isblk-ischr-false"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "regs.tar"
plan = {
    "alpha.txt": b"alpha regular payload\n",
    "beta.txt": b"beta regular payload\n",
    "gamma.txt": b"gamma regular payload bytes\n",
}

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name, payload in plan.items():
        writer.add_file_from_memory(name, len(payload), payload)

flags = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        flags[entry.pathname] = (
            entry.isreg,
            entry.isdev,
            entry.isblk,
            entry.ischr,
        )
        b"".join(entry.get_blocks())

assert sorted(flags) == sorted(plan), (sorted(flags), sorted(plan))
for name, (isreg, isdev, isblk, ischr) in flags.items():
    assert isreg is True, (name, isreg)
    assert isdev is False, (name, isdev)
    assert isblk is False, (name, isblk)
    assert ischr is False, (name, ischr)
print("device-flags-false", flags)
PY

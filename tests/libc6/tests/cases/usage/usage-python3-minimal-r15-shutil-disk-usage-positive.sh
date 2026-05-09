#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r15-shutil-disk-usage-positive
# @title: python3 os.statvfs returns positive total/used/free for /tmp
# @description: Calls os.statvfs('/tmp') in a single-shot python3 invocation, derives total/used/free from f_blocks, f_bavail, f_bfree, f_frsize, asserts each field is a positive integer, and asserts used + free <= total (filesystem accounting invariant) — exercising the libc statvfs binding directly. shutil.disk_usage is a thin wrapper over the same call but lives in the python3 package, not python3-minimal.
# @timeout: 60
# @tags: usage, python3, shutil, statvfs, libc, r15
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import os

st = os.statvfs("/tmp")
total = st.f_blocks * st.f_frsize
free  = st.f_bavail * st.f_frsize
used  = (st.f_blocks - st.f_bfree) * st.f_frsize

for name, value in (("total", total), ("free", free), ("used", used)):
    assert isinstance(value, int), (name, type(value))
    assert value > 0, (name, value)

# used + free should never exceed total on a sane statvfs.
assert used + free <= total, (used, free, total)

print("ok", total, used, free)
PY

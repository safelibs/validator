#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r15-shutil-disk-usage-positive
# @title: python3 shutil.disk_usage returns positive integer total/used/free for /tmp
# @description: Calls shutil.disk_usage('/tmp') in a single-shot python3 invocation, asserts the returned namedtuple's total, used, and free fields are positive integers, and asserts used + free <= total (filesystem accounting invariant) — exercising the libc-backed statvfs binding via python's shutil.
# @timeout: 60
# @tags: usage, python3, shutil, statvfs, libc, r15
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import shutil

usage = shutil.disk_usage("/tmp")
assert isinstance(usage.total, int), type(usage.total)
assert isinstance(usage.used, int),  type(usage.used)
assert isinstance(usage.free, int),  type(usage.free)

assert usage.total > 0, usage.total
assert usage.used  > 0, usage.used
assert usage.free  > 0, usage.free

# used + free should never exceed total on a sane statvfs.
assert usage.used + usage.free <= usage.total, (usage.used, usage.free, usage.total)

print("ok", usage.total, usage.used, usage.free)
PY

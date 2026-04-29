#!/usr/bin/env bash
# @testcase: usage-python3-hashlib-md5
# @title: python3 hashlib md5
# @description: Computes a known MD5 digest through the Python standard library runtime.
# @timeout: 180
# @tags: usage, python, runtime
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-hashlib-md5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import hashlib
print(hashlib.md5(b'abc').hexdigest())
PYCASE
validator_assert_contains "$tmpdir/out" '900150983cd24fb0d6963f7d28e17f72'

#!/usr/bin/env bash
# @testcase: usage-python3-ctypes-strlen
# @title: python3 ctypes calls libc strlen
# @description: Loads libc through ctypes.CDLL, declares argtypes/restype for strlen, and verifies the returned length matches a known byte string measured in Python.
# @timeout: 120
# @tags: usage, python, ctypes, libc
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-ctypes-strlen"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import ctypes
import ctypes.util

libc_name = ctypes.util.find_library('c') or 'libc.so.6'
libc = ctypes.CDLL(libc_name, use_errno=True)
libc.strlen.argtypes = [ctypes.c_char_p]
libc.strlen.restype = ctypes.c_size_t

samples = [b'', b'a', b'hello', b'libc-via-ctypes']
for s in samples:
    n = libc.strlen(s)
    print(f"len({s!r})={n} py={len(s)} ok={n == len(s)}")
PYCASE

validator_assert_contains "$tmpdir/out" "len(b'')=0 py=0 ok=True"
validator_assert_contains "$tmpdir/out" "len(b'hello')=5 py=5 ok=True"
validator_assert_contains "$tmpdir/out" "len(b'libc-via-ctypes')=15 py=15 ok=True"

#!/usr/bin/env bash
# @testcase: usage-python3-ctypes-libc-strlen
# @title: python3 ctypes calls libc strlen
# @description: Loads libc through ctypes.CDLL using ctypes.util.find_library and invokes strlen on a fixed byte string to verify the FFI bridge returns the expected length.
# @timeout: 120
# @tags: usage, python, libc
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-ctypes-libc-strlen"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import ctypes
import ctypes.util

name = ctypes.util.find_library("c")
assert name, "find_library('c') returned no name"
libc = ctypes.CDLL(name, use_errno=True)
libc.strlen.argtypes = [ctypes.c_char_p]
libc.strlen.restype = ctypes.c_size_t
sample = b"hello, ctypes"
n = libc.strlen(sample)
print(f"name={name}")
print(f"strlen={n}")
PYCASE

validator_assert_contains "$tmpdir/out" 'strlen=13'

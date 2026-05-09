#!/usr/bin/env bash
# @testcase: usage-python3-ctypes-libc-strlen
# @title: python3 ctypes calls libc memcmp on equal and unequal buffers
# @description: Loads libc through ctypes.CDLL using ctypes.util.find_library and invokes memcmp on three buffer pairs (equal, lhs<rhs, lhs>rhs) to verify the FFI bridge returns 0 for equal inputs and a sign-correct nonzero result for unequal inputs. Distinct from the strlen ctypes test in this library.
# @timeout: 120
# @tags: usage, python, libc
# @client: python3

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
libc.memcmp.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_size_t]
libc.memcmp.restype = ctypes.c_int

cases = [
    (b"abcdef", b"abcdef", 0),
    (b"abcdef", b"abcdeg", -1),
    (b"abcdeh", b"abcdeg",  1),
]
for a, b, want_sign in cases:
    n = libc.memcmp(a, b, len(a))
    sign = 0 if n == 0 else (1 if n > 0 else -1)
    ok = sign == want_sign
    print(f"name={name} a={a!r} b={b!r} memcmp={n} sign={sign} want={want_sign} ok={ok}")
PYCASE

grep -Eq 'a=.*b=.*memcmp=0 sign=0 want=0 ok=True'  "$tmpdir/out"
grep -Eq 'sign=-1 want=-1 ok=True' "$tmpdir/out"
grep -Eq 'sign=1 want=1 ok=True'   "$tmpdir/out"

#!/usr/bin/env bash
# @testcase: usage-python3-r19-struct-pack-int-network
# @title: python3 struct.pack with ">I" emits four big-endian bytes for an unsigned int
# @description: Invokes a one-line python3 program that calls struct.pack(">I", 0x01020304) and prints the resulting bytes as hex, then asserts the captured hex equals "01020304" - locking in libc-backed byte-order conversion via the python struct module.
# @timeout: 30
# @tags: usage, python3, struct, network-byte-order, r19
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import struct; print(struct.pack(">I", 0x01020304).hex())')
[[ "$got" == "01020304" ]] || {
    printf 'expected "01020304", got %q\n' "$got" >&2
    exit 1
}

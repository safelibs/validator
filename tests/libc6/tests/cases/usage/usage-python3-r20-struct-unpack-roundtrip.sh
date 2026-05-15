#!/usr/bin/env bash
# @testcase: usage-python3-r20-struct-unpack-roundtrip
# @title: python3 struct.unpack(">H", b"\x12\x34") recovers 0x1234
# @description: Invokes a one-line python3 program that calls struct.unpack(">H", b"\\x12\\x34") and prints the first tuple element in hex, then asserts the captured value equals "0x1234" - locking in libc-backed byte-order unpacking via the python struct module.
# @timeout: 30
# @tags: usage, python3, struct, unpack, r20
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import struct; print(hex(struct.unpack(">H", b"\x12\x34")[0]))')
[[ "$got" == "0x1234" ]] || {
    printf 'expected "0x1234", got %q\n' "$got" >&2
    exit 1
}

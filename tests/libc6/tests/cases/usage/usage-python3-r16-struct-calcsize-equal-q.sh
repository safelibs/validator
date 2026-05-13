#!/usr/bin/env bash
# @testcase: usage-python3-r16-struct-calcsize-equal-q
# @title: python3 struct.calcsize("=Q") reports 8 bytes on Ubuntu 24.04
# @description: Asks the full python3 interpreter for the size of "=Q" (standard, no padding, unsigned 64-bit) and asserts the answer is 8, locking in the standard-layout struct width that libc-aligned struct packing relies on.
# @timeout: 30
# @tags: usage, python3, struct
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(python3 -c "import struct;print(struct.calcsize('=Q'))")
[[ "$out" == "8" ]] || {
    printf 'expected 8, got %q\n' "$out" >&2
    exit 1
}

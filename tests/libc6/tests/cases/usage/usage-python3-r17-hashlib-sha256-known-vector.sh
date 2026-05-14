#!/usr/bin/env bash
# @testcase: usage-python3-r17-hashlib-sha256-known-vector
# @title: python3 hashlib.sha256("abc") matches the NIST FIPS 180 test vector
# @description: Runs python3 -c with hashlib.sha256(b"abc").hexdigest() and asserts the value equals the canonical NIST FIPS 180 test vector ba7816...f20015ad — locking in libc-backed openssl/hashlib digest for a well-known input.
# @timeout: 30
# @tags: usage, python3, hashlib, sha256
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import hashlib; print(hashlib.sha256(b"abc").hexdigest())')
want='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
[[ "$got" == "$want" ]] || {
    printf 'sha256("abc") mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}

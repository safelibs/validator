#!/usr/bin/env bash
# @testcase: usage-gpg-r21-print-md-ripemd160-pangram-vector
# @title: gpg --print-md RIPEMD160 of the lazy-dog pangram matches the RFC vector
# @description: Computes the RIPEMD-160 digest of the canonical "The quick brown fox jumps over the lazy dog" pangram via gpg --print-md and asserts the captured uppercase-hex digest equals the published vector 37F332F68DB77BD9D7EDD4969571AD671CF9DD3B, locking in libgcrypt's RIPEMD-160 implementation on a 43-byte input distinct from prior abc and empty-input vectors.
# @timeout: 60
# @tags: usage, gpg, print-md, ripemd160, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'The quick brown fox jumps over the lazy dog' | gpg --print-md RIPEMD160 2>/dev/null \
    | LC_ALL=C tr -d '[:space:]')
expected='37F332F68DB77BD9D7EDD4969571AD671CF9DD3B'
[[ "$digest" == "$expected" ]] || {
    printf 'expected %s\ngot      %s\n' "$expected" "$digest" >&2
    exit 1
}

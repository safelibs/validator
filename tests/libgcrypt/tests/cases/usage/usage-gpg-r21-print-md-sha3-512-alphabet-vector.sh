#!/usr/bin/env bash
# @testcase: usage-gpg-r21-print-md-sha3-512-alphabet-vector
# @title: gpg --print-md SHA3-512 of "abcdefghijklmnopqrstuvwxyz" matches NIST vector
# @description: Computes the SHA3-512 digest of the 26-character lowercase alphabet via gpg --print-md and asserts the captured uppercase-hex digest equals the published NIST CAVS vector AF328D17FA28753A3C9F5CB72E376B90440B96F0289E5703B729324A975AB384EDA565FC92AADED143669900D761861687ACDC0A5FFA358BD0571AAAD80ACA68, locking in libgcrypt's SHA3-512 implementation on a non-trivial input distinct from the existing abc and empty vectors.
# @timeout: 60
# @tags: usage, gpg, print-md, sha3-512, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'abcdefghijklmnopqrstuvwxyz' | gpg --print-md SHA3-512 2>/dev/null \
    | LC_ALL=C tr -d '[:space:]')
expected='AF328D17FA28753A3C9F5CB72E376B90440B96F0289E5703B729324A975AB384EDA565FC92AADED143669900D761861687ACDC0A5FFA358BD0571AAAD80ACA68'
[[ "$digest" == "$expected" ]] || {
    printf 'expected %s\ngot      %s\n' "$expected" "$digest" >&2
    exit 1
}

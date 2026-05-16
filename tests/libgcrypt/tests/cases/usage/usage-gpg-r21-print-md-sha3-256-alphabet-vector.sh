#!/usr/bin/env bash
# @testcase: usage-gpg-r21-print-md-sha3-256-alphabet-vector
# @title: gpg --print-md SHA3-256 of "abcdefghijklmnopqrstuvwxyz" matches NIST vector
# @description: Computes the SHA3-256 digest of the 26-character lowercase alphabet via gpg --print-md and asserts the captured uppercase-hex digest (whitespace stripped) equals the published NIST CAVS vector 7CAB2DC765E21B241DBC1C255CE620B29F527C6D5E7F5F843E56288F0D707521, locking in libgcrypt's SHA3-256 implementation on a 26-byte input distinct from prior abc and empty-input vectors.
# @timeout: 60
# @tags: usage, gpg, print-md, sha3-256, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'abcdefghijklmnopqrstuvwxyz' | gpg --print-md SHA3-256 2>/dev/null \
    | LC_ALL=C tr -d '[:space:]')
expected='7CAB2DC765E21B241DBC1C255CE620B29F527C6D5E7F5F843E56288F0D707521'
[[ "$digest" == "$expected" ]] || {
    printf 'expected %s\ngot      %s\n' "$expected" "$digest" >&2
    exit 1
}

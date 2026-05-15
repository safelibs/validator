#!/usr/bin/env bash
# @testcase: usage-gpg-r20-print-md-sha224-pangram-vector
# @title: gpg --print-md SHA224 of the FIPS pangram matches the canonical KAT
# @description: Pipes the 43-byte pangram "The quick brown fox jumps over the lazy dog" to gpg --print-md SHA224 and asserts the captured lowercase digest equals 730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525 - locking in libgcrypt's SHA224 path on the canonical pangram vector (distinct from r17 SHA224 abc and existing SHA1 pangram coverage).
# @timeout: 60
# @tags: usage, gpg, print-md, sha224, pangram, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'The quick brown fox jumps over the lazy dog' | gpg --print-md SHA224 \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:56}
expected='730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525'
[[ "$digest" == "$expected" ]] || {
    printf 'expected SHA224(pangram)=%s, got %s\n' "$expected" "$digest" >&2
    exit 1
}

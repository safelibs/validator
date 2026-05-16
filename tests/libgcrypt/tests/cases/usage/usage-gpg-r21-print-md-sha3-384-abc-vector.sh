#!/usr/bin/env bash
# @testcase: usage-gpg-r21-print-md-sha3-384-abc-vector
# @title: gpg --print-md SHA3-384 of "abc" matches the NIST abc vector
# @description: Computes the SHA3-384 digest of the three-byte literal "abc" via gpg --print-md and asserts the captured uppercase-hex digest equals the NIST CAVS vector EC01498288516FC926459F58E2C6AD8DF9B473CB0FC08C2596DA7CF0E49BE4B298D88CEA927AC7F539F1EDF228376D25, locking in libgcrypt's SHA3-384 implementation on the canonical abc input (the existing r20 case covered only the empty-input vector).
# @timeout: 60
# @tags: usage, gpg, print-md, sha3-384, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'abc' | gpg --print-md SHA3-384 2>/dev/null \
    | LC_ALL=C tr -d '[:space:]')
expected='EC01498288516FC926459F58E2C6AD8DF9B473CB0FC08C2596DA7CF0E49BE4B298D88CEA927AC7F539F1EDF228376D25'
[[ "$digest" == "$expected" ]] || {
    printf 'expected %s\ngot      %s\n' "$expected" "$digest" >&2
    exit 1
}

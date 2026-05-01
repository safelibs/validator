#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-cipher-camellia128
# @title: gpg symmetric encryption with camellia128
# @description: Encrypts and decrypts a payload with --cipher-algo CAMELLIA128 and confirms --list-packets reports symkey cipher 11 (camellia128) on the encrypted blob.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-cipher-camellia128"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

printf 'camellia128 payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase 'test' --cipher-algo CAMELLIA128 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
grep -Eqi 'cipher 11|camellia128|CAMELLIA128' "$tmpdir/packets"

"${gpg_batch[@]}" --passphrase 'test' --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"

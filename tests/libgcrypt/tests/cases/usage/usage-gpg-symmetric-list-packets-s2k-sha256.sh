#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-list-packets-s2k-sha256
# @title: gpg symmetric encryption advertises sha256 s2k digest
# @description: Encrypts symmetrically using --s2k-digest-algo SHA256 and confirms --list-packets reports a sha256 string-to-key specification on the encrypted blob.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-list-packets-s2k-sha256"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

printf 's2k digest probe payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase 'test' \
  --s2k-digest-algo SHA256 --s2k-mode 3 --cipher-algo AES256 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" 'symkey enc packet'
grep -Eqi 'sha256|digest 8' "$tmpdir/packets"

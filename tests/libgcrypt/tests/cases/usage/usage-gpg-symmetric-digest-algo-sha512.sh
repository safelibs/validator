#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-digest-algo-sha512
# @title: gpg symmetric s2k with --digest-algo SHA512
# @description: Symmetrically encrypts a payload with explicit --digest-algo SHA512 (S2K hash) and round-trips the plaintext, confirming the s2k symkey packet header is present.
# @timeout: 180
# @tags: usage, gpg, crypto, s2k
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-digest-algo-sha512"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-digest-algo-passphrase

printf 'digest-algo sha512 payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo AES256 \
  --digest-algo SHA512 --s2k-mode 3 --symmetric \
  -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"

"${gpg_batch[@]}" --passphrase "$passphrase" --list-packets \
  "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" 'symkey enc packet'

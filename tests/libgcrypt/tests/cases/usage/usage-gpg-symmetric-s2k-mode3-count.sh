#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-s2k-mode3-count
# @title: gpg symmetric s2k mode 3 with explicit count
# @description: Encrypts symmetrically with explicit --s2k-mode 3 and --s2k-count, then decrypts and verifies the roundtrip sha256 matches.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-s2k-mode3-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-s2k-passphrase

printf 's2k mode three payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase "$passphrase" \
  --cipher-algo AES256 --s2k-mode 3 --s2k-count 65011712 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"

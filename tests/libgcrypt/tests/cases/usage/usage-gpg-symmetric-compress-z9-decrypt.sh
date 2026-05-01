#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-compress-z9-decrypt
# @title: gpg symmetric encryption with compression level 9
# @description: Encrypts a highly compressible payload with --compress-level 9 and ZLIB, confirms ciphertext is materially smaller than plaintext, and verifies the decrypt sha256 matches.
# @timeout: 180
# @tags: usage, gpg, compression
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-compress-z9-decrypt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

# 16 KiB of repeating bytes is highly compressible.
yes 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' | head -c 16384 >"$tmpdir/plain.txt"
plain_size=$(wc -c <"$tmpdir/plain.txt")
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase 'test' \
  --compress-algo ZLIB --compress-level 9 --cipher-algo AES256 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

cipher_size=$(wc -c <"$tmpdir/plain.gpg")
test "$cipher_size" -lt "$plain_size"

"${gpg_batch[@]}" --passphrase 'test' --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"

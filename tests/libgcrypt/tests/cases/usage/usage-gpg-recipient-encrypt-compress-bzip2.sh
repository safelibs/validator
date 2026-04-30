#!/usr/bin/env bash
# @testcase: usage-gpg-recipient-encrypt-compress-bzip2
# @title: gpg recipient encrypt with --compress-algo BZIP2
# @description: Encrypts a compressible payload to a generated recipient using --compress-algo BZIP2, verifies the OpenPGP packet stream contains a compressed packet with algo=3 (BZip2), and round-trips the plaintext through decryption.
# @timeout: 240
# @tags: usage, gpg, crypto, compression
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-recipient-encrypt-compress-bzip2"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator BzRecipient <validator-bz-recipient@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1

# Make the payload large and repetitive so a compressed packet really materializes.
# Avoid `yes | head -c` -- pipefail+SIGPIPE on `yes` would fail the script.
{
  i=0
  while ((i < 200)); do
    printf 'bzip2 recipient payload %04d\n' "$i"
    ((i+=1))
  done
} >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --trust-model always \
  --compress-algo BZIP2 \
  --encrypt -r "$uid" \
  -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
# OpenPGP compression algo 3 == BZip2 (RFC 4880 9.3).
validator_assert_contains "$tmpdir/packets" ':compressed packet: algo=3'

"${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg" 2>/dev/null
cmp "$tmpdir/plain.txt" "$tmpdir/out"

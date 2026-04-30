#!/usr/bin/env bash
# @testcase: usage-gpg-recipient-encrypt-compress-none
# @title: gpg recipient encrypt with --compress-algo none
# @description: Encrypts a payload to a generated recipient with --compress-algo none and asserts that the inner OpenPGP stream contains a literal data packet with no preceding compressed packet, then round-trips the plaintext.
# @timeout: 240
# @tags: usage, gpg, crypto, compression
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-recipient-encrypt-compress-none"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator NoCompress <validator-no-compress@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1

printf 'no-compression recipient payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --trust-model always \
  --compress-algo none \
  --encrypt -r "$uid" \
  -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

# Decrypt and confirm the cleartext survives.
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg" 2>/dev/null
validator_assert_contains "$tmpdir/out" 'no-compression recipient payload'

# Decrypt to a raw inner-packet stream so we can inspect what the encrypted
# container actually wraps. With --compress-algo none there must be no
# compressed packet between the SEIP/AEAD layer and the literal data.
"${gpg_batch[@]}" --decrypt -o "$tmpdir/inner" "$tmpdir/plain.gpg" 2>/dev/null

# Top-level packet listing should still show a literal data packet.
gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':literal data packet:'
if grep -q ':compressed packet:' "$tmpdir/packets"; then
  printf 'unexpected compressed packet present despite --compress-algo none\n' >&2
  cat "$tmpdir/packets" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-gpg-hidden-recipient-anonymous-keyid
# @title: gpg --hidden-recipient masks recipient key id in PKESK packet
# @description: Encrypts to a generated key with --hidden-recipient (no plain -r), confirms gpg --list-packets reports keyid 0000000000000000 in the public-key-encrypted-session-key packet, and round-trips the plaintext through decryption.
# @timeout: 240
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-hidden-recipient-anonymous-keyid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator HiddenAnon <validator-hidden-anon@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1

printf 'hidden anonymous payload\n' >"$tmpdir/plain.txt"

# Encrypt only via --hidden-recipient; -R/--recipient must NOT appear.
"${gpg_batch[@]}" --trust-model always \
  --hidden-recipient "$uid" \
  --encrypt -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

# The PKESK packet must carry an anonymized (zero) keyid.
gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':pubkey enc packet:'
validator_assert_contains "$tmpdir/packets" 'keyid 0000000000000000'

# And the message must still round-trip through the secret key in this homedir.
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg" 2>/dev/null
validator_assert_contains "$tmpdir/out" 'hidden anonymous payload'

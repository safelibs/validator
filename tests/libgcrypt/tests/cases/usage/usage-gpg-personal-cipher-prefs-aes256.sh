#!/usr/bin/env bash
# @testcase: usage-gpg-personal-cipher-prefs-aes256
# @title: gpg --personal-cipher-preferences AES256 selects symmetric cipher
# @description: Generates a recipient key and encrypts a payload with --personal-cipher-preferences AES256 set, then inspects the resulting OpenPGP packet stream after decryption and asserts the symmetric cipher recorded was AES256 (cipher 9).
# @timeout: 240
# @tags: usage, gpg, encryption, preferences
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-personal-cipher-prefs-aes256"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Cipher Pref User <cipherpref@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

printf 'cipher pref payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --personal-cipher-preferences AES256 \
  --trust-model always --encrypt -r "$uid" \
  -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

# Decrypt and ensure the round-trip works.
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out.txt" "$tmpdir/cipher.gpg"
validator_assert_contains "$tmpdir/out.txt" 'cipher pref payload'

# --list-packets will report the cipher used inside the SED/AEAD container.
# AES256 is OpenPGP symmetric cipher id 9; emitted as "cipher=9" (AEAD form)
# or "cipher 9" / "sym algo 9" (legacy SEIPDv1 form) depending on gpg version.
gpg --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets.txt" 2>&1
grep -Eq 'cipher[ =:]+9([^0-9]|$)|sym algo[ :]+9([^0-9]|$)' "$tmpdir/packets.txt" || {
  printf 'expected AES256 (cipher 9) marker in packet listing:\n' >&2
  cat "$tmpdir/packets.txt" >&2
  exit 1
}

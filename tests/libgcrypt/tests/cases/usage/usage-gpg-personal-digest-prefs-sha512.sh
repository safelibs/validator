#!/usr/bin/env bash
# @testcase: usage-gpg-personal-digest-prefs-sha512
# @title: gpg --personal-digest-preferences SHA512 selects digest for signing
# @description: Generates an ed25519 signing key and signs a payload with --personal-digest-preferences SHA512 set, then inspects the resulting signature packet and asserts the chosen digest algorithm is SHA512 (10).
# @timeout: 240
# @tags: usage, gpg, signature, preferences
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-personal-digest-prefs-sha512"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Digest Pref Signer <digestpref@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'digest pref payload\n' >"$tmpdir/plain.txt"

# --personal-digest-preferences SHA512 should drive the digest selection
# without us specifying --digest-algo explicitly.
"${gpg_batch[@]}" --personal-digest-preferences SHA512 \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"

gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/verify.out" 2>&1
validator_assert_contains "$tmpdir/verify.out" 'Good signature'

gpg --list-packets "$tmpdir/plain.sig" >"$tmpdir/packets.txt"
# SHA512 = OpenPGP digest algorithm id 10.
validator_assert_contains "$tmpdir/packets.txt" 'digest algo 10'

#!/usr/bin/env bash
# @testcase: usage-gpg-enarmor-roundtrip
# @title: gpg enarmor round trip
# @description: Converts binary data to ASCII armor with gpg enarmor, dearmors it again, and verifies the bytes match.
# @timeout: 180
# @tags: usage, crypto, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-enarmor-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator More <validator-more@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

printf 'armored file payload\n' >"$tmpdir/plain.bin"
gpg --enarmor <"$tmpdir/plain.bin" >"$tmpdir/plain.asc"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP ARMORED FILE'
gpg --dearmor -o "$tmpdir/out.bin" "$tmpdir/plain.asc"
cmp "$tmpdir/plain.bin" "$tmpdir/out.bin"

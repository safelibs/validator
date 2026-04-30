#!/usr/bin/env bash
# @testcase: usage-gpg-import-options-keep-ownertrust-roundtrip
# @title: gpg import-options keep-ownertrust round-trip
# @description: Generates a key, exports its ownertrust and public key, re-imports both into a fresh GNUPGHOME with --import-options keep-ownertrust, and verifies the original ownertrust value is preserved across the round-trip.
# @timeout: 240
# @tags: usage, gpg, trustdb, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-options-keep-ownertrust-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src_home="$tmpdir/src"
dst_home="$tmpdir/dst"
mkdir -p "$src_home" "$dst_home"
chmod 700 "$src_home" "$dst_home"

gpg_src=(gpg --homedir "$src_home" --batch --yes --pinentry-mode loopback)
gpg_dst=(gpg --homedir "$dst_home" --batch --yes --pinentry-mode loopback)

uid='Validator KeepOwnertrust <validator-keepownertrust@example.invalid>'

"${gpg_src[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

fingerprint=$(gpg --homedir "$src_home" --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
test -n "$fingerprint"

# Quick-generated keys land at trust=ultimate (6). Capture and re-stamp it
# explicitly so the assertion below is unambiguous.
printf '%s:6:\n' "$fingerprint" | gpg --homedir "$src_home" --import-ownertrust >/dev/null 2>&1

gpg --homedir "$src_home" --export-ownertrust >"$tmpdir/ownertrust.txt" 2>/dev/null
validator_assert_contains "$tmpdir/ownertrust.txt" "$fingerprint:6:"

gpg --homedir "$src_home" --armor --export "$uid" >"$tmpdir/pub.asc"
validator_assert_contains "$tmpdir/pub.asc" 'BEGIN PGP PUBLIC KEY BLOCK'

# Seed the destination's ownertrust file BEFORE importing the public key,
# then import with keep-ownertrust so gpg does not stomp the seeded value.
gpg --homedir "$dst_home" --import-ownertrust <"$tmpdir/ownertrust.txt" >/dev/null 2>&1

gpg --homedir "$dst_home" --import-options keep-ownertrust --import "$tmpdir/pub.asc" >"$tmpdir/import.out" 2>&1
validator_assert_contains "$tmpdir/import.out" 'imported'

gpg --homedir "$dst_home" --export-ownertrust >"$tmpdir/dst_ownertrust.txt" 2>/dev/null
validator_assert_contains "$tmpdir/dst_ownertrust.txt" "$fingerprint:6:"

# Cross-check via with-colons listing: the imported key's owner trust must be 'u' (ultimate).
gpg --homedir "$dst_home" --with-colons --list-keys "$fingerprint" >"$tmpdir/colons.out" 2>&1
trust_field=$(awk -F: '$1 == "pub" {print $2; exit}' "$tmpdir/colons.out")
test "$trust_field" = "u"

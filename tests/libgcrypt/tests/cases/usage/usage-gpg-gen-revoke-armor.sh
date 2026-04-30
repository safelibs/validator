#!/usr/bin/env bash
# @testcase: usage-gpg-gen-revoke-armor
# @title: gpg auto-generated revocation certificate
# @description: Generates an unattended ed25519 key, locates the armored revocation certificate gpg auto-stores under openpgp-revocs.d, and confirms gpg --list-packets reports a class 0x20 signature.
# @timeout: 240
# @tags: usage, gpg, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-gen-revoke-armor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator Revoke <validator-revoke@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# gpg automatically stores a usable revocation certificate alongside each
# generated key in openpgp-revocs.d/<FPR>.rev. The file is a regular
# armored OpenPGP public key block prefixed by an explanatory comment
# header, with a leading ':' inserted before the dashes to prevent
# accidental import. Strip that colon before parsing.
shopt -s nullglob
rev_files=("$GNUPGHOME/openpgp-revocs.d/"*.rev)
shopt -u nullglob
test "${#rev_files[@]}" -eq 1
rev_file=${rev_files[0]}
test -s "$rev_file"

grep -q '^:-----BEGIN PGP PUBLIC KEY BLOCK-----' "$rev_file"
grep -q '^-----END PGP PUBLIC KEY BLOCK-----' "$rev_file"

# Remove the protective leading colon on the BEGIN line so gpg can parse
# the armored block (the END line is left intact by gpg).
sed 's/^://' "$rev_file" >"$tmpdir/revoke.asc"
grep -q '^-----BEGIN PGP PUBLIC KEY BLOCK-----' "$tmpdir/revoke.asc"

gpg --list-packets "$tmpdir/revoke.asc" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" 'sigclass 0x20'
validator_assert_contains "$tmpdir/packets" ':signature packet:'

#!/usr/bin/env bash
# @testcase: usage-gpg-r13-clearsign-banner-and-payload
# @title: gpg --clearsign output begins with PGP SIGNED MESSAGE banner and embeds the payload
# @description: Generates an Ed25519 signing key, produces a --clearsign output over a fixed payload, asserts the first line is exactly "-----BEGIN PGP SIGNED MESSAGE-----", and asserts the cleartext payload appears verbatim before the signature block.
# @timeout: 240
# @tags: usage, gpg, clearsign
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R13 Clearsign <r13-clearsign@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

payload='r13 clearsign banner payload'
printf '%s\n' "$payload" >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --clearsign -o "$tmpdir/signed.asc" "$tmpdir/plain.txt" >/dev/null 2>&1

first=$(sed -n '1p' "$tmpdir/signed.asc")
[[ "$first" == "-----BEGIN PGP SIGNED MESSAGE-----" ]]

validator_assert_contains "$tmpdir/signed.asc" "$payload"
validator_assert_contains "$tmpdir/signed.asc" '-----BEGIN PGP SIGNATURE-----'
validator_assert_contains "$tmpdir/signed.asc" '-----END PGP SIGNATURE-----'

#!/usr/bin/env bash
# @testcase: usage-gpg-r13-textmode-sign-decrypt-roundtrip
# @title: gpg --textmode --sign followed by --decrypt recovers the original payload byte-for-byte
# @description: Generates an Ed25519 signing key, signs a multi-line text payload with --textmode (canonical-text mode), runs gpg --decrypt on the resulting OpenPGP message, and asserts the recovered plaintext matches the original via cmp.
# @timeout: 240
# @tags: usage, gpg, textmode, sign, decrypt
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R13 Textmode <r13-textmode@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'r13 textmode payload line 1\nr13 textmode payload line 2\n' \
  >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --textmode --sign -o "$tmpdir/signed.pgp" "$tmpdir/plain.txt" >/dev/null 2>&1

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/signed.pgp" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"

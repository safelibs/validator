#!/usr/bin/env bash
# @testcase: usage-gpg-r10-export-options-export-clean
# @title: gpg --export with --export-options export-clean exports a public key
# @description: Generates an Ed25519 key, exports it with --export-options export-clean, and verifies the resulting bytes are a non-empty OpenPGP public key block (public-key packet at the start).
# @timeout: 240
# @tags: usage, gpg, export
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 ExportClean <r10-exclean@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --export-options export-clean --export "$uid" >"$tmpdir/pub.gpg" 2>/dev/null
[[ -s "$tmpdir/pub.gpg" ]]

gpg --batch --list-packets "$tmpdir/pub.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':public key packet:'

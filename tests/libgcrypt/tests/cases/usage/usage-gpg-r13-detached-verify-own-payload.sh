#!/usr/bin/env bash
# @testcase: usage-gpg-r13-detached-verify-own-payload
# @title: gpg --detach-sign followed by --verify succeeds on the original payload
# @description: Generates an Ed25519 signing key, produces a detached signature with --detach-sign over a fixed payload, runs gpg --verify against the unmodified payload, and asserts both the verify exit status is zero and the status output reports a Good signature.
# @timeout: 240
# @tags: usage, gpg, detach-sign, verify
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R13 Detach <r13-detach@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'r13 detached own-payload sample\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1

# Verify must succeed; capture combined output for the Good-signature assertion.
gpg --batch --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/v.out" 2>"$tmpdir/v.err"

# Status text appears on stderr from gpg --verify.
validator_assert_contains "$tmpdir/v.err" 'Good signature'

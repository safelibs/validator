#!/usr/bin/env bash
# @testcase: usage-gpg-r12-detach-sign-verify-tampered-fails
# @title: gpg --detach-sign verifies original payload but rejects mutated payload
# @description: Generates an Ed25519 key, produces a detached signature with --detach-sign, verifies it succeeds against the unmodified payload, then mutates the payload and asserts gpg --verify exits non-zero against the tampered file.
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

uid='Validator R12 Detach <r12-detach@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'r12 detach sign payload\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1

# Verify against unchanged payload succeeds.
gpg --batch --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1

# Mutate the payload and verify must fail.
printf 'r12 detach sign payload TAMPERED\n' >"$tmpdir/plain.txt"
if gpg --batch --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1; then
  echo 'verify unexpectedly succeeded for tampered payload' >&2
  exit 1
fi

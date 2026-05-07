#!/usr/bin/env bash
# @testcase: usage-gpg-r15-detached-binary-sign-verify-roundtrip
# @title: gpg --detach-sign produces a binary signature that --verify accepts
# @description: Generates an Ed25519 sign-only key in an ephemeral GNUPGHOME, produces a binary detached signature with --detach-sign (no --armor), asserts the resulting .sig file is a non-empty binary blob whose first byte is NOT '-' (i.e., not an ASCII-armor header), then asserts gpg --verify accepts the detached signature against the original payload.
# @timeout: 240
# @tags: usage, gpg, detach-sign, binary, verify, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R15 Detach Binary <r15-detach-bin@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'r15 binary detach payload line 1\nr15 line 2\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1

[[ -s "$tmpdir/plain.sig" ]]

# Binary detached sig must NOT begin with '-' (ASCII-armor banner starts "-----").
first_byte=$(LC_ALL=C dd if="$tmpdir/plain.sig" bs=1 count=1 status=none | LC_ALL=C od -An -c \
              | LC_ALL=C tr -d ' ')
[[ "$first_byte" != "-" ]] || {
  echo 'detached signature unexpectedly looks ASCII-armored' >&2
  exit 1
}

gpg --batch --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >/dev/null 2>&1

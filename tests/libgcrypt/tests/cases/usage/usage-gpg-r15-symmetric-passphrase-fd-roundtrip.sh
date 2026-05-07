#!/usr/bin/env bash
# @testcase: usage-gpg-r15-symmetric-passphrase-fd-roundtrip
# @title: gpg --symmetric --passphrase-fd reads the passphrase from a file descriptor and round-trips
# @description: Symmetrically encrypts a fixed payload by feeding the passphrase via --passphrase-fd 0 (stdin) under an ephemeral GNUPGHOME, decrypts back the same way, and asserts the recovered plaintext matches the original via cmp — exercising libgcrypt's S2K + symmetric crypto path under fd-based passphrase entry rather than literal --passphrase.
# @timeout: 60
# @tags: usage, gpg, symmetric, passphrase-fd, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r15 symmetric passphrase-fd payload\n' >"$tmpdir/plain.txt"
pp='r15-passphrase-fd-pp'

# Feed passphrase via stdin (--passphrase-fd 0).
printf '%s' "$pp" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

[[ -s "$tmpdir/cipher.gpg" ]]

printf '%s' "$pp" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"

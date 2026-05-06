#!/usr/bin/env bash
# @testcase: usage-gpg-r9-symmetric-binary-magic
# @title: gpg symmetric binary file lacks ASCII armor header
# @description: Encrypts a file symmetrically without --armor and verifies the resulting bytes do not contain the BEGIN PGP MESSAGE armor banner.
# @timeout: 120
# @tags: usage, gpg, symmetric, binary
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'binary symmetric content\n' >"$tmpdir/plain"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --symmetric -o "$tmpdir/cipher.bin" "$tmpdir/plain"

[[ -s "$tmpdir/cipher.bin" ]]
! grep -q 'BEGIN PGP MESSAGE' "$tmpdir/cipher.bin"

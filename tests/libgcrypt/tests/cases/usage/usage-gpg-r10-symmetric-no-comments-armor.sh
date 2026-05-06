#!/usr/bin/env bash
# @testcase: usage-gpg-r10-symmetric-no-comments-armor
# @title: gpg --no-comments suppresses Comment line in armored output
# @description: Encrypts a file symmetrically with --armor and --no-comments and verifies the resulting ASCII-armor block contains the BEGIN PGP MESSAGE banner but no Comment: header line.
# @timeout: 60
# @tags: usage, gpg, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'no-comments payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --armor --no-comments --symmetric -o "$tmpdir/cipher.asc" "$tmpdir/plain.txt"

validator_assert_contains "$tmpdir/cipher.asc" 'BEGIN PGP MESSAGE'
if grep -qE '^Comment:' "$tmpdir/cipher.asc"; then
  printf 'unexpected Comment: header in armored output:\n' >&2
  sed -n '1,20p' "$tmpdir/cipher.asc" >&2
  exit 1
fi

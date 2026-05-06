#!/usr/bin/env bash
# @testcase: usage-gpg-r10-show-session-key-symmetric
# @title: gpg --show-session-key emits session key on symmetric decrypt
# @description: Symmetrically encrypts a payload then decrypts with --show-session-key and verifies the session key debug line is printed alongside the recovered plaintext.
# @timeout: 60
# @tags: usage, gpg, symmetric, session-key
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'session key payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --show-session-key -d "$tmpdir/cipher.gpg" >"$tmpdir/out" 2>"$tmpdir/err"

validator_assert_contains "$tmpdir/out" 'session key payload'
grep -qiE 'session key' "$tmpdir/err" || {
  printf 'expected session key line on stderr\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}

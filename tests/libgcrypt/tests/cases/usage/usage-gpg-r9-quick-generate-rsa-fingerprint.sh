#!/usr/bin/env bash
# @testcase: usage-gpg-r9-quick-generate-rsa-fingerprint
# @title: gpg --quick-generate-key RSA emits fingerprint
# @description: Generates an RSA-2048 signing key in a fresh GNUPGHOME and verifies a 40-character hex fingerprint can be extracted via --with-colons.
# @timeout: 240
# @tags: usage, gpg, rsa
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R9 <r9@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" rsa2048 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1
fpr=$(awk -F: '$1=="fpr"{print $10; exit}' "$tmpdir/colons")
[[ ${#fpr} -eq 40 ]] || {
  printf 'expected 40-char fingerprint, got %s\n' "$fpr" >&2
  exit 1
}
[[ "$fpr" =~ ^[A-F0-9]+$ ]]

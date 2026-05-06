#!/usr/bin/env bash
# @testcase: usage-gpg-r10-quick-generate-nistp384
# @title: gpg --quick-generate-key NIST P-384 produces 40-char fingerprint
# @description: Generates a NIST P-384 ECC signing key in a fresh GNUPGHOME and verifies the resulting fingerprint is 40 uppercase hex characters.
# @timeout: 240
# @tags: usage, gpg, ecc
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 nistp384 <r10-p384@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" nistp384 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1
fpr=$(awk -F: '$1=="fpr"{print $10; exit}' "$tmpdir/colons")
[[ ${#fpr} -eq 40 ]] || {
  printf 'expected 40-char fingerprint, got %s\n' "$fpr" >&2
  exit 1
}
[[ "$fpr" =~ ^[A-F0-9]+$ ]]

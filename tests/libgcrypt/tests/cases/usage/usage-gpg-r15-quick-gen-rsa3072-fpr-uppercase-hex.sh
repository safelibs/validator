#!/usr/bin/env bash
# @testcase: usage-gpg-r15-quick-gen-rsa3072-fpr-uppercase-hex
# @title: gpg --quick-generate-key rsa3072 produces a 40-uppercase-hex fingerprint
# @description: Generates an RSA-3072 signing key in a fresh ephemeral GNUPGHOME, runs gpg --batch --with-colons --list-keys, extracts the fpr record's field 10 with awk, and asserts the value is exactly 40 characters and matches the uppercase hex pattern [A-F0-9]{40} — exercising libgcrypt's RSA keygen at a 3072-bit modulus distinct from r9's rsa2048 case.
# @timeout: 240
# @tags: usage, gpg, quick-generate, rsa3072, fingerprint, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R15 RSA3072 <r15-rsa3072@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" rsa3072 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1

fpr=$(LC_ALL=C awk -F: '$1=="fpr"{print $10; exit}' "$tmpdir/colons")
[[ ${#fpr} -eq 40 ]] || {
  printf 'expected 40-char fingerprint, got %s\n' "$fpr" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}
[[ "$fpr" =~ ^[A-F0-9]{40}$ ]] || {
  printf 'fingerprint not uppercase-hex: %s\n' "$fpr" >&2
  exit 1
}

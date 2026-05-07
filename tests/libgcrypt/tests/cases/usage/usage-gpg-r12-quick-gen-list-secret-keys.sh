#!/usr/bin/env bash
# @testcase: usage-gpg-r12-quick-gen-list-secret-keys
# @title: gpg --quick-generate-key registers an ed25519 key visible in --list-secret-keys
# @description: Generates an Ed25519 sign-only key in a fresh GNUPGHOME with --quick-generate-key and asserts gpg --with-colons --list-secret-keys emits exactly one sec: record whose fingerprint is 40 uppercase hex characters.
# @timeout: 240
# @tags: usage, gpg, keygen, list-secret-keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R12 Sec <r12-sec@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-secret-keys >"$tmpdir/colons" 2>&1

sec_count=$(awk -F: '$1=="sec"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$sec_count" -eq 1 ]] || {
  printf 'expected exactly 1 sec record, got %s\n' "$sec_count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}

fpr=$(awk -F: '$1=="fpr"{print $10; exit}' "$tmpdir/colons")
[[ ${#fpr} -eq 40 ]] || {
  printf 'expected 40-char fingerprint, got %s\n' "$fpr" >&2
  exit 1
}
[[ "$fpr" =~ ^[A-F0-9]+$ ]]

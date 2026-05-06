#!/usr/bin/env bash
# @testcase: usage-gpg-r10-list-sigs-self-signature
# @title: gpg --list-sigs reports self-signature on freshly generated key
# @description: Generates an Ed25519 key in a fresh GNUPGHOME and verifies gpg --with-colons --list-sigs emits a sig: record (the self-signature on the user id).
# @timeout: 240
# @tags: usage, gpg, signatures
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 ListSigs <r10-listsigs@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-sigs >"$tmpdir/sigs" 2>&1
grep -qE '^sig:' "$tmpdir/sigs" || {
  printf 'expected at least one sig: record from --list-sigs\n' >&2
  cat "$tmpdir/sigs" >&2
  exit 1
}

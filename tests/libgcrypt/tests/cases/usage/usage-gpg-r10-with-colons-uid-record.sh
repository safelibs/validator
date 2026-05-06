#!/usr/bin/env bash
# @testcase: usage-gpg-r10-with-colons-uid-record
# @title: gpg --with-colons --list-keys uid record exposes the user id
# @description: Generates an Ed25519 key with a distinctive user id and verifies the with-colons listing emits a uid: record whose user-id field 10 contains the configured email tag.
# @timeout: 240
# @tags: usage, gpg, with-colons
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 WithColons <r10-wc@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1

uid_field=$(awk -F: '$1=="uid"{print $10; exit}' "$tmpdir/colons")
[[ -n "$uid_field" ]] || {
  printf 'no uid: record found\n' >&2
  cat "$tmpdir/colons" >&2
  exit 1
}
case "$uid_field" in
  *r10-wc@example.invalid*) ;;
  *)
    printf 'uid field 10 missing email tag: %s\n' "$uid_field" >&2
    exit 1
    ;;
esac

#!/usr/bin/env bash
# @testcase: usage-gpg-r11-quick-add-uid-second-uid
# @title: gpg --quick-add-uid attaches a second user-id reported by --list-keys
# @description: Generates a primary key, runs --quick-add-uid to attach a second user-id, and verifies --with-colons --list-keys reports two uid records with the expected mailbox addresses.
# @timeout: 240
# @tags: usage, gpg, uid, quick-add-uid
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

primary='Validator R11 primary <r11-primary@example.invalid>'
extra='Validator R11 extra <r11-extra@example.invalid>'

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$primary" default default 1d >/dev/null 2>&1

fpr=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')
[[ -n "$fpr" ]] || { echo 'no fingerprint after keygen' >&2; exit 1; }

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-add-uid "$fpr" "$extra" >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1

count=$(awk -F: '$1=="uid"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$count" -eq 2 ]] || {
  printf 'expected exactly 2 uid records, got %s\n' "$count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}

awk -F: '$1=="uid"{print $10}' "$tmpdir/colons" >"$tmpdir/uids"
grep -Fq 'r11-primary@example.invalid' "$tmpdir/uids"
grep -Fq 'r11-extra@example.invalid' "$tmpdir/uids"

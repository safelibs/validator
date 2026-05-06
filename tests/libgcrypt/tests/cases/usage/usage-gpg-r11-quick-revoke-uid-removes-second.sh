#!/usr/bin/env bash
# @testcase: usage-gpg-r11-quick-revoke-uid-removes-second
# @title: gpg --quick-revoke-uid marks the targeted user-id revoked in colons output
# @description: Adds a second user-id with --quick-add-uid, revokes it with --quick-revoke-uid, and verifies the colons-mode --list-keys output keeps both uid records but reports the revoked address with field-2 validity 'r' while the primary stays at non-r validity.
# @timeout: 240
# @tags: usage, gpg, uid, quick-revoke-uid
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

primary='Validator R11 keep <r11-keep@example.invalid>'
extra='Validator R11 drop <r11-drop@example.invalid>'

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$primary" default default 1d >/dev/null 2>&1
fpr=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-add-uid "$fpr" "$extra" >/dev/null 2>&1

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-revoke-uid "$fpr" "$extra" >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1

count=$(awk -F: '$1=="uid"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$count" -eq 2 ]] || {
  printf 'expected 2 uid records (1 primary + 1 revoked), got %s\n' "$count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}

drop_validity=$(awk -F: '$1=="uid" && $10 ~ /r11-drop@example.invalid/{print $2; exit}' "$tmpdir/colons")
keep_validity=$(awk -F: '$1=="uid" && $10 ~ /r11-keep@example.invalid/{print $2; exit}' "$tmpdir/colons")

[[ "$drop_validity" == "r" ]] || {
  printf 'revoked uid validity should be r, got %s\n' "$drop_validity" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}
[[ "$keep_validity" != "r" ]] || {
  printf 'primary uid was unexpectedly marked revoked\n' >&2
  cat "$tmpdir/colons" >&2
  exit 1
}

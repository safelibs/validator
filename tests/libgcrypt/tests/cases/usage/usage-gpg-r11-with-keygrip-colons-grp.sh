#!/usr/bin/env bash
# @testcase: usage-gpg-r11-with-keygrip-colons-grp
# @title: gpg --with-keygrip --with-colons --list-keys emits grp records on the public keyring
# @description: Generates a default key and verifies that --with-keygrip on the public --list-keys output (no --with-secret) emits at least two grp records of 40 uppercase hex chars (one per primary and subkey).
# @timeout: 240
# @tags: usage, gpg, with-keygrip, colons
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R11 keygrip <r11-keygrip@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

# Sanity: without --with-keygrip there must be no grp records.
plain_grp=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="grp"{n++} END{print n+0}')
[[ "$plain_grp" -eq 0 ]] || {
  printf 'unexpected grp records without --with-keygrip: %d\n' "$plain_grp" >&2
  exit 1
}

gpg --batch --with-keygrip --with-colons --list-keys >"$tmpdir/colons" 2>&1

count=$(awk -F: '$1=="grp"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$count" -ge 2 ]] || {
  printf 'expected >= 2 grp records with --with-keygrip, got %s\n' "$count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}

awk -F: '$1=="grp"{print $10}' "$tmpdir/colons" | while read -r grp; do
  [[ "$grp" =~ ^[A-F0-9]{40}$ ]] || {
    printf 'malformed grp: %s\n' "$grp" >&2
    exit 1
  }
done

#!/usr/bin/env bash
# @testcase: usage-gpg-r11-export-filter-keep-uid
# @title: gpg --export-filter keep-uid restricts exported user-ids to a regex match
# @description: Adds a second user-id to a key, runs --export with --export-filter keep-uid="uid =~ secondary", and verifies the exported packet stream contains only the secondary uid (the primary uid is filtered out).
# @timeout: 240
# @tags: usage, gpg, export, export-filter
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

primary='Validator R11 primary uid <r11-prim-uid@example.invalid>'
secondary='Validator R11 secondary uid <r11-secondary@example.invalid>'

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$primary" default default 1d >/dev/null 2>&1
fpr=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-add-uid "$fpr" "$secondary" >/dev/null 2>&1

gpg --batch --export-filter 'keep-uid=uid =~ secondary' \
  --export "$fpr" >"$tmpdir/filtered.gpg" 2>/dev/null
[[ -s "$tmpdir/filtered.gpg" ]] || { echo 'empty filtered export' >&2; exit 1; }

gpg --batch --list-packets "$tmpdir/filtered.gpg" >"$tmpdir/packets" 2>&1

grep -F 'r11-secondary@example.invalid' "$tmpdir/packets" >/dev/null
if grep -F 'r11-prim-uid@example.invalid' "$tmpdir/packets" >/dev/null; then
  echo 'primary uid leaked through keep-uid filter' >&2
  cat "$tmpdir/packets" >&2
  exit 1
fi

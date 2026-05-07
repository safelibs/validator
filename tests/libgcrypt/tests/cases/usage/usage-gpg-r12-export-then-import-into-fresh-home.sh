#!/usr/bin/env bash
# @testcase: usage-gpg-r12-export-then-import-into-fresh-home
# @title: gpg armored export imports cleanly into a separate GNUPGHOME
# @description: Generates a key in a source GNUPGHOME, exports it with --armor --export, imports it into a brand-new GNUPGHOME, and verifies the imported key shows up as a pub: record in --with-colons --list-keys with the same fingerprint.
# @timeout: 240
# @tags: usage, gpg, export, import
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
dst="$tmpdir/dst"
mkdir -p "$src" "$dst"
chmod 700 "$src" "$dst"

uid='Validator R12 Roundtrip <r12-roundtrip@example.invalid>'

GNUPGHOME="$src" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

src_fpr=$(GNUPGHOME="$src" gpg --batch --with-colons --list-keys \
  | awk -F: '$1=="fpr"{print $10; exit}')
[[ -n "$src_fpr" ]] || { echo 'no source fingerprint' >&2; exit 1; }

GNUPGHOME="$src" gpg --batch --armor --export >"$tmpdir/pub.asc" 2>/dev/null

GNUPGHOME="$dst" gpg --batch --import "$tmpdir/pub.asc" >/dev/null 2>&1

dst_fpr=$(GNUPGHOME="$dst" gpg --batch --with-colons --list-keys \
  | awk -F: '$1=="fpr"{print $10; exit}')
[[ "$dst_fpr" == "$src_fpr" ]] || {
  printf 'fingerprint mismatch after import: src=%s dst=%s\n' "$src_fpr" "$dst_fpr" >&2
  exit 1
}

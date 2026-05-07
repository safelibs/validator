#!/usr/bin/env bash
# @testcase: usage-gpg-r15-export-import-fingerprint-stable-binary
# @title: gpg binary --export imports cleanly into a fresh GNUPGHOME with a stable fingerprint
# @description: Generates an Ed25519 sign-only key in a source GNUPGHOME, exports it as a binary OpenPGP packet stream (no --armor) into a file, asserts the export file is non-empty and that its first byte is NOT '-' (i.e., not ASCII-armored), imports the binary export into a brand-new GNUPGHOME, and asserts the destination fingerprint matches the source fingerprint byte-for-byte — distinct from the r12 armored export/import variant.
# @timeout: 240
# @tags: usage, gpg, export, import, binary, fingerprint, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
dst="$tmpdir/dst"
mkdir -p "$src" "$dst"
chmod 700 "$src" "$dst"

uid='Validator R15 Binary Export <r15-bin-export@example.invalid>'

GNUPGHOME="$src" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

src_fpr=$(GNUPGHOME="$src" gpg --batch --with-colons --list-keys \
  | LC_ALL=C awk -F: '$1=="fpr"{print $10; exit}')
[[ ${#src_fpr} -eq 40 ]] || { echo "bad src_fpr=$src_fpr" >&2; exit 1; }

# Binary export (no --armor).
GNUPGHOME="$src" gpg --batch --export -o "$tmpdir/pub.bin" "$src_fpr" >/dev/null 2>&1
[[ -s "$tmpdir/pub.bin" ]]

first_byte=$(LC_ALL=C dd if="$tmpdir/pub.bin" bs=1 count=1 status=none | LC_ALL=C od -An -c \
              | LC_ALL=C tr -d ' ')
[[ "$first_byte" != "-" ]] || {
  echo 'binary export unexpectedly begins with ASCII-armor banner' >&2
  exit 1
}

GNUPGHOME="$dst" gpg --batch --import "$tmpdir/pub.bin" >/dev/null 2>&1

dst_fpr=$(GNUPGHOME="$dst" gpg --batch --with-colons --list-keys \
  | LC_ALL=C awk -F: '$1=="fpr"{print $10; exit}')
[[ "$dst_fpr" == "$src_fpr" ]] || {
  printf 'fingerprint mismatch: src=%s dst=%s\n' "$src_fpr" "$dst_fpr" >&2
  exit 1
}

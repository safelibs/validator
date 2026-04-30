#!/usr/bin/env bash
# @testcase: usage-gpg-fingerprint-stable-export-import
# @title: gpg fingerprint stable across export and import
# @description: Generates an ed25519 key, exports it armored, imports into a fresh GNUPGHOME, and confirms the fingerprint is byte-identical across both keyrings.
# @timeout: 240
# @tags: usage, gpg, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-fingerprint-stable-export-import"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

original_home="$tmpdir/gnupghome-a"
mkdir -p "$original_home"
chmod 700 "$original_home"
fresh_home="$tmpdir/gnupghome-b"
mkdir -p "$fresh_home"
chmod 700 "$fresh_home"

uid='Validator Stable <validator-stable@example.invalid>'

GNUPGHOME="$original_home" gpg --batch --yes --pinentry-mode loopback \
  --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

GNUPGHOME="$original_home" gpg --batch --with-colons --fingerprint "$uid" \
  >"$tmpdir/colons.a"
fp_a=$(awk -F: '/^fpr:/ {print $10; exit}' "$tmpdir/colons.a")
test -n "$fp_a"

GNUPGHOME="$original_home" gpg --batch --armor --export "$uid" \
  >"$tmpdir/pub.asc"
test -s "$tmpdir/pub.asc"

GNUPGHOME="$fresh_home" gpg --batch --import "$tmpdir/pub.asc" \
  >"$tmpdir/import.log" 2>&1
validator_assert_contains "$tmpdir/import.log" 'imported'

GNUPGHOME="$fresh_home" gpg --batch --with-colons --fingerprint "$uid" \
  >"$tmpdir/colons.b"
fp_b=$(awk -F: '/^fpr:/ {print $10; exit}' "$tmpdir/colons.b")
test -n "$fp_b"

test "$fp_a" = "$fp_b"

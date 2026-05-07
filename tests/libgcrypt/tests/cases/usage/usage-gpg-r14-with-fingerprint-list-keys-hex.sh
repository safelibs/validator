#!/usr/bin/env bash
# @testcase: usage-gpg-r14-with-fingerprint-list-keys-hex
# @title: gpg --with-fingerprint --list-keys emits a 40-hex grouped fingerprint line
# @description: Generates an Ed25519 sign-only key in a fresh GNUPGHOME, runs gpg --with-fingerprint --list-keys, and asserts the human-readable output contains an indented fingerprint line of ten 4-hex groups (40 hex digits total) separated by single spaces with a double-space midline gap, plus the uid being listed.
# @timeout: 240
# @tags: usage, gpg, with-fingerprint, list-keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R14 Fingerprint <r14-fpr@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --with-fingerprint --list-keys >"$tmpdir/out" 2>&1

# uid line present.
validator_assert_contains "$tmpdir/out" 'Validator R14 Fingerprint'

# Fingerprint line: 10 groups of 4 hex chars; gpg prints them in two halves
# of 5 groups separated by a double space, e.g.
#   "      C6C0 BB67 7731 5ACE 7ABA  0469 907A 58E1 2F35 DD4F"
LC_ALL=C grep -E '([0-9A-F]{4} ){4}[0-9A-F]{4}  ([0-9A-F]{4} ){4}[0-9A-F]{4}' \
  "$tmpdir/out" >/dev/null || {
  echo 'no 40-hex fingerprint line found in --with-fingerprint output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}

#!/usr/bin/env bash
# @testcase: usage-gpg-list-keys-with-colons-pub-record
# @title: gpg --list-keys --with-colons pub record parsing
# @description: Generates a key and parses the machine-readable colon-listing output, verifying the pub record carries the documented field layout (validity, length, public-key algorithm, 16-hex keyid) and a matching fpr record with a 40-hex fingerprint.
# @timeout: 180
# @tags: usage, gpg, keyring, parsing
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-keys-with-colons-pub-record"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator ColonParse <validator-colon-parse@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --with-colons --list-keys "$uid" >"$tmpdir/colons"

# Per gnupg/doc/DETAILS the pub record layout is:
#   pub:<validity>:<length>:<pubkey-algo>:<keyid>:<creationdate>:...
pub_line=$(grep '^pub:' "$tmpdir/colons" | head -n1)
test -n "$pub_line"

validity=$(printf '%s' "$pub_line" | cut -d: -f2)
length=$(printf '%s' "$pub_line"   | cut -d: -f3)
algo=$(printf '%s' "$pub_line"     | cut -d: -f4)
keyid=$(printf '%s' "$pub_line"    | cut -d: -f5)

# Validity is a single character per DETAILS (e.g. u/r/e/-/...).
printf '%s' "$validity" | grep -qE '^[a-z-]$' || {
  printf 'unexpected validity flag: %q\n' "$validity" >&2; exit 1; }
# Length must be a positive decimal integer.
printf '%s' "$length" | grep -qE '^[1-9][0-9]*$' || {
  printf 'unexpected key length: %q\n' "$length" >&2; exit 1; }
# Algo must be a positive decimal integer (RFC 4880 algo number, e.g. 22 == EdDSA).
printf '%s' "$algo" | grep -qE '^[1-9][0-9]*$' || {
  printf 'unexpected pubkey algo: %q\n' "$algo" >&2; exit 1; }
# KeyID is a 16-hex-digit long key id.
printf '%s' "$keyid" | grep -qE '^[0-9A-F]{16}$' || {
  printf 'unexpected key id: %q\n' "$keyid" >&2; exit 1; }

# The associated fpr record carries the 40-hex full fingerprint in field 10.
fpr_line=$(grep '^fpr:' "$tmpdir/colons" | head -n1)
test -n "$fpr_line"
fpr=$(printf '%s' "$fpr_line" | cut -d: -f10)
printf '%s' "$fpr" | grep -qE '^[0-9A-F]{40}$' || {
  printf 'unexpected fingerprint: %q\n' "$fpr" >&2; exit 1; }

# Cross-check: the long keyid is the trailing 16 hex chars of the fingerprint.
test "${fpr: -16}" = "$keyid"

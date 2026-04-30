#!/usr/bin/env bash
# @testcase: usage-gpg-list-secret-keys-keyid-format-0xlong
# @title: gpg --list-secret-keys --keyid-format 0xlong
# @description: Confirms that gpg --list-secret-keys --keyid-format 0xlong renders the trailing 16 hex digits of the primary fingerprint with the explicit "0x" prefix on the sec line.
# @timeout: 180
# @tags: usage, gpg, keys, listing
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-secret-keys-keyid-format-0xlong"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator SecretLong <validator-seclong@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

primary_fpr=$(gpg --with-colons --fingerprint "$uid" \
  | awk -F: '$1 == "fpr" {print $10; exit}')
test "${#primary_fpr}" = "40"

long_id="${primary_fpr: -16}"
short_id="${primary_fpr: -8}"

gpg --list-secret-keys --keyid-format 0xlong "$uid" \
  >"$tmpdir/long.out" 2>&1

# The 0xlong format renders the 16-hex keyid prefixed by "0x" after the
# algorithm slash on the sec line.
validator_assert_contains "$tmpdir/long.out" "/0x$long_id"

# Sanity: the bare 8-hex short form must not appear with the same algorithm
# prefix, which would indicate the formatter ignored 0xlong.
if grep -Eq "/${short_id}( |$)" "$tmpdir/long.out"; then
  printf '0xlong listing unexpectedly contains short keyid /%s\n' "$short_id" >&2
  cat "$tmpdir/long.out" >&2
  exit 1
fi

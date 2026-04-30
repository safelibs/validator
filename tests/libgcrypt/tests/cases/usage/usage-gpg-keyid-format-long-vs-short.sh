#!/usr/bin/env bash
# @testcase: usage-gpg-keyid-format-long-vs-short
# @title: gpg keyid-format long vs short
# @description: Generates a key and confirms that gpg --keyid-format long renders the trailing 16 hex digits of the fingerprint and --keyid-format short renders only the trailing 8 hex digits.
# @timeout: 180
# @tags: usage, gpg, keys, listing
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-keyid-format-long-vs-short"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator KeyIDFormat <validator-keyidformat@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
test -n "$fingerprint"
test "${#fingerprint}" = "40"

long_id="${fingerprint: -16}"
short_id="${fingerprint: -8}"

gpg --keyid-format long --list-keys "$uid" >"$tmpdir/long.out" 2>&1
gpg --keyid-format short --list-keys "$uid" >"$tmpdir/short.out" 2>&1

# long form must show 16-hex keyid; short must show 8-hex keyid but NOT the long form
validator_assert_contains "$tmpdir/long.out" "/$long_id"
validator_assert_contains "$tmpdir/short.out" "/$short_id"

if grep -Fq -- "/$long_id" "$tmpdir/short.out"; then
  printf 'short keyid output unexpectedly contains long form %s\n' "$long_id" >&2
  cat "$tmpdir/short.out" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-gpg-sign-file-roundtrip
# @title: gpg sign file round trip
# @description: Exercises gpg sign file round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-sign-file-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Even More <validator-even-more@example.invalid>'

make_default_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1
}

make_default_key
printf 'signed file payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --sign -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'signed file payload'

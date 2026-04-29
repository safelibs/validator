#!/usr/bin/env bash
# @testcase: usage-gpg-recipient-encrypt-decrypt-output
# @title: gpg recipient encrypt decrypt output
# @description: Exercises gpg recipient encrypt decrypt output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-recipient-encrypt-decrypt-output"
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
printf 'recipient payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out.txt" 'recipient payload'

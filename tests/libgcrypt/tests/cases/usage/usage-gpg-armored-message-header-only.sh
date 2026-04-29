#!/usr/bin/env bash
# @testcase: usage-gpg-armored-message-header-only
# @title: gpg armored message header only
# @description: Exercises gpg armored message header only through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-armored-message-header-only"
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
printf 'armored recipient payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --trust-model always --armor --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'

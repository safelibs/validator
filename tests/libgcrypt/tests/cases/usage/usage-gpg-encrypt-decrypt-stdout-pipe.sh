#!/usr/bin/env bash
# @testcase: usage-gpg-encrypt-decrypt-stdout-pipe
# @title: gpg encrypt decrypt stdout pipe
# @description: Exercises gpg encrypt decrypt stdout pipe through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-encrypt-decrypt-stdout-pipe"
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
printf 'stdout decrypt payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdout decrypt payload'

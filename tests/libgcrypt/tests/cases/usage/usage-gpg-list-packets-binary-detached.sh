#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-binary-detached
# @title: gpg list packets binary detached
# @description: Exercises gpg list packets binary detached through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-binary-detached"
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
printf 'binary signature payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
gpg --list-packets "$tmpdir/plain.sig" >"$tmpdir/out" 2>&1 || true
validator_assert_contains "$tmpdir/out" 'signature packet'

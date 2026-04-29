#!/usr/bin/env bash
# @testcase: usage-gpg-clearsign-verify-status
# @title: gpg clearsign verify status
# @description: Exercises gpg clearsign verify status through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-clearsign-verify-status"
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
printf 'clearsign payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
gpg --verify "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1 || true
validator_assert_contains "$tmpdir/out" 'Good signature'

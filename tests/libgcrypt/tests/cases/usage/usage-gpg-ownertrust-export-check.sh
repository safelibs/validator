#!/usr/bin/env bash
# @testcase: usage-gpg-ownertrust-export-check
# @title: gpg ownertrust export check
# @description: Exercises gpg ownertrust export check through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-ownertrust-export-check"
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
fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
printf '%s:6:\n' "$fingerprint" | gpg --import-ownertrust >"$tmpdir/import.out" 2>&1
gpg --export-ownertrust >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "$fingerprint"

#!/usr/bin/env bash
# @testcase: usage-gpg-import-public-key-listing
# @title: gpg import public key listing
# @description: Exercises gpg import public key listing through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-public-key-listing"
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
gpg --armor --export "$uid" >"$tmpdir/public.asc"
other_home="$tmpdir/other"
mkdir -p "$other_home"
chmod 700 "$other_home"
GNUPGHOME="$other_home" gpg --batch --import "$tmpdir/public.asc" >"$tmpdir/import.out" 2>&1
GNUPGHOME="$other_home" gpg --list-keys "$uid" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Validator Even More'

#!/usr/bin/env bash
# @testcase: usage-gpg-list-options-show-keyserver-urls
# @title: gpg --list-options show-keyserver-urls
# @description: Generates a key and verifies that --list-options show-keyserver-urls is accepted and produces a normal --list-keys listing including the new uid.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-options-show-keyserver-urls"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator KeyserverUrls <validator-keyserver-urls@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

gpg --list-options show-keyserver-urls --list-keys "$uid" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Validator KeyserverUrls'
validator_assert_contains "$tmpdir/out" 'pub'

#!/usr/bin/env bash
# @testcase: usage-gpg-keyserver-options-no-honor
# @title: gpg --keyserver-options no-honor-keyserver-url
# @description: Generates a key and verifies that --keyserver-options no-honor-keyserver-url is accepted as a no-op for offline --list-keys: the listing still includes the uid and the command exits 0 without any keyserver traffic.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-keyserver-options-no-honor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator NoHonor <validator-no-honor@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

if ! gpg --keyserver-options no-honor-keyserver-url --list-keys "$uid" \
    >"$tmpdir/out" 2>"$tmpdir/err"; then
  printf '--keyserver-options no-honor-keyserver-url --list-keys failed\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" 'validator-no-honor@example.invalid'
validator_assert_contains "$tmpdir/out" 'pub'

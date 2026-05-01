#!/usr/bin/env bash
# @testcase: usage-gpg-no-greeting-version
# @title: gpg --no-greeting --version still prints version
# @description: Runs gpg with --no-greeting before --version and asserts the version banner including the linked libgcrypt version is still printed.
# @timeout: 120
# @tags: usage, gpg, version
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-no-greeting-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --no-greeting --version >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'gpg (GnuPG)'
validator_assert_contains "$tmpdir/out" 'libgcrypt'
validator_assert_contains "$tmpdir/out" 'Cipher:'
validator_assert_contains "$tmpdir/out" 'Hash:'

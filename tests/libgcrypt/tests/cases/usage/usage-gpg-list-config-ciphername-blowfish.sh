#!/usr/bin/env bash
# @testcase: usage-gpg-list-config-ciphername-blowfish
# @title: gpg list-config cipher names include BLOWFISH
# @description: Runs gpg --with-colons --list-config ciphername and asserts BLOWFISH appears in the reported cipher algorithms list.
# @timeout: 120
# @tags: usage, gpg, crypto, config
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-config-ciphername-blowfish"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config ciphername >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'cfg:ciphername:'
grep -E '^cfg:ciphername:' "$tmpdir/out" | grep -qi 'BLOWFISH'

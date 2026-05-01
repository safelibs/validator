#!/usr/bin/env bash
# @testcase: usage-gpg-list-config-pubkeyname-rsa
# @title: gpg list-config public key algorithms include RSA
# @description: Lists configured public key algorithm names with --with-colons --list-config pubkeyname and asserts RSA is present.
# @timeout: 120
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-config-pubkeyname-rsa"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config pubkeyname >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'cfg:pubkeyname:'
grep -E '^cfg:pubkeyname:' "$tmpdir/out" | grep -qi 'RSA'

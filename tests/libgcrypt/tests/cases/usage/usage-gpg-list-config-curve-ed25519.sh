#!/usr/bin/env bash
# @testcase: usage-gpg-list-config-curve-ed25519
# @title: gpg list-config curve includes ed25519
# @description: Inspects the list-config curve record with colon output and asserts that ed25519 is among the configured ECC curves.
# @timeout: 120
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-config-curve-ed25519"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config curve >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'cfg:curve:'
grep -E '^cfg:curve:' "$tmpdir/out" | grep -q 'ed25519'

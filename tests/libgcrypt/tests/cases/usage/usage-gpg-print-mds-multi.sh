#!/usr/bin/env bash
# @testcase: usage-gpg-print-mds-multi
# @title: gpg --print-mds shows multiple digest algorithms
# @description: Runs gpg --print-mds on a fixed payload and asserts that several digest algorithm labels (MD5, SHA1, RMD160, SHA256, SHA512) appear in the output.
# @timeout: 120
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-mds-multi"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'print-mds payload\n' >"$tmpdir/data.txt"
gpg --batch --print-mds "$tmpdir/data.txt" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'MD5 ='
validator_assert_contains "$tmpdir/out" 'SHA1 ='
validator_assert_contains "$tmpdir/out" 'RMD160 ='
validator_assert_contains "$tmpdir/out" 'SHA256 ='
validator_assert_contains "$tmpdir/out" 'SHA512 ='

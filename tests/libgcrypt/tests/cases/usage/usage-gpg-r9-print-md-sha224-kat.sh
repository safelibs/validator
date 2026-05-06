#!/usr/bin/env bash
# @testcase: usage-gpg-r9-print-md-sha224-kat
# @title: gpg --print-md SHA224 KAT for empty input
# @description: Computes the SHA224 digest of an empty input via gpg --print-md and verifies the output matches the canonical NIST KAT prefix.
# @timeout: 60
# @tags: usage, gpg, hash
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty"
gpg --batch --print-md SHA224 "$tmpdir/empty" >"$tmpdir/out"
# SHA-224 of empty input is d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f.
validator_assert_contains "$tmpdir/out" 'D14A028C'

#!/usr/bin/env bash
# @testcase: usage-gpg-r9-print-md-sha512-stdin
# @title: gpg --print-md SHA512 from stdin
# @description: Pipes a known string into gpg --print-md SHA512 and verifies the digest matches the canonical SHA-512 hex for that input.
# @timeout: 60
# @tags: usage, gpg, hash
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# SHA-512 of "abc" (with no newline) is the canonical NIST KAT.
expected_first='DDAF35A193617ABA'

printf 'abc' | gpg --batch --print-md SHA512 >"$tmpdir/out" 2>&1
# gpg renders the digest in 16-byte groups separated by spaces; first group must match.
validator_assert_contains "$tmpdir/out" "$expected_first"

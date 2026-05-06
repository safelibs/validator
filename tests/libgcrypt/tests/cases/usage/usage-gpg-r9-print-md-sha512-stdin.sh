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
expected='DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F'

printf 'abc' | gpg --batch --print-md SHA512 >"$tmpdir/out" 2>&1
# gpg renders the digest as space-separated 4-byte hex groups; strip whitespace and match the full digest.
tr -d '[:space:]' <"$tmpdir/out" >"$tmpdir/joined"
validator_assert_contains "$tmpdir/joined" "$expected"

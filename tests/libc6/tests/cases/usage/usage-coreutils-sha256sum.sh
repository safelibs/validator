#!/usr/bin/env bash
# @testcase: usage-coreutils-sha256sum
# @title: coreutils sha256sum digest
# @description: Computes a SHA-256 digest with coreutils and verifies the expected prefix.
# @timeout: 180
# @tags: usage, coreutils, digest
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-sha256sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'payload' >"$tmpdir/file.txt"
sha256sum "$tmpdir/file.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '239f59ed'

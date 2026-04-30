#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha3-256
# @title: gpg print-md SHA3-256 hex
# @description: Computes a SHA3-256 digest with gpg --print-md and confirms the output contains enough hex groups for a 256 bit digest.
# @timeout: 180
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha3-256"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'sha3-256 payload\n' >"$tmpdir/plain.txt"
gpg --print-md SHA3-256 "$tmpdir/plain.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'plain.txt:'
groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
test "$groups" -ge 14

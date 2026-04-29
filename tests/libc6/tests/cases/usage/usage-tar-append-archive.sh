#!/usr/bin/env bash
# @testcase: usage-tar-append-archive
# @title: tar appends archive member
# @description: Appends a new member to an existing tar archive and verifies list mode shows both entries.
# @timeout: 180
# @tags: usage, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-append-archive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
printf 'alpha\n' >"$tmpdir/tree/alpha.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/tree" alpha.txt
printf 'beta\n' >"$tmpdir/tree/beta.txt"
tar -rf "$tmpdir/archive.tar" -C "$tmpdir/tree" beta.txt
tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'beta.txt'

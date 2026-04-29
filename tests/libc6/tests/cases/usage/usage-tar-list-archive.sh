#!/usr/bin/env bash
# @testcase: usage-tar-list-archive
# @title: tar lists archive
# @description: Creates a tar archive and verifies tar list mode reports all stored file names.
# @timeout: 180
# @tags: usage, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-list-archive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/alpha.txt"
printf 'beta\n' >"$tmpdir/src/beta.txt"
tar -C "$tmpdir/src" -cf "$tmpdir/archive.tar" alpha.txt beta.txt
tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'beta.txt'

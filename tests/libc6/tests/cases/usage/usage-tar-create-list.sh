#!/usr/bin/env bash
# @testcase: usage-tar-create-list
# @title: tar create list
# @description: Creates a tar archive and verifies the member path is listed by the tar client afterward.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-create-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/sub"
printf 'tar payload\n' >"$tmpdir/tree/sub/file.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/tree" .
tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" './sub/file.txt'

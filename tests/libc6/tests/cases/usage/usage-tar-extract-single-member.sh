#!/usr/bin/env bash
# @testcase: usage-tar-extract-single-member
# @title: tar extract single member
# @description: Extracts only one named member from a tar archive and verifies the other entry was not extracted.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-extract-single-member"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha body\n' >"$tmpdir/src/alpha.txt"
printf 'beta body\n' >"$tmpdir/src/beta.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/src" .
mkdir -p "$tmpdir/dest"
tar -xf "$tmpdir/archive.tar" -C "$tmpdir/dest" ./alpha.txt
validator_assert_contains "$tmpdir/dest/alpha.txt" 'alpha body'
test ! -e "$tmpdir/dest/beta.txt"

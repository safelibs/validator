#!/usr/bin/env bash
# @testcase: usage-tar-to-stdout-member-batch11
# @title: tar extract member to stdout
# @description: Extracts a single tar member directly to stdout.
# @timeout: 180
# @tags: usage, tar, filesystem
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-to-stdout-member-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'stdout member\n' >"$tmpdir/src/member.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/src" member.txt
tar -xOf "$tmpdir/archive.tar" member.txt >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'stdout member'

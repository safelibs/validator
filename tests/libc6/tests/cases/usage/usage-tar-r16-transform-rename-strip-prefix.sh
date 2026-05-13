#!/usr/bin/env bash
# @testcase: usage-tar-r16-transform-rename-strip-prefix
# @title: tar --transform renames archived members via a sed expression at create time
# @description: Archives a file at path "src/data.txt" with --transform 's,^src/,renamed/,' and asserts the resulting tar contains "renamed/data.txt" rather than "src/data.txt" — locking in tar's libc-backed string rewrite via member-name transformation.
# @timeout: 60
# @tags: usage, tar, transform, rename
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'r16 transform body\n' >"$tmpdir/src/data.txt"

cd "$tmpdir"
tar --transform 's,^src/,renamed/,' -cf "$tmpdir/out.tar" src/data.txt
tar -tf "$tmpdir/out.tar" >"$tmpdir/listing"

validator_assert_contains "$tmpdir/listing" 'renamed/data.txt'
! grep -F 'src/data.txt' "$tmpdir/listing"

#!/usr/bin/env bash
# @testcase: usage-tar-r17-exclude-pattern-roundtrip
# @title: tar --exclude omits matching members from a created archive
# @description: Stages three files under one directory and creates a tar archive with --exclude='*.skip' then asserts the listing contains the kept files but not the excluded one — locking in tar's create-time exclude-pattern matching.
# @timeout: 60
# @tags: usage, tar, exclude
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'keep alpha\n' >"$tmpdir/src/a.keep"
printf 'keep bravo\n' >"$tmpdir/src/b.keep"
printf 'omit charlie\n' >"$tmpdir/src/c.skip"

cd "$tmpdir"
tar --exclude='*.skip' -cf "$tmpdir/out.tar" src
tar -tf "$tmpdir/out.tar" | sort >"$tmpdir/listing"

validator_assert_contains "$tmpdir/listing" 'src/a.keep'
validator_assert_contains "$tmpdir/listing" 'src/b.keep'
! grep -F 'c.skip' "$tmpdir/listing"

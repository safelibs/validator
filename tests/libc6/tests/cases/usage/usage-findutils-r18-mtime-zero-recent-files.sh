#!/usr/bin/env bash
# @testcase: usage-findutils-r18-mtime-zero-recent-files
# @title: find -mtime -1 lists a freshly created file in the working tree
# @description: Creates a fresh file under a temp directory and asserts find with -mtime -1 finds the file by path, locking in libc-backed mtime predicate matching for recently modified files.
# @timeout: 30
# @tags: usage, findutils, mtime, r18
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

touch "$tmpdir/fresh.txt"

find "$tmpdir" -type f -mtime -1 >"$tmpdir/hits"
validator_assert_contains "$tmpdir/hits" 'fresh.txt'

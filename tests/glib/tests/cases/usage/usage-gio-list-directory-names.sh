#!/usr/bin/env bash
# @testcase: usage-gio-list-directory-names
# @title: gio lists directory
# @description: Lists directory entries with gio list and verifies the emitted filenames.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-directory-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/list"
printf 'alpha\n' >"$tmpdir/list/a.txt"
printf 'beta\n' >"$tmpdir/list/b.txt"
gio list "$tmpdir/list" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'a.txt'
validator_assert_contains "$tmpdir/out" 'b.txt'

#!/usr/bin/env bash
# @testcase: usage-gio-r15-list-shows-created-entry
# @title: gio list enumerates a freshly created file in its parent directory
# @description: Creates a file named r15-listed.txt under a fresh directory and runs gio list against the directory, asserting the listing contains the created filename verbatim.
# @timeout: 60
# @tags: usage, gio, list
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/dir"
printf 'r15-listed\n' >"$tmpdir/dir/r15-listed.txt"

gio list "$tmpdir/dir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'r15-listed.txt'

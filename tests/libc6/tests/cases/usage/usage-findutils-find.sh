#!/usr/bin/env bash
# @testcase: usage-findutils-find
# @title: findutils traverses files
# @description: Locates a named file in a directory tree with find.
# @timeout: 120
# @tags: usage, cli
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-find"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/sub"
printf 'payload\n' >"$tmpdir/root/sub/target.txt"
find "$tmpdir/root" -name target.txt -print >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'target.txt'

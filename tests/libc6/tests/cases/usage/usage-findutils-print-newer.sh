#!/usr/bin/env bash
# @testcase: usage-findutils-print-newer
# @title: findutils newer than file
# @description: Filters files newer than a marker with find -newer and verifies only the recently created file is reported.
# @timeout: 180
# @tags: usage, findutils, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-print-newer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/old.txt"
sleep 1
touch "$tmpdir/marker"
sleep 1
: >"$tmpdir/tree/new.txt"
find "$tmpdir/tree" -type f -newer "$tmpdir/marker" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'new.txt'

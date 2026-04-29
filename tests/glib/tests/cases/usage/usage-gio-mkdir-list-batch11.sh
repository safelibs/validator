#!/usr/bin/env bash
# @testcase: usage-gio-mkdir-list-batch11
# @title: gio mkdir and list
# @description: Creates a directory through gio and lists a file inside it.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-mkdir-list-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio mkdir "$tmpdir/gio-dir"
printf 'listed\n' >"$tmpdir/gio-dir/item.txt"
gio list "$tmpdir/gio-dir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'item.txt'

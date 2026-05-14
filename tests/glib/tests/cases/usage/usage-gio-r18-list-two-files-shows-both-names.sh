#!/usr/bin/env bash
# @testcase: usage-gio-r18-list-two-files-shows-both-names
# @title: gio list on a tmpdir with two files shows both filenames in its output
# @description: Creates two distinctly named files alpha.txt and beta.txt inside a tmpdir and asserts that gio list on the directory emits both filename strings on its stdout, exercising the directory enumeration projection on a deterministic two-entry directory.
# @timeout: 60
# @tags: usage, gio, list, enumeration, r18
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

dir="$tmpdir/two"
mkdir -p "$dir"
printf 'r18-a\n' >"$dir/alpha.txt"
printf 'r18-b\n' >"$dir/beta.txt"

gio list "$dir" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'beta.txt'

#!/usr/bin/env bash
# @testcase: usage-gio-batch12-list-empty-directory
# @title: gio list on empty directory yields zero lines
# @description: Creates an empty directory and verifies "gio list" outputs nothing (zero lines).
# @timeout: 60
# @tags: usage, gio, list
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/empty"
gio list "$tmpdir/empty" >"$tmpdir/out.txt"
count=$(wc -l <"$tmpdir/out.txt")
[[ "$count" == 0 ]]

#!/usr/bin/env bash
# @testcase: usage-findutils-r11-newer-mtime-filter
# @title: findutils find -newer compares libc-stat mtime between two files
# @description: Creates two files with explicit mtimes one hour apart and verifies find -newer reports only the newer file relative to the older anchor exercising findutils libc stat-based mtime comparison.
# @timeout: 60
# @tags: usage, findutils, mtime
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
workdir=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$workdir"' EXIT

: >"$workdir/old.txt"
: >"$workdir/new.txt"
touch -d '2023-01-01T00:00:00Z' "$workdir/old.txt"
touch -d '2024-01-01T00:00:00Z' "$workdir/new.txt"

LC_ALL=C find "$workdir" -maxdepth 1 -type f -newer "$workdir/old.txt" -printf '%f\n' | LC_ALL=C sort >"$tmpdir/got.txt"
[[ "$(cat "$tmpdir/got.txt")" == "new.txt" ]]

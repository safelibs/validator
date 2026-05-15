#!/usr/bin/env bash
# @testcase: usage-findutils-r20-find-empty-flag-on-empty-dir
# @title: find -type d -empty locates an empty directory among populated peers
# @description: Builds a tree with one empty directory and two populated peers, runs find -type d -empty rooted at the tree, and asserts the captured output contains the empty directory path and excludes the populated peers - locking in libc-backed directory iteration through findutils' -empty predicate.
# @timeout: 30
# @tags: usage, findutils, find, empty, r20
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/empty" "$tmpdir/full1" "$tmpdir/full2"
: >"$tmpdir/full1/marker"
: >"$tmpdir/full2/marker"

find "$tmpdir" -type d -empty >"$tmpdir/out"

if ! LC_ALL=C grep -Fxq -- "$tmpdir/empty" "$tmpdir/out"; then
    echo 'empty directory not reported' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
if LC_ALL=C grep -Fxq -- "$tmpdir/full1" "$tmpdir/out"; then
    echo 'full1 should not be reported as empty' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
if LC_ALL=C grep -Fxq -- "$tmpdir/full2" "$tmpdir/out"; then
    echo 'full2 should not be reported as empty' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-findutils-r17-prune-skips-subtree
# @title: find -prune skips a named subdirectory's contents during traversal
# @description: Builds a directory tree with files under both a "keep" subdirectory and a "skip" subdirectory then asserts find with -prune omits everything under skip while still emitting the files under keep — locking in libc-backed traversal pruning.
# @timeout: 30
# @tags: usage, findutils, prune
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/keep" "$tmpdir/root/skip"
touch "$tmpdir/root/keep/k1" "$tmpdir/root/keep/k2"
touch "$tmpdir/root/skip/s1" "$tmpdir/root/skip/s2"

find "$tmpdir/root" \
    -type d -name skip -prune -o \
    -type f -print | sort >"$tmpdir/hits"

validator_assert_contains "$tmpdir/hits" 'root/keep/k1'
validator_assert_contains "$tmpdir/hits" 'root/keep/k2'
! grep -F '/skip/' "$tmpdir/hits"

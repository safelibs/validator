#!/usr/bin/env bash
# @testcase: usage-gio-r20-mkdir-then-list-shows-three-dirs
# @title: gio mkdir followed by gio list shows three created directories
# @description: Creates three sibling directories alpha, beta, gamma via gio mkdir in a tmpdir, runs gio list on the parent, and asserts the listing contains every directory name on its own row, exercising the multi-mkdir-then-list flow for a deterministic set of named entries distinct from prior single-mkdir or move-cycle tests.
# @timeout: 60
# @tags: usage, gio, mkdir, list, r20
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio mkdir "$tmpdir/alpha"
gio mkdir "$tmpdir/beta"
gio mkdir "$tmpdir/gamma"

gio list "$tmpdir" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'alpha'
validator_assert_contains "$tmpdir/list.txt" 'beta'
validator_assert_contains "$tmpdir/list.txt" 'gamma'

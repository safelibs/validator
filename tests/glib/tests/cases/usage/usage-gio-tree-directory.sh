#!/usr/bin/env bash
# @testcase: usage-gio-tree-directory
# @title: gio tree lists nested directory
# @description: Renders a nested directory tree with gio tree and verifies child entries appear.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-tree-directory"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/inner"
printf 'alpha\n' >"$tmpdir/root/alpha.txt"
printf 'beta\n' >"$tmpdir/root/inner/beta.txt"

gio tree "$tmpdir/root" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'inner'
validator_assert_contains "$tmpdir/out" 'beta.txt'

#!/usr/bin/env bash
# @testcase: usage-coreutils-basename-suffix
# @title: coreutils basename suffix
# @description: Strips a multi-extension suffix from a path with basename and verifies the shortened filename.
# @timeout: 180
# @tags: usage, coreutils, path
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-basename-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/path"
: >"$tmpdir/path/archive.tar.gz"
basename "$tmpdir/path/archive.tar.gz" .tar.gz >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'archive'

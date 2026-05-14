#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-tvv-shows-block-summary
# @title: bzip2 -tvv reports a per-block summary line for a valid archive
# @description: Compresses a small payload, runs bzip2 -tvv against the archive, and asserts the verbose-test stderr contains the literal "block" token alongside an "ok" verdict line — locking in the double-verbose archive-test reporting shape.
# @timeout: 60
# @tags: usage, bzip2, test, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 tvv block summary line\nrow alpha\nrow bravo\nrow charlie\nrow delta\n' >"$tmpdir/payload.txt"
bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz2"

bzip2 -tvv "$tmpdir/payload.bz2" 2>"$tmpdir/tvv.err"

validator_assert_contains "$tmpdir/tvv.err" 'block'
validator_assert_contains "$tmpdir/tvv.err" 'ok'

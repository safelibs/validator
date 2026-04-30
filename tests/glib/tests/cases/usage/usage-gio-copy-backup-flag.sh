#!/usr/bin/env bash
# @testcase: usage-gio-copy-backup-flag
# @title: gio copy backup flag
# @description: Copies a file with gio copy --backup over an existing destination and verifies the original target is preserved with a tilde-suffixed backup name.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-backup-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'new-payload\n' >"$tmpdir/src.txt"
printf 'original-payload\n' >"$tmpdir/dst.txt"

gio copy --backup "$tmpdir/src.txt" "$tmpdir/dst.txt"

validator_require_file "$tmpdir/dst.txt"
validator_require_file "$tmpdir/dst.txt~"
validator_assert_contains "$tmpdir/dst.txt" 'new-payload'
validator_assert_contains "$tmpdir/dst.txt~" 'original-payload'

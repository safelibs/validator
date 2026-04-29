#!/usr/bin/env bash
# @testcase: usage-gio-copy-local-file-batch11
# @title: gio local file copy
# @description: Copies a local file through gio and verifies the copied content.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-local-file-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gio copy payload\n' >"$tmpdir/source.txt"
gio copy "$tmpdir/source.txt" "$tmpdir/copied.txt"
validator_assert_contains "$tmpdir/copied.txt" 'gio copy payload'

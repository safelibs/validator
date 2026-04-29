#!/usr/bin/env bash
# @testcase: usage-gio-save-stdin-file
# @title: gio saves stdin to file
# @description: Writes bytes through gio save and verifies the created file content.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-save-stdin-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'saved through gio\n' | gio save "$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'saved through gio'

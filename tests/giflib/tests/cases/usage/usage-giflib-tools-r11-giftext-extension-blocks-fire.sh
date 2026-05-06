#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftext-extension-blocks-fire
# @title: giftext -e fire reports application, comment, and graphics control extensions
# @description: Runs giftext -e on the fire fixture and verifies the report enumerates the GIF89 application (Ext Code 255), comment (254), and graphics control (249) extension blocks the file is known to carry.
# @timeout: 60
# @tags: usage, cli, giftext, extensions
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -e "$gif" >"$tmpdir/dump.txt"

validator_assert_contains "$tmpdir/dump.txt" 'Ext Code = 255'
validator_assert_contains "$tmpdir/dump.txt" 'Ext Code = 254'
validator_assert_contains "$tmpdir/dump.txt" 'Ext Code = 249'

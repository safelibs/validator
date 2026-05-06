#!/usr/bin/env bash
# @testcase: usage-pngquant-r11-h-short-help
# @title: pngquant -h short flag prints the options banner
# @description: Runs pngquant with the short -h flag and confirms the printed banner contains both the "usage:" line and an "options:" section header, distinguishing it from the bare invocation banner.
# @timeout: 60
# @tags: usage, image, png, cli
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant -h >"$tmpdir/help.out" 2>&1

validator_assert_contains "$tmpdir/help.out" 'usage:  pngquant'
validator_assert_contains "$tmpdir/help.out" 'options:'
validator_assert_contains "$tmpdir/help.out" '--quality'

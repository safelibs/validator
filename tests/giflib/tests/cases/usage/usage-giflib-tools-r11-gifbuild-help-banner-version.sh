#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-gifbuild-help-banner-version
# @title: gifbuild -h prints version banner and usage line
# @description: Invokes gifbuild -h, which exits zero on noble, and verifies the printed banner names the binary, includes a "Version" string, and contains the documented "Usage: gifbuild" line.
# @timeout: 30
# @tags: usage, cli, gifbuild, help
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gifbuild -h >"$tmpdir/banner.txt" 2>&1

validator_assert_contains "$tmpdir/banner.txt" 'gifbuild Version'
validator_assert_contains "$tmpdir/banner.txt" 'Usage: gifbuild'

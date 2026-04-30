#!/usr/bin/env bash
# @testcase: usage-gio-help-launch
# @title: gio help launch usage banner
# @description: Invokes gio help launch and verifies the documented usage line for launching desktop files is reported.
# @timeout: 120
# @tags: usage, gio, help
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-help-launch"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio help launch >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'Usage:'
validator_assert_contains "$tmpdir/out" 'gio launch'
validator_assert_contains "$tmpdir/out" 'DESKTOP-FILE'

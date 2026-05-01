#!/usr/bin/env bash
# @testcase: usage-gio-launch-missing-desktop-error
# @title: gio launch reports missing desktop file
# @description: Invokes gio launch without arguments and confirms it reports the no-desktop-file error and prints the launch usage banner on stderr.
# @timeout: 60
# @tags: usage, gio, error
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-launch-missing-desktop-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
gio launch >"$tmpdir/stdout" 2>"$tmpdir/stderr"
status=$?
set -e

[[ $status -ne 0 ]] || { echo "expected gio launch to exit non-zero" >&2; exit 1; }
validator_assert_contains "$tmpdir/stderr" 'No desktop file given'
validator_assert_contains "$tmpdir/stderr" 'gio launch DESKTOP-FILE'

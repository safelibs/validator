#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-help-shows-version-line
# @title: bzip2 --help banner contains a "Version 1.0" line
# @description: Runs "bzip2 --help" and asserts stdout/stderr include a "Version 1.0" prefix substring, confirming the help banner identifies the bzip2 1.0.x family on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, bzip2, help, version
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# bzip2 --help writes to stderr on noble; capture both.
bzip2 --help >"$tmpdir/help.out" 2>"$tmpdir/help.err" || true
cat "$tmpdir/help.out" "$tmpdir/help.err" >"$tmpdir/help.all"

grep -F 'Version 1.0' "$tmpdir/help.all" >/dev/null

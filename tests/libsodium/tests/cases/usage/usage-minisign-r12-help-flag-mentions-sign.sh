#!/usr/bin/env bash
# @testcase: usage-minisign-r12-help-flag-mentions-sign
# @title: minisign -h help output advertises the -S sign verb
# @description: Runs minisign -h capturing combined stdout and stderr, asserts the exit status is non-failing or the help text was emitted, and verifies the output mentions the -S sign verb so the CLI surface area is intact.
# @timeout: 60
# @tags: usage, minisign, cli
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# minisign -h prints help to stderr and exits non-zero on some builds; tolerate it.
minisign -h >"$tmpdir/out" 2>&1 || true

# Help banner identifies the tool and the sign verb.
grep -q -i 'minisign' "$tmpdir/out"
grep -q -E ' -S\b' "$tmpdir/out"

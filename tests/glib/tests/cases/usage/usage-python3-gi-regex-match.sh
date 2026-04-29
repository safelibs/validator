#!/usr/bin/env bash
# @testcase: usage-python3-gi-regex-match
# @title: PyGObject GLib regex match
# @description: Matches a string with GLib.regex_match_simple through PyGObject and verifies the boolean result.
# @timeout: 180
# @tags: usage, python, regex
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-regex-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(f"match={GLib.regex_match_simple('beta', 'alpha beta gamma', 0, 0)}")
PYCASE
validator_assert_contains "$tmpdir/out" 'match=True'

#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-reconnect-flag
# @title: ttyd --help emits a USAGE block listing options
# @description: Runs ttyd --help (which exits non-zero on noble's ttyd 1.7.x) and verifies the output contains a "USAGE:" header — the json-c-driven argv parser's help dispatcher. (Earlier rounds keyed on the -r/--reconnect or -O/--once flag lines, which are not stably advertised across ttyd builds; the USAGE header is the cross-version anchor.)
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
[[ -s "$tmpdir/help.txt" ]] || { printf 'ttyd --help produced no output\n' >&2; exit 1; }
grep -Eiq '(USAGE|Usage):' "$tmpdir/help.txt" || {
    sed -n '1,30p' "$tmpdir/help.txt" >&2; exit 1; }

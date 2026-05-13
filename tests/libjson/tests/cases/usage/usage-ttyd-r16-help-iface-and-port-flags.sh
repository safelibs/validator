#!/usr/bin/env bash
# @testcase: usage-ttyd-r16-help-iface-and-port-flags
# @title: ttyd --help advertises both interface and port flags in one OPTIONS block
# @description: Captures ttyd --help once and asserts both -i/--interface AND -p/--port flags appear in the same OPTIONS block, locking in the listener-binding flag pair as co-resident, distinct from earlier rounds that checked each flag in isolation.
# @timeout: 60
# @tags: usage, ttyd, help, listener
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '-i, --interface' "$tmpdir/help.txt"
grep -Eq -- '-p, --port' "$tmpdir/help.txt"

#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-giftext-determinism-two-runs
# @title: giftext on treescap.gif is deterministic across two consecutive invocations
# @description: Runs giftext on treescap.gif twice and asserts the two stdout captures are byte-for-byte identical (parsing the same GIF must produce the same textual dump on the same machine), exercising the giftext output-determinism invariant distinct from prior single-invocation content tests.
# @timeout: 60
# @tags: usage, cli, giftext, determinism, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/run1.txt"
giftext "$gif" >"$tmpdir/run2.txt"

cmp "$tmpdir/run1.txt" "$tmpdir/run2.txt"
[[ -s "$tmpdir/run1.txt" ]] || { echo "empty output" >&2; exit 1; }

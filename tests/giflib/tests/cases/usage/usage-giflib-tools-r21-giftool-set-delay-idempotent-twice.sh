#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-giftool-set-delay-idempotent-twice
# @title: giftool -d 30 applied twice on fire.gif is byte-for-byte identical to applying once
# @description: Pipes fire.gif through giftool -d 30 once, then pipes the result through giftool -d 30 a second time, and asserts the two output GIFs are byte-for-byte identical, exercising the idempotence of the per-frame delay setter on a multi-frame fixture distinct from the prior single-application delay-setter tests.
# @timeout: 60
# @tags: usage, cli, giftool, delay, idempotent, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 30 <"$gif" >"$tmpdir/once.gif"
giftool -d 30 <"$tmpdir/once.gif" >"$tmpdir/twice.gif"

cmp "$tmpdir/once.gif" "$tmpdir/twice.gif"

# Sanity: result still parses and emits delay=30 for every frame.
giftool -f '%d\n' <"$tmpdir/twice.gif" >"$tmpdir/d.txt"
unique=$(sort -u "$tmpdir/d.txt")
[[ "$unique" == "30" ]] || { echo "unexpected delays: $unique" >&2; exit 1; }

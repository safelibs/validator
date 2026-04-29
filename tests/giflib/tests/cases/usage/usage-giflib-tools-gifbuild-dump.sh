#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-dump
# @title: giflib-tools gifbuild dump
# @description: Runs giflib-tools gifbuild dump on a GIF fixture and checks image metadata.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
grep -E 'screen|image|rgb' -i "$tmpdir/dump.txt" | head

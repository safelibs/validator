#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftool-set-disposal-zero-fire
# @title: giftool -x 0 clears disposal mode on every fire frame
# @description: Pipes the multi-frame fire fixture through giftool -x 0 and uses gifbuild -d to confirm every frame's "disposal mode" line collapses to mode 0, distinct from the file's source disposal mode 1.
# @timeout: 60
# @tags: usage, cli, giftool, disposal
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -x 0 <"$gif" >"$tmpdir/out.gif"
gifbuild -d "$tmpdir/out.gif" >"$tmpdir/dump.txt"

# Collect every disposal-mode line and ensure it is mode 0 only.
modes=$(grep -E '^[[:space:]]+disposal mode [0-9]+$' "$tmpdir/dump.txt" | sort -u)
if [[ "$modes" != "$(printf '\tdisposal mode 0')" ]]; then
    printf 'expected only "disposal mode 0", got:\n%s\n' "$modes" >&2
    exit 1
fi

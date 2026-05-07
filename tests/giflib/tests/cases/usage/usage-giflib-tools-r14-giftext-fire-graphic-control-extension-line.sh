#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftext-fire-graphic-control-extension-line
# @title: giftext -e on fire.gif emits a GIF89 graphics control marker per frame
# @description: Runs giftext -e on the fire animation fixture and asserts the count of "GIF89 graphics control" extension markers equals the per-frame count reported by giftool -f '%n\n', confirming the GCB extension is enumerated once per image record.
# @timeout: 60
# @tags: usage, cli, giftext, extension
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -e "$gif" >"$tmpdir/ext.txt"
giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"

frames=$(wc -l <"$tmpdir/n.txt")
gcb=$(grep -cE 'GIF89 graphics control' "$tmpdir/ext.txt" || true)

[[ "$frames" -ge 2 ]]
[[ "$gcb" -eq "$frames" ]] || {
    printf 'gcb count=%s != frames=%s\n' "$gcb" "$frames" >&2
    exit 1
}

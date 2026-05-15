#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giffix-fire-image-count-preserved
# @title: giffix on treescap.gif yields a file whose gifbuild dump has the same image-record count
# @description: Runs giffix on the single-frame treescap.gif fixture and asserts the resulting file's gifbuild dump contains exactly the same number of "image # N" header lines as the original (1), exercising image-record count preservation across a clean-input giffix pass distinct from prior tests focused on screen-size or palette preservation.
# @timeout: 60
# @tags: usage, cli, giffix, image-count, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giffix "$gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

before=$(gifbuild -d "$gif" | grep -cE '^image # [0-9]+$' || true)
after=$(gifbuild -d "$tmpdir/fixed.gif" | grep -cE '^image # [0-9]+$' || true)

[[ "$before" -ge 1 ]] || { printf 'expected at least one image, got %s\n' "$before" >&2; exit 1; }
[[ "$before" == "$after" ]] || {
    printf 'image-count mismatch before=%s after=%s\n' "$before" "$after" >&2
    exit 1
}

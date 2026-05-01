#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-extension-disposal-modes
# @title: giftext -e dumps GIF89 graphics control blocks with Disposal Mode lines
# @description: Runs giftext -e on fire.gif (an animated multi-frame GIF89 fixture) and asserts the extension-block listing contains GIF89 graphics control records carrying Disposal Mode and DelayTime lines, with the Disposal Mode count matching the frame count reported by giftext on the same fixture.
# @timeout: 60
# @tags: usage, cli, giftext, extensions
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -e "$gif" >"$tmpdir/ext.txt"
giftext "$gif" >"$tmpdir/info.txt"

validator_assert_contains "$tmpdir/ext.txt" 'GIF89 graphics control'
validator_assert_contains "$tmpdir/ext.txt" 'Disposal Mode:'
validator_assert_contains "$tmpdir/ext.txt" 'DelayTime:'

frame_count=$(grep -cE '^Image #[0-9]+:' "$tmpdir/info.txt" || true)
disposal_count=$(grep -cE 'Disposal Mode:' "$tmpdir/ext.txt" || true)

if (( frame_count < 2 )); then
  printf 'expected fire.gif fixture to be multi-frame, got %s\n' "$frame_count" >&2
  exit 1
fi

if [[ "$frame_count" != "$disposal_count" ]]; then
  printf 'frame/disposal count mismatch: frames=%s disposals=%s\n' \
    "$frame_count" "$disposal_count" >&2
  exit 1
fi

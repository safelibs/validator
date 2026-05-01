#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-quantize-stream-byte-count
# @title: gif2rgb -c 4 -1 -o produces a single concatenated RGB stream of W*H*3 bytes
# @description: Runs gif2rgb -c 4 -1 -o <file> on fire.gif and verifies that exactly one output file is produced (no .R/.G/.B planar split) whose byte count equals width*height*3 = 5400, anchoring the quantize+stream combination of flags.
# @timeout: 60
# @tags: usage, cli, gif2rgb, quantize, stream
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

out="$tmpdir/q4.rgb"
gif2rgb -c 4 -1 -o "$out" "$gif"

[[ -f "$out" ]] || {
  printf 'expected single stream output %s\n' "$out" >&2
  exit 1
}

# In stream mode (-1) gif2rgb must NOT emit planar .R/.G/.B variants alongside.
for plane in R G B; do
  if [[ -e "${out}.${plane}" ]]; then
    printf 'unexpected planar output %s in stream mode\n' "${out}.${plane}" >&2
    exit 1
  fi
done

size=$(wc -c <"$out")
if [[ "$size" -ne 5400 ]]; then
  printf 'expected 5400 stream bytes for 30x60x3, got %s\n' "$size" >&2
  exit 1
fi

distinct=$(od -An -tu1 -w1 "$out" | tr -d ' ' | sort -u | wc -l)
if (( distinct < 1 )); then
  printf 'stream output had no byte values\n' >&2
  exit 1
fi

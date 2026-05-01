#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-quantize-planar-equal-bytes
# @title: gif2rgb -c 16 -o writes three equal-size R/G/B planes for fire.gif
# @description: Runs gif2rgb -c 16 -o <prefix> on fire.gif (without -1) and verifies the tool emits exactly three planar files (.R, .G, .B) each with byte count equal to width*height (1800 for 30x60), exercising the color-quantization path that is otherwise untested in usage coverage.
# @timeout: 60
# @tags: usage, cli, gif2rgb, quantize, planar
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

prefix="$tmpdir/q16"
gif2rgb -c 16 -o "$prefix" "$gif"

for plane in R G B; do
  path="${prefix}.${plane}"
  [[ -f "$path" ]] || {
    printf 'expected planar output %s to exist\n' "$path" >&2
    exit 1
  }
  size=$(wc -c <"$path")
  if [[ "$size" -ne 1800 ]]; then
    printf 'plane %s expected 1800 bytes, got %s\n' "$plane" "$size" >&2
    exit 1
  fi
done

# Each plane must be a non-empty byte stream with at least two distinct
# values (a single-color result would mean the quantizer collapsed the
# image and is a regression worth surfacing).
for plane in R G B; do
  distinct=$(od -An -tu1 -w1 "${prefix}.${plane}" | tr -d ' ' | sort -u | wc -l)
  if (( distinct < 2 )); then
    printf 'plane %s collapsed to %s distinct bytes\n' "$plane" "$distinct" >&2
    exit 1
  fi
done

#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-tag-make-explicit
# @title: exif --machine-readable --tag=Make returns the explicit Canon scalar
# @description: Runs the exif client with --machine-readable --tag=Make against the canon fixture and verifies the streamed output is a single tab-delimited record whose payload is exactly the literal Canon manufacturer string. The probe pins the explicit-value contract for dependent clients that key off Make, ruling out localized labels, multi-row framing, or accidental empty payloads when --tag is combined with --machine-readable.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-tag-make-explicit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Make "$img" >"$tmpdir/out"

# Exactly one line
line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for Make, got %d\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

# Payload is the bare scalar (no leading "Manufacturer\t" prefix when --tag is used)
read -r value <"$tmpdir/out"
if [[ "$value" != "Canon" ]]; then
  printf 'expected explicit Make value "Canon", got %q\n' "$value" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

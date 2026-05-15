#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-tag-model-readback-non-empty
# @title: exif --tag=Model on canon fixture emits a non-empty Value line
# @description: Runs exif --tag=Model --ifd=0 on the canon fixture, captures the pretty output, and asserts it includes a Value: line whose value text is non-empty - locking in libexif's IFD0 Model tag readback path with a value present.
# @timeout: 60
# @tags: usage, exif, tag, model, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Model --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"
val_line=$(LC_ALL=C grep -E '^[[:space:]]*Value:' "$tmpdir/out" | head -n1 || true)
if [[ -z "$val_line" ]]; then
    echo 'no Value: line in output' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
# Strip "Value:" prefix and surrounding whitespace.
val=$(printf '%s' "$val_line" | sed -E 's/^[[:space:]]*Value:[[:space:]]*//' | sed -E 's/[[:space:]]+$//')
if [[ -z "$val" ]]; then
    printf 'empty Value field: %q\n' "$val_line" >&2
    exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-machine-readable-canon-tab-token-count
# @title: exif -m on IFD0 emits nine rows each with a tab-separated key value pair
# @description: Runs exif --machine-readable --ifd=0 on the Canon fixture and asserts the captured output contains exactly nine non-empty rows where every row matches "<label><TAB><value>" - locking in the structural shape of libexif's machine-readable IFD0 listing where each entry is one row of two tab-separated fields.
# @timeout: 60
# @tags: usage, exif, machine-readable, ifd-zero, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"

# Count non-empty rows.
rows=$(LC_ALL=C grep -c -v '^$' "$tmpdir/out" || true)
[[ "$rows" -eq 9 ]] || {
    printf 'expected 9 rows, got %s\n' "$rows" >&2
    cat "$tmpdir/out" >&2
    exit 1
}

# Every non-empty row must contain at least one TAB.
if LC_ALL=C grep -n -v '^$' "$tmpdir/out" | LC_ALL=C grep -vE $'\t' >"$tmpdir/bad"; then
    if [[ -s "$tmpdir/bad" ]]; then
        echo 'rows missing tab separator:' >&2
        head -5 "$tmpdir/bad" >&2
        exit 1
    fi
fi

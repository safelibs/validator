#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-ids-show-mnote-hex-pattern
# @title: exif --ids --show-mnote prints rows beginning with 0x and a hex tag id
# @description: Runs exif --ids --show-mnote on the Canon fixture, skips the header line, and asserts every remaining non-empty line starts with the "0x" prefix followed by exactly four lowercase hex digits and a "|" delimiter - locking in libexif's --ids rendering for MakerNote tag identifiers as 16-bit hex.
# @timeout: 60
# @tags: usage, exif, show-mnote, ids, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --show-mnote "$img" >"$tmpdir/out" 2>"$tmpdir/err"
# Drop the "MakerNote contains N values:" header.
LC_ALL=C tail -n +2 "$tmpdir/out" | LC_ALL=C grep -v '^$' >"$tmpdir/body"
[[ -s "$tmpdir/body" ]] || { echo 'no mnote rows after header' >&2; cat "$tmpdir/out" >&2; exit 1; }
# Every row must start with 0xHHHH|
if LC_ALL=C grep -vE '^0x[0-9a-f]{4}\|' "$tmpdir/body" >"$tmpdir/bad"; then
    if [[ -s "$tmpdir/bad" ]]; then
        echo 'rows not matching 0xHHHH| prefix:' >&2
        head -5 "$tmpdir/bad" >&2
        exit 1
    fi
fi

#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-description-without-ifd-error
# @title: exif -s without --ifd demands an IFD
# @description: Runs exif --show-description --tag=Orientation against the canon fixture without specifying an --ifd and verifies the client refuses to disambiguate, exiting non-zero with the canonical "You need to specify an IFD!" diagnostic. This pins the libexif Ubuntu 24.04 behavior that show-description requires an explicit IFD scope when the requested tag is registered in more than one IFD.
# @timeout: 60
# @tags: usage, metadata, error
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-description-without-ifd-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --show-description --tag=Orientation "$img" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected non-zero exit when --ifd missing, got rc=0\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'You need to specify an IFD!'

# Adding --ifd=0 turns the error into a successful show-description run.
exif --show-description --tag=Orientation --ifd=0 "$img" >"$tmpdir/ok"
validator_assert_contains "$tmpdir/ok" "Tag 'Orientation' (0x0112, 'Orientation')"

#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-remove-make-and-model-both-gone
# @title: exif --remove with two -t flags drops both Make and Model in a single pass
# @description: Removes both the Make and Model tags in IFD 0 with a single exif --remove invocation that lists --tag=Make and --tag=Model together, writes the new JPEG via --output, and verifies subsequent --machine-readable lookups for either tag fail (non-zero exit) and produce no value lines, asserting libexif honours multiple repeated -t selections during a single remove pass.
# @timeout: 60
# @tags: usage, remove, multiple-tags
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --ifd=0 --tag=Make --tag=Model \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

# Both readbacks should fail (exif exits non-zero when the requested tag is absent).
if exif --machine-readable --tag=Make "$tmpdir/out.jpg" >"$tmpdir/make.out" 2>"$tmpdir/make.err"; then
  printf 'expected Make readback to fail after removal\n' >&2
  cat "$tmpdir/make.out" >&2
  exit 1
fi

if exif --machine-readable --tag=Model "$tmpdir/out.jpg" >"$tmpdir/model.out" 2>"$tmpdir/model.err"; then
  printf 'expected Model readback to fail after removal\n' >&2
  cat "$tmpdir/model.out" >&2
  exit 1
fi

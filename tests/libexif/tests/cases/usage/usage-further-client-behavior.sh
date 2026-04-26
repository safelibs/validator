#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

extract_value() {
  sed -n 's/.*Value: //p' "$1" >"$tmpdir/value"
  test -s "$tmpdir/value"
}

case "$case_id" in
  usage-exif-cli-tag-make-sed)
    exif --tag=Make "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" 'Canon'
    ;;
  usage-exif-cli-tag-model-sed)
    exif --tag=Model "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" 'Canon PowerShot S70'
    ;;
  usage-exif-cli-tag-datetime-sed)
    exif --tag=DateTime "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" '2009:10:10 16:42:32'
    ;;
  usage-exif-cli-tag-orientation-sed)
    exif --tag=Orientation "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" 'Right-top'
    ;;
  usage-exif-cli-tag-focal-length-sed)
    exif --tag=FocalLength "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" '5.8 mm'
    ;;
  usage-exif-cli-tag-color-space-sed)
    exif --tag=ColorSpace "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" 'sRGB'
    ;;
  usage-exif-cli-tag-pixel-x-sed)
    exif --tag=PixelXDimension "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" '640'
    ;;
  usage-exif-cli-tag-pixel-y-sed)
    exif --tag=PixelYDimension "$img" >"$tmpdir/out"
    extract_value "$tmpdir/out"
    validator_assert_contains "$tmpdir/value" '480'
    ;;
  usage-exif-cli-xml-model-regex)
    exif --xml-output "$img" >"$tmpdir/out.xml"
    python3 - <<'PYCASE' "$tmpdir/out.xml" >"$tmpdir/out"
from pathlib import Path
import re
import sys
text = Path(sys.argv[1]).read_text(encoding='utf-8')
match = re.search(r'<Model>([^<]+)</Model>', text)
if not match:
    raise SystemExit('missing Model tag')
print(match.group(1))
PYCASE
    validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
    ;;
  usage-exif-cli-machine-record-count)
    exif --machine-readable "$img" >"$tmpdir/out"
    grep -Fx $'Maker Note\t904 bytes undefined data' "$tmpdir/out" >"$tmpdir/maker"
    grep -Fx $'ThumbnailSize\t4' "$tmpdir/out" >"$tmpdir/thumb"
    ;;
  *)
    printf 'unknown libexif further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

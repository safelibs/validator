#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-model-regex
# @title: exif XML model via regex
# @description: Parses exif XML output through Python regex matching and verifies the extracted model tag content.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-model-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

extract_value() {
  sed -n 's/.*Value: //p' "$1" >"$tmpdir/value"
  test -s "$tmpdir/value"
}

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

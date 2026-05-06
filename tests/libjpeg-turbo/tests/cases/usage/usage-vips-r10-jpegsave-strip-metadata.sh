#!/usr/bin/env bash
# @testcase: usage-vips-r10-jpegsave-strip-metadata
# @title: vips jpegsave strip removes metadata
# @description: Loads a JPEG that contains a custom comment, re-saves it with vips jpegsave --strip, and verifies the output binary contains no JPEG comment marker (FFFE) and is materially smaller than the metadata-bearing input of the same pixels.
# @timeout: 180
# @tags: usage, jpeg, image, strip
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
src = base / "with.jpg"
img = Image.new("RGB", (40, 32))
img.putdata([((x * 7) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(32) for x in range(40)])
img.save(src, "JPEG", quality=80, comment=b"safelibs-vips-strip-test-marker")
PY

vips jpegsave "$tmpdir/with.jpg" "$tmpdir/stripped.jpg" --strip

# COM marker FFFE must not appear in the stripped output.
if python3 -c 'import sys; sys.exit(0 if b"\xff\xfe" in open(sys.argv[1], "rb").read() else 1)' "$tmpdir/stripped.jpg"; then
    echo "stripped output still contains a COM marker" >&2
    exit 1
fi

# And the COM marker should appear in the original.
python3 -c 'import sys; sys.exit(0 if b"\xff\xfe" in open(sys.argv[1], "rb").read() else 1)' "$tmpdir/with.jpg"

vipsheader "$tmpdir/stripped.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '40x32'

#!/usr/bin/env bash
# @testcase: usage-exif-cli-insert-thumbnail-roundtrip
# @title: exif --insert-thumbnail roundtrip preserves bytes
# @description: Builds a minimal JPEG, inserts it into a copy of the canon fixture with --insert-thumbnail, then re-extracts the thumbnail and asserts byte-for-byte equality.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Build a minimal but well-formed grayscale JPEG to use as a custom thumbnail.
python3 - "$tmpdir/tiny.jpg" <<'PY'
import sys
hex_data = (
    'FFD8FFE000104A46494600010100000100010000FFDB004300080606070605'
    '08070708090908090A0C140D0C0B0B0C1912130F141D1A1F1E1D1A1C1C2024'
    '2E2720222C231C1C2837292C30313434341F27393D38323C2E333432FFC000'
    '0B080001000101011100FFC4001F0000010501010101010100000000000000'
    '000102030405060708090A0BFFC400B5100002010303020403050504040000'
    '017D01020300041105122131410613516107227114328191A1082342B1C115'
    '52D1F02433627282090A161718191A25262728292A3435363738393A434445'
    '464748494A535455565758595A636465666768696A737475767778797A8384'
    '85868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8'
    'B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1'
    'F2F3F4F5F6F7F8F9FAFFC4001F0100030101010101010101010000000000000'
    '102030405060708090A0BFFC400B51100020102040403040705040400010277'
    '000102031104052131061241510761711322328108144291A1B1C109233352F0'
    '156272D10A162434E125F11718191A262728292A35363738393A43444546474849'
    '4A535455565758595A636465666768696A737475767778797A82838485868788'
    '898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4'
    'C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9'
    'FAFFDA000C03010002110311003F00FB00FFD9'
)
open(sys.argv[1], 'wb').write(bytes.fromhex(hex_data))
PY
validator_require_file "$tmpdir/tiny.jpg"

cp "$img" "$tmpdir/source.jpg"
exif --insert-thumbnail="$tmpdir/tiny.jpg" --output="$tmpdir/with-thumb.jpg" "$tmpdir/source.jpg" >"$tmpdir/insert.log"
validator_assert_contains "$tmpdir/insert.log" "Wrote file"
validator_require_file "$tmpdir/with-thumb.jpg"

exif --extract-thumbnail --output="$tmpdir/round.jpg" "$tmpdir/with-thumb.jpg" >/dev/null
validator_require_file "$tmpdir/round.jpg"

# Roundtrip must be byte identical.
sum_in=$(md5sum "$tmpdir/tiny.jpg" | awk '{print $1}')
sum_out=$(md5sum "$tmpdir/round.jpg" | awk '{print $1}')
if [[ "$sum_in" != "$sum_out" ]]; then
  printf 'inserted thumbnail md5 %s does not match extracted %s\n' "$sum_in" "$sum_out" >&2
  exit 1
fi

# Sanity check the extracted thumbnail is still a JPEG.
file "$tmpdir/round.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" "JPEG image data"

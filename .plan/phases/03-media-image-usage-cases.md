# 3. Media, Image, and Metadata Dependent Usage Cases

## Phase Name

Media, Image, and Metadata Dependent Usage Cases

## Implement Phase ID

`impl_phase_03_media_image_usage_cases`

## Preexisting Inputs

- `tests/cjson/` concrete phase 1 output directory.
- `tests/libcsv/` concrete phase 1 output directory.
- `tests/libjson/` concrete phase 1 output directory.
- `tests/libxml/` concrete phase 1 output directory.
- `tests/libyaml/` concrete phase 1 output directory.
- `tests/libuv/` concrete phase 1 output directory.
- `tests/libarchive/` concrete phase 2 output directory.
- `tests/libbz2/` concrete phase 2 output directory.
- `tests/liblzma/` concrete phase 2 output directory.
- `tests/libzstd/` concrete phase 2 output directory.
- `repositories.yml` canonical manifest and package list; consume it unchanged.
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/run_library_tests.sh`
- Existing `tests/giflib/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libexif/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libjpeg-turbo/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libpng/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libtiff/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libvips/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libwebp/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing tracked `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, `artifacts/proof/original-validation-proof.json`, and `site/` evidence. Consume these artifacts in place; do not refetch, recollect, rediscover, regenerate, expand, or reorder dependent inventories.

## New Outputs

- 14 new usage testcase manifest entries.
- 14 new executable usage scripts.
- Updated `exif` common helper.

## File Changes

- Modify `tests/giflib/testcases.yml`.
- Add `tests/giflib/tests/cases/usage/usage-giflib-tools-gif2rgb-fire-fixture.sh`.
- Add `tests/giflib/tests/cases/usage/usage-giflib-tools-giftext-interlaced-fixture.sh`.
- Modify `tests/libexif/testcases.yml`.
- Modify `tests/libexif/tests/cases/usage/usage-exif-cli-common.sh`.
- Add `tests/libexif/tests/cases/usage/usage-exif-cli-tag-datetime.sh`.
- Add `tests/libexif/tests/cases/usage/usage-exif-cli-tag-datetime-original.sh`.
- Modify `tests/libjpeg-turbo/testcases.yml`.
- Add `tests/libjpeg-turbo/tests/cases/usage/usage-python3-pil-progressive-jpeg.sh`.
- Add `tests/libjpeg-turbo/tests/cases/usage/usage-vips-extract-band-jpeg.sh`.
- Modify `tests/libpng/testcases.yml`.
- Add `tests/libpng/tests/cases/usage/usage-pngquant-posterize-png.sh`.
- Add `tests/libpng/tests/cases/usage/usage-netpbm-pamflip-png.sh`.
- Modify `tests/libtiff/testcases.yml`.
- Add `tests/libtiff/tests/cases/usage/usage-python3-pil-deflate-tiff.sh`.
- Add `tests/libtiff/tests/cases/usage/usage-python3-pil-tiff-dpi-save.sh`.
- Modify `tests/libvips/testcases.yml`.
- Add `tests/libvips/tests/cases/usage/usage-ruby-vips-gaussblur-image.sh`.
- Add `tests/libvips/tests/cases/usage/usage-ruby-vips-histogram-image.sh`.
- Modify `tests/libwebp/testcases.yml`.
- Add `tests/libwebp/tests/cases/usage/usage-python3-pil-webp-alpha.sh`.
- Add `tests/libwebp/tests/cases/usage/usage-ffmpeg-webp-scale-filter.sh`.

## Implementation Details

- Apply the global testcase entry contract to all 14 new manifest entries:
  - Use the new script filename without `.sh` as each manifest entry `id`.
  - Set `kind: usage`.
  - Set `timeout_seconds: 180`.
  - Use a semantic `title`.
  - Use a client-behavior `description`.
  - Set `client_application` to one of the existing identifiers named below.
  - Set `command` exactly to `bash /validator/tests/<library>/tests/cases/usage/<script>.sh`.
  - Tags must include `usage` and one or more behavior tags already consistent with the library's local manifest style, such as `metadata`, `image`, or `compression`.
- Wrapper scripts that call a library-local common helper must contain `#!/usr/bin/env bash`, `set -euo pipefail`, and then execute the common helper with the exact workload argument named here.
- Do not modify `repositories.yml`; it remains the fixed canonical manifest and package list.
- Do not modify any affected `tests/<library>/Dockerfile`; every dependent package required by the planned clients is already installed.
- Use only these existing dependent client identifiers:
  - `giflib`: `giflib-tools`
  - `libexif`: `exif`
  - `libjpeg-turbo`: `python3-pil` and `vips`
  - `libpng`: `pngquant` and `netpbm`
  - `libtiff`: `python3-pil`
  - `libvips`: `ruby-vips`
  - `libwebp`: `python3-pil` and `ffmpeg`
- Do not modify any `tests/<library>/tests/fixtures/dependents.json`.
- `giflib`:
  - `usage-giflib-tools-gif2rgb-fire-fixture.sh`: read `"$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"`, run `gif2rgb -1 -o`, and compare output bytes to `"$VALIDATOR_SAMPLE_ROOT/tests/fire.rgb"` with `cmp`.
  - `usage-giflib-tools-giftext-interlaced-fixture.sh`: read `treescap-interlaced.gif`, run `giftext`, assert `Screen Size`, and require a case-insensitive `interlace` match in the output.
- `libexif`: extend `usage-exif-cli-common.sh` with these workloads:
  - `tag-datetime`: run `exif --tag=DateTime` and assert `2009:10:10 16:42:32`.
  - `tag-datetime-original`: run `exif --tag=DateTimeOriginal` and assert `2009:10:10 16:42:32`.
- `libjpeg-turbo`:
  - `usage-python3-pil-progressive-jpeg.sh`: generate a small PPM, encode it with `cjpeg -progressive`, open the output with Pillow, call `load()`, assert size and mode, and assert `im.info.get("progressive") == 1` or `im.info.get("progression") == 1`.
  - `usage-vips-extract-band-jpeg.sh`: generate a JPEG with `cjpeg`, run `vips extract_band "$jpg" "$tmpdir/band.pgm" 0`, assert the output file exists, and assert `vipsheader "$tmpdir/band.pgm"` reports a one-band image.
- `libpng`:
  - `usage-pngquant-posterize-png.sh`: run `pngquant --posterize 4 --force --output "$tmpdir/out.png"` against an existing PNGSuite fixture and assert `file` reports PNG for `"$tmpdir/out.png"`.
  - `usage-netpbm-pamflip-png.sh`: run `pngtopam` on a PNGSuite fixture, rotate with `pamflip -r90`, write PNG with `pnmtopng`, assert `file` reports PNG, and assert the rotated dimensions with `pngtopam "$tmpdir/out.png" | pamfile -`.
- `libtiff`:
  - `usage-python3-pil-deflate-tiff.sh`: create a deterministic RGB image with Pillow, save as TIFF using `compression="tiff_adobe_deflate"`, reopen it, and assert exact mode and size.
  - `usage-python3-pil-tiff-dpi-save.sh`: create a deterministic RGB image, save a TIFF with `dpi=(300, 300)`, reopen it, and assert TIFF XResolution and YResolution tags decode to 300.
- `libvips`:
  - `usage-ruby-vips-gaussblur-image.sh`: create an 8x8 image through ruby-vips, apply `gaussblur(1.2)`, assert width and height remain 8, and assert the blurred image average is greater than 0 and less than 255.
  - `usage-ruby-vips-histogram-image.sh`: create a small uchar image, run `hist_find`, and assert the histogram width is 256 and its maximum value is greater than 0.
- `libwebp`:
  - `usage-python3-pil-webp-alpha.sh`: use Pillow to save an RGBA WebP, reopen it, and assert alpha channel preservation.
  - `usage-ffmpeg-webp-scale-filter.sh`: generate a WebP with `cwebp` from a deterministic PPM fixture, run `ffmpeg -hide_banner -loglevel error -i "$webp" -vf scale=2:2 "$tmpdir/out.png"`, assert `file` reports PNG, and assert `ffprobe` reports dimensions `2,2`.
- Make all new scripts executable.

## Verification Phases

- Phase ID: `check_phase_03_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_03_media_image_usage_cases`
- Purpose: validate manifests and cumulative counts after media/image additions.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 189 \
  --min-cases 284
```

- Phase ID: `check_phase_03_matrix_smoke`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_03_media_image_usage_cases`
- Purpose: run the affected image/media libraries with casts and verify selected proof output.
- Commands:

```bash
rm -rf /tmp/validator-more-cases-phase03
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase03 \
  --record-casts \
  --library giflib \
  --library libexif \
  --library libjpeg-turbo \
  --library libpng \
  --library libtiff \
  --library libvips \
  --library libwebp

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase03 \
  --proof-output /tmp/validator-more-cases-phase03/proof/original-validation-proof.json \
  --library giflib \
  --library libexif \
  --library libjpeg-turbo \
  --library libpng \
  --library libtiff \
  --library libvips \
  --library libwebp \
  --min-source-cases 35 \
  --min-usage-cases 71 \
  --min-cases 106 \
  --require-casts
```

## Success Criteria

- Phase 3 adds exactly 14 usage cases across `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libtiff`, `libvips`, and `libwebp` while leaving source cases unchanged.
- Manifest validation reports at least 95 source cases, 189 usage cases, and 284 total cases.
- The phase 3 matrix smoke passes with casts and selected proof totals of 35 source cases, 71 usage cases, and 106 total cases.
- Image scripts use deterministic generated or checked-in fixtures and do not rely on network or display hardware.
- Temporary verifier output under `/tmp/validator-more-cases-phase03` is not committed.
- `repositories.yml`, affected library Dockerfiles, dependent fixtures, prepared inventories, current tracked artifacts, proof data, and rendered site evidence are preserved unchanged unless explicitly updated by existing tools.

## Git Commit Requirement

The implementer must commit all phase 3 scoped work to git before yielding. Do not yield with uncommitted phase 3 file changes.

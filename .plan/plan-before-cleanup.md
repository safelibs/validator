# Initial Implementation Plan: Additional Dependent-Application Testcases

## Context

This repository validates the original Ubuntu 24.04 apt builds for 19 fixed libraries. The main validation surface is library-specific Docker harnesses under `tests/<library>/`, testcase manifests under `tests/<library>/testcases.yml`, compact dependent-client fixtures under `tests/<library>/tests/fixtures/dependents.json`, generated matrix artifacts under `artifacts/`, and the rendered review site under `site/`.

The existing structure and rules are documented in `README.md:8-26` and `README.md:36-47`. `repositories.yml:6-161` fixes the library order, canonical apt package lists, testcase manifest paths, and dependent fixture paths. That canonical manifest should be consumed as an existing input and should not be expanded or reordered for this goal.

The current testcase baseline is:

- 95 source cases.
- 155 usage cases.
- 250 total cases.
- Every library already has at least 8 usage cases; `libjson`, `libsodium`, and `libwebp` have 9.

The goal is to add more testcases for all libraries, focused on exercising library behavior through dependent applications. The implementation should add two new `kind: usage` cases per library, for 38 new usage cases. Source cases remain at 95. Final expected totals are:

- 95 source cases.
- 193 usage cases.
- 288 total cases.

The plan keeps all new usage cases on existing dependent applications already declared in compact `dependents.json` fixtures and already installed by each library Dockerfile. No new dependent inventory should be fetched, scraped, rediscovered, or regenerated. Existing prepared inputs include the checked-in test harnesses, sample fixtures, dependent-client fixtures, current artifacts, proof JSON, and rendered site. Later implementation phases must consume or update those artifacts in place.

Relevant codebase contracts:

- `tools/testcases.py:247-306` validates testcase fields, `kind`, `client_application`, and dependent fixture membership.
- `tools/testcases.py:430-474` requires each source or usage case to execute an executable script under the matching `tests/cases/<kind>/` directory.
- `tools/testcases.py:623-645` validates compact dependent fixtures and checks that each used dependent package appears in the library Dockerfile.
- `tools/testcases.py:709-735` enforces manifest thresholds.
- `tools/run_matrix.py:523-574` wraps each testcase command in the Docker container through `/validator/tests/_shared/run_library_tests.sh`.
- `tools/run_matrix.py:653-719` writes per-case result JSON, logs, and optional casts.
- `tools/proof.py:401-431` requires artifact result files to match testcase manifests exactly.
- `tools/proof.py:480-560` builds proof totals from manifests and matrix artifacts.
- `scripts/verify-site.sh:168-178` rebuilds proof with casts required and compares it to the rendered site.
- `Makefile:20-21` currently enforces the old testcase thresholds and must be raised after all testcase additions land.
- `README.md:80-113` documents proof/site threshold commands and must be updated to the new final counts.

## Generated Workflow Contract

The generated workflow for this plan must follow these fixed rules:

- Linear execution only. Do not emit `parallel_groups`.
- YAML must be self-contained and inline only. Do not use a top-level `include`, and do not use phase-level `prompt_file`, `workflow_file`, `workflow_dir`, `checks`, or any other YAML-source indirection.
- Do not generate agent-guided `bounce_targets` lists. Use only a fixed `bounce_target`.
- Every verifier must be an explicit top-level `check` phase.
- Every verifier must stay in the implement block it verifies and must bounce to that implement phase.
- If a verifier needs to run tests, lint, build, matrix, proof, site, or any other command, write those commands into the checker instructions. Do not model command execution as a non-agentic phase.
- Existing workspace artifacts are inputs. The workflow must list and consume existing checked-in manifests, dependent fixtures, sample fixtures, Docker harnesses, `artifacts/results`, `artifacts/logs`, `artifacts/casts`, `artifacts/proof/original-validation-proof.json`, and `site/` as existing inputs.
- Prepared artifacts such as dependent inventories, test harnesses, source/sample fixtures, current matrix artifacts, proof data, and rendered site evidence must be preserved under a consume-existing-artifacts contract. Do not refetch, recollect, rediscover, or regenerate inventories from scratch. New matrix artifacts are added or updated in place by the existing matrix/proof/site tools.
- Every implement prompt in the final generated workflow must instruct the agent to commit its scoped work to git before yielding.

The generated workflow topology must be:

1. `impl_phase_01_data_parser_usage_cases`
2. `check_phase_01_manifest_contract`
3. `check_phase_01_matrix_smoke`
4. `impl_phase_02_archive_compression_usage_cases`
5. `check_phase_02_manifest_contract`
6. `check_phase_02_matrix_smoke`
7. `impl_phase_03_media_image_usage_cases`
8. `check_phase_03_manifest_contract`
9. `check_phase_03_matrix_smoke`
10. `impl_phase_04_runtime_crypto_usage_cases`
11. `check_phase_04_manifest_contract`
12. `check_phase_04_matrix_smoke`
13. `impl_phase_05_thresholds_artifacts_site`
14. `check_phase_05_unit_manifest_contract`
15. `check_phase_05_full_matrix_proof_site`

Artifact flow is:

`tests/<library>/testcases.yml` plus `tests/<library>/tests/cases/usage/*.sh` -> `bash test.sh`/`tools/run_matrix.py` -> `artifacts/results`, `artifacts/logs`, `artifacts/casts` -> `tools/verify_proof_artifacts.py` -> `artifacts/proof/original-validation-proof.json` -> `tools/render_site.py` -> `site/` -> `scripts/verify-site.sh`.

## Implementation Phases

Global testcase entry contract for all implementation phases:

- Each new manifest entry must use the new script filename without `.sh` as its `id`.
- Each new manifest entry must set `kind: usage`, `timeout_seconds: 180`, a semantic `title`, a client-behavior `description`, and `client_application` to one of the existing identifiers named in that phase.
- Each new manifest entry must set `command` exactly to `bash` followed by the script's container path, for example `/validator/tests/<library>/tests/cases/usage/<script>.sh`.
- Wrapper scripts that call a library-local common helper must contain `#!/usr/bin/env bash`, `set -euo pipefail`, and then execute the common helper with the exact workload argument named in the implementation details.
- Tags must include `usage` and one or more behavior tags already consistent with that library's local manifest style, such as `json`, `compression`, `metadata`, `image`, `runtime`, or `crypto`.

### 1. Data, Parser, and Event-Loop Dependent Usage Cases

**Phase Name:** Data, Parser, and Event-Loop Dependent Usage Cases

**Implement Phase ID:** `impl_phase_01_data_parser_usage_cases`

**Verification Phases:**

- Phase ID: `check_phase_01_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_01_data_parser_usage_cases`
- Purpose: validate manifest schema, executable scripts, dependent-client references, Dockerfile package coverage, and cumulative counts after phase 1.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 167 \
  --min-cases 262

python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --list-summary
```

- Phase ID: `check_phase_01_matrix_smoke`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_01_data_parser_usage_cases`
- Purpose: run the affected data/parser/event-loop libraries with casts and verify proof generation for the selected result set.
- Commands:

```bash
rm -rf /tmp/validator-more-cases-phase01
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase01 \
  --record-casts \
  --library cjson \
  --library libcsv \
  --library libjson \
  --library libxml \
  --library libyaml \
  --library libuv

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase01 \
  --proof-output /tmp/validator-more-cases-phase01/proof/original-validation-proof.json \
  --library cjson \
  --library libcsv \
  --library libjson \
  --library libxml \
  --library libyaml \
  --library libuv \
  --min-source-cases 30 \
  --min-usage-cases 61 \
  --min-cases 91 \
  --require-casts
```

**Preexisting Inputs:**

- `.plan/goal.md`
- `repositories.yml`
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/runtime_helpers.sh`
- Existing manifests, Dockerfiles, dependent fixtures, and usage scripts for `cjson`, `libcsv`, `libjson`, `libxml`, `libyaml`, and `libuv`.
- Existing sample fixtures under each affected `tests/<library>/tests/fixtures/` directory.

**New Outputs:**

- 12 new usage testcase manifest entries.
- 12 new executable usage scripts.
- Updated library-local common usage helpers for `cjson`, `libcsv`, and `libjson`.

**File Changes:**

- Modify `tests/cjson/testcases.yml`.
- Modify `tests/cjson/tests/cases/usage/usage-iperf3-json-common.sh`.
- Add `tests/cjson/tests/cases/usage/usage-iperf3-json-zero-copy.sh`.
- Add `tests/cjson/tests/cases/usage/usage-iperf3-json-omit-warmup.sh`.
- Modify `tests/libcsv/testcases.yml`.
- Modify `tests/libcsv/tests/cases/usage/usage-readstat-common.sh`.
- Add `tests/libcsv/tests/cases/usage/usage-readstat-escaped-quotes-csv.sh`.
- Add `tests/libcsv/tests/cases/usage/usage-readstat-wide-csv.sh`.
- Modify `tests/libjson/testcases.yml`.
- Modify `tests/libjson/tests/cases/usage/usage-gdal-json-common.sh`.
- Add `tests/libjson/tests/cases/usage/usage-gdal-ogr2ogr-where-geojson.sh`.
- Add `tests/libjson/tests/cases/usage/usage-gdal-ogr2ogr-reproject-geojson.sh`.
- Modify `tests/libxml/testcases.yml`.
- Add `tests/libxml/tests/cases/usage/usage-python3-lxml-xinclude-xml.sh`.
- Add `tests/libxml/tests/cases/usage/usage-xmlstarlet-transform-xml.sh`.
- Modify `tests/libyaml/testcases.yml`.
- Add `tests/libyaml/tests/cases/usage/usage-python3-yaml-cbase-loader.sh`.
- Add `tests/libyaml/tests/cases/usage/usage-python3-yaml-binary-scalar.sh`.
- Modify `tests/libuv/testcases.yml`.
- Add `tests/libuv/tests/cases/usage/usage-nodejs-fs-watch.sh`.
- Add `tests/libuv/tests/cases/usage/usage-nodejs-crypto-pbkdf2.sh`.

**Implementation Details:**

- Apply the global testcase entry contract to all 12 new manifest entries.
- Do not modify `tests/<library>/tests/fixtures/dependents.json`; use only these existing `client_application` values:
  - `cjson`: `iperf3`
  - `libcsv`: `readstat`
  - `libjson`: `gdal`
  - `libxml`: `python3-lxml` and `xmlstarlet`
  - `libyaml`: `python3-yaml`
  - `libuv`: `nodejs`
- `cjson`: extend `usage-iperf3-json-common.sh` with workloads:
  - `zero-copy`: start the existing one-shot loopback server, run `iperf3 -c 127.0.0.1 -p "$port" -J -Z -n 32K`, and assert with `jq -e` that `.end.sum_sent.bytes > 0` and `.end.sum_sent.bits_per_second > 0`.
  - `omit-warmup`: run `iperf3 -c 127.0.0.1 -p "$port" -J -O 1 -t 2 -i 1`, and assert with `jq -e` that `.intervals` is non-empty, at least one interval is marked omitted through `.sum.omitted` or `.streams[].omitted`, and `.end` is an object.
- `libcsv`: extend `usage-readstat-common.sh` with workloads:
  - `escaped-quotes-csv`: create CSV containing an escaped double quote field such as `"alpha ""quoted"""`, convert through readstat metadata into DTA, read back to CSV with `readstat "$tmpdir/out.dta" -`, and assert the escaped quote text survives in the exported CSV.
  - `wide-csv`: create a four-column CSV and matching four-variable metadata, convert to DTA, run `readstat "$tmpdir/out.dta"` for summary and assert `Columns: 4`, then export with `readstat "$tmpdir/out.dta" -` and assert a row value from the fourth column.
- `libjson`: extend `usage-gdal-json-common.sh` with workloads:
  - `ogr2ogr-where`: use the existing generated GeoJSON fixture, run `ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$geojson" -where 'value=2'`, assert `beta` is present and `alpha` is absent.
  - `ogr2ogr-reproject`: run `ogr2ogr -f GeoJSON "$tmpdir/reprojected.geojson" "$geojson" -s_srs EPSG:4326 -t_srs EPSG:3857`, then use `jq` to assert a FeatureCollection exists and coordinates were written.
- `libxml`:
  - `usage-python3-lxml-xinclude-xml.sh`: create `main.xml` with an `xi:include` element and `fragment.xml`, parse with `lxml.etree`, call `tree.xinclude()`, and assert the included element text is visible.
  - `usage-xmlstarlet-transform-xml.sh`: create XML and XSLT fixtures, run `xmlstarlet tr`, and assert the transformed output contains the expected value.
- `libyaml`:
  - `usage-python3-yaml-cbase-loader.sh`: in Python, assert `yaml.__with_libyaml__` is true, load nested YAML through `yaml.CBaseLoader`, assert scalar values are loaded as strings as expected for `BaseLoader`, and print a parsed value.
  - `usage-python3-yaml-binary-scalar.sh`: load a `!!binary` scalar through `yaml.safe_load`, assert the decoded bytes, and print the decoded length.
- `libuv`:
  - `usage-nodejs-fs-watch.sh`: create a temporary file, run a Node script using `fs.watch`, mutate the file, and assert a `change` event arrives before timeout.
  - `usage-nodejs-crypto-pbkdf2.sh`: run Node's asynchronous `crypto.pbkdf2`, which uses libuv threadpool work, and assert the derived key length and callback completion.
- Make all new scripts executable.
- The implementer must commit the phase 1 changes to git before yielding.

**Verification:**

- Run the two check phases above.
- Review `python3 tools/testcases.py --config repositories.yml --tests-root tests --list-summary` and confirm phase 1 cumulative totals are at least 95 source, 167 usage, and 262 total.
- Inspect generated smoke proof in `/tmp/validator-more-cases-phase01/proof/original-validation-proof.json` only as a temporary verifier artifact; do not commit it.

### 2. Archive and Compression Dependent Usage Cases

**Phase Name:** Archive and Compression Dependent Usage Cases

**Implement Phase ID:** `impl_phase_02_archive_compression_usage_cases`

**Verification Phases:**

- Phase ID: `check_phase_02_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_02_archive_compression_usage_cases`
- Purpose: validate manifest schema and cumulative counts after archive/compression additions.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 175 \
  --min-cases 270
```

- Phase ID: `check_phase_02_matrix_smoke`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_02_archive_compression_usage_cases`
- Purpose: run the affected archive/compression libraries with casts and verify selected proof output.
- Commands:

```bash
rm -rf /tmp/validator-more-cases-phase02
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase02 \
  --record-casts \
  --library libarchive \
  --library libbz2 \
  --library liblzma \
  --library libzstd

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase02 \
  --proof-output /tmp/validator-more-cases-phase02/proof/original-validation-proof.json \
  --library libarchive \
  --library libbz2 \
  --library liblzma \
  --library libzstd \
  --min-source-cases 20 \
  --min-usage-cases 40 \
  --min-cases 60 \
  --require-casts
```

**Preexisting Inputs:**

- Phase 1 committed changes.
- `repositories.yml`
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- Existing manifests, Dockerfiles, dependent fixtures, sample fixtures, and usage scripts for `libarchive`, `libbz2`, `liblzma`, and `libzstd`.

**New Outputs:**

- 8 new usage testcase manifest entries.
- 8 new executable usage scripts.
- Updated `python-libarchive-c` common helper.

**File Changes:**

- Modify `tests/libarchive/testcases.yml`.
- Modify `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-common.sh`.
- Add `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-zip-roundtrip.sh`.
- Add `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-nested-paths.sh`.
- Modify `tests/libbz2/testcases.yml`.
- Add `tests/libbz2/tests/cases/usage/usage-bzip2-decompress-keep-input.sh`.
- Add `tests/libbz2/tests/cases/usage/usage-bzip2-force-overwrite.sh`.
- Modify `tests/liblzma/testcases.yml`.
- Add `tests/liblzma/tests/cases/usage/usage-libarchive-tools-xz-metadata-list.sh`.
- Add `tests/liblzma/tests/cases/usage/usage-libarchive-tools-xz-preserve-permissions.sh`.
- Modify `tests/libzstd/testcases.yml`.
- Add `tests/libzstd/tests/cases/usage/usage-libarchive-tools-zstd-metadata-list.sh`.
- Add `tests/libzstd/tests/cases/usage/usage-libarchive-tools-zstd-preserve-permissions.sh`.

**Implementation Details:**

- Apply the global testcase entry contract to all 8 new manifest entries.
- Use only existing dependent client identifiers:
  - `libarchive`: `python3-libarchive-c`
  - `libbz2`: `bzip2`
  - `liblzma`: `libarchive-tools`
  - `libzstd`: `libarchive-tools`
- `libarchive`: extend `usage-python-libarchive-c-common.sh` with workloads:
  - `zip-roundtrip`: write a ZIP archive through `libarchive.file_writer(..., "zip")`, read it back through `libarchive.file_reader`, and assert file names and contents.
  - `nested-paths`: write entries such as `dir/sub.txt` and `dir/space name.txt`, read them back, and assert path names and byte contents.
- `libbz2`:
  - `usage-bzip2-decompress-keep-input.sh`: write a payload through `bzip2 -c` to `payload.bz2`, run `bunzip2 -k "$tmpdir/payload.bz2"`, assert both `payload.bz2` and decompressed `payload` still exist, and compare content.
  - `usage-bzip2-force-overwrite.sh`: create one compressed output, replace the source content, run `bzip2 -kf` to overwrite the existing `.bz2`, then decompress and assert the new content is present.
- `liblzma`:
  - `usage-libarchive-tools-xz-metadata-list.sh`: create an executable file, archive with `bsdtar -cJf`, run `bsdtar -tvf`, and assert the listed path and executable mode marker.
  - `usage-libarchive-tools-xz-preserve-permissions.sh`: archive and extract an executable file through `bsdtar -cJf`/`bsdtar -xf`, then assert `test -x`.
- `libzstd`:
  - Mirror the `liblzma` metadata and permission tests, using `bsdtar --zstd -cf` for creation and normal `bsdtar -tf`/`-xf` for reading.
- Make all new scripts executable.
- The implementer must commit the phase 2 changes to git before yielding.

**Verification:**

- Run the two check phases above.
- Confirm selected proof totals for phase 2 are 20 source, 40 usage, and 60 total.
- Review new archive/compression logs for deterministic output and no host absolute paths.

### 3. Media, Image, and Metadata Dependent Usage Cases

**Phase Name:** Media, Image, and Metadata Dependent Usage Cases

**Implement Phase ID:** `impl_phase_03_media_image_usage_cases`

**Verification Phases:**

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

**Preexisting Inputs:**

- Phase 2 committed changes.
- `repositories.yml`
- `test.sh`
- `tools/testcases.py`
- Existing manifests, Dockerfiles, dependent fixtures, sample fixtures, and usage scripts for `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libtiff`, `libvips`, and `libwebp`.

**New Outputs:**

- 14 new usage testcase manifest entries.
- 14 new executable usage scripts.
- Updated `exif` common helper.

**File Changes:**

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

**Implementation Details:**

- Apply the global testcase entry contract to all 14 new manifest entries.
- Use only existing dependent client identifiers:
  - `giflib`: `giflib-tools`
  - `libexif`: `exif`
  - `libjpeg-turbo`: `python3-pil` and `vips`
  - `libpng`: `pngquant` and `netpbm`
  - `libtiff`: `python3-pil`
  - `libvips`: `ruby-vips`
  - `libwebp`: `python3-pil` and `ffmpeg`
- `giflib`:
  - `usage-giflib-tools-gif2rgb-fire-fixture.sh`: read `"$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"`, run `gif2rgb -1 -o`, compare output bytes to `"$VALIDATOR_SAMPLE_ROOT/tests/fire.rgb"` with `cmp`.
  - `usage-giflib-tools-giftext-interlaced-fixture.sh`: read `treescap-interlaced.gif`, run `giftext`, assert `Screen Size`, and require a case-insensitive `interlace` match in the output.
- `libexif`: extend `usage-exif-cli-common.sh` with workloads:
  - `tag-datetime`: run `exif --tag=DateTime`, assert `2009:10:10 16:42:32`.
  - `tag-datetime-original`: run `exif --tag=DateTimeOriginal`, assert `2009:10:10 16:42:32`.
- `libjpeg-turbo`:
  - `usage-python3-pil-progressive-jpeg.sh`: generate a small PPM, encode with `cjpeg -progressive`, open with Pillow, call `load()`, assert size and mode, and assert `im.info.get("progressive") == 1` or `im.info.get("progression") == 1`.
  - `usage-vips-extract-band-jpeg.sh`: generate a JPEG with `cjpeg`, run `vips extract_band "$jpg" "$tmpdir/band.pgm" 0`, and assert the output file exists and `vipsheader "$tmpdir/band.pgm"` reports a one-band image.
- `libpng`:
  - `usage-pngquant-posterize-png.sh`: run `pngquant --posterize 4 --force --output "$tmpdir/out.png"` against an existing PNGSuite fixture and assert `file` reports PNG.
  - `usage-netpbm-pamflip-png.sh`: run `pngtopam` on a PNGSuite fixture, rotate with `pamflip -r90`, write PNG with `pnmtopng`, assert `file` reports PNG, and assert the rotated dimensions with `pngtopam "$tmpdir/out.png" | pamfile -`.
- `libtiff`:
  - `usage-python3-pil-deflate-tiff.sh`: create a deterministic RGB image with Pillow, save as TIFF using `compression="tiff_adobe_deflate"`, reopen, and assert exact mode and size.
  - `usage-python3-pil-tiff-dpi-save.sh`: create a deterministic RGB image, save a TIFF with `dpi=(300, 300)`, reopen, and assert TIFF XResolution and YResolution tags decode to 300.
- `libvips`:
  - `usage-ruby-vips-gaussblur-image.sh`: create an 8x8 image through ruby-vips, apply `gaussblur(1.2)`, assert width and height remain 8, and assert the blurred image average is greater than 0 and less than 255.
  - `usage-ruby-vips-histogram-image.sh`: create a small uchar image, run `hist_find`, and assert the histogram width is 256 and its maximum value is greater than 0.
- `libwebp`:
  - `usage-python3-pil-webp-alpha.sh`: use Pillow to save an RGBA WebP, reopen it, and assert alpha channel preservation.
  - `usage-ffmpeg-webp-scale-filter.sh`: generate a WebP with `cwebp` from a deterministic PPM fixture, run `ffmpeg -hide_banner -loglevel error -i "$webp" -vf scale=2:2 "$tmpdir/out.png"`, assert `file` reports PNG, and assert `ffprobe` reports dimensions `2,2`.
- Make all new scripts executable.
- The implementer must commit the phase 3 changes to git before yielding.

**Verification:**

- Run the two check phases above.
- Confirm selected proof totals for phase 3 are 35 source, 71 usage, and 106 total.
- Review image scripts for deterministic generated fixtures and no reliance on network or display hardware.

### 4. Runtime, GUI, and Crypto Dependent Usage Cases

**Phase Name:** Runtime, GUI, and Crypto Dependent Usage Cases

**Implement Phase ID:** `impl_phase_04_runtime_crypto_usage_cases`

**Verification Phases:**

- Phase ID: `check_phase_04_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_runtime_crypto_usage_cases`
- Purpose: validate all testcase additions and final cumulative counts before threshold/doc/artifact updates.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 193 \
  --min-cases 288

python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --list-summary
```

- Phase ID: `check_phase_04_matrix_smoke`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_runtime_crypto_usage_cases`
- Purpose: run the affected GUI/runtime/crypto libraries with casts and verify selected proof output.
- Commands:

```bash
rm -rf /tmp/validator-more-cases-phase04
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase04 \
  --record-casts \
  --library libsdl \
  --library libsodium

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase04 \
  --proof-output /tmp/validator-more-cases-phase04/proof/original-validation-proof.json \
  --library libsdl \
  --library libsodium \
  --min-source-cases 10 \
  --min-usage-cases 21 \
  --min-cases 31 \
  --require-casts
```

**Preexisting Inputs:**

- Phase 3 committed changes.
- `repositories.yml`
- `test.sh`
- `tools/testcases.py`
- Existing manifests, Dockerfiles, dependent fixtures, sample fixtures, and usage scripts for `libsdl` and `libsodium`.

**New Outputs:**

- 4 new usage testcase manifest entries.
- 4 new executable usage scripts.

**File Changes:**

- Modify `tests/libsdl/testcases.yml`.
- Add `tests/libsdl/tests/cases/usage/usage-python3-pygame-key-event.sh`.
- Add `tests/libsdl/tests/cases/usage/usage-python3-pygame-mask-collision.sh`.
- Modify `tests/libsodium/testcases.yml`.
- Add `tests/libsodium/tests/cases/usage/usage-python3-nacl-public-box.sh`.
- Add `tests/libsodium/tests/cases/usage/usage-php83-sodium-sign-detached.sh`.

**Implementation Details:**

- Apply the global testcase entry contract to all 4 new manifest entries.
- Use only existing dependent client identifiers:
  - `libsdl`: `python3-pygame`
  - `libsodium`: `python3-nacl` and `php8.3-cli`
- `libsdl`:
  - `usage-python3-pygame-key-event.sh`: export `PYGAME_HIDE_SUPPORT_PROMPT=1` and `SDL_VIDEODRIVER=dummy` before Python starts, initialize pygame, post a `KEYDOWN` event for `pygame.K_a`, pump the event queue, and assert that exact key event is received.
  - `usage-python3-pygame-mask-collision.sh`: export `PYGAME_HIDE_SUPPORT_PROMPT=1` and `SDL_VIDEODRIVER=dummy`, create two `pygame.Surface((10, 10), pygame.SRCALPHA)` objects, fill them transparent, draw opaque overlapping rectangles, build masks with `pygame.mask.from_surface`, call `overlap` with a fixed offset, and assert the returned collision coordinate is the expected tuple.
- `libsodium`:
  - `usage-python3-nacl-public-box.sh`: use PyNaCl `PrivateKey.generate()`, derive two public keys, encrypt with `Box`, decrypt, and assert plaintext round trip.
  - `usage-php83-sodium-sign-detached.sh`: run PHP CLI using `sodium_crypto_sign_keypair`, `sodium_crypto_sign_detached`, and `sodium_crypto_sign_verify_detached`, then assert verification returns true.
- Make all new scripts executable.
- The implementer must commit the phase 4 changes to git before yielding.

**Verification:**

- Run the two check phases above.
- The list summary must show final target totals: 95 source, 193 usage, 288 total.
- Review scripts for headless execution only; do not require a real display, audio device, entropy service beyond normal container support, or network.

### 5. Thresholds, Artifacts, Proof, and Site

**Phase Name:** Thresholds, Artifacts, Proof, and Site

**Implement Phase ID:** `impl_phase_05_thresholds_artifacts_site`

**Verification Phases:**

- Phase ID: `check_phase_05_unit_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_05_thresholds_artifacts_site`
- Purpose: verify tooling unit tests, final manifest thresholds, and documented counts.
- Commands:

```bash
make unit
make check-testcases
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --list-summary
```

- Phase ID: `check_phase_05_full_matrix_proof_site`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_05_thresholds_artifacts_site`
- Purpose: update and verify the full tracked original-package evidence set, proof manifest, and rendered site in place.
- Commands:

```bash
RECORD_CASTS=1 make matrix

REQUIRE_CASTS=1 \
MIN_SOURCE_CASES=95 \
MIN_USAGE_CASES=193 \
MIN_CASES=288 \
make proof

make site
make verify-site
```

**Preexisting Inputs:**

- Phase 4 committed changes.
- Existing tracked `artifacts/results`, `artifacts/logs`, `artifacts/casts`, `artifacts/proof/original-validation-proof.json`.
- Existing tracked `site/` rendered output and evidence copies.
- `Makefile`
- `README.md`
- `tools/verify_proof_artifacts.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`

**New Outputs:**

- Updated `Makefile` thresholds.
- Updated `README.md` proof/check examples and count text.
- Updated in-place matrix artifacts for all 288 cases:
  - `artifacts/results/<library>/<testcase-id>.json`
  - `artifacts/logs/<library>/<testcase-id>.log`
  - `artifacts/casts/<library>/<testcase-id>.cast`
  - `artifacts/results/<library>/summary.json`
- Updated `artifacts/proof/original-validation-proof.json` with 95 source, 193 usage, and 288 total cases.
- Updated `site/site-data.json`, `site/index.html`, `site/library/*.html`, `site/evidence/logs/**`, and `site/evidence/casts/**`.

**File Changes:**

- Modify `Makefile`.
- Modify `README.md`.
- Update generated artifacts under `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, and `artifacts/proof/original-validation-proof.json` by running the existing tools.
- Update generated site output under `site/` by running the existing tools.

**Implementation Details:**

- Raise the `Makefile` `check-testcases` command to `--min-source-cases 95 --min-usage-cases 193 --min-cases 288`.
- Update `README.md:80-113` examples so proof and smoke documentation uses the final full thresholds where appropriate:
  - Full proof example: `--min-source-cases 95 --min-usage-cases 193 --min-cases 288`.
  - Make proof example: `MIN_SOURCE_CASES=95 MIN_USAGE_CASES=193 MIN_CASES=288`.
- If README keeps the default `make matrix-smoke` example for `SMOKE_LIBRARIES ?= cjson libarchive libuv libwebp`, update that selected-library proof example to `MIN_SOURCE_CASES=20 MIN_USAGE_CASES=41 MIN_CASES=61`.
- If README documents a different selected-library smoke set, compute its thresholds from the final manifests and write those exact selected-library values in the example.
- Run the full matrix with casts to update the existing tracked artifact tree in place. Do not delete or refetch dependent inventories.
- Regenerate proof and site through the existing tools only; do not manually edit generated JSON or HTML.
- Confirm proof totals and site totals match the new manifests exactly.
- The implementer must commit the phase 5 changes, including updated generated artifacts and site output, to git before yielding.

**Verification:**

- Run the two check phases above.
- `make check-testcases` must pass with the new final thresholds.
- `artifacts/proof/original-validation-proof.json` must report totals of 19 libraries, 288 cases, 95 source cases, 193 usage cases, and 288 casts when casts are required.
- `make verify-site` must pass against the tracked `site/` output.

## Critical Files

- `tests/cjson/testcases.yml`: add two `iperf3` usage entries.
- `tests/cjson/tests/cases/usage/usage-iperf3-json-common.sh`: add `zero-copy` and `omit-warmup` workloads.
- `tests/cjson/tests/cases/usage/usage-iperf3-json-zero-copy.sh`: new wrapper script.
- `tests/cjson/tests/cases/usage/usage-iperf3-json-omit-warmup.sh`: new wrapper script.
- `tests/libcsv/testcases.yml`: add two `readstat` usage entries.
- `tests/libcsv/tests/cases/usage/usage-readstat-common.sh`: add `escaped-quotes-csv` and `wide-csv` workloads.
- `tests/libcsv/tests/cases/usage/usage-readstat-escaped-quotes-csv.sh`: new wrapper script.
- `tests/libcsv/tests/cases/usage/usage-readstat-wide-csv.sh`: new wrapper script.
- `tests/libjson/testcases.yml`: add two `gdal` usage entries.
- `tests/libjson/tests/cases/usage/usage-gdal-json-common.sh`: add `ogr2ogr-where` and `ogr2ogr-reproject` workloads.
- `tests/libjson/tests/cases/usage/usage-gdal-ogr2ogr-where-geojson.sh`: new wrapper script.
- `tests/libjson/tests/cases/usage/usage-gdal-ogr2ogr-reproject-geojson.sh`: new wrapper script.
- `tests/libxml/testcases.yml`: add one `python3-lxml` and one `xmlstarlet` usage entry.
- `tests/libxml/tests/cases/usage/usage-python3-lxml-xinclude-xml.sh`: new usage script.
- `tests/libxml/tests/cases/usage/usage-xmlstarlet-transform-xml.sh`: new usage script.
- `tests/libyaml/testcases.yml`: add two `python3-yaml` usage entries.
- `tests/libyaml/tests/cases/usage/usage-python3-yaml-cbase-loader.sh`: new usage script.
- `tests/libyaml/tests/cases/usage/usage-python3-yaml-binary-scalar.sh`: new usage script.
- `tests/libuv/testcases.yml`: add two `nodejs` usage entries.
- `tests/libuv/tests/cases/usage/usage-nodejs-fs-watch.sh`: new usage script.
- `tests/libuv/tests/cases/usage/usage-nodejs-crypto-pbkdf2.sh`: new usage script.
- `tests/libarchive/testcases.yml`: add two `python3-libarchive-c` usage entries.
- `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-common.sh`: add `zip-roundtrip` and `nested-paths` workloads.
- `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-zip-roundtrip.sh`: new wrapper script.
- `tests/libarchive/tests/cases/usage/usage-python-libarchive-c-nested-paths.sh`: new wrapper script.
- `tests/libbz2/testcases.yml`: add two `bzip2` usage entries.
- `tests/libbz2/tests/cases/usage/usage-bzip2-decompress-keep-input.sh`: new usage script.
- `tests/libbz2/tests/cases/usage/usage-bzip2-force-overwrite.sh`: new usage script.
- `tests/liblzma/testcases.yml`: add two `libarchive-tools` usage entries.
- `tests/liblzma/tests/cases/usage/usage-libarchive-tools-xz-metadata-list.sh`: new usage script.
- `tests/liblzma/tests/cases/usage/usage-libarchive-tools-xz-preserve-permissions.sh`: new usage script.
- `tests/libzstd/testcases.yml`: add two `libarchive-tools` usage entries.
- `tests/libzstd/tests/cases/usage/usage-libarchive-tools-zstd-metadata-list.sh`: new usage script.
- `tests/libzstd/tests/cases/usage/usage-libarchive-tools-zstd-preserve-permissions.sh`: new usage script.
- `tests/giflib/testcases.yml`: add two `giflib-tools` usage entries.
- `tests/giflib/tests/cases/usage/usage-giflib-tools-gif2rgb-fire-fixture.sh`: new usage script.
- `tests/giflib/tests/cases/usage/usage-giflib-tools-giftext-interlaced-fixture.sh`: new usage script.
- `tests/libexif/testcases.yml`: add two `exif` usage entries.
- `tests/libexif/tests/cases/usage/usage-exif-cli-common.sh`: add `tag-datetime` and `tag-datetime-original` workloads.
- `tests/libexif/tests/cases/usage/usage-exif-cli-tag-datetime.sh`: new wrapper script.
- `tests/libexif/tests/cases/usage/usage-exif-cli-tag-datetime-original.sh`: new wrapper script.
- `tests/libjpeg-turbo/testcases.yml`: add one `python3-pil` and one `vips` usage entry.
- `tests/libjpeg-turbo/tests/cases/usage/usage-python3-pil-progressive-jpeg.sh`: new usage script.
- `tests/libjpeg-turbo/tests/cases/usage/usage-vips-extract-band-jpeg.sh`: new usage script.
- `tests/libpng/testcases.yml`: add one `pngquant` and one `netpbm` usage entry.
- `tests/libpng/tests/cases/usage/usage-pngquant-posterize-png.sh`: new usage script.
- `tests/libpng/tests/cases/usage/usage-netpbm-pamflip-png.sh`: new usage script.
- `tests/libtiff/testcases.yml`: add two `python3-pil` usage entries.
- `tests/libtiff/tests/cases/usage/usage-python3-pil-deflate-tiff.sh`: new usage script.
- `tests/libtiff/tests/cases/usage/usage-python3-pil-tiff-dpi-save.sh`: new usage script.
- `tests/libvips/testcases.yml`: add two `ruby-vips` usage entries.
- `tests/libvips/tests/cases/usage/usage-ruby-vips-gaussblur-image.sh`: new usage script.
- `tests/libvips/tests/cases/usage/usage-ruby-vips-histogram-image.sh`: new usage script.
- `tests/libwebp/testcases.yml`: add one `python3-pil` and one `ffmpeg` usage entry.
- `tests/libwebp/tests/cases/usage/usage-python3-pil-webp-alpha.sh`: new usage script.
- `tests/libwebp/tests/cases/usage/usage-ffmpeg-webp-scale-filter.sh`: new usage script.
- `tests/libsdl/testcases.yml`: add two `python3-pygame` usage entries.
- `tests/libsdl/tests/cases/usage/usage-python3-pygame-key-event.sh`: new usage script.
- `tests/libsdl/tests/cases/usage/usage-python3-pygame-mask-collision.sh`: new usage script.
- `tests/libsodium/testcases.yml`: add one `python3-nacl` and one `php8.3-cli` usage entry.
- `tests/libsodium/tests/cases/usage/usage-python3-nacl-public-box.sh`: new usage script.
- `tests/libsodium/tests/cases/usage/usage-php83-sodium-sign-detached.sh`: new usage script.
- `Makefile`: raise `check-testcases` thresholds to 95 source, 193 usage, 288 total.
- `README.md`: update full proof/check threshold examples and resulting count references.
- `artifacts/results/**`, `artifacts/logs/**`, `artifacts/casts/**`, `artifacts/proof/original-validation-proof.json`: update through `RECORD_CASTS=1 make matrix` and proof generation.
- `site/**`: update through `make site`.

Files intentionally not changed:

- `repositories.yml`: remains the fixed canonical v2 manifest and package list.
- `tests/<library>/tests/fixtures/dependents.json`: remains the existing compact dependent inventory unchanged; every planned `client_application` already exists in the relevant fixture.
- `tests/<library>/Dockerfile`: remains unchanged; every dependent package required by the planned clients is already installed today.

## Final Verification

After all phases complete, verify the full implementation with:

```bash
make unit
make check-testcases

python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --list-summary

RECORD_CASTS=1 make matrix

REQUIRE_CASTS=1 \
MIN_SOURCE_CASES=95 \
MIN_USAGE_CASES=193 \
MIN_CASES=288 \
make proof

make site
make verify-site
```

Expected final results:

- `make unit` passes.
- `make check-testcases` passes using the raised thresholds.
- The testcase summary reports 19 libraries, 95 source cases, 193 usage cases, and 288 total cases.
- Full matrix results pass with casts for all cases.
- `artifacts/proof/original-validation-proof.json` reports 288 cases, 95 source cases, 193 usage cases, 0 failed cases, and 288 casts.
- `make verify-site` confirms `site/` matches proof data and copied evidence.

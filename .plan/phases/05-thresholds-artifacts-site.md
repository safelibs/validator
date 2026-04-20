# 5. Thresholds, Artifacts, Proof, and Site

## Phase Name

Thresholds, Artifacts, Proof, and Site

## Implement Phase ID

`impl_phase_05_thresholds_artifacts_site`

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
- `tests/giflib/` concrete phase 3 output directory.
- `tests/libexif/` concrete phase 3 output directory.
- `tests/libjpeg-turbo/` concrete phase 3 output directory.
- `tests/libpng/` concrete phase 3 output directory.
- `tests/libtiff/` concrete phase 3 output directory.
- `tests/libvips/` concrete phase 3 output directory.
- `tests/libwebp/` concrete phase 3 output directory.
- `tests/libsdl/` concrete phase 4 output directory.
- `tests/libsodium/` concrete phase 4 output directory.
- Existing tracked `artifacts/results/`.
- Existing tracked `artifacts/logs/`.
- Existing tracked `artifacts/casts/`.
- Existing tracked `artifacts/proof/original-validation-proof.json`.
- Existing tracked `site/` rendered output and evidence copies.
- `Makefile`
- `README.md`
- `repositories.yml`
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- Existing `tests/` manifests, Dockerfiles, dependent fixtures, sample fixtures, and usage scripts after phases 1 through 4. Consume dependent inventories in place; do not refetch, recollect, rediscover, regenerate, expand, or reorder them.

## New Outputs

- Updated `Makefile` thresholds.
- Updated `README.md` proof/check examples and count text.
- Updated in-place matrix artifacts for all 288 cases:
  - `artifacts/results/<library>/<testcase-id>.json`
  - `artifacts/logs/<library>/<testcase-id>.log`
  - `artifacts/casts/<library>/<testcase-id>.cast`
  - `artifacts/results/<library>/summary.json`
- Updated `artifacts/proof/original-validation-proof.json` with 95 source, 193 usage, and 288 total cases.
- Updated `site/site-data.json`, `site/index.html`, `site/library/*.html`, `site/evidence/logs/**`, and `site/evidence/casts/**`.

## File Changes

- Modify `Makefile`.
- Modify `README.md`.
- Update generated artifacts under `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, and `artifacts/proof/original-validation-proof.json` by running the existing tools.
- Update generated site output under `site/` by running the existing tools.

## Implementation Details

- Raise the `Makefile` `check-testcases` command to `--min-source-cases 95 --min-usage-cases 193 --min-cases 288`.
- Update `README.md:80-113` examples so proof and smoke documentation uses the final full thresholds where appropriate:
  - Full proof example: `--min-source-cases 95 --min-usage-cases 193 --min-cases 288`.
  - Make proof example: `MIN_SOURCE_CASES=95 MIN_USAGE_CASES=193 MIN_CASES=288`.
- If README keeps the default `make matrix-smoke` example for `SMOKE_LIBRARIES ?= cjson libarchive libuv libwebp`, update that selected-library proof example to `MIN_SOURCE_CASES=20 MIN_USAGE_CASES=41 MIN_CASES=61`.
- If README documents a different selected-library smoke set, compute its thresholds from the final manifests and write those exact selected-library values in the example.
- Run the full matrix with casts to update the existing tracked artifact tree in place. Do not delete or refetch dependent inventories.
- Regenerate proof and site through the existing tools only; do not manually edit generated JSON or HTML.
- Confirm proof totals and site totals match the new manifests exactly.
- Do not modify `repositories.yml`; it remains the fixed canonical manifest and package list.
- Do not modify any `tests/<library>/Dockerfile`; every dependent package required by the final client set is already installed.

## Verification Phases

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

## Success Criteria

- `make unit` passes.
- `make check-testcases` passes with the raised final thresholds.
- The testcase summary reports 19 libraries, 95 source cases, 193 usage cases, and 288 total cases.
- Full matrix results pass with casts for all 288 cases.
- `artifacts/proof/original-validation-proof.json` reports totals of 19 libraries, 288 cases, 95 source cases, 193 usage cases, 0 failed cases, and 288 casts when casts are required.
- `make verify-site` passes against the tracked `site/` output.
- Generated artifacts and site output are produced through the existing tools only.
- `repositories.yml`, library Dockerfiles, and dependent fixture inventories remain intentionally unchanged.

## Git Commit Requirement

The implementer must commit all phase 5 scoped work, including updated generated artifacts and site output, to git before yielding. Do not yield with uncommitted phase 5 file changes.

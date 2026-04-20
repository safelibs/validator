# 2. Archive and Compression Dependent Usage Cases

## Phase Name

Archive and Compression Dependent Usage Cases

## Implement Phase ID

`impl_phase_02_archive_compression_usage_cases`

## Preexisting Inputs

- `tests/cjson/` concrete phase 1 output directory.
- `tests/libcsv/` concrete phase 1 output directory.
- `tests/libjson/` concrete phase 1 output directory.
- `tests/libxml/` concrete phase 1 output directory.
- `tests/libyaml/` concrete phase 1 output directory.
- `tests/libuv/` concrete phase 1 output directory.
- `repositories.yml` canonical manifest and package list; consume it unchanged.
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/run_library_tests.sh`
- Existing `tests/libarchive/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libbz2/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/liblzma/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libzstd/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing tracked `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, `artifacts/proof/original-validation-proof.json`, and `site/` evidence. Consume these artifacts in place; do not refetch, recollect, rediscover, regenerate, expand, or reorder dependent inventories.

## New Outputs

- 8 new usage testcase manifest entries.
- 8 new executable usage scripts.
- Updated `python-libarchive-c` common helper.

## File Changes

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

## Implementation Details

- Apply the global testcase entry contract to all 8 new manifest entries:
  - Use the new script filename without `.sh` as each manifest entry `id`.
  - Set `kind: usage`.
  - Set `timeout_seconds: 180`.
  - Use a semantic `title`.
  - Use a client-behavior `description`.
  - Set `client_application` to one of the existing identifiers named below.
  - Set `command` exactly to `bash /validator/tests/<library>/tests/cases/usage/<script>.sh`.
  - Tags must include `usage` and one or more behavior tags already consistent with the library's local manifest style, such as `compression`, `metadata`, or `archive`.
- Wrapper scripts that call a library-local common helper must contain `#!/usr/bin/env bash`, `set -euo pipefail`, and then execute the common helper with the exact workload argument named here.
- Do not modify `repositories.yml`; it remains the fixed canonical manifest and package list.
- Do not modify any affected `tests/<library>/Dockerfile`; every dependent package required by the planned clients is already installed.
- Use only these existing dependent client identifiers:
  - `libarchive`: `python3-libarchive-c`
  - `libbz2`: `bzip2`
  - `liblzma`: `libarchive-tools`
  - `libzstd`: `libarchive-tools`
- Do not modify any `tests/<library>/tests/fixtures/dependents.json`.
- `libarchive`: extend `usage-python-libarchive-c-common.sh` with these workloads:
  - `zip-roundtrip`: write a ZIP archive through `libarchive.file_writer(..., "zip")`, read it back through `libarchive.file_reader`, and assert file names and contents.
  - `nested-paths`: write entries such as `dir/sub.txt` and `dir/space name.txt`, read them back, and assert path names and byte contents.
- `libbz2`:
  - `usage-bzip2-decompress-keep-input.sh`: write a payload through `bzip2 -c` to `payload.bz2`, run `bunzip2 -k "$tmpdir/payload.bz2"`, assert both `payload.bz2` and decompressed `payload` still exist, and compare content.
  - `usage-bzip2-force-overwrite.sh`: create one compressed output, replace the source content, run `bzip2 -kf` to overwrite the existing `.bz2`, then decompress and assert the new content is present.
- `liblzma`:
  - `usage-libarchive-tools-xz-metadata-list.sh`: create an executable file, archive with `bsdtar -cJf`, run `bsdtar -tvf`, and assert the listed path and executable mode marker.
  - `usage-libarchive-tools-xz-preserve-permissions.sh`: archive and extract an executable file through `bsdtar -cJf` and `bsdtar -xf`, then assert `test -x`.
- `libzstd`:
  - `usage-libarchive-tools-zstd-metadata-list.sh`: mirror the `liblzma` metadata listing test, using `bsdtar --zstd -cf` for creation and normal `bsdtar -tf` or `bsdtar -tvf` for reading.
  - `usage-libarchive-tools-zstd-preserve-permissions.sh`: mirror the `liblzma` permission preservation test, using `bsdtar --zstd -cf` for creation and normal `bsdtar -xf` for extraction.
- Make all new scripts executable.

## Verification Phases

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

## Success Criteria

- Phase 2 adds exactly 8 usage cases across `libarchive`, `libbz2`, `liblzma`, and `libzstd` while leaving source cases unchanged.
- Manifest validation reports at least 95 source cases, 175 usage cases, and 270 total cases.
- The phase 2 matrix smoke passes with casts and selected proof totals of 20 source cases, 40 usage cases, and 60 total cases.
- New archive/compression logs have deterministic output and no host absolute paths.
- Temporary verifier output under `/tmp/validator-more-cases-phase02` is not committed.
- `repositories.yml`, affected library Dockerfiles, dependent fixtures, prepared inventories, current tracked artifacts, proof data, and rendered site evidence are preserved unchanged unless explicitly updated by existing tools.

## Git Commit Requirement

The implementer must commit all phase 2 scoped work to git before yielding. Do not yield with uncommitted phase 2 file changes.

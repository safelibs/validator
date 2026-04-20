# 1. Data, Parser, and Event-Loop Dependent Usage Cases

## Phase Name

Data, Parser, and Event-Loop Dependent Usage Cases

## Implement Phase ID

`impl_phase_01_data_parser_usage_cases`

## Preexisting Inputs

- `.plan/goal.md`
- `.plan/plan.md`
- `repositories.yml` canonical manifest and package list; consume it unchanged.
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/runtime_helpers.sh`
- `tests/_shared/run_library_tests.sh`
- Existing `tests/cjson/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libcsv/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libjson/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libxml/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libyaml/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libuv/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing sample fixtures under each affected `tests/<library>/tests/fixtures/` directory.
- Existing tracked `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, `artifacts/proof/original-validation-proof.json`, and `site/` evidence. Consume these artifacts in place; do not refetch, recollect, rediscover, regenerate, expand, or reorder dependent inventories.

## New Outputs

- 12 new usage testcase manifest entries.
- 12 new executable usage scripts.
- Updated library-local common usage helpers for `cjson`, `libcsv`, and `libjson`.

## File Changes

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

## Implementation Details

- Apply the global testcase entry contract to all 12 new manifest entries:
  - Use the new script filename without `.sh` as each manifest entry `id`.
  - Set `kind: usage`.
  - Set `timeout_seconds: 180`.
  - Use a semantic `title`.
  - Use a client-behavior `description`.
  - Set `client_application` to one of the existing identifiers named below.
  - Set `command` exactly to `bash /validator/tests/<library>/tests/cases/usage/<script>.sh`.
  - Tags must include `usage` and one or more behavior tags already consistent with the library's local manifest style, such as `json`, `compression`, `metadata`, `image`, `runtime`, or `crypto`.
- Wrapper scripts that call a library-local common helper must contain `#!/usr/bin/env bash`, `set -euo pipefail`, and then execute the common helper with the exact workload argument named here.
- Do not modify `repositories.yml`; it remains the fixed canonical manifest and package list.
- Do not modify any affected `tests/<library>/Dockerfile`; every dependent package required by the planned clients is already installed.
- Use only these existing `client_application` values:
  - `cjson`: `iperf3`
  - `libcsv`: `readstat`
  - `libjson`: `gdal`
  - `libxml`: `python3-lxml` and `xmlstarlet`
  - `libyaml`: `python3-yaml`
  - `libuv`: `nodejs`
- Do not modify any `tests/<library>/tests/fixtures/dependents.json`.
- `cjson`: extend `usage-iperf3-json-common.sh` with these workloads:
  - `zero-copy`: start the existing one-shot loopback server, run `iperf3 -c 127.0.0.1 -p "$port" -J -Z -n 32K`, and assert with `jq -e` that `.end.sum_sent.bytes > 0` and `.end.sum_sent.bits_per_second > 0`.
  - `omit-warmup`: run `iperf3 -c 127.0.0.1 -p "$port" -J -O 1 -t 2 -i 1`, and assert with `jq -e` that `.intervals` is non-empty, at least one interval is marked omitted through `.sum.omitted` or `.streams[].omitted`, and `.end` is an object.
- `libcsv`: extend `usage-readstat-common.sh` with these workloads:
  - `escaped-quotes-csv`: create CSV containing an escaped double quote field such as `"alpha ""quoted"""`, convert through readstat metadata into DTA, read back to CSV with `readstat "$tmpdir/out.dta" -`, and assert the escaped quote text survives in the exported CSV.
  - `wide-csv`: create a four-column CSV and matching four-variable metadata, convert to DTA, run `readstat "$tmpdir/out.dta"` for summary and assert `Columns: 4`, then export with `readstat "$tmpdir/out.dta" -` and assert a row value from the fourth column.
- `libjson`: extend `usage-gdal-json-common.sh` with these workloads:
  - `ogr2ogr-where`: use the existing generated GeoJSON fixture, run `ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$geojson" -where 'value=2'`, assert `beta` is present, and assert `alpha` is absent.
  - `ogr2ogr-reproject`: run `ogr2ogr -f GeoJSON "$tmpdir/reprojected.geojson" "$geojson" -s_srs EPSG:4326 -t_srs EPSG:3857`, then use `jq` to assert a FeatureCollection exists and coordinates were written.
- `libxml`:
  - `usage-python3-lxml-xinclude-xml.sh`: create `main.xml` with an `xi:include` element and create `fragment.xml`, parse `main.xml` with `lxml.etree`, call `tree.xinclude()`, and assert the included element text is visible.
  - `usage-xmlstarlet-transform-xml.sh`: create XML and XSLT fixtures, run `xmlstarlet tr`, and assert the transformed output contains the expected value.
- `libyaml`:
  - `usage-python3-yaml-cbase-loader.sh`: in Python, assert `yaml.__with_libyaml__` is true, load nested YAML through `yaml.CBaseLoader`, assert scalar values are loaded as strings as expected for `BaseLoader`, and print a parsed value.
  - `usage-python3-yaml-binary-scalar.sh`: load a `!!binary` scalar through `yaml.safe_load`, assert the decoded bytes, and print the decoded length.
- `libuv`:
  - `usage-nodejs-fs-watch.sh`: create a temporary file, run a Node script using `fs.watch`, mutate the file, and assert a `change` event arrives before timeout.
  - `usage-nodejs-crypto-pbkdf2.sh`: run Node's asynchronous `crypto.pbkdf2`, which uses libuv threadpool work, and assert the derived key length and callback completion.
- Make all new scripts executable.

## Verification Phases

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

## Success Criteria

- Phase 1 adds exactly 12 usage cases across `cjson`, `libcsv`, `libjson`, `libxml`, `libyaml`, and `libuv` while leaving source cases unchanged.
- Manifest validation reports at least 95 source cases, 167 usage cases, and 262 total cases.
- The phase 1 matrix smoke passes with casts and selected proof totals of at least 30 source cases, 61 usage cases, and 91 total cases.
- `/tmp/validator-more-cases-phase01/proof/original-validation-proof.json` is used only as a temporary verifier artifact and is not committed.
- `repositories.yml`, affected library Dockerfiles, dependent fixtures, prepared inventories, current tracked artifacts, proof data, and rendered site evidence are preserved unchanged unless explicitly updated by existing tools.

## Git Commit Requirement

The implementer must commit all phase 1 scoped work to git before yielding. Do not yield with uncommitted phase 1 file changes.

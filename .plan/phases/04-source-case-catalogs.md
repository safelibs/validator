# 4. Source-Based Testcase Catalogs

## Phase Name

Source-Based Testcase Catalogs

## Implement Phase ID

`impl_phase_04_source_case_catalogs`

## Preexisting Inputs

- `.plan/goal.md`
- `repositories.yml` v2
- `tests/<library>/testcases.yml` skeletons
- `tools/testcases.py`
- `test.sh`
- `tools/verify_proof_artifacts.py`
- Existing `tests/<library>/tests/tagged-port/original/**` source snapshots.
- Existing `tests/<library>/tests/tagged-port/safe/**` as migration source only where it already contains useful test logic that can be made original-only and renamed.
- Existing `tests/<library>/tests/fixtures/relevant_cves.json` as migration diagnostics only. Do not reference these files from final testcase manifests, proof, site data, or `repositories.yml`. Copy useful binary or text fixture descriptions into new non-CVE fixture files with no safe/unsafe/excluded vocabulary, then delete the original `relevant_cves.json` before final acceptance.
- Existing library `tests/run.sh` scripts, many of which already compile or run original-package checks but currently reference safe paths.

## New Outputs

- `tests/<library>/testcases.yml` source entries for all 19 libraries.
- `tests/<library>/tests/cases/source/*.sh` executable scripts.
- Neutral fixture files under `tests/<library>/tests/fixtures/` as needed by source cases.

## File Changes

For each library:

- Add or modify `tests/<library>/testcases.yml`.
- Add scripts under `tests/<library>/tests/cases/source/`.
- Modify `tests/<library>/tests/run.sh` only as dispatcher glue.
- Keep or move useful source fixtures from `tests/<library>/tests/tagged-port/original/**`.
- For current scripts that reference `tests/tagged-port/safe/**`, copy only the needed test logic into a neutral source testcase script and update names/descriptions to remove safe-language.

## Implementation Details

### Phase Scope Notes

This phase owns source testcase metadata and executable source-case scripts. Consume existing `tests/<library>/tests/tagged-port/original/**`, `tests/<library>/tests/tagged-port/safe/**` migration material, `tests/<library>/tests/fixtures/relevant_cves.json`, and `tests/<library>/tests/harness-source/original-test-script.sh` only as existing inputs; copy useful neutral logic into `tests/<library>/tests/cases/source/` rather than regenerating snapshots or rediscovering source material.

Minimum source testcase targets by library. Each library must have at least 5 source cases so the repository reaches the 95-case source floor without depending on usage cases:

- `cjson`: parse/print round trip, minify behavior, cJSON_Utils patch/pointer behavior, allocator hook edge behavior, malformed-number rejection.
- `giflib`: `giftext` metadata inspection, `gif2rgb` conversion, `gifbuild` or `gifsponge` round trip, interlaced or transparency fixture handling, malformed GIF rejection with nonzero status.
- `libarchive`: `bsdtar` create/extract for tar and zip, `bsdcpio` copy-in/copy-out, metadata/listing behavior, path traversal rejection, API compile smoke using `archive_read_*`.
- `libbz2`: CLI compress/decompress, stream concatenation, C API compile/link round trip, corrupted stream rejection, Debian autopkgtest parity where suitable.
- `libcsv`: parser callback behavior, strict quote/error behavior, example tool compile/run, large-field handling, empty-field and custom-delimiter behavior.
- `libexif`: parse representative JPEG EXIF data through the C API, maker-note data handling, tag lookup and value-formatting behavior, C API compile/link smoke, invalid data handling. The `exif` CLI package is a dependent client from the `dependents.json` inventory and must be modeled only as a usage case with `client_application: exif`.
- `libjpeg-turbo`: `cjpeg`/`djpeg` round trip, `jpegtran` transform, TurboJPEG API compile smoke, progressive JPEG or color-space conversion, malformed input handling.
- `libjson`: json-c tokener parse, serializer round trip, refcount/object mutation behavior, CLI or small C compile smoke, malformed JSON handling.
- `liblzma`: `xz` compress/decompress, integrity check, streaming C API compile smoke, multi-stream behavior, corrupted stream rejection.
- `libpng`: `pngfix` or `pngcp` fixture handling, libpng read/write C API smoke, metadata/chunk inspection, palette or transparency handling, malformed PNG rejection.
- `libsdl`: version/query compile smoke, headless event/timer/platform tests, surface pixel format or blit behavior, dummy audio queue behavior, selected installed SDL test binaries under dummy video/audio drivers.
- `libsodium`: hash, secretbox, sign/verify, key exchange/randombytes, C compile/link smoke.
- `libtiff`: `tiffinfo`, `tiffcp`, `tiffdump`, C API read/write smoke, malformed TIFF rejection.
- `libuv`: event loop timer, fs read/write, TCP loopback smoke, DNS/getaddrinfo smoke, process or pipe API smoke.
- `libvips`: `vips` CLI load/save, thumbnail behavior, C API compile smoke, GObject-introspection smoke through the canonical `gir1.2-vips-8.0` package, metadata/header checks. Python `pyvips` is a dependent wrapper and must be modeled only as a usage case with `client_application: pyvips` when that identifier exists in the dependent fixture.
- `libwebp`: `cwebp`/`dwebp`, `webpinfo`, `webpmux`, C API decode smoke, malformed WebP rejection.
- `libxml`: `xmllint`, `xmlcatalog`, Python `libxml2` binding smoke, SAX/reader behavior, schema and XInclude checks. `xsltproc` is not in the canonical `libxml` `apt_packages` list and must be modeled only as a usage case with a matching dependent-client identifier if it is included at all.
- `libyaml`: parser/emitter round trip, loader/dumper cases, anchor and alias handling, C API compile smoke, invalid YAML rejection.
- `libzstd`: `zstd` compress/decompress, dictionary train/use, streaming C API compile smoke, long-distance or multi-frame behavior, corrupted frame rejection.

Script standards:

- `set -euo pipefail`.
- Source `tests/_shared/runtime_helpers.sh`.
- Use `mktemp -d` with cleanup trap.
- Use only apt-installed original packages and checked-in fixtures.
- Do not assert a package version is SafeLibs or non-SafeLibs.
- Print enough command output for the cast to be useful.
- Avoid network access inside testcase scripts.

## Verification Phases

`check_phase_04_source_catalog_unit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_source_case_catalogs`
- Purpose: validate every source testcase manifest entry, executable script, description, and artifact path.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95
python3 - <<'PY'
from pathlib import Path
import yaml

manifest = yaml.safe_load(Path("repositories.yml").read_text())
for entry in manifest["libraries"]:
    cases = yaml.safe_load(Path(entry["testcases"]).read_text())["testcases"]
    source_cases = [case for case in cases if case["kind"] == "source"]
    assert len(source_cases) >= 5, f"{entry['name']} needs at least 5 source cases"
    for case in source_cases:
        assert len(case["description"].split()) >= 8, case["id"]
PY
```

`check_phase_04_source_matrix_smoke`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_source_case_catalogs`
- Purpose: run representative source testcases that exercise C APIs, CLI tools, Python bindings, and media/data fixtures.
- Commands:

```bash
rm -rf /tmp/validator-phase04-artifacts
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase04-artifacts \
  --record-casts \
  --library cjson \
  --library libbz2 \
  --library libexif \
  --library libjpeg-turbo \
  --library libxml \
  --library libzstd
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase04-artifacts \
  --proof-output /tmp/validator-phase04-artifacts/proof/original-validation-proof.json \
  --library cjson \
  --library libbz2 \
  --library libexif \
  --library libjpeg-turbo \
  --library libxml \
  --library libzstd \
  --min-source-cases 30 \
  --require-casts
```

## Success Criteria

- Every library has at least five source testcases and the repository has at least 95 source cases.
- Source cases exercise only the canonical original package surface and use checked-in source snapshots or neutral fixtures.
- Source scripts are executable, deterministic, network-free, and avoid safe/unsafe/replacement terminology.
- Representative source matrix proof generation succeeds with casts.
- All explicit phase 4 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Catalog unit and source matrix smoke above.
  - Review:

  ```bash
  rg -n "safe|unsafe|replacement|safedebs|SAFE" tests/*/testcases.yml tests/*/tests/cases/source tests/*/tests/run.sh || true
  ```

  Any remaining match must be part of an upstream filename copied from an existing source snapshot and must not be user-facing testcase language.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_04_source_case_catalogs` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

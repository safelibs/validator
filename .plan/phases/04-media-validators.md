# Phase 04

**Phase Name**

`media-validators`

**Implement Phase ID**

`impl_04_media_validators`

**Preexisting Inputs**

- `.gitignore`
- `Makefile`
- `inventory/`
- `repositories.yml`
- `tools/`
- `unit/`
- `test.sh`
- `scripts/verify-site.sh`
- `tests/_shared/`
- `tests/cjson/`
- `tests/libcsv/`
- `tests/libjson/`
- `tests/libxml/`
- `tests/libyaml/`
- staged tag-backed inputs for `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libsdl`, `libtiff`, `libvips`, and `libwebp` as defined in `repositories.yml`

**New Outputs**

- `tests/giflib/**`
- `tests/libexif/**`
- `tests/libjpeg-turbo/**`
- `tests/libpng/**`
- `tests/libsdl/**`
- `tests/libtiff/**`
- `tests/libvips/**`
- `tests/libwebp/**`

**File Changes**

- Create validator-owned test trees for `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libsdl`, `libtiff`, `libvips`, and `libwebp`.
- Within each library tree, create `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`.
- Populate each library's fixtures, harness-source files, and mirrored tagged inputs only through `tools/import_port_assets.py`.

**Implementation Details**

- Treat the currently checked-in generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, as stale reference inputs during phases 01 through 05.
- Do not rewrite, rename, delete, or stage changes to those generated workflow artifacts in this phase; only phase 06 may replace the generated workflow file set.
- This phase covers:
  - `giflib`
  - `libexif`
  - `libjpeg-turbo`
  - `libpng`
  - `libsdl`
  - `libtiff`
  - `libvips`
  - `libwebp`
- Import fixtures and harness inputs only through `tools/import_port_assets.py`.
- Treat `libexif` as a mature tagged import from `refs/tags/libexif/04-test`, not as a bootstrap case.
- Preserve `libpng`'s checked-in-artifact path and `libvips`'s explicit docker build path from the manifest.
- Create validator-owned `tests/<library>/tests/run.sh` for every library in this batch and keep imported tag mirrors under `tests/<library>/tests/tagged-port/`.
- Make every `tests/<library>/docker-entrypoint.sh` in this batch invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`.
- Implement the exact fixed runtime contract for this batch:
  - `giflib`
    - exact `validator.imports`: `safe/tests`, `original/tests`, `original/pic`, `original/gif_lib.h`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that runs the copied upstream makefile suite under `tests/tagged-port/original/tests` against the copied corpora under `tests/tagged-port/original/pic`, plus the copied safe compatibility and malformed probes under `tests/tagged-port/safe/tests`.
  - `libexif`
    - exact `validator.imports`: `safe/tests`, `original/libexif`, `original/test`, `original/contrib/examples`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that executes the copied safe wrappers `tests/tagged-port/safe/tests/run-original-test-suite.sh`, `run-original-shell-test.sh`, `run-original-nls-test.sh`, `run-package-build.sh`, `run-c-test.sh`, `run-cve-regressions.sh`, `run-export-compare.sh`, and `run-test-mnote-matrix.sh` against copied sources under `tests/tagged-port/original/libexif`, `tests/tagged-port/original/test`, and `tests/tagged-port/original/contrib/examples` only.
  - `libjpeg-turbo`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/testimages`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that preserves its runtime and compile-time dependent checks, using copied samples under `tests/tagged-port/original/testimages`, copied package smokes under `tests/tagged-port/safe/debian/tests`, copied helper scripts under `tests/tagged-port/safe/scripts`, and copied regression drivers under `tests/tagged-port/safe/tests`.
  - `libpng`
    - exact `validator.imports`: `safe/tests`, `original/tests`, `original/contrib/pngsuite`, `original/contrib/testpngs`, `original/png.h`, `original/pngconf.h`, `original/pngtest.png`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that compiles and runs the copied drivers under `tests/tagged-port/safe/tests/core-smoke`, `cve-regressions`, `dependents`, `read-core`, `read-transforms`, and `upstream` against copied corpora under `tests/tagged-port/original/tests`, `tests/tagged-port/original/contrib/pngsuite`, `tests/tagged-port/original/contrib/testpngs`, and `tests/tagged-port/original/pngtest.png`, using copied headers `tests/tagged-port/original/png.h` and `tests/tagged-port/original/pngconf.h`.
  - `libsdl`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/generated/dependent_regression_manifest.json`, `safe/generated/noninteractive_test_list.json`, `safe/generated/original_test_port_map.json`, `safe/generated/perf_workload_manifest.json`, `safe/generated/perf_thresholds.json`, `safe/generated/reports/perf-baseline-vs-safe.json`, `safe/generated/reports/perf-waivers.md`, `safe/upstream-tests`, `original/test`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that runs the copied noninteractive upstream coverage described by `tests/tagged-port/safe/generated/noninteractive_test_list.json` and `tests/tagged-port/safe/generated/original_test_port_map.json`, the copied dependent and perf inventories under `tests/tagged-port/safe/generated/**/*`, the copied installed-tests payload under `tests/tagged-port/safe/upstream-tests/**/*`, and the copied `tests/tagged-port/original/test/**/*` sources and fixtures. Any validator-owned helpers translated from `tests/tagged-port/safe/tests/*.rs` must drive only those copied original-test and generated inputs.
  - `libtiff`
    - exact `validator.imports`: `safe/test`, `safe/scripts`, `original/test`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that runs the copied safe C and shell suite under `tests/tagged-port/safe/test`, using copied helpers under `tests/tagged-port/safe/scripts` and copied fixtures under `tests/tagged-port/original/test`, with no dependency on `original/build/**/*` or `original/build-step2/**/*`.
  - `libvips`
    - exact `validator.imports`: `safe/tests/dependents`, `safe/tests/upstream`, `safe/vendor/pyvips-3.1.1`, `original/test`, `original/examples`
    - fixed `tests/run.sh` target: narrow the imported harness into one runtime-only contract. It must keep the copied dependent suite under `tests/tagged-port/safe/tests/dependents`, the copied upstream wrappers and manifests under `tests/tagged-port/safe/tests/upstream`, the vendored Python package under `tests/tagged-port/safe/vendor/pyvips-3.1.1`, and the copied upstream assets under `tests/tagged-port/original/test` and `tests/tagged-port/original/examples`. It must rewrite `manifest.json`, `run-shell-suite.sh`, `run-pytest-suite.sh`, `test/variables.sh`, `dependents/run-suite.sh`, and `dependents/lib.sh` into installed-package-only wrappers and must not invoke Meson, Cargo, `dpkg-buildpackage`, or any `build-check*` directory inside validator.
  - `libwebp`
    - exact `validator.imports`: `safe/tests`, `original/examples`, `original/tests/public_api_test.c`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that preserves its direct package-surface probes, tool smokes, and dependent runtime cases, compiling `tests/tagged-port/original/tests/public_api_test.c` and using `tests/tagged-port/original/examples/test.webp` plus `tests/tagged-port/original/examples/test_ref.ppm` together with the copied C drivers under `tests/tagged-port/safe/tests/c`.
- The tests in this batch must remain implementation-blind and must not read any explicit safe/original mode selector from the shared runner contract.
- Preserve tracked generated or vendor inputs when present. In particular, `libsdl` and `libvips` must carry forward their manifest-declared generated/vendor imports rather than regenerating them in validator.

**Verification Phases**

- `check_04_media_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: verify the media batch in both modes, including mature tagged `libexif` and the special docker/check-out-artifacts paths.
  - commands:
    - `rm -rf .work/check04`
    - `mkdir -p .work/check04`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check04 --dest-root .work/check04/ports --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check04/ports --artifact-root .work/check04/artifacts --mode both --record-casts --library giflib --library libexif --library libjpeg-turbo --library libpng --library libsdl --library libtiff --library libvips --library libwebp`
    - `python3 tools/render_site.py --results-root .work/check04/artifacts/results --artifacts-root .work/check04/artifacts --output-root .work/check04/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check04/artifacts/results --site-root .work/check04/site`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do test -f .work/check04/artifacts/results/$lib/original.json && test -f .work/check04/artifacts/results/$lib/safe.json && test -f .work/check04/artifacts/casts/$lib/safe.cast; done`
- `check_04_media_review`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: review imported-asset fidelity, generated/vendor imports, the fixed per-library runtime contract from `Fixed Library Contract`, and the batch build-mode rules.
  - commands:
    - `rm -rf .work/check04-review`
    - `mkdir -p .work/check04-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check04-review --dest-root .work/check04-review/ports --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check04-review/ports --tests-root tests --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libpng"]["build"]["mode"] != "checkout-artifacts":
          raise SystemExit("libpng must remain checkout-artifacts")
      if by_name["libvips"]["build"]["mode"] != "docker":
          raise SystemExit("libvips must remain explicit docker")
      if by_name["libexif"]["build"]["mode"] != "safe-debian":
          raise SystemExit("libexif must remain safe-debian")
      PY
    - `test -f tests/libsdl/tests/tagged-port/safe/upstream-tests/installed-tests/usr/share/installed-tests/SDL2/testautomation.test`
    - `test -f tests/libsdl/tests/tagged-port/safe/generated/noninteractive_test_list.json`
    - `find tests/libvips/tests/tagged-port/safe/vendor -type f | grep -q .`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`
    - |
      python3 - <<'PY'
      from pathlib import Path

      required_tokens = {
          "giflib": [
              "VALIDATOR_TAGGED_ROOT",
              "original/tests",
              "original/pic",
              "safe/tests",
          ],
          "libexif": [
              "VALIDATOR_TAGGED_ROOT",
              "original/libexif",
              "original/test",
              "safe/tests/run-original-test-suite.sh",
          ],
          "libjpeg-turbo": [
              "VALIDATOR_TAGGED_ROOT",
              "original/testimages",
              "safe/debian/tests",
              "safe/tests",
          ],
          "libpng": [
              "VALIDATOR_TAGGED_ROOT",
              "original/contrib/pngsuite",
              "original/tests",
              "safe/tests",
          ],
          "libsdl": [
              "VALIDATOR_TAGGED_ROOT",
              "original/test",
              "safe/generated/noninteractive_test_list.json",
              "safe/upstream-tests",
          ],
          "libtiff": [
              "VALIDATOR_TAGGED_ROOT",
              "original/test",
              "safe/test",
              "safe/scripts",
          ],
          "libvips": [
              "VALIDATOR_TAGGED_ROOT",
              "safe/tests/dependents",
              "safe/tests/upstream",
              "safe/vendor/pyvips-3.1.1",
          ],
          "libwebp": [
              "VALIDATOR_TAGGED_ROOT",
              "original/examples",
              "original/tests/public_api_test.c",
              "safe/tests/c",
          ],
      }
      forbidden_tokens = [
          "/home/yans/safelibs/",
          "original/build",
          "build-check",
          "dpkg-buildpackage",
          "cargo test",
          "meson test",
      ]
      for lib, tokens in required_tokens.items():
          text = (Path("tests") / lib / "tests" / "run.sh").read_text()
          for token in tokens:
              if token not in text:
                  raise SystemExit(f"{lib} run.sh missing runtime token: {token}")
          for token in forbidden_tokens:
              if token in text:
                  raise SystemExit(f"{lib} run.sh kept forbidden build-tree token: {token}")
      PY

**Success Criteria**

- Both `check_04_media_matrix` and `check_04_media_review` pass.
- Every library in this batch has validator-owned `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`, with fixtures, harness-source files, and mirrored tagged inputs preserved under `tests/<library>/tests/`.
- The batch keeps `libexif` as a mature tagged `safe-debian` import, preserves `libpng` as `checkout-artifacts`, preserves `libvips` as explicit `docker`, and carries forward generated/vendor imports such as `safe/generated/noninteractive_test_list.json` and `safe/vendor/pyvips-3.1.1`.
- Every entrypoint reuses the shared install and dispatch scripts, no harness branches on run mode, and each `tests/run.sh` reflects the exact fixed runtime bullet for its library.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

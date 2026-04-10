# Phase 03

**Phase Name**

`data-text-validators`

**Implement Phase ID**

`impl_03_data_text_validators`

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
- staged tag-backed inputs for `cjson`, `libcsv`, `libjson`, `libxml`, and `libyaml` as defined in `repositories.yml`

**New Outputs**

- `tests/cjson/**`
- `tests/libcsv/**`
- `tests/libjson/**`
- `tests/libxml/**`
- `tests/libyaml/**`

**File Changes**

- Create validator-owned test trees for `cjson`, `libcsv`, `libjson`, `libxml`, and `libyaml`.
- Within each library tree, create `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`.
- Populate `tests/<library>/tests/fixtures/`, `tests/<library>/tests/harness-source/`, and `tests/<library>/tests/tagged-port/` only through `tools/import_port_assets.py`.

**Implementation Details**

- Treat the currently checked-in generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, as stale reference inputs during phases 01 through 05.
- Do not rewrite, rename, delete, or stage changes to those generated workflow artifacts in this phase; only phase 06 may replace the generated workflow file set.
- This phase covers:
  - `cjson`
  - `libcsv`
  - `libjson`
  - `libxml`
  - `libyaml`
- For each library:
  - import fixtures and harness inputs only through `tools/import_port_assets.py`
  - create a validator-owned `tests/<library>/Dockerfile`
  - create a validator-owned `tests/<library>/docker-entrypoint.sh`
  - create a validator-owned executable `tests/<library>/tests/run.sh`
  - keep all library tests under `tests/<library>/tests/`
  - keep imported tag content under `tests/<library>/tests/tagged-port/` and preserve those files byte-for-byte
  - make `tests/<library>/docker-entrypoint.sh` invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`
- Implement the exact fixed runtime contract for this batch:
  - `cjson`
    - exact `validator.imports`: `safe/tests`, `safe/scripts`, `original/tests`, `original/fuzzing`, `original/test.c`, `original/cJSON.h`, `original/cJSON_Utils.h`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that compiles and runs the copied upstream C suite under `tests/tagged-port/original/tests`, the copied smoke at `tests/tagged-port/original/test.c`, and the copied safe regression and perf inputs under `tests/tagged-port/safe/tests`, using copied headers from `tests/tagged-port/original/cJSON.h` and `tests/tagged-port/original/cJSON_Utils.h`.
  - `libcsv`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `original/examples`, `original/test_csv.c`, `original/csv.h`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that compiles the copied `tests/tagged-port/original/test_csv.c`, every copied example under `tests/tagged-port/original/examples`, and the copied package and Debian smokes under `tests/tagged-port/safe/tests/c` and `tests/tagged-port/safe/debian/tests`.
  - `libjson`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`
    - fixed `tests/run.sh` target: execute the copied package-surface and upstream C suites under `tests/tagged-port/safe/tests/foundation`, `tests/tagged-port/safe/tests/package`, `tests/tagged-port/safe/tests/security`, and `tests/tagged-port/safe/tests/upstream`, plus the copied Debian autopkgtest `tests/tagged-port/safe/debian/tests/unit-test`, while replacing every expectation of `original/build/*` or prepared CMake export trees with validator-owned scratch copies built only from those imported package-smoke sources.
  - `libxml`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
    - fixed `tests/run.sh` target: execute the copied suites under `tests/tagged-port/safe/tests/abi`, `tests/tagged-port/safe/tests/link-compat`, `tests/tagged-port/safe/tests/regressions`, `tests/tagged-port/safe/tests/security`, and `tests/tagged-port/safe/tests/upstream`, using copied helper scripts under `tests/tagged-port/safe/scripts` and copied fixtures under `tests/tagged-port/original/**/*` only. Any helper binaries must compile against installed packages instead of `original/.libs/**/*` or any safe build tree.
  - `libyaml`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/include`, `original/tests`, `original/examples`
    - fixed `tests/run.sh` target: compile and run the copied upstream C tests under `tests/tagged-port/original/tests` and the copied examples under `tests/tagged-port/original/examples` against installed libyaml packages, while using copied package-smoke inputs from `tests/tagged-port/safe/debian/tests` and copied fixture sources from `tests/tagged-port/safe/tests/fixtures` only. It must not cargo-test the imported Rust tree.
- The tests must remain implementation-blind. They may validate behavior and package presence, but they must not branch on `safe` versus `original`, and they must not depend on a mode-specific environment variable because none is part of the shared runner contract.
- Preserve the manifest-declared build mode. In this batch, `libcsv` must keep its checked-in-artifact path instead of rebuilding packages.

**Verification Phases**

- `check_03_data_text_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_03_data_text_validators`
  - purpose: verify the data/text batch in both modes with imported tag-backed fixtures and validator-owned harnesses.
  - commands:
    - `rm -rf .work/check03`
    - `mkdir -p .work/check03`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check03 --dest-root .work/check03/ports --libraries cjson libcsv libjson libxml libyaml`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check03/ports --artifact-root .work/check03/artifacts --mode both --record-casts --library cjson --library libcsv --library libjson --library libxml --library libyaml`
    - `python3 tools/render_site.py --results-root .work/check03/artifacts/results --artifacts-root .work/check03/artifacts --output-root .work/check03/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check03/artifacts/results --site-root .work/check03/site`
    - `for lib in cjson libcsv libjson libxml libyaml; do test -f .work/check03/artifacts/results/$lib/original.json && test -f .work/check03/artifacts/results/$lib/safe.json && test -f .work/check03/artifacts/casts/$lib/safe.cast; done`
- `check_03_data_text_review`
  - type: `check`
  - fixed `bounce_target`: `impl_03_data_text_validators`
  - purpose: review imported-asset fidelity, shared-entrypoint usage, the fixed per-library runtime contract from `Fixed Library Contract`, and the batch build-mode rules.
  - commands:
    - `rm -rf .work/check03-review`
    - `mkdir -p .work/check03-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check03-review --dest-root .work/check03-review/ports --libraries cjson libcsv libjson libxml libyaml`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check03-review/ports --tests-root tests --libraries cjson libcsv libjson libxml libyaml`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libcsv"]["build"]["mode"] != "checkout-artifacts":
          raise SystemExit("libcsv must remain checkout-artifacts")
      PY
    - `for lib in cjson libcsv libjson libxml libyaml; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in cjson libcsv libjson libxml libyaml; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`
    - |
      python3 - <<'PY'
      from pathlib import Path

      required_tokens = {
          "cjson": [
              "VALIDATOR_TAGGED_ROOT",
              "original/tests",
              "original/fuzzing",
              "safe/tests",
          ],
          "libcsv": [
              "VALIDATOR_TAGGED_ROOT",
              "original/examples",
              "original/test_csv.c",
              "safe/debian/tests",
          ],
          "libjson": [
              "VALIDATOR_TAGGED_ROOT",
              "safe/tests/package",
              "safe/debian/tests/unit-test",
              "safe/tests/upstream",
          ],
          "libxml": [
              "VALIDATOR_TAGGED_ROOT",
              "safe/tests/upstream",
              "safe/tests/security",
              "original",
          ],
          "libyaml": [
              "VALIDATOR_TAGGED_ROOT",
              "original/tests",
              "original/examples",
              "safe/debian/tests",
          ],
      }
      forbidden_tokens = [
          "/home/yans/safelibs/",
          "original/build",
          ".libs/",
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

- Both `check_03_data_text_matrix` and `check_03_data_text_review` pass.
- Every library in this batch has validator-owned `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`, with imported fixtures and mirrored tag inputs preserved byte-for-byte under `tests/<library>/tests/`.
- Every `docker-entrypoint.sh` reuses `tests/_shared/install_safe_debs.sh` and `tests/_shared/run_library_tests.sh`, and no library harness branches on run mode or reads `VALIDATOR_MODE`.
- `tools/verify_imported_assets.py` passes against freshly staged manifest refs, `libcsv` keeps `checkout-artifacts`, and each `tests/run.sh` reflects the exact fixed runtime bullet for its library.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

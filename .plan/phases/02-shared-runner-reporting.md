# Phase 02

**Phase Name**

`shared-runner-reporting`

**Implement Phase ID**

`impl_02_shared_runner_reporting`

**Preexisting Inputs**

- `.gitignore`
- `Makefile`
- `inventory/`
- `repositories.yml`
- `tools/`
- `unit/`
- `README.md`
- `/home/yans/safelibs/website/package.json`
- `/home/yans/safelibs/website/scripts/build.mjs`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`

**New Outputs**

- `test.sh`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/run_library_tests.sh`
- `unit/test_run_matrix.py`
- `unit/test_render_site.py`
- `unit/fixtures/demo-manifest.yml`
- `unit/fixtures/demo-debs/demo/*.deb`
- `unit/fixtures/demo-tests/**`
- `unit/fixtures/demo-failure-manifest.yml`
- `unit/fixtures/demo-failure-debs/demo-pass/*.deb`
- `unit/fixtures/demo-failure-debs/demo-fail/*.deb`
- `unit/fixtures/demo-failure-tests/**`

**File Changes**

- Create the shared matrix entrypoints `test.sh`, `tools/run_matrix.py`, `tools/render_site.py`, and `scripts/verify-site.sh`.
- Create the validator-owned shared runtime scripts `tests/_shared/install_safe_debs.sh` and `tests/_shared/run_library_tests.sh`.
- Create runner and renderer unit coverage plus the self-contained demo and aggregate-failure fixtures under `unit/fixtures/`.

**Implementation Details**

- Treat the currently checked-in generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, as stale reference inputs during phases 01 through 05.
- Do not rewrite, rename, delete, or stage changes to those generated workflow artifacts in this phase; only phase 06 may replace the generated workflow file set.
- `test.sh` must be a thin CLI wrapper over `tools/run_matrix.py`. It must support:
  - `--config`
  - `--tests-root`
  - `--port-root`
  - `--artifact-root`
  - `--safe-deb-root`
  - `--mode`
  - `--record-casts`
  - repeated `--library`
  - `--list-libraries`
- When `--library` is omitted, both `test.sh` and `tools/run_matrix.py` must select every manifest library in manifest order. `--list-libraries` must print that same ordered library list and exit without running any build or test work.
- `tools/run_matrix.py` must orchestrate original and safe runs per library and write explicit JSON results under `<artifact-root>/results/<library>/<mode>.json`.
- The phase-02 demo fixture is fixed: `unit/fixtures/demo-manifest.yml` must define exactly one library named `demo`, `unit/fixtures/demo-tests/` must contain only that library's harness, and `unit/fixtures/demo-debs/` must contain exactly one safe-deb leaf directory at `unit/fixtures/demo-debs/demo/`.
- `tools/run_matrix.py` and `test.sh` must treat the selected matrix as one aggregate run: they must attempt every requested library/mode pair in order, continue after individual build or test failures, emit the JSON result for every attempted run, and return a non-zero process exit only after the full requested matrix finishes when any attempted run failed.
- A failed run must still emit its result JSON, write its log, and, for safe mode when `--record-casts` is enabled, preserve the cast captured up to the failure point.
- Every run must write its log at `<artifact-root>/logs/<library>/<mode>.log`. When `--record-casts` is enabled for a safe run, that run must also write `<artifact-root>/casts/<library>/safe.cast`. Original runs never produce a cast file.
- Every result JSON must include at least `library`, `mode`, `status`, `started_at`, `finished_at`, `duration_seconds`, `log_path`, and `cast_path`. `log_path` and `cast_path` must be artifact-root-relative paths, and `cast_path` must be `null` whenever no cast file is produced.
- `--safe-deb-root` is a matrix-level host directory. Its exact required layout is `<safe-deb-root>/<library>/*.deb` for every selected library that will run in safe mode.
- When `--safe-deb-root` is supplied, `tools/run_matrix.py` must resolve the per-library leaf directory at `<safe-deb-root>/<library>/`, fail clearly if that leaf is missing or contains no `.deb` files, and mount that leaf into the library container as `/safedebs`.
- Passing a leaf directory that contains `.deb` files directly to `--safe-deb-root` is invalid. `tools/run_matrix.py` must reject that ambiguous shape instead of guessing.
- When `--safe-deb-root` is omitted and `--port-root` is supplied, `tools/run_matrix.py` must call `tools/build_safe_debs.py` once per selected library, place the resulting packages under `<artifact-root>/debs/<library>/`, and mount that per-library leaf into the library container as `/safedebs` for the safe run.
- Safe-mode runs must record an asciinema cast and must execute the test command under `bash -x` so the cast shows the commands being run.
- Original and safe runs must use the same validator-owned test command and the same shared-library test interface. The only allowed mode difference is whether replacement `.deb` packages are installed before the tests start.
- `tests/_shared/install_safe_debs.sh` must install every `.deb` mounted under `/safedebs` when that directory is present and skip cleanly when it is absent. The container only ever sees the single-library leaf directory mounted at `/safedebs`.
- `tests/_shared/run_library_tests.sh` must be the single shared runtime entrypoint that every library-specific `docker-entrypoint.sh` delegates to after any optional safe-deb installation.
- The shared runtime contract is fixed and validator-owned:
  - every library must provide an executable `tests/<library>/tests/run.sh`
  - `tests/_shared/run_library_tests.sh` must locate that file and execute it
  - before execution it must export at least `VALIDATOR_LIBRARY`, `VALIDATOR_LIBRARY_ROOT`, and `VALIDATOR_TAGGED_ROOT=$VALIDATOR_LIBRARY_ROOT/tests/tagged-port`
  - it must not export `VALIDATOR_MODE` or any other explicit safe/original selector into `tests/<library>/tests/run.sh`
- Library `tests/<library>/tests/run.sh` files may invoke imported scripts or compile imported sources from `tests/<library>/tests/tagged-port`, but they must not rewrite the mirrored tag inputs in place.
- Every library `tests/<library>/tests/run.sh` must implement the exact per-library runtime bullet from `Fixed Library Contract`; phase 02 creates the shared interface, but it does not leave any library-local runtime behavior open-ended.
- `tools/render_site.py` must render a deterministic static site from the matrix results and cast paths.
- `scripts/verify-site.sh` must verify that the rendered site covers exactly the libraries and modes present in the result JSON and that every referenced cast or log path exists.
- Add small self-contained demo fixtures under `unit/fixtures/`, including a checked-in dummy safe-deb tree at `unit/fixtures/demo-debs/demo/*.deb`, so phase 02 can exercise the shared runner and renderer without depending on real port staging.
- Add a second self-contained failure fixture under `unit/fixtures/demo-failure-*` with exactly two libraries, `demo-fail` then `demo-pass`, so phase 02 can prove the matrix continues through a failing library and returns one aggregate non-zero exit only after both libraries and both modes are attempted.
- `unit/test_run_matrix.py` must cover both the accepted matrix-root safe-deb layout (`unit/fixtures/demo-debs/<library>/*.deb`), rejection of a single-library leaf passed directly as `--safe-deb-root`, and the aggregate-failure fixture that verifies continuation plus one final non-zero exit status.

**Verification Phases**

- `check_02_shared_runner_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_runner_reporting`
  - purpose: verify the shared matrix runner, aggregate-failure contract, result schema, safe-mode trace capture, and static-site renderer before library-specific harnesses exist.
  - commands:
    - `rm -rf .work/check02`
    - `mkdir -p .work/check02`
    - `python3 -m unittest unit.test_run_matrix unit.test_render_site -v`
    - `test -d unit/fixtures/demo-debs/demo`
    - `ls unit/fixtures/demo-debs/demo/*.deb >/dev/null`
    - `python3 tools/run_matrix.py --config unit/fixtures/demo-manifest.yml --tests-root unit/fixtures/demo-tests --artifact-root .work/check02/artifacts --safe-deb-root unit/fixtures/demo-debs --mode both --record-casts`
    - |
      set +e
      python3 tools/run_matrix.py --config unit/fixtures/demo-failure-manifest.yml --tests-root unit/fixtures/demo-failure-tests --artifact-root .work/check02/failure-artifacts --safe-deb-root unit/fixtures/demo-failure-debs --mode both --record-casts
      matrix_exit_code=$?
      set -e
      test "$matrix_exit_code" -ne 0
    - `python3 tools/render_site.py --results-root .work/check02/artifacts/results --artifacts-root .work/check02/artifacts --output-root .work/check02/site`
    - `bash scripts/verify-site.sh --config unit/fixtures/demo-manifest.yml --results-root .work/check02/artifacts/results --site-root .work/check02/site`
    - `bash test.sh --config repositories.yml --list-libraries > .work/check02/libraries.txt`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      expected = [entry["name"] for entry in yaml.safe_load(Path("repositories.yml").read_text())["repositories"]]
      actual = Path(".work/check02/libraries.txt").read_text().splitlines()
      if actual != expected:
          raise SystemExit(f"library listing mismatch: {actual}")
      PY
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      failure_root = Path(".work/check02/failure-artifacts/results")
      fail_original = json.loads((failure_root / "demo-fail" / "original.json").read_text())
      pass_original = json.loads((failure_root / "demo-pass" / "original.json").read_text())
      fail_safe = json.loads((failure_root / "demo-fail" / "safe.json").read_text())
      pass_safe = json.loads((failure_root / "demo-pass" / "safe.json").read_text())
      if fail_original["status"] == "passed":
          raise SystemExit("demo-fail original run must fail in the aggregate-failure fixture")
      if fail_safe["status"] == "passed":
          raise SystemExit("demo-fail safe run must fail in the aggregate-failure fixture")
      if pass_original["status"] != "passed" or pass_safe["status"] != "passed":
          raise SystemExit("demo-pass runs must still execute and pass after demo-fail fails")
      PY
    - `find .work/check02/artifacts/casts -name 'safe.cast' | grep -q .`
    - `find .work/check02/failure-artifacts/casts -name 'safe.cast' | grep -q .`
    - `test -f .work/check02/site/index.html`
- `check_02_shared_runner_review`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_runner_reporting`
  - purpose: review the shared runner CLI, the exact `--safe-deb-root` contract, the result schema, the shared entrypoint contract, aggregate-failure behavior, and site-verification invariants using fresh demo runs.
  - commands:
    - `rm -rf .work/check02-review`
    - `mkdir -p .work/check02-review`
    - `git diff --check HEAD^ HEAD`
    - `test -f test.sh && test -f tools/run_matrix.py && test -f tools/render_site.py && test -f scripts/verify-site.sh`
    - `test -f tests/_shared/install_safe_debs.sh && test -f tests/_shared/run_library_tests.sh`
    - `python3 tools/run_matrix.py --config unit/fixtures/demo-manifest.yml --tests-root unit/fixtures/demo-tests --artifact-root .work/check02-review/artifacts --safe-deb-root unit/fixtures/demo-debs --mode both --record-casts`
    - `python3 tools/render_site.py --results-root .work/check02-review/artifacts/results --artifacts-root .work/check02-review/artifacts --output-root .work/check02-review/site`
    - `bash scripts/verify-site.sh --config unit/fixtures/demo-manifest.yml --results-root .work/check02-review/artifacts/results --site-root .work/check02-review/site`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      safe_results = list(Path(".work/check02-review/artifacts/results").glob("*/safe.json"))
      if len(safe_results) != 1:
          raise SystemExit(f"expected exactly one demo safe result, found {safe_results}")
      safe_result = json.loads(safe_results[0].read_text())
      required = {
          "library",
          "mode",
          "status",
          "started_at",
          "finished_at",
          "duration_seconds",
          "log_path",
          "cast_path",
      }
      if set(safe_result) < required:
          raise SystemExit(f"result schema mismatch: {set(safe_result)}")

      run_matrix = Path("tools/run_matrix.py").read_text()
      if "bash -x" not in run_matrix:
          raise SystemExit("safe-mode bash -x trace missing")

      demo_deb_root = Path("unit/fixtures/demo-debs")
      demo_deb_dirs = sorted(path.name for path in demo_deb_root.iterdir() if path.is_dir())
      if demo_deb_dirs != ["demo"]:
          raise SystemExit(f"demo safe-deb root must use per-library subdirectories, found {demo_deb_dirs}")
      if not list((demo_deb_root / "demo").glob("*.deb")):
          raise SystemExit("demo safe-deb root must contain .deb files under unit/fixtures/demo-debs/demo/")

      install_script = Path("tests/_shared/install_safe_debs.sh").read_text()
      if "/safedebs" not in install_script:
          raise SystemExit("safe-deb installer must target /safedebs")

      shared_runner = Path("tests/_shared/run_library_tests.sh").read_text()
      if "set -euo pipefail" not in shared_runner:
          raise SystemExit("shared test runner must be strict-shell")
      if 'tests/$library/tests/run.sh' not in shared_runner and 'tests/${library}/tests/run.sh' not in shared_runner:
          raise SystemExit("shared runner must dispatch to tests/<library>/tests/run.sh")
      for required_name in ["VALIDATOR_LIBRARY", "VALIDATOR_LIBRARY_ROOT", "VALIDATOR_TAGGED_ROOT"]:
          if required_name not in shared_runner:
              raise SystemExit(f"shared runner missing {required_name}")
      if "VALIDATOR_MODE" in shared_runner:
          raise SystemExit("shared runner must not expose VALIDATOR_MODE to library tests")
      PY
    - |
      set +e
      python3 tools/run_matrix.py --config unit/fixtures/demo-failure-manifest.yml --tests-root unit/fixtures/demo-failure-tests --artifact-root .work/check02-review/failure-artifacts --safe-deb-root unit/fixtures/demo-failure-debs --mode both --record-casts
      matrix_exit_code=$?
      set -e
      test "$matrix_exit_code" -ne 0
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      failure_root = Path(".work/check02-review/failure-artifacts/results")
      expected = {
          ("demo-fail", "original"),
          ("demo-fail", "safe"),
          ("demo-pass", "original"),
          ("demo-pass", "safe"),
      }
      actual = {(path.parent.name, path.stem) for path in failure_root.glob("*/*.json")}
      if actual != expected:
          raise SystemExit(f"aggregate-failure fixture results mismatch: {sorted(actual)}")
      for library, mode in expected:
          payload = json.loads((failure_root / library / f"{mode}.json").read_text())
          if payload["library"] != library or payload["mode"] != mode:
              raise SystemExit(f"wrong identity in {library}/{mode}: {payload}")
      if json.loads((failure_root / "demo-fail" / "original.json").read_text())["status"] == "passed":
          raise SystemExit("demo-fail original run must fail")
      if json.loads((failure_root / "demo-pass" / "safe.json").read_text())["status"] != "passed":
          raise SystemExit("demo-pass safe run must complete successfully despite earlier failure")
      PY
    - `find .work/check02-review/artifacts/casts -name 'safe.cast' | grep -q .`
    - `find .work/check02-review/failure-artifacts/casts -name 'safe.cast' | grep -q .`
    - `test -f .work/check02-review/site/index.html`

**Success Criteria**

- Both `check_02_shared_runner_smoke` and `check_02_shared_runner_review` pass.
- `test.sh` and `tools/run_matrix.py` preserve the fixed aggregate matrix contract, emit complete result JSON for every attempted run, and return one non-zero exit only after the requested matrix finishes when any run failed.
- Safe-mode runs execute under `bash -x`, capture `safe.cast`, and mount safe `.deb` packages only from the matrix-root layout `<safe-deb-root>/<library>/*.deb` as `/safedebs`.
- `tests/_shared/run_library_tests.sh` exports `VALIDATOR_LIBRARY`, `VALIDATOR_LIBRARY_ROOT`, and `VALIDATOR_TAGGED_ROOT`, dispatches to `tests/<library>/tests/run.sh`, and never exports `VALIDATOR_MODE`.
- The rendered site matches the matrix results and referenced artifact paths exactly, and the demo plus aggregate-failure fixtures stay self-contained.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

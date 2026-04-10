# Phase 05

**Phase Name**

`system-archive-validators`

**Implement Phase ID**

`impl_05_system_archive_validators`

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
- `tests/giflib/`
- `tests/libexif/`
- `tests/libjpeg-turbo/`
- `tests/libpng/`
- `tests/libsdl/`
- `tests/libtiff/`
- `tests/libvips/`
- `tests/libwebp/`
- staged tag-backed inputs for `libarchive`, `libbz2`, `liblzma`, `libsodium`, `libuv`, and `libzstd` as defined in `repositories.yml`

**New Outputs**

- `tests/libarchive/**`
- `tests/libbz2/**`
- `tests/liblzma/**`
- `tests/libsodium/**`
- `tests/libuv/**`
- `tests/libzstd/**`

**File Changes**

- Create validator-owned test trees for `libarchive`, `libbz2`, `liblzma`, `libsodium`, `libuv`, and `libzstd`.
- Within each library tree, create `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`.
- Populate each library's fixtures, harness-source files, and mirrored tagged inputs only through `tools/import_port_assets.py`.

**Implementation Details**

- Treat the currently checked-in generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, as stale reference inputs during phases 01 through 05.
- Do not rewrite, rename, delete, or stage changes to those generated workflow artifacts in this phase; only phase 06 may replace the generated workflow file set.
- This phase covers:
  - `libarchive`
  - `libbz2`
  - `liblzma`
  - `libsodium`
  - `libuv`
  - `libzstd`
- Import fixtures and harness inputs only through `tools/import_port_assets.py`.
- Treat `libuv` as a mature tagged import from `refs/tags/libuv/04-test`, not as a bootstrap-from-HEAD project.
- Preserve tag-rooted fixture copying for every library in this batch.
- `liblzma` must consume the exact phase-01 imports `safe/docker`, `safe/scripts`, `safe/tests/dependents`, `safe/tests/extra`, and `safe/tests/upstream`; it must not depend on `validator.import_excludes` to prune `safe/tests/generated` after import.
- Create validator-owned `tests/<library>/tests/run.sh` for every library in this batch and keep imported tag mirrors under `tests/<library>/tests/tagged-port/`.
- Make every `tests/<library>/docker-entrypoint.sh` in this batch invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`.
- Implement the exact fixed runtime contract for this batch:
  - `libarchive`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `safe/generated/api_inventory.json`, `safe/generated/cve_matrix.json`, `safe/generated/link_compat_manifest.json`, `safe/generated/original_build_contract.json`, `safe/generated/original_package_metadata.json`, `safe/generated/original_c_build`, `safe/generated/original_link_objects`, `safe/generated/original_pkgconfig/libarchive.pc`, `safe/generated/pkgconfig/libarchive.pc`, `safe/generated/rust_test_manifest.json`, `safe/generated/test_manifest.json`, `original/libarchive-3.7.2`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that compiles helper binaries from copied sources under `tests/tagged-port/original/libarchive-3.7.2/**/*`, runs the copied upstream suites under `tests/tagged-port/safe/tests/{cat,cpio,libarchive,tar,unzip}`, and consumes the copied generated manifests and pkg-config contracts under `tests/tagged-port/safe/generated/**/*` from validator-owned paths only. It must use copied helpers under `tests/tagged-port/safe/scripts/run-upstream-c-tests.sh` and `run-debian-minitar.sh` rather than sibling-repo build trees.
  - `libbz2`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that preserves its exact dependent smoke functions from `tests/harness-source/original-test-script.sh` while using only copied upstream samples, headers, and source files under `tests/tagged-port/original/**/*`, copied package smokes under `tests/tagged-port/safe/debian/tests`, copied helper scripts under `tests/tagged-port/safe/scripts`, and copied validator-facing probes under `tests/tagged-port/safe/tests`.
  - `liblzma`
    - exact `validator.imports`: `safe/docker`, `safe/scripts`, `safe/tests/dependents`, `safe/tests/extra`, `safe/tests/upstream`
    - fixed `tests/run.sh` target: execute the copied dependent smokes under `tests/tagged-port/safe/tests/dependents`, the copied extra regression cases under `tests/tagged-port/safe/tests/extra`, and the copied upstream suite under `tests/tagged-port/safe/tests/upstream`, using only copied helpers under `tests/tagged-port/safe/docker` and `tests/tagged-port/safe/scripts` plus installed liblzma packages. It must not read `safe/tests/generated` and it must not import or read any `original/**/*` tree.
  - `libsodium`
    - exact `validator.imports`: `safe/tests`, `safe/docker`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only dependent matrix that preserves the exact 16 dependent smokes named in `dependents.json` and `tests/harness-source/original-test-script.sh`, using only copied helper assets under `tests/tagged-port/safe/tests` and `tests/tagged-port/safe/docker`. It must not add any undeclared `original/**/*` dependency.
  - `libuv`
    - exact `validator.imports`: `safe/docker`, `safe/include`, `safe/prebuilt`, `safe/scripts`, `safe/test`, `safe/test-extra`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only dependent matrix that preserves the exact dependent list from `dependents.json`, and compile or run the copied upstream suite under `tests/tagged-port/safe/test/**/*` plus the copied regressions under `tests/tagged-port/safe/test-extra/**/*` against installed libuv packages using copied headers under `tests/tagged-port/safe/include/**/*`, copied helpers under `tests/tagged-port/safe/scripts/**/*`, the copied dependent-image Dockerfile under `tests/tagged-port/safe/docker/dependents.Dockerfile`, and the copied runtime-support archive under `tests/tagged-port/safe/prebuilt/**/*`. It must not rebuild `original/**/*` from source inside validator.
  - `libzstd`
    - exact `validator.imports`: `safe/tests`, `safe/debian/tests`, `safe/docker`, `safe/scripts`, `original/libzstd-1.5.5+dfsg2`
    - fixed `tests/run.sh` target: translate the imported harness into an installed-package-only matrix that runs the copied dependent suite described by `tests/tagged-port/safe/tests/dependents/dependent_matrix.toml`, the copied C API drivers under `tests/tagged-port/safe/tests/capi`, the copied link-compat and whitebox suites under `tests/tagged-port/safe/tests/link-compat` and `tests/tagged-port/safe/tests/ported`, and the copied upstream corpus under `tests/tagged-port/original/libzstd-1.5.5+dfsg2`, using only copied helpers under `tests/tagged-port/safe/docker` and `tests/tagged-port/safe/scripts` plus installed packages.
- The tests in this batch must remain implementation-blind and must not read any explicit safe/original mode selector from the shared runner contract.
- Do not add any validator logic for out-of-scope untagged repos in this phase.

**Verification Phases**

- `check_05_system_archive_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_05_system_archive_validators`
  - purpose: verify the remaining tagged libraries in both modes, including mature tagged `libuv`.
  - commands:
    - `rm -rf .work/check05`
    - `mkdir -p .work/check05`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check05 --dest-root .work/check05/ports --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check05/ports --artifact-root .work/check05/artifacts --mode both --record-casts --library libarchive --library libbz2 --library liblzma --library libsodium --library libuv --library libzstd`
    - `python3 tools/render_site.py --results-root .work/check05/artifacts/results --artifacts-root .work/check05/artifacts --output-root .work/check05/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check05/artifacts/results --site-root .work/check05/site`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do test -f .work/check05/artifacts/results/$lib/original.json && test -f .work/check05/artifacts/results/$lib/safe.json && test -f .work/check05/artifacts/casts/$lib/safe.cast; done`
- `check_05_system_archive_review`
  - type: `check`
  - fixed `bounce_target`: `impl_05_system_archive_validators`
  - purpose: review imported-asset fidelity, `libuv`'s mature-tagged import contract, `liblzma`'s split test-import contract, the fixed per-library runtime contract from `Fixed Library Contract`, and batch completeness.
  - commands:
    - `rm -rf .work/check05-review`
    - `mkdir -p .work/check05-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check05-review --dest-root .work/check05-review/ports --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check05-review/ports --tests-root tests --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      names = [entry["name"] for entry in manifest["repositories"]]
      if "glib" in names or "libc6" in names or "libcurl" in names or "libgcrypt" in names or "libjansson" in names:
          raise SystemExit("out-of-scope untagged libraries must not reappear")

      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libuv"]["ref"] != "refs/tags/libuv/04-test":
          raise SystemExit("libuv must be pinned to refs/tags/libuv/04-test")
      if by_name["libuv"]["build"]["mode"] != "safe-debian":
          raise SystemExit("libuv must remain safe-debian")
      PY
    - `test -f tests/libarchive/tests/tagged-port/original/libarchive-3.7.2/libarchive/test/test_acl_nfs4.c`
    - `test -f tests/liblzma/tests/tagged-port/safe/tests/dependents/boost_iostreams_smoke.cpp`
    - `test -f tests/liblzma/tests/tagged-port/safe/tests/upstream/bcj_test.c`
    - `test ! -e tests/liblzma/tests/tagged-port/safe/tests/generated`
    - `test -f tests/libuv/tests/tagged-port/safe/docker/dependents.Dockerfile`
    - `test -f tests/libuv/tests/tagged-port/safe/prebuilt/x86_64-unknown-linux-gnu/libuv_safe_runtime_support.a`
    - `test -f tests/libuv/tests/tagged-port/safe/test/run-tests.c`
    - `test -f tests/libuv/tests/tagged-port/safe/test-extra/run-regressions.c`
    - `test -f tests/libzstd/tests/tagged-port/safe/scripts/run-full-suite.sh`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`
    - |
      python3 - <<'PY'
      from pathlib import Path

      required_tokens = {
          "libarchive": [
              "VALIDATOR_TAGGED_ROOT",
              "original/libarchive-3.7.2",
              "safe/generated/test_manifest.json",
              "safe/scripts/run-upstream-c-tests.sh",
          ],
          "libbz2": [
              "fixtures/dependents.json",
              "VALIDATOR_TAGGED_ROOT",
              "original",
              "safe/tests",
          ],
          "liblzma": [
              "VALIDATOR_TAGGED_ROOT",
              "safe/tests/dependents",
              "safe/tests/extra",
              "safe/tests/upstream",
          ],
          "libsodium": [
              "fixtures/dependents.json",
              "VALIDATOR_TAGGED_ROOT",
              "safe/tests",
              "safe/docker",
          ],
          "libuv": [
              "fixtures/dependents.json",
              "VALIDATOR_TAGGED_ROOT",
              "safe/test",
              "safe/test-extra",
          ],
          "libzstd": [
              "VALIDATOR_TAGGED_ROOT",
              "original/libzstd-1.5.5+dfsg2",
              "safe/tests/dependents",
              "safe/scripts/run-dependent-matrix.sh",
          ],
      }
      forbidden_tokens = [
          "/home/yans/safelibs/",
          "original/build",
          ".libs/",
          "safe/tests/generated",
          "LIBUV_IMPL=",
          "IMPLEMENTATION=",
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

- Both `check_05_system_archive_matrix` and `check_05_system_archive_review` pass.
- Every library in this batch has validator-owned `Dockerfile`, `docker-entrypoint.sh`, and executable `tests/run.sh`, with fixtures, harness-source files, and mirrored tagged inputs preserved under `tests/<library>/tests/`.
- `libuv` stays pinned to `refs/tags/libuv/04-test` as a mature tagged `safe-debian` import, `liblzma` keeps its split import contract without `safe/tests/generated`, and no out-of-scope untagged repo logic reappears.
- Every entrypoint reuses the shared install and dispatch scripts, no harness branches on run mode, and each `tests/run.sh` reflects the exact fixed runtime bullet for its library.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

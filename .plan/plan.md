# Validator Implementation Plan

## Context

`README.md:1-23` defines the required end state for this greenfield validator repository:

- one validator harness per library under `tests/<library>/`
- each harness contains `Dockerfile`, `docker-entrypoint.sh`, and a mode-blind `tests/` tree
- top-level `test.sh` runs one library or the full matrix
- CI runs both original and replacement-package modes, records safe-mode asciinema output, reports results, and publishes a GitHub Pages site

The tracked tree currently contains only `README.md`, `.plan/` is untracked, and `git remote -v` is empty. The implementation must create the repository contents and publish the new public repo `github.com/safelibs/validator`.

The goal text says `github.com/safelibs/repos-*`, but the authoritative inventory available from this workspace on April 7, 2026 is `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url`, which returns zero `repos-*` repos and 23 private library repos named `safelibs/port-*`. Phase 1 must verify that mismatch, check the proof into validator-owned artifacts, and use that 23-library set everywhere else.

Verified library scope as of April 7, 2026:

- `cjson`
- `giflib`
- `glib`
- `libarchive`
- `libbz2`
- `libcsv`
- `libcurl`
- `libexif`
- `libgcrypt`
- `libjansson`
- `libjpeg-turbo`
- `libjson`
- `liblzma`
- `libpng`
- `libsdl`
- `libsodium`
- `libtiff`
- `libuv`
- `libvips`
- `libwebp`
- `libxml`
- `libyaml`
- `libzstd`

Relevant codebase and workspace inputs:

- `README.md:7-23` is the repository contract and must remain the source of truth for the validator layout.
- `/home/yans/safelibs/apt-repo/README.md:6-25` shows the existing SafeLibs manifest style and proves that `apt-repo` currently covers only the 17 `port-*` repos that expose a `04-test` tag; validator must be a strict superset of that scope, not a copy of it.
- `/home/yans/safelibs/apt-repo/tools/build_site.py:69-165` provides the existing config-loading, source-sync, build-mode, and Rust-toolchain-detection patterns to reuse, but its destructive `reset --hard` and `clean -fdx` sync logic must not be copied into validator because sibling `port-*` worktrees are read-only inputs here.
- `/home/yans/safelibs/apt-repo/tests/test_build_site.py:1-260` shows the prevailing Python conventions to follow: stdlib-first imports, typed functions, `Path`, dataclasses, `yaml.safe_load`, and `unittest`.
- Representative validator-relevant harness patterns already exist in sibling repos and need normalization rather than reinvention:
  - `/home/yans/safelibs/port-cjson/test-original.sh:42-220` builds a Docker image and runs an inventory-validated dependent matrix.
  - `/home/yans/safelibs/port-libpng/test-original.sh:83-220` hard-codes original vs safe image construction inside one script.
  - `/home/yans/safelibs/port-liblzma/test-original.sh:85-181` already separates tracked `safe/docker`, `safe/scripts`, and dependent smoke assets.
  - `/home/yans/safelibs/port-libvips/test-original.sh:9-27` delegates to tracked dependent-suite helpers under `safe/tests/dependents/`.
- `/home/yans/safelibs/port-libvips/.plan/workflow-structure.yaml:1-220` demonstrates the explicit-phase, linear workflow vocabulary validator must emit.

Artifact maturity groups:

- Existing validator inputs that must be consumed in place and copied into validator-owned paths: `cjson`, `giflib`, `libarchive`, `libbz2`, `libcsv`, `libexif`, `libjpeg-turbo`, `libjson`, `liblzma`, `libpng`, `libsdl`, `libsodium`, `libtiff`, `libvips`, `libwebp`, `libxml`, `libyaml`, and `libzstd`. Across those repos the concrete reusable artifacts are `dependents.json`, `relevant_cves.json`, `test-original.sh`, `safe/debian/control`, `safe/debian/tests/**/*` when present, `safe/tests/**/*` or `safe/test/**/*`, `safe/docker/**/*`, `safe/scripts/**/*` when the final validator harness still consumes them, library-specific tracked `safe/generated/**/*` and `safe/vendor/**/*` roots when phase 1 declares them, and the exact tracked `original/**/*` source roots that phase 1 must declare in `repositories.yml`.
- The mature-library `original/**/*` import contract must be closed in phase 1 rather than rediscovered later. The exact tracked mature-source additions are:
  - `cjson -> original/tests, original/fuzzing, original/test.c, original/cJSON.h, original/cJSON_Utils.h`
  - `giflib -> original/tests, original/pic, original/gif_lib.h`
  - `libarchive -> original/libarchive-3.7.2`
  - `libbz2 -> original`
  - `libcsv -> original/examples, original/test_csv.c, original/csv.h`
  - `libexif -> original/libexif, original/test, original/contrib/examples`
  - `libjpeg-turbo -> original/testimages`
  - `libpng -> original/tests, original/contrib/pngsuite, original/contrib/testpngs, original/png.h, original/pngconf.h, original/pngtest.png`
  - `libsdl -> original/test`
  - `libtiff -> original/test`
  - `libvips -> original/test, original/examples`
  - `libwebp -> original/examples, original/tests/public_api_test.c`
  - `libxml -> original`
  - `libyaml -> original/include, original/tests, original/examples`
  - `libzstd -> original/libzstd-1.5.5+dfsg2`
- Mature-harness rewrite exceptions are fixed too: phase 1 must not declare missing build-output paths such as `port-libjson/original/build/**/*`, `port-libtiff/original/build/**/*`, `port-libtiff/original/build-step2/**/*`, `port-libxml/original/.libs/**/*`, or `port-libexif/original/libexif/.libs/**/*` as importable validator inputs. Later phases must rewrite those current harness behaviors to compile against installed packages or copied tracked source files instead.
- Additional tracked harness-source inputs that phase 1 must close instead of leaving implicit are:
  - `libarchive -> safe/generated/api_inventory.json, safe/generated/cve_matrix.json, safe/generated/link_compat_manifest.json, safe/generated/original_build_contract.json, safe/generated/original_package_metadata.json, safe/generated/original_c_build, safe/generated/original_link_objects, safe/generated/original_pkgconfig/libarchive.pc, safe/generated/pkgconfig/libarchive.pc, safe/generated/rust_test_manifest.json, safe/generated/test_manifest.json`
  - `libsdl -> safe/generated/dependent_regression_manifest.json, safe/generated/noninteractive_test_list.json, safe/generated/original_test_port_map.json, safe/generated/perf_workload_manifest.json, safe/generated/perf_thresholds.json, safe/generated/reports/perf-baseline-vs-safe.json, safe/generated/reports/perf-waivers.md`
- `libvips` is a fixed narrowing case for validator import scope: phase 1 must import only the tracked runtime-facing `safe/tests/dependents/**/*`, `safe/tests/upstream/**/*`, `safe/vendor/pyvips-3.1.1/**/*`, `original/test/**/*`, and `original/examples/**/*` assets plus the common existing-harness roots. It must not import `safe/meson.build`, `safe/scripts/**/*`, `safe/reference/**/*`, `safe/src/**/*`, `safe/tests/abi_layout.rs`, `safe/tests/init_version_smoke.rs`, `safe/tests/operation_registry.rs`, `safe/tests/ops_advanced.rs`, `safe/tests/ops_core.rs`, `safe/tests/runtime_io.rs`, `safe/tests/security.rs`, `safe/tests/security/**/*`, `safe/tests/threading.rs`, `safe/tests/introspection/**/*`, or `safe/tests/link_compat/**/*` into validator.
- `libvips` phase 4 is a fixed runtime-only rewrite, not an open-ended port. The imported `safe/tests/upstream/**/*` tree is only seed material: the final validator-owned `tests/libvips/tests/upstream/manifest.json` must keep only `shell` and `pytest` wrappers, `standalone_shell_tests` must be exactly `["test/test_thumbnail.sh"]`, `python_requirements` must stay `["pyvips==3.1.1"]`, and the final tree must omit `safe_build_dir_env`, Meson test lists, fuzz target lists, `run-meson-suite.sh`, and `run-fuzz-suite.sh`.
- `libvips` phase 4 must also generate `tests/libvips/tests/upstream/test/variables.sh` from the copied `original/test/variables.sh.in` contract so the surviving shell regression uses copied fixtures under `tests/libvips/tests/upstream/test/test-suite/images/**/*` and installed `vips`, `vipsthumbnail`, and `vipsheader` binaries from `PATH` rather than any build tree or `VIPS_SAFE_BUILD_DIR` state from the sibling repo.
- Bootstrap-only source imports that lack validator fixtures today: `glib`, `libcurl`, `libgcrypt`, `libjansson`, and `libuv`. Their concrete inputs are existing upstream and Debian-packaging trees:
  - `/home/yans/safelibs/port-glib/original`
  - `/home/yans/safelibs/port-libcurl/original`
  - `/home/yans/safelibs/port-libgcrypt/original/libgcrypt20-1.10.3`
  - `/home/yans/safelibs/port-libjansson/original/jansson-2.14`
  - `/home/yans/safelibs/port-libuv/original`

The six libraries absent from `apt-repo/repositories.yml` must be pinned explicitly in validator’s manifest from the current local Git state:

- `glib`: `530f1e25df9491687ba5578904722602f69e1480`
- `libcurl`: `2663317e76bc5db50e7f5e51da73b5808d36ba6e`
- `libexif`: `043cc14d44fa2ece8d52ded545d61e37539918d6`
- `libgcrypt`: `946d1aaa8c691a848898bce17526550c9178a565`
- `libjansson`: `2a003bb019cc9253550d8d43da0d3f0cb4282f04`
- `libuv`: `9e5d552c21af689e653335dba9e89d7cfd70e07b`

Implementation conventions:

- Python stays stdlib + `PyYAML`, run with `python3 -m unittest`.
- Python unit tests live under `unit/`; `tests/` is reserved for the validator harness tree described in `README.md`.
- Shell uses `bash` with `set -euo pipefail`.
- Ubuntu 24.04 is the default Docker base.
- Validator must become self-contained after implementation: the checked-in validator tree is the runtime test source, while sibling `port-*` repos remain read-only import/build inputs only.

## Generated Workflow Contract

The generated workflow must obey:

- linear execution only; no `parallel_groups`
- self-contained inline-only YAML; no top-level `include` and no phase-level `prompt_file`, `workflow_file`, `workflow_dir`, `checks`, or any other YAML indirection
- no agent-guided `bounce_targets` lists; use only a fixed `bounce_target`
- every verifier is an explicit top-level `check` phase
- every verifier stays attached to the implement phase it verifies and bounces only to that implement phase
- if a verifier needs to run tests, lint, build, Docker, `gh`, or any other command, those commands must appear directly in the checker instructions instead of being modeled as a non-agentic phase
- if the goal or workspace already provides artifacts, list them as existing inputs and consume or update them in place instead of refetching, recollecting, rediscovering, or regenerating them from scratch
- if prepared artifacts such as source snapshots, dependent inventories, CVE data, or test harnesses already exist, preserve that consume-existing-artifacts contract explicitly
- whenever a verifier, local command sequence, or GitHub Actions job runs a multi-library or multi-mode matrix and then renders, verifies, uploads, or publishes reports, it must capture the matrix exit code, continue through report generation from the results that were produced, and surface any non-zero matrix status only after those report artifacts exist
- every verifier, local command sequence, and GitHub Actions job that writes to a fixed scratch or output root must remove that root before reuse so stale `.deb`, result JSON, cast, rendered-site, or staged-repo artifacts cannot satisfy checks; local phase verifiers must start by clearing their `.work/checkNN` root, and report-producing jobs must also clear `artifacts/`, `site/`, and any staged `port-root` they recreate
- safe-mode cast publication is part of the report contract: any recorded safe result must use a published relative `cast_path` under `casts/<library>/safe.cast`, and every renderer or publisher must copy the source `.cast` file into `site/casts/<library>/safe.cast` before verification or deployment
- every implement prompt in the final generated workflow must instruct the agent to finish the phase with exactly one git commit before yielding, because the review verifiers inspect `HEAD^..HEAD`

Validator-specific workflow rules:

- Phase 1 must verify the real GitHub library inventory with `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url`, check in both the raw repo-list snapshot and the filtered 23-library `port-*` subset under `inventory/`, and write `repositories.yml` from that verified 23-library scope. No later phase may replace that scope with a guessed subset.
- The workflow must treat the goal’s `repos-*` wording as a naming mismatch only after phase 1 proves that GitHub currently exposes the SafeLibs library family as `port-*`. The proof artifact must remain checked in for later phases to consume.
- `repositories.yml` must be a checked-in superset of `/home/yans/safelibs/apt-repo/repositories.yml`: copy the 17 tagged entries verbatim for `github_repo`, `ref`, and build data, then append the six untagged libraries pinned to the SHAs listed in Context.
- The six appended manifest entries are fixed, not inferred later:
  - `glib`: `github_repo: safelibs/port-glib`, `ref: 530f1e25df9491687ba5578904722602f69e1480`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
  - `libcurl`: `github_repo: safelibs/port-libcurl`, `ref: 2663317e76bc5db50e7f5e51da73b5808d36ba6e`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
  - `libexif`: `github_repo: safelibs/port-libexif`, `ref: 043cc14d44fa2ece8d52ded545d61e37539918d6`, `build: {mode: safe-debian, artifact_globs: ["*.deb"]}`
  - `libgcrypt`: `github_repo: safelibs/port-libgcrypt`, `ref: 946d1aaa8c691a848898bce17526550c9178a565`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
  - `libjansson`: `github_repo: safelibs/port-libjansson`, `ref: 2a003bb019cc9253550d8d43da0d3f0cb4282f04`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
  - `libuv`: `github_repo: safelibs/port-libuv`, `ref: 9e5d552c21af689e653335dba9e89d7cfd70e07b`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
- The same appended entries must also use fixed `validator.build_root` values: `glib -> original`, `libcurl -> original`, `libexif -> .`, `libgcrypt -> original/libgcrypt20-1.10.3`, `libjansson -> original/jansson-2.14`, and `libuv -> original`.
- Phase 1 must also create non-destructive staging tooling that can materialize the manifest-pinned `port-*` repos into a scratch root from either a local sibling-repo tree or authenticated GitHub access. The verifier must exercise both paths, including one tagged ref and one pinned-SHA ref through the GitHub clone path. Every later matrix verifier, the final verification sequence, and every GitHub Actions job must materialize the needed manifest-pinned repos into a fresh scratch root with `tools/stage_port_repos.py` before invoking `test.sh`; `/home/yans/safelibs` may appear only as a read-only `--source-root` input to that staging step, never as the active `--port-root` for test execution.
- Phase 1 must define and smoke-verify every manifest build path that later phases depend on: `safe-debian`, `checkout-artifacts`, explicit `mode: docker`, implicit default-to-docker when `mode` is omitted, and `source-debian-original`. Do not leave `libjson`, `libvips`, or `libzstd` build behavior implicit.
- Phase 1 must also make `repositories.yml` the checked-in import/build contract for later phases by proving the exact `inventory` keys and the exact per-library `validator` keys `harness_origin`, `sibling_repo`, `build_root`, `import_roots`, `import_excludes`, and `runtime_fixture_paths`. Later phases must not replace that contract with phase-local hardcoded source-path maps.
- Phase 1 must encode the exact ordered `validator.import_roots` lists listed in Phase 1 Implementation Details for all 23 libraries, including the mature-library `original/**/*` source roots enumerated in Context, the tracked `safe/generated/**/*` roots enumerated in Context for `libarchive` and `libsdl`, the tracked `safe/vendor/pyvips-3.1.1/**/*` root for `libvips`, `safe/debian/tests` for `libarchive`, `libbz2`, `libcsv`, `libjpeg-turbo`, `libjson`, `libsdl`, `libxml`, `libyaml`, and `libzstd`, `safe/docker` and `safe/scripts` for the mature libraries that actually ship those trees and still use them in validator, and the versioned `original/libgcrypt20-1.10.3/**` and `original/jansson-2.14/**` bootstrap roots. No later phase may consume a sibling-repo path that phase 1 did not declare there.
- Phase 1 must encode the exact ordered `validator.import_excludes` lists too: `liblzma` is the only non-empty case and must exclude `safe/tests/generated`; every other library must use `[]`.
- Phase 1 must define fixed `tools/import_port_assets.py` projection rules for every declared import root: fixture JSON goes under `tests/<library>/tests/fixtures/`, `safe/tests/package/**/*` goes under `tests/<library>/tests/package/`, remaining `safe/tests/**/*` or `safe/test/**/*` goes under `tests/<library>/tests/upstream/`, `safe/debian/tests/**/*` goes under `tests/<library>/tests/package/debian-tests/`, `safe/scripts/**/*` goes under `tests/<library>/tests/harness-source/scripts/`, `safe/docker/**/*` goes under `tests/<library>/tests/harness-source/docker/`, `safe/generated/**/*` goes under `tests/<library>/tests/harness-source/generated/`, `safe/vendor/**/*` goes under `tests/<library>/tests/harness-source/vendor/`, Debian control files go under `tests/<library>/tests/harness-source/debian/control`, bootstrap `original/debian/tests/**/*` goes under `tests/<library>/tests/upstream/debian-tests/`, and every other declared `original/**` import root preserves its path relative to `original/` under `tests/<library>/tests/upstream/`.
- Phase 1 must encode the tracked runtime fixture contract exactly, not as placeholder lists. For the current 23-library inventory every `validator.runtime_fixture_paths` value must be `[]`, because every tracked mature sibling input now arrives through declared `validator.import_roots` and every missing build-output path must be handled by later rewrite instructions instead of being smuggled into the runtime-fixture list.
- Phase 1 review must reject any `validator.import_roots` or `validator.runtime_fixture_paths` entry under missing build-output prefixes such as `original/build`, `original/build-step2`, `original/.libs`, or `original/libexif/.libs`.
- Phase 4 must rewrite the imported `libvips` upstream seeds into one exact runtime-only contract: the final `tests/libvips/tests/upstream/manifest.json` must contain exactly `wrappers: {shell: run-shell-suite.sh, pytest: run-pytest-suite.sh}`, `standalone_shell_tests: ["test/test_thumbnail.sh"]`, and `python_requirements: ["pyvips==3.1.1"]`; it must not keep `safe_build_dir_env`, `meson_tests`, or `fuzz_targets`, and the final tree must not contain `run-meson-suite.sh`, `run-fuzz-suite.sh`, `meson-tests.txt`, or `fuzz-targets.txt`.
- Phase 4 must rewrite `tests/libvips/tests/upstream/run-shell-suite.sh` and `run-pytest-suite.sh` into zero-argument runtime wrappers, and it must create `tests/libvips/tests/upstream/test/variables.sh` with fixed installed-package bindings. The final upstream and dependent `libvips` scripts must not reference `VIPS_SAFE_BUILD_DIR`, `build-check`, `build-check-install`, `build_and_install_safe_libvips`, `prepare_extracted_prefix`, `verify_packaged_prefix`, or `dpkg-buildpackage`.
- Later phases may depend only on:
  - checked-in outputs from earlier validator phases
  - read-only sibling repo inputs listed in this plan
  - phase-local scratch directories such as `.work/checkNN`, but only inside the implement/check phase that creates them
- No later phase may list `.work/**` as a required preexisting input unless an earlier implement phase explicitly created that exact checked-in artifact. In this plan, `.work/**` is scratch only.
- No later phase or GitHub workflow may pass `/home/yans/safelibs` directly as the active `port-root` to `test.sh` or `tools/build_safe_debs.py`; local verifiers may use it only as the read-only `tools/stage_port_repos.py --source-root` input, then must run against the resulting staged scratch root, and CI must do the same with GitHub clones when local siblings are unavailable.
- Public helper targets must be portable: checked-in `make stage-ports`, `make test`, and `make test-one` must default to clone-backed staging when `PORT_SOURCE_ROOT` is unset, and may pass `--source-root "$PORT_SOURCE_ROOT"` only when the caller explicitly opts into a local sibling checkout. Neither those helper targets nor the README may hard-code `/home/yans/safelibs`.
- Existing mature port artifacts must be consumed in place from sibling repos and copied into validator-owned paths; they must not be rediscovered from the network.
- Bootstrap libraries may create new validator-owned `dependents.json` and `relevant_cves.json` fixtures only because those inputs do not already exist in the sibling repos. Those new fixtures must be derived from the existing upstream source tree, Debian packaging metadata, and local Ubuntu package metadata, then checked into validator so later phases consume them in place.
- Validator must never mutate sibling `port-*` worktrees. Any build or import step that needs a writable tree must stage a copy under `.work/`.
- The final implement phase must create or connect the public GitHub repo `safelibs/validator`, push `main`, and leave an idempotent checked-in publication script behind. Publication cannot be left as a manual follow-up.

Generated workflow phase order:

1. `impl_01_inventory_scaffold`
2. `check_01_inventory_scaffold_smoke`
3. `check_01_inventory_scaffold_review`
4. `impl_02_shared_matrix_reporting`
5. `check_02_shared_matrix_reporting_smoke`
6. `check_02_shared_matrix_reporting_review`
7. `impl_03_text_data_validators`
8. `check_03_text_data_matrix`
9. `check_03_text_data_review`
10. `impl_04_media_validators`
11. `check_04_media_matrix`
12. `check_04_media_review`
13. `impl_05_archive_system_validators`
14. `check_05_archive_system_matrix`
15. `check_05_archive_system_review`
16. `impl_06_bootstrap_missing_validators`
17. `check_06_bootstrap_matrix`
18. `check_06_bootstrap_review`
19. `impl_07_ci_pages_publish`
20. `check_07_full_matrix`
21. `check_07_release_publish_review`

## Implementation Phases

### 1. Inventory, Manifest, and Scaffold

**Implement Phase ID**: `impl_01_inventory_scaffold`

**Verification Phases**

- `check_01_inventory_scaffold_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: prove the GitHub inventory, raw-to-filtered scope verification, both staging sources, every required build mode including the appended untagged `libexif` safe-debian case, and asset-import path normalization for upstream, package-smoke, harness-source, declared mature `original/**/*` roots, and versioned bootstrap inputs all work before any validator harness directories are added
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check01
    mkdir -p .work/check01
    python3 -m unittest unit.test_inventory unit.test_stage_port_repos unit.test_build_safe_debs unit.test_import_port_assets -v
    gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url > .work/check01/github-repo-list.json
    python3 tools/inventory.py --config repositories.yml --github-json .work/check01/github-repo-list.json --verify-scope
    python3 tools/stage_port_repos.py --config repositories.yml --libraries cjson giflib libarchive libpng libsdl libjson libvips libzstd libjansson libexif libtiff liblzma libgcrypt libxml libyaml --source-root /home/yans/safelibs --workspace .work/check01 --dest-root .work/check01/ports
    python3 tools/stage_port_repos.py --config repositories.yml --libraries giflib glib --workspace .work/check01 --dest-root .work/check01/ports-gh
    python3 tools/build_safe_debs.py --config repositories.yml --library giflib --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/giflib
    python3 tools/build_safe_debs.py --config repositories.yml --library libpng --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libpng
    python3 tools/build_safe_debs.py --config repositories.yml --library libjansson --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libjansson
    python3 tools/build_safe_debs.py --config repositories.yml --library libexif --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libexif
    python3 tools/build_safe_debs.py --config repositories.yml --library libjson --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libjson
    python3 tools/build_safe_debs.py --config repositories.yml --library libvips --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libvips
    python3 tools/build_safe_debs.py --config repositories.yml --library libzstd --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libzstd
    python3 tools/build_safe_debs.py --config repositories.yml --library giflib --port-root .work/check01/ports-gh --workspace .work/check01 --output .work/check01/debs-gh/giflib
    python3 tools/import_port_assets.py --config repositories.yml --library cjson --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library giflib --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libarchive --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libpng --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libsdl --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libexif --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libtiff --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libjson --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libvips --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library liblzma --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libzstd --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libgcrypt --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libjansson --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libxml --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library libyaml --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported
    python3 tools/import_port_assets.py --config repositories.yml --library glib --port-root .work/check01/ports-gh --workspace .work/check01 --dest-root .work/check01/imported
    test -n "$(find .work/check01/debs/giflib -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libpng -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libjansson -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libexif -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libjson -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libvips -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs/libzstd -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -n "$(find .work/check01/debs-gh/giflib -maxdepth 1 -type f -name '*.deb' -print -quit)"
    test -f .work/check01/imported/tests/cjson/tests/upstream/tests/parse_examples.c
    test -f .work/check01/imported/tests/cjson/tests/upstream/fuzzing/json.dict
    test -f .work/check01/imported/tests/giflib/tests/upstream/tests/public_api_regress.c
    test -f .work/check01/imported/tests/giflib/tests/upstream/pic/welcome2.gif
    test -f .work/check01/imported/tests/libarchive/tests/upstream/libarchive-3.7.2/libarchive/test/test_acl_nfs4.c
    test -f .work/check01/imported/tests/libarchive/tests/harness-source/generated/test_manifest.json
    test -f .work/check01/imported/tests/libarchive/tests/harness-source/generated/original_c_build/libarchive/test/list.h
    test -f .work/check01/imported/tests/libarchive/tests/harness-source/generated/original_pkgconfig/libarchive.pc
    test -f .work/check01/imported/tests/libarchive/tests/harness-source/generated/original_link_objects/examples/minitar.o
    test -f .work/check01/imported/tests/libpng/tests/upstream/tests/pngtest-all
    test -f .work/check01/imported/tests/libpng/tests/upstream/png.h
    test -f .work/check01/imported/tests/libsdl/tests/upstream/test/utf8.txt
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/dependent_regression_manifest.json
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/noninteractive_test_list.json
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/original_test_port_map.json
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/perf_workload_manifest.json
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/reports/perf-baseline-vs-safe.json
    test -f .work/check01/imported/tests/libsdl/tests/harness-source/generated/reports/perf-waivers.md
    test -f .work/check01/imported/tests/libexif/tests/upstream/libexif/exif-data.c
    test -f .work/check01/imported/tests/libexif/tests/upstream/test/test-extract.c
    test -f .work/check01/imported/tests/libtiff/tests/upstream/api_codec_smoke.c
    test -f .work/check01/imported/tests/libtiff/tests/upstream/test/images/rgb-3c-8b.tiff
    test -f .work/check01/imported/tests/libjson/tests/package/cmake-smoke/CMakeLists.txt
    test -f .work/check01/imported/tests/libjson/tests/package/debian-tests/unit-test
    test -f .work/check01/imported/tests/libvips/tests/upstream/manifest.json
    test -f .work/check01/imported/tests/libvips/tests/upstream/run-pytest-suite.sh
    test -f .work/check01/imported/tests/libvips/tests/upstream/run-shell-suite.sh
    test -f .work/check01/imported/tests/libvips/tests/upstream/standalone-shell-tests.txt
    test -f .work/check01/imported/tests/libvips/tests/upstream/test_thumbnail.sh
    test -f .work/check01/imported/tests/libvips/tests/upstream/test/test-suite/images/sample.jpg
    test -f .work/check01/imported/tests/libvips/tests/upstream/test/test_thumbnail.sh
    test -f .work/check01/imported/tests/libvips/tests/harness-source/vendor/pyvips-3.1.1/pyvips/__init__.py
    test ! -e .work/check01/imported/tests/libvips/tests/upstream/abi_layout.rs
    test ! -e .work/check01/imported/tests/libvips/tests/harness-source/scripts/run_release_gate.sh
    test -f .work/check01/imported/tests/liblzma/tests/fixtures/dependents.json
    test -f .work/check01/imported/tests/liblzma/tests/upstream/dependents/boost_iostreams_smoke.cpp
    test -f .work/check01/imported/tests/liblzma/tests/harness-source/docker/dependent-test.Dockerfile
    test -f .work/check01/imported/tests/liblzma/tests/harness-source/scripts/run-dependent-smokes.sh
    test ! -e .work/check01/imported/tests/liblzma/tests/upstream/generated
    test -f .work/check01/imported/tests/libzstd/tests/upstream/dependents/dependent_matrix.toml
    test -f .work/check01/imported/tests/libzstd/tests/upstream/libzstd-1.5.5+dfsg2/tests/zstreamtest.c
    test -f .work/check01/imported/tests/libgcrypt/tests/upstream/libgcrypt20-1.10.3/tests/basic.c
    test -f .work/check01/imported/tests/libgcrypt/tests/harness-source/debian/control
    test -f .work/check01/imported/tests/libjansson/tests/upstream/jansson-2.14/test/run-suites
    test -f .work/check01/imported/tests/libjansson/tests/upstream/jansson-2.14/test/scripts/run-tests.sh
    test -f .work/check01/imported/tests/libxml/tests/upstream/doc/examples/io1.c
    test -f .work/check01/imported/tests/libxml/tests/upstream/test/valid/REC-xml-19980210.xml
    test -f .work/check01/imported/tests/libyaml/tests/upstream/examples/anchors.yaml
    test -f .work/check01/imported/tests/libyaml/tests/upstream/tests/run-scanner.c
    test -f .work/check01/imported/tests/glib/tests/upstream/debian-tests/control
    ```

- `check_01_inventory_scaffold_review`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: review that validator now has checked-in raw and filtered inventory proofs, an exact manifest contract for later import/build phases including ordered import roots and excludes, verbatim mature build metadata, exact appended pinned-entry build metadata, and non-destructive staging/import/build tooling
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path
    import json
    import yaml

    expected = [
        "cjson", "giflib", "glib", "libarchive", "libbz2", "libcsv", "libcurl",
        "libexif", "libgcrypt", "libjansson", "libjpeg-turbo", "libjson",
        "liblzma", "libpng", "libsdl", "libsodium", "libtiff", "libuv",
        "libvips", "libwebp", "libxml", "libyaml", "libzstd",
    ]
    manifest = yaml.safe_load(Path("repositories.yml").read_text())
    inventory = manifest.get("inventory")
    if not isinstance(inventory, dict):
        raise SystemExit("missing inventory block")
    required_inventory = {
        "gh_repo_list_command": "gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url",
        "raw_snapshot": "inventory/github-repo-list.json",
        "filtered_snapshot": "inventory/github-port-repos.json",
        "goal_repo_family": "repos-*",
        "verified_repo_family": "port-*",
    }
    for key, value in required_inventory.items():
        if inventory.get(key) != value:
            raise SystemExit(f"inventory {key} mismatch: {inventory.get(key)!r}")
    if not inventory.get("verified_at"):
        raise SystemExit("inventory verified_at missing")
    names = [entry["name"] for entry in manifest["repositories"]]
    if names != expected:
        raise SystemExit(names)
    bootstrap = {"glib", "libcurl", "libgcrypt", "libjansson", "libuv"}
    mature_common = [
        "dependents.json",
        "relevant_cves.json",
        "test-original.sh",
        "safe/debian/control",
    ]
    expected_import_roots = {
        "cjson": mature_common + [
            "safe/tests",
            "safe/scripts",
            "original/tests",
            "original/fuzzing",
            "original/test.c",
            "original/cJSON.h",
            "original/cJSON_Utils.h",
        ],
        "giflib": mature_common + ["safe/tests", "original/tests", "original/pic", "original/gif_lib.h"],
        "glib": [
            "original/debian/control",
            "original/debian/tests",
            "original/tests",
            "original/glib/tests",
            "original/gio/tests",
            "original/gobject/tests",
            "original/fuzzing",
        ],
        "libarchive": mature_common + [
            "safe/tests",
            "safe/debian/tests",
            "safe/scripts",
            "safe/generated/api_inventory.json",
            "safe/generated/cve_matrix.json",
            "safe/generated/link_compat_manifest.json",
            "safe/generated/original_build_contract.json",
            "safe/generated/original_package_metadata.json",
            "safe/generated/original_c_build",
            "safe/generated/original_link_objects",
            "safe/generated/original_pkgconfig/libarchive.pc",
            "safe/generated/pkgconfig/libarchive.pc",
            "safe/generated/rust_test_manifest.json",
            "safe/generated/test_manifest.json",
            "original/libarchive-3.7.2",
        ],
        "libbz2": mature_common + ["safe/tests", "safe/debian/tests", "safe/scripts", "original"],
        "libcsv": mature_common + ["safe/tests", "safe/debian/tests", "original/examples", "original/test_csv.c", "original/csv.h"],
        "libcurl": ["original/debian/control", "original/debian/tests", "original/tests"],
        "libexif": mature_common + ["safe/tests", "original/libexif", "original/test", "original/contrib/examples"],
        "libgcrypt": ["original/libgcrypt20-1.10.3/debian/control", "original/libgcrypt20-1.10.3/tests"],
        "libjansson": [
            "original/jansson-2.14/debian/control",
            "original/jansson-2.14/test/bin",
            "original/jansson-2.14/test/run-suites",
            "original/jansson-2.14/test/scripts",
            "original/jansson-2.14/test/suites",
            "original/jansson-2.14/test/ossfuzz",
        ],
        "libjpeg-turbo": mature_common + ["safe/tests", "safe/debian/tests", "safe/scripts", "original/testimages"],
        "libjson": mature_common + ["safe/tests", "safe/debian/tests"],
        "liblzma": mature_common + ["safe/tests", "safe/docker", "safe/scripts"],
        "libpng": mature_common + [
            "safe/tests",
            "original/tests",
            "original/contrib/pngsuite",
            "original/contrib/testpngs",
            "original/png.h",
            "original/pngconf.h",
            "original/pngtest.png",
        ],
        "libsdl": mature_common + [
            "safe/tests",
            "safe/debian/tests",
            "safe/generated/dependent_regression_manifest.json",
            "safe/generated/noninteractive_test_list.json",
            "safe/generated/original_test_port_map.json",
            "safe/generated/perf_workload_manifest.json",
            "safe/generated/perf_thresholds.json",
            "safe/generated/reports/perf-baseline-vs-safe.json",
            "safe/generated/reports/perf-waivers.md",
            "original/test",
        ],
        "libsodium": mature_common + ["safe/tests", "safe/docker"],
        "libtiff": mature_common + ["safe/test", "safe/scripts", "original/test"],
        "libuv": ["original/debian/control", "original/test"],
        "libvips": mature_common + [
            "safe/tests/dependents",
            "safe/tests/upstream",
            "safe/vendor/pyvips-3.1.1",
            "original/test",
            "original/examples",
        ],
        "libwebp": mature_common + ["safe/tests", "original/examples", "original/tests/public_api_test.c"],
        "libxml": mature_common + ["safe/tests", "safe/debian/tests", "safe/scripts", "original"],
        "libyaml": mature_common + ["safe/tests", "safe/debian/tests", "safe/scripts", "original/include", "original/tests", "original/examples"],
        "libzstd": mature_common + ["safe/tests", "safe/debian/tests", "safe/docker", "safe/scripts", "original/libzstd-1.5.5+dfsg2"],
    }
    expected_import_excludes = {name: [] for name in expected}
    expected_import_excludes["liblzma"] = ["safe/tests/generated"]
    expected_build_roots = {name: "." for name in expected}
    expected_build_roots.update({
        "glib": "original",
        "libcurl": "original",
        "libgcrypt": "original/libgcrypt20-1.10.3",
        "libjansson": "original/jansson-2.14",
        "libuv": "original",
    })
    for entry in manifest["repositories"]:
        validator = entry.get("validator")
        if not isinstance(validator, dict):
            raise SystemExit(f"{entry['name']} missing validator block")
        required_validator_keys = [
            "harness_origin",
            "sibling_repo",
            "build_root",
            "import_roots",
            "import_excludes",
            "runtime_fixture_paths",
        ]
        missing = [key for key in required_validator_keys if key not in validator]
        if missing:
            raise SystemExit(f"{entry['name']} missing validator keys: {missing}")
        if validator["sibling_repo"] != f"port-{entry['name']}":
            raise SystemExit(f"{entry['name']} sibling_repo mismatch: {validator['sibling_repo']}")
        if not isinstance(validator["build_root"], str) or not validator["build_root"]:
            raise SystemExit(f"{entry['name']} build_root missing")
        if not isinstance(validator["import_roots"], list) or not validator["import_roots"]:
            raise SystemExit(f"{entry['name']} import_roots missing")
        if not isinstance(validator["import_excludes"], list):
            raise SystemExit(f"{entry['name']} import_excludes must be a list")
        if not isinstance(validator["runtime_fixture_paths"], list):
            raise SystemExit(f"{entry['name']} runtime_fixture_paths must be a list")
        expected_origin = "bootstrap-original-source" if entry["name"] in bootstrap else "existing-port-harness"
        if validator["harness_origin"] != expected_origin:
            raise SystemExit(f"{entry['name']} harness_origin mismatch: {validator['harness_origin']}")
    validator_by_name = {entry["name"]: entry["validator"] for entry in manifest["repositories"]}
    for name, validator in validator_by_name.items():
        if validator["build_root"] != expected_build_roots[name]:
            raise SystemExit(f"{name} build_root mismatch: {validator['build_root']!r}")
        if validator["runtime_fixture_paths"] != []:
            raise SystemExit(f"{name} runtime_fixture_paths mismatch: {validator['runtime_fixture_paths']!r}")
        if validator["import_roots"] != expected_import_roots[name]:
            raise SystemExit(f"{name} import_roots mismatch: {validator['import_roots']!r}")
        if validator["import_excludes"] != expected_import_excludes[name]:
            raise SystemExit(f"{name} import_excludes mismatch: {validator['import_excludes']!r}")
        for path in validator["import_roots"]:
            if (
                path.startswith("original/build")
                or path.startswith("original/build-step2")
                or path.startswith("original/.libs")
                or path.startswith("original/libexif/.libs")
            ):
                raise SystemExit(f"{name} import_roots contains forbidden build output: {path}")
    raw_inventory = json.loads(Path("inventory/github-repo-list.json").read_text())
    raw_port_names = sorted(
        item["name"].removeprefix("port-")
        for item in raw_inventory
        if item["name"].startswith("port-")
    )
    if raw_port_names != expected:
        raise SystemExit(raw_port_names)
    filtered_inventory = json.loads(Path("inventory/github-port-repos.json").read_text())
    filtered_port_names = sorted(item["name"].removeprefix("port-") for item in filtered_inventory)
    if filtered_port_names != expected:
        raise SystemExit(filtered_port_names)
    PY
    python3 - <<'PY'
    from pathlib import Path
    import yaml

    apt_manifest = yaml.safe_load(Path("/home/yans/safelibs/apt-repo/repositories.yml").read_text())
    validator_manifest = yaml.safe_load(Path("repositories.yml").read_text())
    apt_by_name = {entry["name"]: entry for entry in apt_manifest["repositories"]}
    validator_by_name = {entry["name"]: entry for entry in validator_manifest["repositories"]}

    copied_verbatim = [
        "cjson", "giflib", "libarchive", "libbz2", "libcsv", "libjpeg-turbo",
        "libjson", "liblzma", "libpng", "libsdl", "libsodium", "libtiff",
        "libvips", "libwebp", "libxml", "libyaml", "libzstd",
    ]
    for name in copied_verbatim:
        apt_entry = apt_by_name[name]
        validator_entry = validator_by_name[name]
        for field in ["github_repo", "ref", "build"]:
            if validator_entry[field] != apt_entry[field]:
                raise SystemExit(f"{name} {field} mismatch")
    expected_pinned = {
        "glib": {
            "github_repo": "safelibs/port-glib",
            "ref": "530f1e25df9491687ba5578904722602f69e1480",
            "build": {"mode": "source-debian-original", "artifact_globs": ["*.deb"]},
        },
        "libcurl": {
            "github_repo": "safelibs/port-libcurl",
            "ref": "2663317e76bc5db50e7f5e51da73b5808d36ba6e",
            "build": {"mode": "source-debian-original", "artifact_globs": ["*.deb"]},
        },
        "libexif": {
            "github_repo": "safelibs/port-libexif",
            "ref": "043cc14d44fa2ece8d52ded545d61e37539918d6",
            "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
        },
        "libgcrypt": {
            "github_repo": "safelibs/port-libgcrypt",
            "ref": "946d1aaa8c691a848898bce17526550c9178a565",
            "build": {"mode": "source-debian-original", "artifact_globs": ["*.deb"]},
        },
        "libjansson": {
            "github_repo": "safelibs/port-libjansson",
            "ref": "2a003bb019cc9253550d8d43da0d3f0cb4282f04",
            "build": {"mode": "source-debian-original", "artifact_globs": ["*.deb"]},
        },
        "libuv": {
            "github_repo": "safelibs/port-libuv",
            "ref": "9e5d552c21af689e653335dba9e89d7cfd70e07b",
            "build": {"mode": "source-debian-original", "artifact_globs": ["*.deb"]},
        },
    }
    for name, expected_entry in expected_pinned.items():
        validator_entry = validator_by_name.get(name)
        if validator_entry is None:
            raise SystemExit(f"missing pinned library: {name}")
        for field in ["github_repo", "ref", "build"]:
            if validator_entry[field] != expected_entry[field]:
                raise SystemExit(f"{name} {field} mismatch: {validator_entry[field]!r}")
    PY
    rg -n 'gh_repo_list_command|goal_repo_family|verified_repo_family|harness_origin' tools/inventory.py unit/test_inventory.py
    rg -n 'build_root|source-debian-original|validatorbootstrap1' tools/build_safe_debs.py
    rg -n 'import_roots|import_excludes|harness-source|debian-tests|runtime_fixture_paths' tools/import_port_assets.py
    ! rg -n 'reset --hard|clean -fdx' tools/inventory.py tools/stage_port_repos.py tools/build_safe_debs.py tools/import_port_assets.py
    ```

**Preexisting Inputs**

- `README.md`
- `/home/yans/safelibs/apt-repo/README.md`
- `/home/yans/safelibs/apt-repo/repositories.yml`
- `/home/yans/safelibs/apt-repo/tools/build_site.py`
- `/home/yans/safelibs/apt-repo/tests/test_build_site.py`
- authenticated access to `gh repo list safelibs` and `gh repo clone safelibs/port-*`
- all 23 local sibling `/home/yans/safelibs/port-*` repos

**New Outputs**

- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- validator-owned `repositories.yml` covering all 23 libraries
- inventory, staging, build, and import tooling under `tools/` that consume manifest-declared validator metadata
- Python unit tests under `unit/` for manifest loading, staging, build modes, and asset projection
- root scaffold files such as `.gitignore` and a `Makefile` skeleton

**File Changes**

- `.gitignore`
- `Makefile`
- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- `repositories.yml`
- `tools/__init__.py`
- `tools/inventory.py`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `tools/import_port_assets.py`
- `unit/__init__.py`
- `unit/test_inventory.py`
- `unit/test_stage_port_repos.py`
- `unit/test_build_safe_debs.py`
- `unit/test_import_port_assets.py`

**Implementation Details**

- Create `inventory/github-repo-list.json` as the checked-in raw snapshot from `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url`, and derive `inventory/github-port-repos.json` as the checked-in filtered 23-library `port-*` subset used by validator.
- Create `repositories.yml` as validator’s checked-in source of truth. Include:
  - an `inventory` mapping with exact keys `verified_at`, `gh_repo_list_command`, `raw_snapshot`, `filtered_snapshot`, `goal_repo_family`, and `verified_repo_family`
  - a `repositories` list in the exact 23-library order above
  - the 17 `apt-repo` entries copied verbatim for `github_repo`, `ref`, and build mode data
  - six appended pinned entries for `glib`, `libcurl`, `libexif`, `libgcrypt`, `libjansson`, and `libuv`
  - those six appended entries must use these exact `github_repo`, `ref`, and `build` mappings:
    - `glib`: `github_repo: safelibs/port-glib`, `ref: 530f1e25df9491687ba5578904722602f69e1480`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
    - `libcurl`: `github_repo: safelibs/port-libcurl`, `ref: 2663317e76bc5db50e7f5e51da73b5808d36ba6e`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
    - `libexif`: `github_repo: safelibs/port-libexif`, `ref: 043cc14d44fa2ece8d52ded545d61e37539918d6`, `build: {mode: safe-debian, artifact_globs: ["*.deb"]}`
    - `libgcrypt`: `github_repo: safelibs/port-libgcrypt`, `ref: 946d1aaa8c691a848898bce17526550c9178a565`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
    - `libjansson`: `github_repo: safelibs/port-libjansson`, `ref: 2a003bb019cc9253550d8d43da0d3f0cb4282f04`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
    - `libuv`: `github_repo: safelibs/port-libuv`, `ref: 9e5d552c21af689e653335dba9e89d7cfd70e07b`, `build: {mode: source-debian-original, artifact_globs: ["*.deb"]}`
  - those same appended entries must use these exact `validator.build_root` values so later phases never infer where packaging starts: `glib -> original`, `libcurl -> original`, `libexif -> .`, `libgcrypt -> original/libgcrypt20-1.10.3`, `libjansson -> original/jansson-2.14`, and `libuv -> original`
  - a `validator` mapping per library with exact keys `harness_origin`, `sibling_repo`, `build_root`, `import_roots`, `import_excludes`, and `runtime_fixture_paths`
  - `validator.harness_origin` set to `bootstrap-original-source` only for `glib`, `libcurl`, `libgcrypt`, `libjansson`, and `libuv`, and to `existing-port-harness` for the other 18 libraries
  - `validator.sibling_repo` stored as the repo directory name such as `port-libpng`, never as an absolute path
  - `validator.build_root` stored as a repo-relative path. It must be `.` for every existing-harness library, and the bootstrap-source libraries must use the fixed non-`.` values `glib -> original`, `libcurl -> original`, `libgcrypt -> original/libgcrypt20-1.10.3`, `libjansson -> original/jansson-2.14`, and `libuv -> original`
  - every existing-harness library must use the ordered common import roots `dependents.json`, `relevant_cves.json`, `test-original.sh`, and `safe/debian/control`, then append only these exact additional roots:
    - `cjson -> [safe/tests, safe/scripts, original/tests, original/fuzzing, original/test.c, original/cJSON.h, original/cJSON_Utils.h]`
    - `giflib -> [safe/tests, original/tests, original/pic, original/gif_lib.h]`
    - `libarchive -> [safe/tests, safe/debian/tests, safe/scripts, safe/generated/api_inventory.json, safe/generated/cve_matrix.json, safe/generated/link_compat_manifest.json, safe/generated/original_build_contract.json, safe/generated/original_package_metadata.json, safe/generated/original_c_build, safe/generated/original_link_objects, safe/generated/original_pkgconfig/libarchive.pc, safe/generated/pkgconfig/libarchive.pc, safe/generated/rust_test_manifest.json, safe/generated/test_manifest.json, original/libarchive-3.7.2]`
    - `libbz2 -> [safe/tests, safe/debian/tests, safe/scripts, original]`
    - `libcsv -> [safe/tests, safe/debian/tests, original/examples, original/test_csv.c, original/csv.h]`
    - `libexif -> [safe/tests, original/libexif, original/test, original/contrib/examples]`
    - `libjpeg-turbo -> [safe/tests, safe/debian/tests, safe/scripts, original/testimages]`
    - `libjson -> [safe/tests, safe/debian/tests]`
    - `liblzma -> [safe/tests, safe/docker, safe/scripts]`
    - `libpng -> [safe/tests, original/tests, original/contrib/pngsuite, original/contrib/testpngs, original/png.h, original/pngconf.h, original/pngtest.png]`
    - `libsdl -> [safe/tests, safe/debian/tests, safe/generated/dependent_regression_manifest.json, safe/generated/noninteractive_test_list.json, safe/generated/original_test_port_map.json, safe/generated/perf_workload_manifest.json, safe/generated/perf_thresholds.json, safe/generated/reports/perf-baseline-vs-safe.json, safe/generated/reports/perf-waivers.md, original/test]`
    - `libsodium -> [safe/tests, safe/docker]`
    - `libtiff -> [safe/test, safe/scripts, original/test]`
    - `libvips -> [safe/tests/dependents, safe/tests/upstream, safe/vendor/pyvips-3.1.1, original/test, original/examples]`
    - `libwebp -> [safe/tests, original/examples, original/tests/public_api_test.c]`
    - `libxml -> [safe/tests, safe/debian/tests, safe/scripts, original]`
    - `libyaml -> [safe/tests, safe/debian/tests, safe/scripts, original/include, original/tests, original/examples]`
    - `libzstd -> [safe/tests, safe/debian/tests, safe/docker, safe/scripts, original/libzstd-1.5.5+dfsg2]`
  - bootstrap libraries must use these exact ordered `validator.import_roots` lists:
    - `glib -> [original/debian/control, original/debian/tests, original/tests, original/glib/tests, original/gio/tests, original/gobject/tests, original/fuzzing]`
    - `libcurl -> [original/debian/control, original/debian/tests, original/tests]`
    - `libgcrypt -> [original/libgcrypt20-1.10.3/debian/control, original/libgcrypt20-1.10.3/tests]`
    - `libjansson -> [original/jansson-2.14/debian/control, original/jansson-2.14/test/bin, original/jansson-2.14/test/run-suites, original/jansson-2.14/test/scripts, original/jansson-2.14/test/suites, original/jansson-2.14/test/ossfuzz]`
    - `libuv -> [original/debian/control, original/test]`
  - `validator.import_excludes` must be `[]` for every library except `liblzma`, which must use exactly `["safe/tests/generated"]`
  - `validator.runtime_fixture_paths` must be `[]` for every current library because the tracked mature source inputs above are imported through `validator.import_roots` instead of an ad hoc runtime-fixture side channel
  - phase 1 must reject missing build-output roots from the manifest contract. The fixed non-importable cases are `libjson -> original/build/**/*`, `libtiff -> original/build/**/* and original/build-step2/**/*`, `libxml -> original/.libs/**/*`, and `libexif -> original/libexif/.libs/**/*`
  - `libjson` is still a fixed rewrite exception for this contract: phase 1 must keep its `validator.import_roots` limited to tracked package-smoke inputs and must not infer or add `original/build/*`
- Implement `tools/inventory.py` with typed dataclasses such as `LibraryConfig`, `BuildConfig`, and `InventoryRecord`, plus functions:
  - `load_manifest(path: Path) -> Manifest`
  - `load_github_inventory(path: Path) -> list[InventoryRecord]`
  - `filter_port_inventory(inventory: list[InventoryRecord]) -> list[InventoryRecord]`
  - `verify_scope(manifest: Manifest, inventory: list[InventoryRecord]) -> None`
  - `stage_read_only_source(entry: LibraryConfig, port_root: Path, workspace: Path) -> Path`
- Implement `tools/stage_port_repos.py` to materialize manifest-pinned `port-*` repos into a scratch root without mutating the source of truth. It must:
  - accept either a local sibling-repo root such as `/home/yans/safelibs` or authenticated GitHub access through `gh`
  - when `--source-root` is provided, copy from that local read-only sibling tree; when `--source-root` is omitted, clone `github_repo` into the requested destination root with `gh repo clone`
  - stage fresh detached copies at the manifest-pinned `ref` under a requested destination root, supporting both tag refs and pinned commit SHAs
  - refuse to reuse or mutate dirty sibling repos in place
  - provide the scratch `port-root` that later phases and GitHub Actions pass into build and import tooling
- Implement `tools/build_safe_debs.py` by adapting the manifest/build patterns in `apt-repo/tools/build_site.py`, but without destructive checkout updates. It must support:
  - existing build modes already used by mature ports: `safe-debian`, `checkout-artifacts`, explicit `mode: docker`, and the apt-repo default behavior where an omitted `mode` is treated as `docker`
  - the existing `SAFEAPTREPO_SOURCE`/`SAFEAPTREPO_OUTPUT` and `SAFEDEBREPO_SOURCE`/`SAFEDEBREPO_OUTPUT` environment contract so copied command-mode scripts from `libjson` and `libzstd` run unchanged inside validator
  - a new `source-debian-original` mode for bootstrap repos that resolves the source tree from `validator.build_root`, stages a writable copy under `.work/`, applies the exact validator-only Debian revision suffix `+validatorbootstrap1`, installs build-deps from Debian metadata, and emits `.deb` files to a requested output directory
  - Implement `tools/import_port_assets.py` to copy only manifest-declared harness source artifacts from staged sibling repos into validator-owned destinations. It must consume `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` directly, reject undeclared sibling-repo paths, normalize path variations like `safe/test/**/*` versus `safe/tests/**/*`, project top-level `dependents.json` and `relevant_cves.json` into `tests/<library>/tests/fixtures/`, project `test-original.sh` into `tests/<library>/tests/harness-source/original-test-script.sh`, project `safe/tests/package/**/*` into `tests/<library>/tests/package/**/*`, project the remaining `safe/tests/**/*` or `safe/test/**/*` into `tests/<library>/tests/upstream/**/*`, project `safe/debian/tests/**/*` into `tests/<library>/tests/package/debian-tests/**/*`, project `safe/scripts/**/*` into `tests/<library>/tests/harness-source/scripts/**/*`, project `safe/docker/**/*` into `tests/<library>/tests/harness-source/docker/**/*`, project `safe/generated/**/*` into `tests/<library>/tests/harness-source/generated/**/*`, project `safe/vendor/**/*` into `tests/<library>/tests/harness-source/vendor/**/*`, project imported Debian control files into `tests/<library>/tests/harness-source/debian/control`, project bootstrap `original/debian/tests/**/*` into `tests/<library>/tests/upstream/debian-tests/**/*`, project every other declared `original/**` import root into `tests/<library>/tests/upstream/<path relative to original/>`, keep `validator.runtime_fixture_paths` as an explicit but currently empty list-valued contract, and explicitly exclude transient inputs such as `.git/`, `.pc/`, `node_modules/`, `*.deb`, `safe/dist/`, and generated logs.
- `Makefile` should define at least `unit`, `inventory`, `stage-ports`, `build-safe`, and `clean` now; later phases extend it.

**Verification**

- Prove the 23-library scope against live GitHub inventory and the checked-in JSON snapshot.
- Prove the raw GitHub repo-list snapshot and the filtered 23-library subset stay aligned.
- Prove `repositories.yml` contains and the tooling consumes the exact `inventory` mapping, the exact `github_repo`/`ref`/`build` contract for all six appended entries, and the per-library `validator` mapping including the exact ordered `import_roots`, the exact ordered `import_excludes`, the all-empty `runtime_fixture_paths` contract, and the fixed missing-build-output rewrites that later phases rely on.
- Prove the non-destructive staging tool can supply a scratch `port-root` from both local sibling repos and authenticated GitHub clones without mutating sibling repos.
- Prove one tagged safe build, one appended pinned safe-debian build (`libexif`), one tagged checkout-artifact build, one explicit `mode: docker` build, one omitted-mode default-to-docker build, and one bootstrap build.
  - Prove `tools/import_port_assets.py` honors the declared projection rules for package tests, harness-source scripts, Docker inputs, generated-fixture inputs, vendored harness inputs, mature `original/**/*` source roots, and versioned bootstrap trees, and that `liblzma` keeps `safe/tests/generated` excluded via the manifest rather than phase-local guesswork.
- Prove the tooling never mutates sibling `port-*` worktrees.

### 2. Shared Matrix Runner, Common Harness Contract, and Reporting

**Implement Phase ID**: `impl_02_shared_matrix_reporting`

**Verification Phases**

- `check_02_shared_matrix_reporting_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_matrix_reporting`
  - purpose: prove the shared runner end to end, including the top-level CLI, safe-deb installation, trace propagation, failure-tolerant result emission, and site rendering, before real library harnesses are imported
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check02
    mkdir -p .work/check02
    python3 -m unittest unit.test_run_matrix unit.test_render_site -v
    python3 - <<'PY'
    from pathlib import Path
    import os
    import stat
    import subprocess
    import textwrap
    import yaml

    root = Path(".work/check02")
    ports = root / "ports"
    tests_root = root / "tests"
    packages_root = root / "packages"

    def write_executable(path: Path, content: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(textwrap.dedent(content))
        path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    for library, failing in [("demo-pass", False), ("demo-fail", True)]:
        repo_root = ports / f"port-{library}"
        repo_root.mkdir(parents=True, exist_ok=True)
        (repo_root / "placeholder").mkdir(parents=True, exist_ok=True)

        package_root = packages_root / library
        (package_root / "DEBIAN").mkdir(parents=True, exist_ok=True)
        (package_root / "opt" / "validator-demo").mkdir(parents=True, exist_ok=True)
        (package_root / "DEBIAN" / "control").write_text(textwrap.dedent(f"""\
            Package: validator-{library}
            Version: 1.0
            Section: misc
            Priority: optional
            Architecture: all
            Maintainer: SafeLibs <validator@example.com>
            Description: Validator smoke package for {library}
        """))
        (package_root / "opt" / "validator-demo" / f"{library}-replacement.txt").write_text("installed\n")
        subprocess.run(
            ["dpkg-deb", "--build", str(package_root), str(repo_root / f"{library}_1.0_all.deb")],
            check=True,
        )

        harness_root = tests_root / library
        write_executable(
            harness_root / "docker-entrypoint.sh",
            f"""\
            #!/usr/bin/env bash
            set -euo pipefail
            source /validator/tests/_shared/entrypoint.sh
            validator_entrypoint "/validator/tests/{library}/tests/run.sh" "$@"
            """,
        )
        write_executable(
            harness_root / "tests" / "run.sh",
            f"""\
            #!/usr/bin/env bash
            set -euo pipefail
            echo trace_{library.replace('-', '_')}
            if [ -f /opt/validator-demo/{library}-replacement.txt ]; then
              echo replacement_present
            else
              echo replacement_absent
            fi
            test -f /opt/validator-demo/base.txt
            {'exit 7' if failing else 'echo completed'}
            """,
        )
        (harness_root / "Dockerfile").write_text(textwrap.dedent(f"""\
            FROM ubuntu:24.04
            RUN mkdir -p /opt/validator-demo && printf 'base\\n' > /opt/validator-demo/base.txt
            COPY tests/_shared /validator/tests/_shared
            COPY .work/check02/tests/{library} /validator/tests/{library}
            ENTRYPOINT ["/validator/tests/{library}/docker-entrypoint.sh"]
        """))

    manifest = {
        "inventory": {
            "verified_at": "2026-04-07T00:00:00Z",
            "gh_repo_list_command": "synthetic-demo",
            "raw_snapshot": "inventory/demo.json",
            "filtered_snapshot": "inventory/demo-port.json",
            "goal_repo_family": "repos-*",
            "verified_repo_family": "port-*",
        },
        "repositories": [
            {
                "name": "demo-pass",
                "github_repo": "safelibs/port-demo-pass",
                "ref": "refs/heads/main",
                "build": {"mode": "checkout-artifacts", "workdir": ".", "artifact_globs": ["*.deb"]},
                "validator": {
                    "harness_origin": "existing-port-harness",
                    "sibling_repo": "port-demo-pass",
                    "build_root": ".",
                    "import_roots": ["placeholder"],
                    "import_excludes": [],
                    "runtime_fixture_paths": [],
                },
            },
            {
                "name": "demo-fail",
                "github_repo": "safelibs/port-demo-fail",
                "ref": "refs/heads/main",
                "build": {"mode": "checkout-artifacts", "workdir": ".", "artifact_globs": ["*.deb"]},
                "validator": {
                    "harness_origin": "existing-port-harness",
                    "sibling_repo": "port-demo-fail",
                    "build_root": ".",
                    "import_roots": ["placeholder"],
                    "import_excludes": [],
                    "runtime_fixture_paths": [],
                },
            }
        ],
    }
    Path(".work/check02/demo-repositories.yml").write_text(yaml.safe_dump(manifest, sort_keys=False))
    PY
    matrix_rc=0
    bash test.sh \
      --config .work/check02/demo-repositories.yml \
      --tests-root .work/check02/tests \
      --port-root .work/check02/ports \
      --artifact-root .work/check02/artifacts \
      --mode both \
      --record-casts \
      --library demo-pass \
      --library demo-fail || matrix_rc=$?
    python3 tools/render_site.py --results-root .work/check02/artifacts/results --artifacts-root .work/check02/artifacts --output-root .work/check02/site
    bash scripts/verify-site.sh --config .work/check02/demo-repositories.yml --results-root .work/check02/artifacts/results --site-root .work/check02/site --library demo-pass --library demo-fail --mode original --mode safe
    python3 - <<'PY'
    from pathlib import Path
    import json

    artifacts = Path(".work/check02/artifacts")
    expected = {
        ("demo-pass", "original"): ("passed", "archive-original", "replacement_absent", False),
        ("demo-pass", "safe"): ("passed", "safe-port", "replacement_present", True),
        ("demo-fail", "original"): ("failed", "archive-original", "replacement_absent", False),
        ("demo-fail", "safe"): ("failed", "safe-port", "replacement_present", True),
    }
    for (library, mode), (status, provenance, replacement_marker, traced) in expected.items():
        result_path = artifacts / "results" / library / f"{mode}.json"
        if not result_path.exists():
            raise SystemExit(f"missing result: {result_path}")
        result = json.loads(result_path.read_text())
        if result["status"] != status:
            raise SystemExit(f"{library} {mode} status mismatch: {result['status']!r}")
        if result["replacement_provenance"] != provenance:
            raise SystemExit(f"{library} {mode} provenance mismatch: {result['replacement_provenance']!r}")
        if (status == "passed" and result["exit_code"] != 0) or (status == "failed" and result["exit_code"] == 0):
            raise SystemExit(f"{library} {mode} exit_code mismatch: {result['exit_code']}")
        log_path = artifacts / result["log_path"]
        log_text = log_path.read_text()
        if replacement_marker not in log_text:
            raise SystemExit(f"{library} {mode} missing {replacement_marker} in {log_path}")
        trace_line = f"+ echo trace_{library.replace('-', '_')}"
        if traced and trace_line not in log_text:
            raise SystemExit(f"{library} {mode} missing traced log line")
        if not traced and trace_line in log_text:
            raise SystemExit(f"{library} {mode} unexpectedly traced")
        if mode == "safe":
            cast_path = artifacts / result["cast_path"]
            if not cast_path.exists():
                raise SystemExit(f"missing cast: {cast_path}")
            site_cast = Path(".work/check02/site") / result["cast_path"]
            if not site_cast.exists():
                raise SystemExit(f"missing published cast: {site_cast}")
    PY
    test "$matrix_rc" -ne 0
    ```

- `check_02_shared_matrix_reporting_review`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_matrix_reporting`
  - purpose: review that manifest-pinned scratch roots, portable clone-first helper targets, mode awareness, and publication paths are explicit, and that `VALIDATOR_TRACE` is the only runner-to-entrypoint trace signal
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    rg -n 'VALIDATOR_TRACE|validator_entrypoint|/safedebs|bash -x|asciinema|replacement_provenance|cast_path|site/casts|exit_code|tests-root' test.sh tools/run_matrix.py tools/render_site.py tests/_shared scripts/verify-site.sh
    rg -n '^stage-ports:|^test-one:|PORT_SOURCE_ROOT|\.work/ports|stage_port_repos.py|tests-root' Makefile test.sh tools/run_matrix.py
    ! rg -n '/home/yans/safelibs' Makefile test.sh tools/run_matrix.py
    python3 - <<'PY'
    from pathlib import Path
    required = [
        Path("test.sh"),
        Path("tools/run_matrix.py"),
        Path("tools/render_site.py"),
        Path("tests/_shared/common.sh"),
        Path("tests/_shared/install_safe_debs.sh"),
        Path("tests/_shared/entrypoint.sh"),
        Path("site-src/styles.css"),
        Path("site-src/script.js"),
        Path("site-src/index.html.template"),
        Path("site-src/library.html.template"),
        Path("scripts/verify-site.sh"),
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit(missing)
    PY
    ```

**Preexisting Inputs**

- outputs of phase 1
- `README.md`
- `/home/yans/safelibs/website/package.json`
- `/home/yans/safelibs/website/scripts/build.mjs`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`

**New Outputs**

- top-level matrix runner `test.sh`
- shared shell helpers under `tests/_shared/`
- result collection and site generation tools
- tracked site source templates and static assets
- unit tests for result rendering and matrix orchestration

**File Changes**

- `Makefile`
- `test.sh`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `unit/test_run_matrix.py`
- `unit/test_render_site.py`
- `tests/_shared/common.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/entrypoint.sh`
- `site-src/index.html.template`
- `site-src/library.html.template`
- `site-src/styles.css`
- `site-src/script.js`
- `scripts/verify-site.sh`

**Implementation Details**

- Extend `Makefile` with stable targets: `unit`, `stage-ports`, `test`, `test-one`, `render-site`, `verify-site`, and `clean`. `stage-ports` must refresh `.work/ports` via `tools/stage_port_repos.py --config repositories.yml --dest-root .work/ports`, adding `--source-root "$PORT_SOURCE_ROOT"` only when `PORT_SOURCE_ROOT` is non-empty; when `PORT_SOURCE_ROOT` is unset it must rely on authenticated GitHub clones so `make stage-ports`, `make test`, and `make test-one` work from a clean public checkout. `test` and `test-one` must call that staging step before invoking `bash test.sh --port-root .work/ports ...`.
- Implement `test.sh` as the single entrypoint for local and CI execution. Support:
  - `--config repositories.yml`
  - `--tests-root <path>` with default `tests`; this exists so phase-local smoke verifiers can point the shared runner at temporary harness fixtures before real checked-in library harnesses are imported
  - `--library <name>` as a repeatable flag; when omitted, run the full manifest order
  - `--mode original|safe|both`
  - `--port-root <path>`
  - `--artifact-root <dir>`
  - `--safe-deb-root <dir>` with a default under `<artifact-root>/debs`
  - `--record-casts`
  - exit with the aggregated matrix status from `tools/run_matrix.py` only after every requested `<library, mode>` pair has either produced its result artifacts or been marked failed in result JSON
  - treat `--port-root` as an already-staged manifest-pinned scratch root; when omitted, default to `.work/ports` only if that directory already exists, otherwise fail with a clear message pointing the caller to `tools/stage_port_repos.py` or `make stage-ports`. It must never silently fall back to `/home/yans/safelibs`.
- Implement `tools/run_matrix.py` with typed result objects such as `RunRequest` and `RunResult`. Concrete responsibilities:
  - in safe mode, call `tools/build_safe_debs.py` before container execution, write replacement packages to `<artifact-root>/debs/<library>/` or the configured safe-deb root, reuse that directory if it is already populated for the current library, and mount it at `/safedebs`
  - accept `--tests-root <path>` with default `tests` and resolve the harness for each requested library from `<tests-root>/<library>/`
  - invoke `docker build` with the repository root as the build context and `-f <tests-root>/<library>/Dockerfile` so both checked-in `tests/<library>` harnesses and phase-local smoke fixtures can `COPY` shared files from the same repo root
  - build `<tests-root>/<library>/Dockerfile`
  - run `<tests-root>/<library>/docker-entrypoint.sh`
  - mount `/safedebs` only in safe mode, after the replacement packages already exist on the host
  - pass `VALIDATOR_TRACE=1` into the container only for safe-mode runs that also enable `--record-casts`; pass `VALIDATOR_TRACE=0` for every other run. This boolean environment variable is the only runner-to-entrypoint tracing contract.
  - wrap safe-mode container execution in `asciinema rec` when `--record-casts` is enabled, while still relying on `VALIDATOR_TRACE=1` inside the container to select `bash -x`
  - emit `<artifact-root>/results/<library>/<mode>.json`, `<artifact-root>/logs/<library>/<mode>.log`, and `<artifact-root>/casts/<library>/safe.cast`
  - record `replacement_provenance` as `archive-original` for original-mode runs, `safe-port` for mature safe builds, and `bootstrap-original-source` for bootstrap safe builds
  - write one result JSON per requested `<library, mode>` pair even when package build, Docker image build, asciinema capture, or container execution fails; each result JSON must include at least `library`, `mode`, `status`, `replacement_provenance`, `exit_code`, `duration_seconds`, and `log_path`, and recorded safe runs must also include `cast_path`
  - use `status: passed` for successful runs and `status: failed` for any run that produced a terminal non-zero outcome after artifact capture; report rendering must consume those explicit statuses instead of inferring failure from missing files
  - never stop at the first failing library or mode; continue through the full requested matrix, flush all result JSON/log/cast artifacts that can be produced, and return a non-zero process exit only after the requested matrix is complete
  - require every caller to supply a staged scratch root via `--port-root` or by prepopulating `.work/ports` for `test.sh`; `tools/run_matrix.py` must never resolve live sibling repos itself
- Implement `tests/_shared/common.sh`, `tests/_shared/install_safe_debs.sh`, and `tests/_shared/entrypoint.sh` so every library harness follows one exact contract:
  - `tests/_shared/entrypoint.sh` must expose `validator_entrypoint <run_script>` and be the only container-side code allowed to inspect `VALIDATOR_TRACE`
  - `validator_entrypoint` must call `tests/_shared/install_safe_debs.sh` to install `/safedebs/*.deb` if present, then execute `<run_script>` under `bash -x` when `VALIDATOR_TRACE=1` and plain `bash` otherwise
  - every later `tests/<library>/docker-entrypoint.sh` must be a thin wrapper that sources `/validator/tests/_shared/entrypoint.sh` and calls `validator_entrypoint "/validator/tests/<library>/tests/run.sh" "$@"`
  - every later `tests/<library>/Dockerfile` must copy both `tests/_shared` and `tests/<library>` into `/validator/tests/` and set `ENTRYPOINT ["/validator/tests/<library>/docker-entrypoint.sh"]`
  - no library-local `Dockerfile`, `docker-entrypoint.sh`, or `tests/**/*` may inspect mode, `/safedebs`, `VALIDATOR_TRACE`, `bash -x`, or `asciinema`; all mode awareness lives in `tools/run_matrix.py` and `tests/_shared/entrypoint.sh`
  - assume the Docker image already contains the distro-packaged original library, so runtime harnesses never rebuild the library from source inside the container
- Implement `tools/render_site.py` to generate a static report site from JSON results. Write:
  - `site/index.html`
  - `site/libraries/<library>.html`
  - `site/report.json`
  - `site/casts/<library>/safe.cast` for every result JSON whose `cast_path` is `casts/<library>/safe.cast`
  - copied static assets from `site-src/`
- `tools/render_site.py` must accept `--results-root`, `--artifacts-root`, and `--output-root`; it must render passed and failed runs into the report, copy published cast files from `<artifacts-root>/casts/` into `site/casts/`, keep the HTML and `site/report.json` links aligned with the relative `cast_path`, and refuse only malformed input or missing artifacts that a result JSON explicitly claims exist
- `site/report.json` must carry every rendered run as explicit per-result data keyed by `library` and `mode` so verification can compare the exact rendered `<library, mode>` set against the expected coverage.
- Implement `scripts/verify-site.sh` to accept `--config <path>`, `--results-root <dir>`, `--site-root <dir>`, repeatable `--library <name>`, and repeatable `--mode <name>`. When `--library` is omitted it must derive the expected library set from `repositories.yml`; when `--mode` is omitted it must require both `original` and `safe`. The script must validate the generated site structure, the aggregate report JSON, the copied safe-mode cast files and links whenever a result JSON declares `cast_path`, and the exact expected `<library, mode>` coverage across both raw result JSON files and `site/report.json`, failing on any missing or unexpected pair.

**Verification**

- Prove `bash test.sh` drives `tools/run_matrix.py` end to end against a phase-local two-library smoke manifest before real library harnesses are added.
- Prove the matrix runner continues after an individual run fails, writes explicit failing result JSON, and returns a non-zero exit only after the requested matrix is complete.
- Prove safe smoke runs install generated `.deb` fixtures, propagate `VALIDATOR_TRACE=1` only when cast recording is enabled, and still publish copied `site/casts/<library>/safe.cast` files even when one smoke library fails.
- Prove the renderer copies recorded safe-mode casts into `site/casts/` and that the published links match the `cast_path` values stored in results.
- Prove `scripts/verify-site.sh` enforces exact expected `<library, mode>` coverage from a provided config and result set.
- The review verifier must prove that manifest-pinned staging, `/safedebs`, `VALIDATOR_TRACE`, and all other mode-aware logic live only in the shared runner/entrypoint layer.

### 3. Import Existing Text and Data Validators

**Implement Phase ID**: `impl_03_text_data_validators`

**Verification Phases**

- `check_03_text_data_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_03_text_data_validators`
  - purpose: run the first batch of real library validators in both modes
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check03
    mkdir -p .work/check03
    python3 tools/stage_port_repos.py --config repositories.yml --libraries cjson giflib libcsv libjson libxml libyaml --source-root /home/yans/safelibs --workspace .work/check03 --dest-root .work/check03/ports
    matrix_rc=0
    bash test.sh --port-root .work/check03/ports --artifact-root .work/check03/artifacts --mode both --record-casts \
      --library cjson \
      --library giflib \
      --library libcsv \
      --library libjson \
      --library libxml \
      --library libyaml || matrix_rc=$?
    python3 tools/render_site.py --results-root .work/check03/artifacts/results --artifacts-root .work/check03/artifacts --output-root .work/check03/site
    bash scripts/verify-site.sh --config repositories.yml --results-root .work/check03/artifacts/results --site-root .work/check03/site --library cjson --library giflib --library libcsv --library libjson --library libxml --library libyaml --mode original --mode safe
    exit "$matrix_rc"
    ```

- `check_03_text_data_review`
  - type: `check`
  - fixed `bounce_target`: `impl_03_text_data_validators`
  - purpose: review that imported test trees are complete, that Dockerfiles and entrypoints delegate to the shared contract, and that validator-authored harness glue stays mode-blind without rejecting unrelated `mode` identifiers inside imported upstream sources
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["cjson", "giflib", "libcsv", "libjson", "libxml", "libyaml"]
    for lib in libraries:
        root = Path("tests") / lib
        required = [
            root / "Dockerfile",
            root / "docker-entrypoint.sh",
            root / "tests" / "run.sh",
            root / "tests" / "fixtures" / "dependents.json",
            root / "tests" / "fixtures" / "relevant_cves.json",
        ]
        missing = [str(path) for path in required if not path.exists()]
        if missing:
            raise SystemExit(f"{lib}: {missing}")
        dockerfile = (root / "Dockerfile").read_text()
        for token in [
            "COPY tests/_shared /validator/tests/_shared",
            f"COPY tests/{lib} /validator/tests/{lib}",
            f'ENTRYPOINT ["/validator/tests/{lib}/docker-entrypoint.sh"]',
        ]:
            if token not in dockerfile:
                raise SystemExit(f"{lib} Dockerfile missing: {token}")
        entrypoint = (root / "docker-entrypoint.sh").read_text()
        for token in [
            "source /validator/tests/_shared/entrypoint.sh",
            f'validator_entrypoint "/validator/tests/{lib}/tests/run.sh"',
        ]:
            if token not in entrypoint:
                raise SystemExit(f"{lib} docker-entrypoint.sh missing: {token}")
    PY
    python3 - <<'PY'
    from pathlib import Path
    import re

    libraries = ["cjson", "giflib", "libcsv", "libjson", "libxml", "libyaml"]
    forbidden_literals = ["/safedebs", "SAFE_MODE", "ORIGINAL_MODE", "IMPLEMENTATION=", "VALIDATOR_TRACE", "bash -x", "asciinema"]
    forbidden_patterns = [
        re.compile(r'==\s*["\'](?:safe|original)["\']'),
        re.compile(r'!=\s*["\'](?:safe|original)["\']'),
        re.compile(r'\b(?:mode|package_mode|implementation)\b\s*=\s*["\'](?:safe|original)["\']'),
    ]
    excluded_roots = {"upstream", "dependents", "cve", "fixtures", "package"}
    for lib in libraries:
        root = Path("tests") / lib
        candidate_paths = [root / "Dockerfile", root / "docker-entrypoint.sh", root / "tests" / "run.sh"]
        for path in (root / "tests").rglob("*"):
            if not path.is_file() or path.stat().st_size > 200_000:
                continue
            rel = path.relative_to(root / "tests")
            if rel.parts and rel.parts[0] in excluded_roots:
                continue
            candidate_paths.append(path)
        seen = set()
        for path in candidate_paths:
            if path in seen or not path.exists():
                continue
            seen.add(path)
            text = path.read_text(errors="ignore")
            if any(token in text for token in forbidden_literals):
                raise SystemExit(f"mode-aware literal in {path}")
            if any(pattern.search(text) for pattern in forbidden_patterns):
                raise SystemExit(f"mode-aware branch in {path}")
    PY
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["cjson", "giflib", "libcsv", "libjson", "libxml", "libyaml"]
    for lib in libraries:
        for fixture in ["dependents.json", "relevant_cves.json"]:
            copied = Path("tests") / lib / "tests" / "fixtures" / fixture
            source = Path("/home/yans/safelibs") / f"port-{lib}" / fixture
            if copied.read_bytes() != source.read_bytes():
                raise SystemExit(f"{lib} fixture mismatch: {fixture}")
    PY
    ```

**Preexisting Inputs**

- outputs of phases 1 and 2
- read-only sibling repos `/home/yans/safelibs/port-cjson`, `/home/yans/safelibs/port-giflib`, `/home/yans/safelibs/port-libcsv`, `/home/yans/safelibs/port-libjson`, `/home/yans/safelibs/port-libxml`, and `/home/yans/safelibs/port-libyaml`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- only the phase-1-declared `validator.import_roots` for those six libraries; no other sibling-repo path is a valid phase-3 input

**New Outputs**

- complete validator harness directories for `cjson`, `giflib`, `libcsv`, `libjson`, `libxml`, and `libyaml`

**File Changes**

- `tests/cjson/**`
- `tests/giflib/**`
- `tests/libcsv/**`
- `tests/libjson/**`
- `tests/libxml/**`
- `tests/libyaml/**`

**Implementation Details**

- For every library in this phase, create:
  - `tests/<library>/Dockerfile`
  - `tests/<library>/docker-entrypoint.sh`
  - `tests/<library>/tests/run.sh`
  - `tests/<library>/tests/fixtures/dependents.json`
  - `tests/<library>/tests/fixtures/relevant_cves.json`
  - imported upstream/dependent/regression assets under `tests/<library>/tests/`
- Use `tools/import_port_assets.py` plus the phase-1 `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` manifest metadata to copy tracked assets into validator-owned paths, then hand-normalize them into a consistent layout:
  - `tests/upstream/` for copied upstream suites
  - `tests/dependents/` for real-application smokes
  - `tests/cve/` for retained regression cases
  - `tests/package/` for copied package-surface compile/install smokes and Debian autopkgtests from `safe/tests/package/**/*` or `safe/debian/tests/**/*`
  - `tests/fixtures/` for inventories and static data
- The phase-3 imports are fixed by library:
  - `cjson` must consume only `safe/tests`, `safe/scripts`, `original/tests`, `original/fuzzing`, `original/test.c`, `original/cJSON.h`, and `original/cJSON_Utils.h`
  - `giflib` must consume only `safe/tests`, `original/tests`, `original/pic`, and `original/gif_lib.h`
  - `libcsv` must consume only `safe/tests`, `safe/debian/tests`, `original/examples`, `original/test_csv.c`, and `original/csv.h`
  - `libjson` must consume only `safe/tests` and `safe/debian/tests`
  - `libxml` must consume only `safe/tests`, `safe/debian/tests`, `safe/scripts`, and `original`
  - `libyaml` must consume only `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/include`, `original/tests`, and `original/examples`
- Derive each `Dockerfile` from the corresponding `port-<lib>/test-original.sh` package install list and build/runtime expectations, but remove host-repo assumptions. The build context must be the validator repo only.
- Translate library-specific host logic from the original scripts into `tests/<library>/tests/run.sh`, keeping the shared `/safedebs` install logic and `VALIDATOR_TRACE` handling entirely inside the phase-2 shared entrypoint contract.
- The batch-specific rewrites are fixed too:
  - `cjson` must compile copied original test and fuzz inputs against the installed distro or replacement package inside the container; it must not call back into sibling `original/` paths after import
  - `giflib` must run its copied `original/tests` and `original/pic` corpora from the validator tree rather than referencing sibling-repo paths
  - `libcsv` must compile copied `original/examples` and `original/test_csv.c` sources against the installed package surface rather than building from a sibling worktree
  - `libjson` must replace the missing `original/build/*` baseline with validator-owned package-surface coverage built from copied `safe/tests/package/**/*` assets plus copied `safe/debian/tests/unit-test`
  - `libxml` must rewrite any current expectation of `original/.libs/**/*` or `safe/target/stage/**/*` so helper binaries compile against installed package headers and run from copied `original/**` fixtures
  - `libyaml` must compile copied `original/tests` and `original/examples` sources against the installed package surface rather than assuming a sibling-repo build tree
- Remove any runtime source-build steps from the translated harnesses. Original mode must execute against distro-packaged libraries baked into the image, and safe mode must execute against the same image after `/safedebs` is installed by the shared entrypoint.
- Preserve existing inventories and CVE selections exactly by byte-identical copies of the sibling repo JSON files into validator-owned fixtures instead of regenerating or reformatting them.

**Verification**

- Each imported library must pass both original and safe runs through `test.sh`.
- Review must prove every library has the required harness layout, that each `Dockerfile` and `docker-entrypoint.sh` delegates to the shared contract, that validator-authored harness glue is mode-blind, and that `dependents.json` and `relevant_cves.json` remain byte-identical to the sibling repo fixtures.

### 4. Import Existing Media and Imaging Validators

**Implement Phase ID**: `impl_04_media_validators`

**Verification Phases**

- `check_04_media_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: run the second batch of real library validators in both modes
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check04
    mkdir -p .work/check04
    python3 tools/stage_port_repos.py --config repositories.yml --libraries libexif libjpeg-turbo libpng libtiff libvips libwebp --source-root /home/yans/safelibs --workspace .work/check04 --dest-root .work/check04/ports
    matrix_rc=0
    bash test.sh --port-root .work/check04/ports --artifact-root .work/check04/artifacts --mode both --record-casts \
      --library libexif \
      --library libjpeg-turbo \
      --library libpng \
      --library libtiff \
      --library libvips \
      --library libwebp || matrix_rc=$?
    python3 tools/render_site.py --results-root .work/check04/artifacts/results --artifacts-root .work/check04/artifacts --output-root .work/check04/site
    bash scripts/verify-site.sh --config repositories.yml --results-root .work/check04/artifacts/results --site-root .work/check04/site --library libexif --library libjpeg-turbo --library libpng --library libtiff --library libvips --library libwebp --mode original --mode safe
    exit "$matrix_rc"
    ```

- `check_04_media_review`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: review that the media-library path variants and fixtures were normalized into the shared Dockerfile and entrypoint contract without adding mode awareness to validator-authored harness glue, and that `libvips` was narrowed to the exact installed-package-only upstream and dependent runtime subset
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path
    import json

    libraries = ["libexif", "libjpeg-turbo", "libpng", "libtiff", "libvips", "libwebp"]
    for lib in libraries:
        root = Path("tests") / lib
        required = [
            root / "Dockerfile",
            root / "docker-entrypoint.sh",
            root / "tests" / "run.sh",
            root / "tests" / "fixtures" / "dependents.json",
            root / "tests" / "fixtures" / "relevant_cves.json",
        ]
        missing = [str(path) for path in required if not path.exists()]
        if missing:
            raise SystemExit(f"{lib}: {missing}")
        dockerfile = (root / "Dockerfile").read_text()
        for token in [
            "COPY tests/_shared /validator/tests/_shared",
            f"COPY tests/{lib} /validator/tests/{lib}",
            f'ENTRYPOINT ["/validator/tests/{lib}/docker-entrypoint.sh"]',
        ]:
            if token not in dockerfile:
                raise SystemExit(f"{lib} Dockerfile missing: {token}")
        entrypoint = (root / "docker-entrypoint.sh").read_text()
        for token in [
            "source /validator/tests/_shared/entrypoint.sh",
            f'validator_entrypoint "/validator/tests/{lib}/tests/run.sh"',
        ]:
            if token not in entrypoint:
                raise SystemExit(f"{lib} docker-entrypoint.sh missing: {token}")
    if not (Path("tests/libtiff/tests/upstream").exists()):
        raise SystemExit("libtiff upstream import missing")
    if not (Path("tests/libvips/tests/dependents").exists()):
        raise SystemExit("libvips dependents import missing")
    if not (Path("tests/libvips/tests/harness-source/vendor/pyvips-3.1.1/pyvips/__init__.py").exists()):
        raise SystemExit("libvips vendored pyvips import missing")
    libvips_manifest = json.loads(Path("tests/libvips/tests/upstream/manifest.json").read_text())
    if libvips_manifest.get("wrappers") != {
        "shell": "run-shell-suite.sh",
        "pytest": "run-pytest-suite.sh",
    }:
        raise SystemExit(f"unexpected libvips wrappers: {libvips_manifest.get('wrappers')!r}")
    if libvips_manifest.get("standalone_shell_tests") != ["test/test_thumbnail.sh"]:
        raise SystemExit(
            f"unexpected libvips standalone_shell_tests: {libvips_manifest.get('standalone_shell_tests')!r}"
        )
    if libvips_manifest.get("python_requirements") != ["pyvips==3.1.1"]:
        raise SystemExit(
            f"unexpected libvips python_requirements: {libvips_manifest.get('python_requirements')!r}"
        )
    for forbidden_key in ["safe_build_dir_env", "meson_tests", "fuzz_targets"]:
        if forbidden_key in libvips_manifest:
            raise SystemExit(f"unexpected libvips manifest key: {forbidden_key}")
    variables = Path("tests/libvips/tests/upstream/test/variables.sh").read_text()
    for token in [
        "/validator/tests/libvips/tests/upstream/test/test-suite/images",
        "command -v vips",
        "command -v vipsthumbnail",
        "command -v vipsheader",
    ]:
        if token not in variables:
            raise SystemExit(f"libvips variables.sh missing token: {token}")
    for token in ["@abs_top_srcdir@", "@abs_top_builddir@", "/tools/vips", "VIPS_SAFE_BUILD_DIR"]:
        if token in variables:
            raise SystemExit(f"libvips variables.sh kept build-tree token: {token}")
    forbidden_libvips_paths = [
        Path("tests/libvips/tests/abi_layout.rs"),
        Path("tests/libvips/tests/init_version_smoke.rs"),
        Path("tests/libvips/tests/operation_registry.rs"),
        Path("tests/libvips/tests/ops_advanced.rs"),
        Path("tests/libvips/tests/ops_core.rs"),
        Path("tests/libvips/tests/runtime_io.rs"),
        Path("tests/libvips/tests/security.rs"),
        Path("tests/libvips/tests/threading.rs"),
        Path("tests/libvips/tests/harness-source/scripts"),
        Path("tests/libvips/tests/upstream/run-meson-suite.sh"),
        Path("tests/libvips/tests/upstream/run-fuzz-suite.sh"),
        Path("tests/libvips/tests/upstream/meson-tests.txt"),
        Path("tests/libvips/tests/upstream/fuzz-targets.txt"),
    ]
    for path in forbidden_libvips_paths:
        if path.exists():
            raise SystemExit(f"unexpected libvips source-build import: {path}")
    for path in [
        Path("tests/libvips/tests/upstream/run-shell-suite.sh"),
        Path("tests/libvips/tests/upstream/run-pytest-suite.sh"),
        Path("tests/libvips/tests/dependents/run-suite.sh"),
        Path("tests/libvips/tests/dependents/lib.sh"),
    ]:
        text = path.read_text(errors="ignore")
        for token in [
            "VIPS_SAFE_BUILD_DIR",
            "build-check-install",
            "build-check/",
            "build_and_install_safe_libvips",
            "prepare_extracted_prefix",
            "verify_packaged_prefix",
            "dpkg-buildpackage",
            "resolve_build_dir",
        ]:
            if token in text:
                raise SystemExit(f"libvips runtime script kept build-tree token {token!r} in {path}")
    if (Path("tests/libpng/tests/generated").exists()):
        raise SystemExit("unexpected generated artifact import: tests/libpng/tests/generated")
    PY
    python3 - <<'PY'
    from pathlib import Path
    import re

    libraries = ["libexif", "libjpeg-turbo", "libpng", "libtiff", "libvips", "libwebp"]
    forbidden_literals = ["/safedebs", "SAFE_MODE", "ORIGINAL_MODE", "IMPLEMENTATION=", "VALIDATOR_TRACE", "bash -x", "asciinema"]
    forbidden_patterns = [
        re.compile(r'==\s*["\'](?:safe|original)["\']'),
        re.compile(r'!=\s*["\'](?:safe|original)["\']'),
        re.compile(r'\b(?:mode|package_mode|implementation)\b\s*=\s*["\'](?:safe|original)["\']'),
    ]
    excluded_roots = {"upstream", "dependents", "cve", "fixtures", "package"}
    for lib in libraries:
        root = Path("tests") / lib
        candidate_paths = [root / "Dockerfile", root / "docker-entrypoint.sh", root / "tests" / "run.sh"]
        for path in (root / "tests").rglob("*"):
            if not path.is_file() or path.stat().st_size > 200_000:
                continue
            rel = path.relative_to(root / "tests")
            if rel.parts and rel.parts[0] in excluded_roots:
                continue
            candidate_paths.append(path)
        seen = set()
        for path in candidate_paths:
            if path in seen or not path.exists():
                continue
            seen.add(path)
            text = path.read_text(errors="ignore")
            if any(token in text for token in forbidden_literals):
                raise SystemExit(f"mode-aware literal in {path}")
            if any(pattern.search(text) for pattern in forbidden_patterns):
                raise SystemExit(f"mode-aware branch in {path}")
    PY
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["libexif", "libjpeg-turbo", "libpng", "libtiff", "libvips", "libwebp"]
    for lib in libraries:
        for fixture in ["dependents.json", "relevant_cves.json"]:
            copied = Path("tests") / lib / "tests" / "fixtures" / fixture
            source = Path("/home/yans/safelibs") / f"port-{lib}" / fixture
            if copied.read_bytes() != source.read_bytes():
                raise SystemExit(f"{lib} fixture mismatch: {fixture}")
    PY
    ```

**Preexisting Inputs**

- outputs of phases 1 and 2
- read-only sibling repos `/home/yans/safelibs/port-libexif`, `/home/yans/safelibs/port-libjpeg-turbo`, `/home/yans/safelibs/port-libpng`, `/home/yans/safelibs/port-libtiff`, `/home/yans/safelibs/port-libvips`, and `/home/yans/safelibs/port-libwebp`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- only the phase-1-declared `validator.import_roots` for those six libraries; no other sibling-repo path is a valid phase-4 input

**New Outputs**

- complete validator harness directories for `libexif`, `libjpeg-turbo`, `libpng`, `libtiff`, `libvips`, and `libwebp`

**File Changes**

- `tests/libexif/**`
- `tests/libjpeg-turbo/**`
- `tests/libpng/**`
- `tests/libtiff/**`
- `tests/libvips/**`
- `tests/libwebp/**`

**Implementation Details**

- Normalize the notable path and layout exceptions in this batch:
  - `libtiff` imports from `safe/test/**/*`, not `safe/tests/**/*`
  - `libvips` already has a reusable dependent-suite subtree under `safe/tests/dependents/**/*`, but validator must keep only the imported dependent and upstream wrappers plus the vendored `pyvips` snapshot rather than the sibling repo’s full safe crate
  - `libpng` currently hard-codes original and safe image assembly in one shell script and needs to be split cleanly into validator `Dockerfile` + shared entrypoint + `tests/run.sh`
  - `libexif` is untagged in `apt-repo` but already has mature validator artifacts, so it must be handled like an existing-harness library, not a bootstrap library
- Preserve existing fixture JSON by byte-identical copies from the sibling repos, preserve regression assets exactly, and drive imports from the phase-1 `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` metadata so the checked-in validator tree is the only runtime build context.
- The phase-4 imports are fixed by library:
  - `libexif` must consume only `safe/tests`, `original/libexif`, `original/test`, and `original/contrib/examples`
  - `libjpeg-turbo` must consume only `safe/tests`, `safe/debian/tests`, `safe/scripts`, and `original/testimages`
  - `libpng` must consume only `safe/tests`, `original/tests`, `original/contrib/pngsuite`, `original/contrib/testpngs`, `original/png.h`, `original/pngconf.h`, and `original/pngtest.png`
  - `libtiff` must consume only `safe/test`, `safe/scripts`, and `original/test`
  - `libvips` must consume only `safe/tests/dependents`, `safe/tests/upstream`, `safe/vendor/pyvips-3.1.1`, `original/test`, and `original/examples`
  - `libwebp` must consume only `safe/tests`, `original/examples`, and `original/tests/public_api_test.c`
- Libraries in this batch that already ship tracked package-smoke assets under `safe/debian/tests/**/*` must preserve them under `tests/<library>/tests/package/debian-tests/**/*` rather than dropping them during import; `libjpeg-turbo` is the explicit case in this phase.
- The batch-specific rewrites are fixed too:
  - `libexif` must rewrite any current expectation of `original/libexif/.libs/**/*` or `original/test/*.o` so copied source files compile against installed package headers and libraries instead
  - `libjpeg-turbo` must use copied `original/testimages/**/*` samples only and must not depend on safe-side stage directories outside the validator tree
  - `libpng` must replace the current safe-stage and original-stage logic with validator-owned copies of the declared original headers, scripts, and sample corpora
  - `libtiff` must rewrite all current expectations of `original/build/**/*` and `original/build-step2/**/*` to use installed-package tools plus copied `original/test/**/*` fixtures
  - `libvips` must intentionally narrow the sibling harness into one exact runtime-only validator contract. Keep only the imported dependent-suite sources, the imported upstream seed files, the vendored `tests/harness-source/vendor/pyvips-3.1.1/**/*` snapshot, and the copied `tests/upstream/test/**/*` and `tests/upstream/examples/**/*` assets. Discard the sibling-only build-source inputs `safe/tests/abi_layout.rs`, `safe/tests/init_version_smoke.rs`, `safe/tests/operation_registry.rs`, `safe/tests/ops_advanced.rs`, `safe/tests/ops_core.rs`, `safe/tests/runtime_io.rs`, `safe/tests/security.rs`, `safe/tests/security/**/*`, `safe/tests/threading.rs`, `safe/tests/introspection/**/*`, `safe/tests/link_compat/**/*`, all `safe/scripts/**/*`, and the imported upstream seed files `tests/libvips/tests/upstream/run-meson-suite.sh`, `tests/libvips/tests/upstream/run-fuzz-suite.sh`, `tests/libvips/tests/upstream/meson-tests.txt`, and `tests/libvips/tests/upstream/fuzz-targets.txt`.
  - `libvips` must rewrite `tests/libvips/tests/upstream/manifest.json` into a validator-owned runtime manifest with exactly `wrappers: {"shell": "run-shell-suite.sh", "pytest": "run-pytest-suite.sh"}`, exactly `standalone_shell_tests: ["test/test_thumbnail.sh"]`, and exactly `python_requirements: ["pyvips==3.1.1"]`. The final manifest must not retain `safe_build_dir_env`, `meson_tests`, or `fuzz_targets`.
  - `libvips` must rewrite `tests/libvips/tests/upstream/run-shell-suite.sh` and `tests/libvips/tests/upstream/run-pytest-suite.sh` into zero-argument runtime wrappers. They must operate entirely inside the validator tree, assume libvips is already installed in the container, read copied upstream fixtures from `tests/libvips/tests/upstream/test/**/*`, source vendored `pyvips` from `tests/libvips/tests/harness-source/vendor/pyvips-3.1.1`, and never reference sibling `original/`, `build-check/`, `build-check-install/`, or `VIPS_SAFE_BUILD_DIR` state.
  - `libvips` must create `tests/libvips/tests/upstream/test/variables.sh` from the copied `original/test/variables.sh.in` template contract. The generated file must bind `test_images` to `/validator/tests/libvips/tests/upstream/test/test-suite/images`, `image` to `sample.jpg` under that directory, `tmp` to a `/tmp` scratch directory, and `vips`, `vipsthumbnail`, and `vipsheader` to installed binaries discovered from `PATH`. The validator runtime shell regression is the safe-local thumbnail smoke stored at `tests/libvips/tests/upstream/test/test_thumbnail.sh`, and it must source that generated `variables.sh`.
  - `libvips` must place the rewritten dependent suite under `tests/libvips/tests/dependents/**/*`, but `run-suite.sh` and `lib.sh` must drop `build_and_install_safe_libvips`, `prepare_extracted_prefix`, `verify_packaged_prefix`, and every `build-check*` reference. They may install dependent-application prerequisites and build or run the dependent applications, but all libvips validation must target the already-installed package surface inside the container.
  - `libvips` runtime harness must not invoke Meson, Cargo, or `dpkg-buildpackage` inside the validator container
  - `libwebp` must compile copied `original/tests/public_api_test.c` against installed packages and copied `original/examples/**/*` fixtures rather than sibling-repo paths
- Remove any runtime source-build paths from the imported media harnesses. Original mode must rely on distro packages in the image, and safe mode must rely on prebuilt replacement `.deb` packages mounted at `/safedebs`.
- Ensure every harness uses `/safedebs` replacement installs and `VALIDATOR_TRACE` handling only through the phase-2 shared entrypoint contract and that every library-local `tests/run.sh` is implementation-blind.

**Verification**

- Each library in this batch must pass original and safe runs.
- Review must prove that the special cases above were normalized into the common validator contract, including the shared Dockerfile and entrypoint delegate pattern.
- Review must also prove that each library keeps `dependents.json` and `relevant_cves.json` byte-identical to the sibling repo fixtures while validator-authored harness glue remains mode-blind.

### 5. Import Existing Archive, Compression, and System Validators

**Implement Phase ID**: `impl_05_archive_system_validators`

**Verification Phases**

- `check_05_archive_system_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_05_archive_system_validators`
  - purpose: run the third batch of real library validators in both modes
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check05
    mkdir -p .work/check05
    python3 tools/stage_port_repos.py --config repositories.yml --libraries libarchive libbz2 liblzma libsdl libsodium libzstd --source-root /home/yans/safelibs --workspace .work/check05 --dest-root .work/check05/ports
    matrix_rc=0
    bash test.sh --port-root .work/check05/ports --artifact-root .work/check05/artifacts --mode both --record-casts \
      --library libarchive \
      --library libbz2 \
      --library liblzma \
      --library libsdl \
      --library libsodium \
      --library libzstd || matrix_rc=$?
    python3 tools/render_site.py --results-root .work/check05/artifacts/results --artifacts-root .work/check05/artifacts --output-root .work/check05/site
    bash scripts/verify-site.sh --config repositories.yml --results-root .work/check05/artifacts/results --site-root .work/check05/site --library libarchive --library libbz2 --library liblzma --library libsdl --library libsodium --library libzstd --mode original --mode safe
    exit "$matrix_rc"
    ```

- `check_05_archive_system_review`
  - type: `check`
  - fixed `bounce_target`: `impl_05_archive_system_validators`
  - purpose: review that large imported harness trees were filtered correctly, that Dockerfiles and entrypoints use the shared delegate path, and that validator-authored harness glue remains mode-blind
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["libarchive", "libbz2", "liblzma", "libsdl", "libsodium", "libzstd"]
    for lib in libraries:
        root = Path("tests") / lib
        required = [
            root / "Dockerfile",
            root / "docker-entrypoint.sh",
            root / "tests" / "run.sh",
            root / "tests" / "fixtures" / "dependents.json",
            root / "tests" / "fixtures" / "relevant_cves.json",
        ]
        missing = [str(path) for path in required if not path.exists()]
        if missing:
            raise SystemExit(f"{lib}: {missing}")
        dockerfile = (root / "Dockerfile").read_text()
        for token in [
            "COPY tests/_shared /validator/tests/_shared",
            f"COPY tests/{lib} /validator/tests/{lib}",
            f'ENTRYPOINT ["/validator/tests/{lib}/docker-entrypoint.sh"]',
        ]:
            if token not in dockerfile:
                raise SystemExit(f"{lib} Dockerfile missing: {token}")
        entrypoint = (root / "docker-entrypoint.sh").read_text()
        for token in [
            "source /validator/tests/_shared/entrypoint.sh",
            f'validator_entrypoint "/validator/tests/{lib}/tests/run.sh"',
        ]:
            if token not in entrypoint:
                raise SystemExit(f"{lib} docker-entrypoint.sh missing: {token}")
    forbidden_paths = [
        Path("tests/liblzma/tests/generated"),
    ]
    for path in forbidden_paths:
        if path.exists():
            raise SystemExit(f"unexpected generated artifact import: {path}")
    required_generated = [
        Path("tests/libarchive/tests/harness-source/generated/test_manifest.json"),
        Path("tests/libarchive/tests/harness-source/generated/original_c_build/libarchive/test/list.h"),
        Path("tests/libarchive/tests/harness-source/generated/original_pkgconfig/libarchive.pc"),
        Path("tests/libsdl/tests/harness-source/generated/dependent_regression_manifest.json"),
        Path("tests/libsdl/tests/harness-source/generated/noninteractive_test_list.json"),
        Path("tests/libsdl/tests/harness-source/generated/original_test_port_map.json"),
        Path("tests/libsdl/tests/harness-source/generated/perf_workload_manifest.json"),
        Path("tests/libsdl/tests/harness-source/generated/reports/perf-baseline-vs-safe.json"),
        Path("tests/libsdl/tests/harness-source/generated/reports/perf-waivers.md"),
    ]
    missing_generated = [str(path) for path in required_generated if not path.exists()]
    if missing_generated:
        raise SystemExit(f"missing generated harness-source imports: {missing_generated}")
    forbidden_generated_locations = [
        Path("tests/libarchive/tests/upstream/generated"),
        Path("tests/libsdl/tests/upstream/generated"),
    ]
    for path in forbidden_generated_locations:
        if path.exists():
            raise SystemExit(f"generated inputs projected to wrong location: {path}")
    PY
    python3 - <<'PY'
    from pathlib import Path
    import re

    libraries = ["libarchive", "libbz2", "liblzma", "libsdl", "libsodium", "libzstd"]
    forbidden_literals = ["/safedebs", "SAFE_MODE", "ORIGINAL_MODE", "IMPLEMENTATION=", "VALIDATOR_TRACE", "bash -x", "asciinema"]
    forbidden_patterns = [
        re.compile(r'==\s*["\'](?:safe|original)["\']'),
        re.compile(r'!=\s*["\'](?:safe|original)["\']'),
        re.compile(r'\b(?:mode|package_mode|implementation)\b\s*=\s*["\'](?:safe|original)["\']'),
    ]
    excluded_roots = {"upstream", "dependents", "cve", "fixtures", "package"}
    for lib in libraries:
        root = Path("tests") / lib
        candidate_paths = [root / "Dockerfile", root / "docker-entrypoint.sh", root / "tests" / "run.sh"]
        for path in (root / "tests").rglob("*"):
            if not path.is_file() or path.stat().st_size > 200_000:
                continue
            rel = path.relative_to(root / "tests")
            if rel.parts and rel.parts[0] in excluded_roots:
                continue
            candidate_paths.append(path)
        seen = set()
        for path in candidate_paths:
            if path in seen or not path.exists():
                continue
            seen.add(path)
            text = path.read_text(errors="ignore")
            if any(token in text for token in forbidden_literals):
                raise SystemExit(f"mode-aware literal in {path}")
            if any(pattern.search(text) for pattern in forbidden_patterns):
                raise SystemExit(f"mode-aware branch in {path}")
    PY
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["libarchive", "libbz2", "liblzma", "libsdl", "libsodium", "libzstd"]
    for lib in libraries:
        for fixture in ["dependents.json", "relevant_cves.json"]:
            copied = Path("tests") / lib / "tests" / "fixtures" / fixture
            source = Path("/home/yans/safelibs") / f"port-{lib}" / fixture
            if copied.read_bytes() != source.read_bytes():
                raise SystemExit(f"{lib} fixture mismatch: {fixture}")
    PY
    ```

**Preexisting Inputs**

- outputs of phases 1 and 2
- read-only sibling repos `/home/yans/safelibs/port-libarchive`, `/home/yans/safelibs/port-libbz2`, `/home/yans/safelibs/port-liblzma`, `/home/yans/safelibs/port-libsdl`, `/home/yans/safelibs/port-libsodium`, and `/home/yans/safelibs/port-libzstd`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- only the phase-1-declared `validator.import_roots` for those six libraries; no other sibling-repo path is a valid phase-5 input

**New Outputs**

- complete validator harness directories for `libarchive`, `libbz2`, `liblzma`, `libsdl`, `libsodium`, and `libzstd`

**File Changes**

- `tests/libarchive/**`
- `tests/libbz2/**`
- `tests/liblzma/**`
- `tests/libsdl/**`
- `tests/libsodium/**`
- `tests/libzstd/**`

**Implementation Details**

- Import the existing tracked harness source from sibling repos by consuming the phase-1 `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` metadata, and keep the declared tracked generated fixtures under `tests/<library>/tests/harness-source/generated/**/*` exactly where phase 1 projected them. Phase 5 may rewrite consumers to those validator-owned paths, but it must not silently drop, rediscover, or regenerate those tracked generated inputs.
- Copy `dependents.json` and `relevant_cves.json` byte-for-byte from the sibling repos for every library in this batch; those JSON fixtures are preserved inputs, not regenerated validator outputs.
- The phase-5 imports are fixed by library:
  - `libarchive` must consume only `safe/tests`, `safe/debian/tests`, `safe/scripts`, `safe/generated/api_inventory.json`, `safe/generated/cve_matrix.json`, `safe/generated/link_compat_manifest.json`, `safe/generated/original_build_contract.json`, `safe/generated/original_package_metadata.json`, `safe/generated/original_c_build`, `safe/generated/original_link_objects`, `safe/generated/original_pkgconfig/libarchive.pc`, `safe/generated/pkgconfig/libarchive.pc`, `safe/generated/rust_test_manifest.json`, `safe/generated/test_manifest.json`, and `original/libarchive-3.7.2`
  - `libbz2` must consume only `safe/tests`, `safe/debian/tests`, `safe/scripts`, and `original`
  - `liblzma` must consume only `safe/tests`, `safe/docker`, and `safe/scripts`
  - `libsdl` must consume only `safe/tests`, `safe/debian/tests`, `safe/generated/dependent_regression_manifest.json`, `safe/generated/noninteractive_test_list.json`, `safe/generated/original_test_port_map.json`, `safe/generated/perf_workload_manifest.json`, `safe/generated/perf_thresholds.json`, `safe/generated/reports/perf-baseline-vs-safe.json`, `safe/generated/reports/perf-waivers.md`, and `original/test`
  - `libsodium` must consume only `safe/tests` and `safe/docker`
  - `libzstd` must consume only `safe/tests`, `safe/debian/tests`, `safe/docker`, `safe/scripts`, and `original/libzstd-1.5.5+dfsg2`
- `liblzma` is the key normalization case in this batch: keep the tracked dependent smoke sources from `safe/tests/dependents/**/*`, but do not import generated output under `safe/tests/generated/**/*`; those artifacts must be regenerated by validator at runtime.
- Libraries in this batch that already ship tracked package-smoke assets under `safe/debian/tests/**/*` must preserve them under `tests/<library>/tests/package/debian-tests/**/*` rather than dropping them during import; `libarchive`, `libbz2`, and `libzstd` are the explicit cases in this phase.
- Libraries that already ship `safe/docker/**/*` or `safe/scripts/**/*` should have those scripts rewritten only as far as needed to fit the validator `tests/<library>/Dockerfile` and shared entrypoint contract.
- The batch-specific rewrites are fixed too:
  - `libarchive` must rewrite every retained consumer of sibling `safe/generated/**/*` to read the copied validator-owned artifacts under `tests/libarchive/tests/harness-source/generated/**/*`. That includes the tracked manifests, preserved original-built object inventory, generated `original_c_build/**/*` headers, and both copied pkg-config contracts; no phase-5 script or test may look back into the sibling repo for those files.
  - `libarchive` must rewrite any current original-oracle or generated-build assumptions so helper binaries compile from copied `original/libarchive-3.7.2/**/*` sources plus the copied `tests/libarchive/tests/harness-source/generated/**/*` artifacts inside validator-owned scratch space only
  - `libbz2` must use copied upstream samples, headers, and source files from `original/**/*` rather than any sibling build output
  - `liblzma` must not add any undeclared `original/**/*` dependency; the final validator harness must run only from copied `safe/tests/**/*`, `safe/docker/**/*`, and `safe/scripts/**/*` assets
  - `libsdl` must rewrite every retained consumer of sibling `safe/generated/**/*` to read the copied validator-owned artifacts under `tests/libsdl/tests/harness-source/generated/**/*`, including `dependent_regression_manifest.json`, `noninteractive_test_list.json`, `original_test_port_map.json`, the perf manifests, and the tracked perf report and waiver files
  - `libsdl` must compile copied `original/test/**/*` sources and fixtures against the installed package surface rather than a sibling build tree, and any validator-owned helper translated from the current `safe/tests/**/*` sources must use only those copied original-test assets plus the copied `tests/libsdl/tests/harness-source/generated/**/*` fixtures
  - `libsodium` must not add any undeclared `original/**/*` dependency; the final validator harness must stay within the copied `safe/tests/**/*` and `safe/docker/**/*` trees
  - `libzstd` must rewrite any current expectation of `safe/out/**/*` or non-imported build directories to validator-owned scratch while keeping all copied upstream tests and corpora under validator control
- Remove any runtime source-build logic from the final archive/system harnesses so the validator containers exercise installed packages, not ad hoc source builds.

**Verification**

- Each library in this batch must pass original and safe runs.
- Review must prove the declared tracked generated sibling artifacts for `libarchive` and `libsdl` were imported into validator-owned `tests/*/tests/harness-source/generated/**/*` paths and then consumed from there, not dropped or rederived, and that the shared Dockerfile and entrypoint delegate contract was preserved.
- Review must also prove that each imported harness keeps `dependents.json` and `relevant_cves.json` byte-identical to the sibling repo fixtures while validator-authored harness glue remains mode-blind.

### 6. Bootstrap Missing Validators from Existing Source Trees

**Implement Phase ID**: `impl_06_bootstrap_missing_validators`

**Verification Phases**

- `check_06_bootstrap_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_06_bootstrap_missing_validators`
  - purpose: prove the new bootstrap harnesses and bootstrap package build mode work in both original and replacement-package runs, and that at least one produced bootstrap `.deb` carries the required validator-only version suffix in package metadata
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check06
    mkdir -p .work/check06
    python3 tools/stage_port_repos.py --config repositories.yml --libraries glib libcurl libgcrypt libjansson libuv --source-root /home/yans/safelibs --workspace .work/check06 --dest-root .work/check06/ports
    matrix_rc=0
    bash test.sh --port-root .work/check06/ports --artifact-root .work/check06/artifacts --mode both --record-casts \
      --library glib \
      --library libcurl \
      --library libgcrypt \
      --library libjansson \
      --library libuv || matrix_rc=$?
    python3 tools/render_site.py --results-root .work/check06/artifacts/results --artifacts-root .work/check06/artifacts --output-root .work/check06/site
    bash scripts/verify-site.sh --config repositories.yml --results-root .work/check06/artifacts/results --site-root .work/check06/site --library glib --library libcurl --library libgcrypt --library libjansson --library libuv --mode original --mode safe
    python3 - <<'PY'
    from pathlib import Path
    import subprocess

    candidates = sorted(Path(".work/check06/artifacts/debs/libjansson").glob("*.deb"))
    if not candidates:
        raise SystemExit("missing libjansson bootstrap deb")
    version = subprocess.check_output(["dpkg-deb", "-f", str(candidates[0]), "Version"], text=True).strip()
    if not version.endswith("+validatorbootstrap1"):
        raise SystemExit(f"unexpected bootstrap version: {version}")
    PY
    exit "$matrix_rc"
    ```

- `check_06_bootstrap_review`
  - type: `check`
  - fixed `bounce_target`: `impl_06_bootstrap_missing_validators`
  - purpose: review that newly created fixtures use the fixed fully typed bootstrap schema, that bootstrap Dockerfiles and entrypoints delegate to the shared contract, and that validator-authored bootstrap harness glue remains mode-blind
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path

    libraries = ["glib", "libcurl", "libgcrypt", "libjansson", "libuv"]
    for lib in libraries:
        root = Path("tests") / lib
        required = [
            root / "Dockerfile",
            root / "docker-entrypoint.sh",
            root / "tests" / "run.sh",
            root / "tests" / "fixtures" / "dependents.json",
            root / "tests" / "fixtures" / "relevant_cves.json",
        ]
        missing = [str(path) for path in required if not path.exists()]
        if missing:
            raise SystemExit(f"{lib}: {missing}")
        dockerfile = (root / "Dockerfile").read_text()
        for token in [
            "COPY tests/_shared /validator/tests/_shared",
            f"COPY tests/{lib} /validator/tests/{lib}",
            f'ENTRYPOINT ["/validator/tests/{lib}/docker-entrypoint.sh"]',
        ]:
            if token not in dockerfile:
                raise SystemExit(f"{lib} Dockerfile missing: {token}")
        entrypoint = (root / "docker-entrypoint.sh").read_text()
        for token in [
            "source /validator/tests/_shared/entrypoint.sh",
            f'validator_entrypoint "/validator/tests/{lib}/tests/run.sh"',
        ]:
            if token not in entrypoint:
                raise SystemExit(f"{lib} docker-entrypoint.sh missing: {token}")
    PY
    python3 - <<'PY'
    from pathlib import Path
    import re

    libraries = ["glib", "libcurl", "libgcrypt", "libjansson", "libuv"]
    forbidden_literals = ["/safedebs", "SAFE_MODE", "ORIGINAL_MODE", "IMPLEMENTATION=", "VALIDATOR_TRACE", "bash -x", "asciinema"]
    forbidden_patterns = [
        re.compile(r'==\s*["\'](?:safe|original)["\']'),
        re.compile(r'!=\s*["\'](?:safe|original)["\']'),
        re.compile(r'\b(?:mode|package_mode|implementation)\b\s*=\s*["\'](?:safe|original)["\']'),
    ]
    excluded_roots = {"upstream", "dependents", "cve", "fixtures", "package"}
    for lib in libraries:
        root = Path("tests") / lib
        candidate_paths = [root / "Dockerfile", root / "docker-entrypoint.sh", root / "tests" / "run.sh"]
        for path in (root / "tests").rglob("*"):
            if not path.is_file() or path.stat().st_size > 200_000:
                continue
            rel = path.relative_to(root / "tests")
            if rel.parts and rel.parts[0] in excluded_roots:
                continue
            candidate_paths.append(path)
        seen = set()
        for path in candidate_paths:
            if path in seen or not path.exists():
                continue
            seen.add(path)
            text = path.read_text(errors="ignore")
            if any(token in text for token in forbidden_literals):
                raise SystemExit(f"mode-aware literal in {path}")
            if any(pattern.search(text) for pattern in forbidden_patterns):
                raise SystemExit(f"mode-aware branch in {path}")
    PY
    python3 - <<'PY'
    from datetime import datetime, timezone
    from pathlib import Path
    import json

    libraries = ["glib", "libcurl", "libgcrypt", "libjansson", "libuv"]
    dependent_keys = {"schema_version", "library", "generated_at_utc", "ubuntu_release", "provenance", "dependents"}
    dependent_provenance_keys = {"source_paths", "package_metadata_commands", "selection_policy"}
    dependent_entry_keys = {"package", "source_package", "selection_reason", "dependency_relationships", "smoke_test", "notes", "evidence"}
    dependent_evidence_keys = {"source_paths", "package_metadata", "autopkgtest_references", "selection_commands"}
    relationship_keys = {"compile_time", "runtime", "autopkgtest"}
    smoke_test_keys = {"kind", "command", "expected_exit_code"}
    cve_keys = {"schema_version", "library", "generated_at_utc", "provenance", "selection_policy", "relevant_cves", "reviewed_but_excluded"}
    cve_provenance_keys = {"source_paths", "debian_references", "upstream_regression_inputs", "notes"}
    cve_entry_keys = {"id", "summary", "why_relevant_to_rust", "evidence", "porting_actions"}
    cve_evidence_keys = {"source_paths", "debian_references", "upstream_inputs"}
    excluded_keys = {"id", "reason"}

    def require_non_empty_string(value, label):
        if not isinstance(value, str) or not value:
            raise SystemExit(f"{label} must be a non-empty string")

    def require_utc_timestamp(value, label):
        require_non_empty_string(value, label)
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError as exc:
            raise SystemExit(f"{label} must be an ISO 8601 timestamp: {exc}") from exc
        if parsed.tzinfo is None or parsed.utcoffset() != timezone.utc.utcoffset(None):
            raise SystemExit(f"{label} must be UTC")

    def require_string_list(value, label, *, allow_empty):
        if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
            raise SystemExit(f"{label} must be a string list")
        if not allow_empty and not value:
            raise SystemExit(f"{label} must be non-empty")

    for lib in libraries:
        fixtures = Path("tests") / lib / "tests" / "fixtures"
        dependents = json.loads((fixtures / "dependents.json").read_text())
        if set(dependents) != dependent_keys:
            raise SystemExit(f"{lib} dependents.json keys mismatch: {sorted(dependents)}")
        if dependents["schema_version"] != 1 or dependents["library"] != lib:
            raise SystemExit(f"{lib} dependents.json identity mismatch")
        require_utc_timestamp(dependents["generated_at_utc"], f"{lib} dependents generated_at_utc")
        if dependents["ubuntu_release"] != "24.04":
            raise SystemExit(f"{lib} dependents ubuntu_release mismatch: {dependents['ubuntu_release']!r}")
        if set(dependents["provenance"]) != dependent_provenance_keys:
            raise SystemExit(f"{lib} dependents provenance mismatch")
        for key in dependent_provenance_keys:
            require_string_list(
                dependents["provenance"][key],
                f"{lib} dependents provenance {key}",
                allow_empty=False,
            )
        if not dependents["dependents"]:
            raise SystemExit(f"{lib} dependents.json must contain at least one dependent")
        for entry in dependents["dependents"]:
            if set(entry) != dependent_entry_keys:
                raise SystemExit(f"{lib} dependent entry keys mismatch: {sorted(entry)}")
            for key in ["package", "source_package", "selection_reason"]:
                require_non_empty_string(entry[key], f"{lib} dependent {key}")
            require_string_list(entry["notes"], f"{lib} dependent notes", allow_empty=True)
            if set(entry["dependency_relationships"]) != relationship_keys:
                raise SystemExit(f"{lib} dependency relationships mismatch")
            for key in relationship_keys:
                require_string_list(
                    entry["dependency_relationships"][key],
                    f"{lib} dependency relationships {key}",
                    allow_empty=True,
                )
            if set(entry["smoke_test"]) != smoke_test_keys:
                raise SystemExit(f"{lib} smoke_test keys mismatch")
            if entry["smoke_test"]["kind"] not in {"cli", "autopkgtest", "library-provided-script"}:
                raise SystemExit(f"{lib} smoke_test kind invalid: {entry['smoke_test']['kind']}")
            require_non_empty_string(entry["smoke_test"]["command"], f"{lib} smoke_test command")
            if not isinstance(entry["smoke_test"]["expected_exit_code"], int):
                raise SystemExit(f"{lib} smoke_test expected_exit_code must be an int")
            if set(entry["evidence"]) != dependent_evidence_keys:
                raise SystemExit(f"{lib} dependent evidence keys mismatch: {sorted(entry['evidence'])}")
            for key in dependent_evidence_keys:
                require_string_list(entry["evidence"][key], f"{lib} dependent evidence {key}", allow_empty=True)
            if not entry["evidence"]["source_paths"]:
                raise SystemExit(f"{lib} dependent evidence source_paths missing")
            if not entry["evidence"]["selection_commands"]:
                raise SystemExit(f"{lib} dependent evidence selection_commands missing")
            if entry["dependency_relationships"]["autopkgtest"] and not entry["evidence"]["autopkgtest_references"]:
                raise SystemExit(f"{lib} dependent autopkgtest evidence missing")
        cves = json.loads((fixtures / "relevant_cves.json").read_text())
        if set(cves) != cve_keys:
            raise SystemExit(f"{lib} relevant_cves.json keys mismatch: {sorted(cves)}")
        if cves["schema_version"] != 1 or cves["library"] != lib:
            raise SystemExit(f"{lib} relevant_cves.json identity mismatch")
        require_utc_timestamp(cves["generated_at_utc"], f"{lib} relevant_cves generated_at_utc")
        require_string_list(cves["selection_policy"], f"{lib} cve selection_policy", allow_empty=False)
        if set(cves["provenance"]) != cve_provenance_keys:
            raise SystemExit(f"{lib} cve provenance mismatch")
        require_string_list(cves["provenance"]["source_paths"], f"{lib} cve provenance source_paths", allow_empty=False)
        require_string_list(cves["provenance"]["debian_references"], f"{lib} cve provenance debian_references", allow_empty=True)
        require_string_list(
            cves["provenance"]["upstream_regression_inputs"],
            f"{lib} cve provenance upstream_regression_inputs",
            allow_empty=True,
        )
        require_string_list(cves["provenance"]["notes"], f"{lib} cve provenance notes", allow_empty=True)
        if not isinstance(cves["relevant_cves"], list) or not isinstance(cves["reviewed_but_excluded"], list):
            raise SystemExit(f"{lib} cve lists missing")
        for entry in cves["relevant_cves"]:
            if set(entry) != cve_entry_keys:
                raise SystemExit(f"{lib} relevant cve entry keys mismatch: {sorted(entry)}")
            require_non_empty_string(entry["id"], f"{lib} relevant cve id")
            require_non_empty_string(entry["summary"], f"{lib} relevant cve summary")
            require_non_empty_string(entry["why_relevant_to_rust"], f"{lib} relevant cve why_relevant_to_rust")
            if set(entry["evidence"]) != cve_evidence_keys:
                raise SystemExit(f"{lib} cve evidence keys mismatch")
            for key in cve_evidence_keys:
                require_string_list(entry["evidence"][key], f"{lib} cve evidence {key}", allow_empty=True)
            if not any(entry["evidence"][key] for key in cve_evidence_keys):
                raise SystemExit(f"{lib} cve evidence must not be entirely empty")
            require_string_list(entry["porting_actions"], f"{lib} cve porting_actions", allow_empty=False)
        for entry in cves["reviewed_but_excluded"]:
            if set(entry) != excluded_keys:
                raise SystemExit(f"{lib} excluded cve entry keys mismatch: {sorted(entry)}")
            require_non_empty_string(entry["id"], f"{lib} excluded cve id")
            require_non_empty_string(entry["reason"], f"{lib} excluded cve reason")
        if not cves["relevant_cves"] and not cves["provenance"]["notes"]:
            raise SystemExit(f"{lib} empty cve fixture must explain why no relevant CVEs were retained")
    PY
    rg -n 'validatorbootstrap1|bootstrap-original-source' repositories.yml tools/build_safe_debs.py test.sh tools/run_matrix.py
    ```

**Preexisting Inputs**

- outputs of phases 1 and 2
- `/home/yans/safelibs/port-glib/original/**/*`
- `/home/yans/safelibs/port-libcurl/original/**/*`
- `/home/yans/safelibs/port-libgcrypt/original/libgcrypt20-1.10.3/**/*`
- `/home/yans/safelibs/port-libjansson/original/jansson-2.14/**/*`
- `/home/yans/safelibs/port-libuv/original/**/*`

**New Outputs**

- complete validator harness directories for `glib`, `libcurl`, `libgcrypt`, `libjansson`, and `libuv`
- validator-authored `dependents.json` and `relevant_cves.json` fixtures for those five libraries

**File Changes**

- `tests/glib/**`
- `tests/libcurl/**`
- `tests/libgcrypt/**`
- `tests/libjansson/**`
- `tests/libuv/**`
- `Makefile`
- `repositories.yml`
- `tools/build_safe_debs.py`

**Implementation Details**

- Use the `source-debian-original` build mode from phase 1 to build replacement `.deb` packages from the imported upstream/Debian source trees for these five libraries. The staged build copy under `.work/` must receive the exact validator-only version suffix `+validatorbootstrap1` so safe-mode package installation is observable and auditable.
- Use `tools/import_port_assets.py` plus the phase-1 `validator.build_root`, `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` metadata to project the selected upstream and Debian test subsets into validator-owned paths before writing each bootstrap harness.
- Create validator-owned `tests/<library>/Dockerfile`, `docker-entrypoint.sh`, and `tests/run.sh` for each bootstrap library. The source material comes from:
  - `glib`: `debian/tests`, `tests/`, `glib/tests/`, `gio/tests/`, `gobject/tests/`, and `fuzzing/`
  - `libcurl`: `debian/tests`, `tests/`, `tests/data`, local server helpers, and upstream `runtests.pl` subsets that can run hermetically inside Docker
  - `libgcrypt`: `tests/` plus Debian control metadata for required packages
  - `libjansson`: `test/bin`, `test/run-suites`, `test/suites`, `test/scripts`, and `test/ossfuzz`
  - `libuv`: `test/` and Debian package metadata
- Each bootstrap harness must still use the same phase-2 Dockerfile and shared-entrypoint contract as mature libraries; bootstrap-specific mode branching is not allowed in library-local files.
- For these libraries only, generate new validator-owned `tests/<library>/tests/fixtures/dependents.json` from existing source and local package metadata because the sibling repos do not already provide one. Use one fixed bootstrap schema so later phases and reviewers do not infer structure from mature repos:
  - exact top-level keys: `schema_version`, `library`, `generated_at_utc`, `ubuntu_release`, `provenance`, and `dependents`
  - `schema_version` is fixed to `1`, `library` must equal the current library name, `generated_at_utc` must be a non-empty UTC timestamp string, and `ubuntu_release` must be the non-empty string `24.04`
  - `provenance` must contain exactly `source_paths`, `package_metadata_commands`, and `selection_policy`, and each value must be a non-empty list of non-empty strings
  - every item in `dependents` must contain exactly `package`, `source_package`, `selection_reason`, `dependency_relationships`, `smoke_test`, `notes`, and `evidence`
  - `package`, `source_package`, and `selection_reason` must each be non-empty strings, and `notes` must be a list of non-empty strings that may be empty only when the fixture has nothing extra to record
  - `dependency_relationships` must contain exactly `compile_time`, `runtime`, and `autopkgtest`, each as a list of non-empty package or autopkgtest dependency strings
  - `smoke_test` must contain exactly `kind`, `command`, and `expected_exit_code`, where `kind` is one of `cli`, `autopkgtest`, or `library-provided-script`, `command` is a non-empty string, and `expected_exit_code` is an integer
  - every `evidence` mapping must contain exactly `source_paths`, `package_metadata`, `autopkgtest_references`, and `selection_commands`
  - `evidence.source_paths`, `evidence.package_metadata`, `evidence.autopkgtest_references`, and `evidence.selection_commands` must each be lists of non-empty strings; `source_paths` and `selection_commands` are required to be non-empty for every dependent, and `autopkgtest_references` must be non-empty whenever `dependency_relationships.autopkgtest` is non-empty
  - derive candidate dependent packages from Debian metadata and locally available Ubuntu package indexes, select deterministic installable dependents that can be exercised noninteractively inside Ubuntu 24.04 Docker, prefer packages already covered by Debian autopkgtest metadata or simple CLI smoke entrypoints over GUI-only dependents, keep at least one dependent entry per bootstrap library, and check the resulting fixture into git so later phases consume it as an existing artifact
- Generate `tests/<library>/tests/fixtures/relevant_cves.json` from existing Debian patch names, changelog references, and tracked upstream regression/fuzz inputs when possible. Use one fixed bootstrap schema even when no relevant CVEs are retained:
  - exact top-level keys: `schema_version`, `library`, `generated_at_utc`, `provenance`, `selection_policy`, `relevant_cves`, and `reviewed_but_excluded`
  - `schema_version` is fixed to `1`, `library` must equal the current library name, and `generated_at_utc` must be a non-empty UTC timestamp string
  - `selection_policy` must be a non-empty list of non-empty strings describing the deterministic filtering rules that produced the file
  - `provenance` must contain exactly `source_paths`, `debian_references`, `upstream_regression_inputs`, and `notes`; each value must be a list of non-empty strings, `source_paths` must be non-empty in every file, and `notes` must be non-empty whenever `relevant_cves` is empty
  - every item in `relevant_cves` must contain exactly `id`, `summary`, `why_relevant_to_rust`, `evidence`, and `porting_actions`
  - `id`, `summary`, and `why_relevant_to_rust` must each be non-empty strings
  - every `evidence` mapping must contain exactly `source_paths`, `debian_references`, and `upstream_inputs`, each as a list of non-empty strings, and at least one of those three lists must be non-empty for every retained CVE
  - `porting_actions` must be a non-empty list of non-empty strings
  - every item in `reviewed_but_excluded` must contain exactly `id` and `reason`, and both values must be non-empty strings
  - if no relevant entries exist, `relevant_cves` must be an explicit empty list and `provenance.notes` must explain why the reviewed Debian or upstream inputs did not yield a retained entry
- Record bootstrap safe runs as `replacement_provenance=bootstrap-original-source`; that distinction belongs in results and the site, not in the tests themselves.

**Verification**

- All five bootstrap libraries must pass original and safe runs through the same validator contract used by mature libraries.
- The bootstrap verifier must read `Version:` from at least one built bootstrap `.deb` artifact and prove it ends with `+validatorbootstrap1`.
- Review must prove the new fixtures are explicit validator outputs, that they match the fixed bootstrap JSON schema including typed `dependents[].evidence` fields and the fully typed `relevant_cves.json` provenance, evidence, and exclusion fields, and that validator-authored bootstrap harness glue remains mode-blind across `Dockerfile`, `docker-entrypoint.sh`, and non-imported helper files under `tests/**/*`.

### 7. CI, Pages Publication, and Public Repo Push

**Implement Phase ID**: `impl_07_ci_pages_publish`

**Verification Phases**

- `check_07_full_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_07_ci_pages_publish`
  - purpose: run the full local validator matrix, render the final site, and verify Pages-ready output
  - commands:

    ```bash
    set -euo pipefail
    rm -rf .work/check07 artifacts site
    python3 -m unittest discover -s unit -v
    mkdir -p .work/check07
    python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check07 --dest-root .work/check07/ports
    matrix_rc=0
    bash test.sh --port-root .work/check07/ports --artifact-root artifacts --mode both --record-casts || matrix_rc=$?
    python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site
    bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site
    exit "$matrix_rc"
    ```

- `check_07_release_publish_review`
  - type: `check`
  - fixed `bounce_target`: `impl_07_ci_pages_publish`
  - purpose: review the GitHub workflows, publication script, Pages deployment topology, and pushed public repo state without depending on generated `site/` output from another verifier
  - commands:

    ```bash
    git diff --check HEAD^ HEAD
    python3 - <<'PY'
    from pathlib import Path
    required = [
        Path(".github/workflows/ci.yml"),
        Path(".github/workflows/pages.yml"),
        Path("scripts/publish-public.sh"),
        Path("README.md"),
        Path("Makefile"),
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit(missing)
    PY
    python3 - <<'PY'
    from pathlib import Path

    ci = Path(".github/workflows/ci.yml").read_text()
    pages = Path(".github/workflows/pages.yml").read_text()

    ci_required = [
        "preflight:",
        "unit-tests:",
        "matrix-smoke:",
        "full-matrix:",
        "SAFELIBS_REPO_TOKEN",
        "GH_TOKEN: ${{ secrets.SAFELIBS_REPO_TOKEN }}",
        "python3 -m unittest discover -s unit -v",
        "python3 tools/stage_port_repos.py --config repositories.yml",
        "--dest-root .work/ports",
        "rm -rf .work/ports artifacts site",
        "--artifact-root artifacts",
        "matrix_exit_code",
        "always()",
        "bash test.sh --port-root .work/ports",
        "--library giflib",
        "--library libpng",
        "--library libjson",
        "--library libvips",
        "--library libjansson",
        "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
        "scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
        "actions/upload-artifact@",
    ]
    for token in ci_required:
        if token not in ci:
            raise SystemExit(f"ci.yml missing: {token}")

    pages_required = [
        "build:",
        "deploy:",
        "report-status:",
        "permissions:",
        "contents: read",
        "pages: write",
        "id-token: write",
        "Validate deployment secrets",
        "GH_TOKEN: ${{ secrets.SAFELIBS_REPO_TOKEN }}",
        "actions/configure-pages@",
        "actions/upload-pages-artifact@",
        "actions/deploy-pages@",
        "environment:",
        "github-pages",
        "needs: [build, deploy]",
        "python3 tools/stage_port_repos.py --config repositories.yml",
        "--dest-root .work/ports",
        "rm -rf .work/ports artifacts site",
        "--artifact-root artifacts",
        "matrix_exit_code",
        "needs.build.outputs.matrix_exit_code",
        "bash test.sh --port-root .work/ports --artifact-root artifacts --mode both --record-casts",
        "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
        "scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
    ]
    for token in pages_required:
        if token not in pages:
            raise SystemExit(f"pages.yml missing: {token}")
    PY
    rg -n 'gh repo (view|create)|git remote (add|set-url)|git push' scripts/publish-public.sh
    rg -n '^publish-public:' Makefile
    rg -n 'make unit|make stage-ports|make test|make render-site|make verify-site|make publish-public|PORT_SOURCE_ROOT|GitHub clone|asciinema|artifacts/casts|site/casts|GitHub Pages' README.md
    ! rg -n '/home/yans/safelibs' README.md
    test "$(gh repo view safelibs/validator --json visibility --jq '.visibility')" = "PUBLIC"
    gh repo view safelibs/validator --json name,visibility,url
    git remote get-url origin
    python3 - <<'PY'
    import re
    import subprocess

    remote = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
    if not re.search(r'[:/]safelibs/validator(?:\\.git)?$', remote):
        raise SystemExit(remote)
    PY
    git ls-remote --heads origin main
    ```

**Preexisting Inputs**

- outputs of phases 1 through 6
- all 23 local sibling `/home/yans/safelibs/port-*` repos
- `/home/yans/safelibs/apt-repo/.github/workflows/ci.yml`
- `/home/yans/safelibs/apt-repo/.github/workflows/pages.yml`
- `/home/yans/safelibs/apt-repo/scripts/verify-in-ubuntu-docker.sh`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`
- authenticated `gh` access with permission to create and inspect repositories under `safelibs`

**New Outputs**

- GitHub Actions workflows for CI and Pages
- idempotent public-repo publication script
- updated repository `README.md`
- pushed public repo `safelibs/validator`

**File Changes**

- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`
- `scripts/publish-public.sh`
- `README.md`
- `Makefile`

**Implementation Details**

- Create `.github/workflows/ci.yml` for Ubuntu 24.04. It must:
  - define `preflight`, `unit-tests`, `matrix-smoke`, and `full-matrix` jobs
  - always run `unit-tests` with `python3 -m unittest discover -s unit -v`
  - expose `GH_TOKEN` from `SAFELIBS_REPO_TOKEN` only in `preflight`, `matrix-smoke`, and `full-matrix`
  - have `preflight` emit a boolean output indicating whether `SAFELIBS_REPO_TOKEN` is present
  - every secret-gated job must begin with `rm -rf .work/ports artifacts site` so reruns cannot reuse stale staged repos, results, casts, or rendered output
  - make `matrix-smoke` run only on pull requests when the repo token is available; it must stage exactly `giflib`, `libpng`, `libjson`, `libvips`, and `libjansson` into `.work/ports`, run both original and safe validator modes for those five libraries in that exact order in one `test.sh` invocation with repeatable `--library` flags, and use that fixed subset because it covers the manifest build-path classes `safe-debian`, `checkout-artifacts`, omitted-mode default-to-docker, explicit `mode: docker`, and bootstrap `source-debian-original`
  - `matrix-smoke` must capture `matrix_exit_code` instead of failing immediately, render `site/` from the produced results, verify that site with `scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site --library giflib --library libpng --library libjson --library libvips --library libjansson --mode original --mode safe`, upload both `artifacts/` and `site/` with `if: ${{ always() }}`, and only then fail the job if `matrix_exit_code` is non-zero
  - make `full-matrix` run only on pushes to `main` when the repo token is available; it must stage the full manifest-pinned repo set into `.work/ports`, run the complete validator matrix with `--record-casts`, capture `matrix_exit_code` instead of failing immediately, render the site from the produced results, verify the generated site with `scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site`, upload the resulting `artifacts/` and `site/` with `if: ${{ always() }}`, and only then fail the job if `matrix_exit_code` is non-zero
  - use `python3 tools/stage_port_repos.py --config repositories.yml --dest-root .work/ports` in every secret-gated job so CI never depends on `/home/yans/safelibs`
- Create `.github/workflows/pages.yml` for GitHub Pages deployment. It must:
  - trigger on `push` to `main` and `workflow_dispatch`
  - declare top-level `permissions` with `contents: read`, `pages: write`, and `id-token: write`
  - define a `build` job that checks out the validator repo, exports `GH_TOKEN` from `SAFELIBS_REPO_TOKEN`, fails fast with a clear error when that secret is missing, installs the missing host packages (`python3-yaml`, `jq`, `asciinema`) while verifying that runner-provided `docker` and `gh` are available, runs `actions/configure-pages`, begins with `rm -rf .work/ports artifacts site`, stages the full manifest-pinned repo set into `.work/ports`, runs the full matrix with `--record-casts`, captures `matrix_exit_code` instead of failing immediately, renders the site from the produced results, verifies the site with `scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site`, uploads `site/` with `actions/upload-pages-artifact`, and exposes `matrix_exit_code` as a job output
  - define a separate `deploy` job that depends on `build`, targets the `github-pages` environment, and uses `actions/deploy-pages`
  - define a final `report-status` job with the exact dependency line `needs: [build, deploy]`, read `needs.build.outputs.matrix_exit_code`, and fail the workflow if it is non-zero so the published report site still exists even when some validator runs failed
  - defer only matrix test failures; missing secrets, staging failures, render failures, verify-site failures, or Pages upload failures must still fail the `build` job immediately because no trustworthy report artifact exists in those cases
  - rebuild the site from scratch inside the Pages workflow instead of relying on `/home/yans/safelibs` or on artifacts from a previous local run
- Implement `scripts/publish-public.sh` as an idempotent repo-publication command. It must:
  - create `safelibs/validator` as a public repo if it does not already exist
  - fail clearly if the existing remote repo is not public
  - add or reconcile the `origin` remote
  - push `main`
  - fail clearly if `gh auth` is missing or lacks permission
- Update `README.md` with:
  - prerequisites (`gh`, `docker`, `python3`, `PyYAML`, `asciinema`)
  - local commands (`make unit`, `make stage-ports`, `make test`, `make render-site`, `make verify-site`, `make publish-public`), including an explicit note that `make stage-ports` and `make test` stage from authenticated GitHub clones by default and accept `PORT_SOURCE_ROOT=/path/to/safelibs` only as an optional local-sibling override
  - artifact layout (`artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, `site/`, and `site/casts/`)
  - GitHub Pages output description

**Verification**

- The full local matrix must pass and generate the final Pages site from a freshly staged manifest-pinned `port-root`.
- The CI and Pages workflows must both render and verify the report site from produced results, including exact manifest-driven `<library, mode>` coverage, before surfacing any deferred matrix failure.
- The public repo must exist, `origin` must point to `github.com/safelibs/validator`, and `main` must be pushed.

## Critical Files

- `README.md`: expand from the current vision-only description to full validator setup, execution, artifact, and publication documentation.
- `.gitignore`: ignore `.work/`, `artifacts/`, `site/`, and other local scratch outputs while keeping checked-in site source and fixtures tracked.
- `Makefile`: standardize `unit`, `inventory`, `stage-ports`, `build-safe`, `test`, `render-site`, `verify-site`, `publish-public`, and `clean`, with clone-backed staging as the default and `PORT_SOURCE_ROOT` only as an explicit local override.
- `inventory/github-repo-list.json`: checked-in raw snapshot of the live GitHub repo list used to resolve the `repos-*` versus `port-*` naming mismatch.
- `inventory/github-port-repos.json`: checked-in filtered 23-library `port-*` proof derived from the raw GitHub snapshot.
- `repositories.yml`: checked-in validator manifest for all 23 libraries, with exact `inventory` metadata, copied `apt-repo` entries plus pinned untagged entries, and exact per-library `validator` metadata consumed by later import/build phases.
- `tools/inventory.py`: manifest loading, GitHub inventory verification, and non-destructive source staging.
- `tools/stage_port_repos.py`: non-destructive staging of manifest-pinned `port-*` repos for local scratch work and CI.
- `tools/build_safe_debs.py`: reusable package build driver for tagged safe ports and bootstrap original-source ports.
- `tools/import_port_assets.py`: deterministic importer for existing sibling harness assets.
- `tools/run_matrix.py`: shared executor for original and safe validator runs that consumes only staged manifest-pinned `port-root` trees, passes the explicit `VALIDATOR_TRACE=0|1` contract into containers, continues through the requested matrix, writes explicit per-run result JSON/log/cast artifacts, and returns a failing exit only after artifact emission completes.
- `tools/render_site.py`: static report-site renderer that consumes explicit result JSON, preserves one explicit rendered record per `<library, mode>` in `site/report.json`, copies published cast files into `site/casts/`, and keeps report links aligned with `cast_path`.
- `unit/test_inventory.py`, `unit/test_stage_port_repos.py`, `unit/test_build_safe_debs.py`, `unit/test_import_port_assets.py`, `unit/test_run_matrix.py`, `unit/test_render_site.py`: unit coverage for the shared tooling without colliding with README-reserved harness paths under `tests/`.
- `tests/_shared/common.sh`, `tests/_shared/install_safe_debs.sh`, and `tests/_shared/entrypoint.sh`: shared runtime contract for every library harness, including `/safedebs` installation and the only allowed `VALIDATOR_TRACE` handling path.
- `test.sh`: single top-level matrix entrypoint that consumes a previously staged `.work/ports` tree or an explicitly supplied staged `--port-root`, and accepts an optional verifier-only `--tests-root` override for phase-local smoke fixtures.
- `site-src/index.html.template`, `site-src/library.html.template`, `site-src/styles.css`, `site-src/script.js`: tracked source for the generated Pages site.
- `scripts/verify-site.sh`: local and CI verification of generated site/report output, including exact expected `<library, mode>` coverage derived from `repositories.yml` or an explicitly provided subset.
- `scripts/publish-public.sh`: idempotent creation/push script for `safelibs/validator`.
- `tests/cjson/**`, `tests/giflib/**`, `tests/libcsv/**`, `tests/libjson/**`, `tests/libxml/**`, `tests/libyaml/**`: imported text/data validator harnesses.
- `tests/libexif/**`, `tests/libjpeg-turbo/**`, `tests/libpng/**`, `tests/libtiff/**`, `tests/libvips/**`, `tests/libwebp/**`: imported media/imaging validator harnesses.
- `tests/libarchive/**`, `tests/libbz2/**`, `tests/liblzma/**`, `tests/libsdl/**`, `tests/libsodium/**`, `tests/libzstd/**`: imported archive/compression/system validator harnesses.
- `tests/glib/**`, `tests/libcurl/**`, `tests/libgcrypt/**`, `tests/libjansson/**`, `tests/libuv/**`: newly bootstrapped validator harnesses and fixtures.
- `.github/workflows/ci.yml` and `.github/workflows/pages.yml`: CI, full-matrix, cast-recording, and Pages publication automation.

## Final Verification

After all phases complete, verify the full implementation with these exact commands:

```bash
set -euo pipefail
rm -rf .work/final artifacts site
python3 -m unittest discover -s unit -v
mkdir -p .work/final
python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/final --dest-root .work/final/ports
matrix_rc=0
bash test.sh --port-root .work/final/ports --artifact-root artifacts --mode both --record-casts || matrix_rc=$?
python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site
bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site
test "$matrix_rc" -eq 0
test "$(gh repo view safelibs/validator --json visibility --jq '.visibility')" = "PUBLIC"
gh repo view safelibs/validator --json name,visibility,url
git remote get-url origin
python3 - <<'PY'
import re
import subprocess

remote = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
if not re.search(r'[:/]safelibs/validator(?:\\.git)?$', remote):
    raise SystemExit(remote)
PY
git ls-remote --heads origin main
```

The final result is acceptable only if:

- every one of the 23 verified SafeLibs libraries has a checked-in `tests/<library>/Dockerfile`, `docker-entrypoint.sh`, and mode-blind `tests/` tree
- `test.sh` can run one library or the full matrix in original and safe modes when pointed at a manifest-pinned staged `port-root`
- every matrix execution path stages manifest-pinned `port-*` repos into scratch and never runs directly against live sibling worktrees
- full-matrix runs executed with `--record-casts` emit asciinema cast files under `artifacts/casts/`, the generated site publishes them under `site/casts/`, and the rendered report links resolve to those published copies
- the generated Pages site and `site/report.json` contain exactly one original result and one safe result for every library listed in `repositories.yml`, with no missing or unexpected `<library, mode>` pairs
- the CI and Pages workflows both render and verify the report site from produced results, including exact manifest-driven `<library, mode>` coverage, before surfacing any deferred matrix failure
- the checked-in manifest still reflects the verified 23-library GitHub inventory
- the public repo `github.com/safelibs/validator` exists, is public, and `main` has been pushed

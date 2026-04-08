# Phase 01

## Phase Name

`inventory-scaffold`

## Implement Phase ID

`impl_01_inventory_scaffold`

## Preexisting Inputs

- `README.md`
- `/home/yans/safelibs/apt-repo/README.md`
- `/home/yans/safelibs/apt-repo/repositories.yml`
- `/home/yans/safelibs/apt-repo/tools/build_site.py`
- `/home/yans/safelibs/apt-repo/tests/test_build_site.py`
- `/home/yans/safelibs/port-libvips/.plan/workflow-structure.yaml`
- authenticated access to `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url`
- authenticated access to `gh repo clone safelibs/port-*`
- all 23 local sibling `/home/yans/safelibs/port-*` repos as read-only import and staging inputs

## New Outputs

- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- validator-owned `repositories.yml` covering all 23 libraries
- inventory, staging, build, and import tooling under `tools/`
- Python unit tests under `unit/`
- root scaffold files such as `.gitignore` and a `Makefile` skeleton

## File Changes

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

## Implementation Details

- Create `inventory/github-repo-list.json` as the checked-in raw snapshot from `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url`.
- Derive `inventory/github-port-repos.json` as the checked-in filtered 23-library `port-*` subset and preserve it as the proof artifact that resolves the goal’s `repos-*` wording mismatch.
- Create `repositories.yml` as validator’s checked-in source of truth with:
  - an `inventory` mapping with exact keys `verified_at`, `gh_repo_list_command`, `raw_snapshot`, `filtered_snapshot`, `goal_repo_family`, and `verified_repo_family`
  - a `repositories` list in the exact verified 23-library order
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

## Verification Phases

### `check_01_inventory_scaffold_smoke`

- phase ID: `check_01_inventory_scaffold_smoke`
- type: `check`
- bounce_target: `impl_01_inventory_scaffold`
- purpose: prove the GitHub inventory, raw-to-filtered scope verification, both staging sources, every required build mode including the appended untagged `libexif` safe-debian case, and asset-import path normalization all work before any validator harness directories are added
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

### `check_01_inventory_scaffold_review`

- phase ID: `check_01_inventory_scaffold_review`
- type: `check`
- bounce_target: `impl_01_inventory_scaffold`
- purpose: review that validator now has checked-in raw and filtered inventory proofs, an exact manifest contract for later import and build phases, verbatim mature build metadata, exact appended pinned-entry build metadata, and non-destructive staging, import, and build tooling
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

## Success Criteria

- The checked-in inventory proves the real SafeLibs repo family is `port-*` and preserves both raw and filtered snapshots.
- `repositories.yml` becomes the exact checked-in import and build contract for all 23 libraries, including fixed pinned entries, build roots, ordered import roots, ordered excludes, and empty runtime fixture lists.
- Non-destructive staging, import, and build tooling works against both local sibling repos and authenticated GitHub clones.
- The phase proves all required build modes and asset-projection rules before later harness phases depend on them.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

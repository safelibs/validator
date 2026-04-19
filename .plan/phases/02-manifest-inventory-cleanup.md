# 2. Manifest, Inventory, and Legacy Safe Tooling Cleanup

## Phase Name

Manifest, Inventory, and Legacy Safe Tooling Cleanup

## Implement Phase ID

`impl_phase_02_manifest_inventory_cleanup`

## Preexisting Inputs

- `.plan/goal.md`
- `tools/testcases.py` from phase 1
- `repositories.yml`
- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- `tools/inventory.py`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `tools/import_port_assets.py`
- `tools/verify_imported_assets.py`
- Existing checked-in `tests/<library>/tests/tagged-port/**`
- Existing `tests/<library>/tests/fixtures/*.json`

## New Outputs

- New original-only `repositories.yml` schema.
- Skeleton `tests/<library>/testcases.yml` files for all 19 libraries with `schema_version`, `library`, `apt_packages`, and an empty `testcases: []` list. Each skeleton's `apt_packages` list must be copied exactly, in order, from its `repositories.yml` entry. These are placeholders only; phase 4 and phase 5 populate the actual source and usage cases.
- Updated inventory validation that no longer requires port-repo tag reachability for normal CI.
- Legacy tool behavior removed from normal commands or isolated behind explicit legacy commands.
- Updated unit coverage for the new schema.

## File Changes

- Rewrite `repositories.yml`.
- Add skeleton `tests/<library>/testcases.yml` files for all 19 libraries.
- Modify `tools/inventory.py`.
- Modify `tools/import_port_assets.py`.
- Modify `tools/verify_imported_assets.py`.
- Modify or delete `tools/build_safe_debs.py` from the active runner path.
- Modify or delete `tools/stage_port_repos.py` from the active workflow path.
- Modify `Makefile`.
- Modify `unit/test_inventory.py`.
- Modify `unit/test_import_port_assets.py`.
- Modify `unit/test_verify_imported_assets.py`.
- Modify `unit/test_build_safe_debs.py`; remove it if the tool is removed.
- Keep `inventory/*.json` as historical snapshots unless final cleanup deletes them.

## Implementation Details

### Phase Scope Notes

This phase owns the canonical `repositories.yml` v2 manifest, all skeleton testcase manifests, and removal or quarantine of legacy inventory/staging/build commands from the active workflow. Consume the existing inventory snapshots, imported test trees, and fixture JSON files as migration inputs; do not refetch repositories, recollect inventory, or regenerate mirrors.

Use this `repositories.yml` top-level shape:

```yaml
schema_version: 2
suite:
  name: ubuntu-24.04-original-apt
  image: ubuntu:24.04
  apt_suite: noble
libraries:
  - name: cjson
    apt_packages:
      - libcjson1
      - libcjson-dev
    testcases: tests/cjson/testcases.yml
    source_snapshot: tests/cjson/tests/tagged-port/original
    fixtures:
      dependents: tests/cjson/tests/fixtures/dependents.json
```

`repositories.yml` `libraries[*].apt_packages` is canonical. The `apt_packages` list in `tests/<library>/testcases.yml` must have exact ordered equality with the canonical list after YAML parsing. `tools/testcases.load_manifests()`, `tools/testcases.py --check-manifest-only`, `tools/testcases.py --check`, runner result validation, proof validation, site data generation, and the phase 2 audit must all enforce this equality so Docker installation metadata, testcase metadata, result JSON, proof, and site data cannot drift. Do not add `override_packages` or any other package-list alias to the schema.

`apt_packages` means the Ubuntu binary packages from the original library source package that are part of the validation surface: runtime shared-library packages, development/header packages, first-party CLI/tool packages, first-party test binary packages, and first-party language binding packages only when this repository directly exercises that binding. Test harness tools, compilers, codecs, unrelated libraries, and dependent client applications must be installed as Dockerfile test dependencies and must not appear in `apt_packages`, result JSON `apt_packages`, proof package lists, or site package lists. The exact ordered canonical package map is:

```yaml
cjson:
  - libcjson1
  - libcjson-dev
giflib:
  - libgif7
  - libgif-dev
  - giflib-tools
libarchive:
  - libarchive13t64
  - libarchive-dev
  - libarchive-tools
libbz2:
  - libbz2-1.0
  - libbz2-dev
  - bzip2
libcsv:
  - libcsv3
  - libcsv-dev
libexif:
  - libexif12
  - libexif-dev
libjpeg-turbo:
  - libjpeg-turbo8
  - libjpeg-turbo8-dev
  - libturbojpeg
  - libturbojpeg0-dev
  - libjpeg-turbo-progs
libjson:
  - libjson-c5
  - libjson-c-dev
liblzma:
  - liblzma5
  - liblzma-dev
  - xz-utils
libpng:
  - libpng16-16t64
  - libpng-dev
  - libpng-tools
libsdl:
  - libsdl2-2.0-0
  - libsdl2-dev
  - libsdl2-tests
libsodium:
  - libsodium23
  - libsodium-dev
libtiff:
  - libtiff6
  - libtiffxx6
  - libtiff-dev
  - libtiff-tools
libuv:
  - libuv1t64
  - libuv1-dev
libvips:
  - libvips42t64
  - libvips-dev
  - libvips-tools
  - gir1.2-vips-8.0
libwebp:
  - libwebp7
  - libwebpdemux2
  - libwebpmux3
  - libwebpdecoder3
  - libsharpyuv0
  - libwebp-dev
  - libsharpyuv-dev
  - webp
libxml:
  - libxml2
  - libxml2-dev
  - libxml2-utils
  - python3-libxml2
libyaml:
  - libyaml-0-2
  - libyaml-dev
libzstd:
  - libzstd1
  - libzstd-dev
  - zstd
```

Required library order:

`cjson`, `giflib`, `libarchive`, `libbz2`, `libcsv`, `libexif`, `libjpeg-turbo`, `libjson`, `liblzma`, `libpng`, `libsdl`, `libsodium`, `libtiff`, `libuv`, `libvips`, `libwebp`, `libxml`, `libyaml`, `libzstd`.

`tools.inventory.load_manifest()` must:

- Accept only `schema_version: 2` for the new workflow.
- Require `suite.image`, `suite.apt_suite`, and a non-empty `libraries` list.
- Require unique library names in the fixed order above.
- Require every library to define `apt_packages`, `testcases`, `source_snapshot`, and `fixtures.dependents`.
- Reject `fixtures.relevant_cves` and any other CVE/security-scope fixture reference in the final v2 manifest. Existing `tests/<library>/tests/fixtures/relevant_cves.json` files are migration diagnostics only. Delete them before final acceptance after extracting any neutral non-CVE fixture data into a different filename with no safe/unsafe/excluded vocabulary.
- Require every library's `apt_packages` to equal the exact ordered canonical package map above; non-empty package lists or Dockerfile-derived package lists are not sufficient.
- Reject `override_packages`, `safe_packages`, `unsafe_packages`, `verify_packages`, or any other package-list field besides `apt_packages`.
- Require all referenced paths to be repository-relative and to exist.
- Forbid active `build`, `github_repo`, `ref`, `validator.imports`, `safe-debian`, `checkout-artifacts`, and `SafeLibs` archive metadata in the final schema.
- Keep compatibility helpers out of normal commands. Limit any legacy fixture helper to isolated tests.

Shared library selection helpers must be updated for the v2 schema:

- Replace `select_repositories()` usage in normal commands with a helper that reads `manifest["libraries"]`, preserves manifest order, rejects duplicate `--library` selections, and errors on unknown libraries.
- Remove normal-command references to `manifest["repositories"]`; that key may appear only inside deleted legacy fixtures or explicitly isolated compatibility tests during migration.

`tools/testcases.py --check-manifest-only` must allow the phase 2 skeleton manifests to contain an empty `testcases` list, but it must still require exact `apt_packages` equality between `repositories.yml` and every `tests/<library>/testcases.yml`. Full `--check` mode must require the same package equality plus the phase 4/5 coverage thresholds and executable scripts.

`Makefile` exposes:

- `make unit`
- `make check-testcases`
- `make matrix`
- `make proof`
- `make site`
- `make verify-site`

Remove from normal workflow and final active code:

- `make inventory`
- `make stage-ports`
- `make build-safe`
- `make import-assets`

Delete the old import/stage/build commands and their unit tests by final acceptance. Any compatibility fixture must be isolated and not imported by normal commands. No final active command, workflow, or README path may import or call `tools/build_safe_debs.py`, `tools/stage_port_repos.py`, `tools/import_port_assets.py`, or `tools/verify_imported_assets.py`.

## Verification Phases

`check_phase_02_manifest_unit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_02_manifest_inventory_cleanup`
- Purpose: verify the new original-only manifest loader, package metadata validation, and library selection behavior.
- Commands:

```bash
python3 -m unittest \
  unit.test_inventory \
  unit.test_testcases \
  unit.test_run_matrix \
  -v
```

`check_phase_02_manifest_audit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_02_manifest_inventory_cleanup`
- Purpose: verify `repositories.yml` has all 19 libraries, no SafeLibs build contract, and every library points at a testcase manifest.
- Commands:

```bash
python3 tools/testcases.py --config repositories.yml --tests-root tests --check-manifest-only
python3 - <<'PY'
from pathlib import Path
import yaml

manifest = yaml.safe_load(Path("repositories.yml").read_text())
libraries = [entry["name"] for entry in manifest["libraries"]]
expected = [
    "cjson", "giflib", "libarchive", "libbz2", "libcsv", "libexif",
    "libjpeg-turbo", "libjson", "liblzma", "libpng", "libsdl",
    "libsodium", "libtiff", "libuv", "libvips", "libwebp",
    "libxml", "libyaml", "libzstd",
]
expected_packages = {
    "cjson": ["libcjson1", "libcjson-dev"],
    "giflib": ["libgif7", "libgif-dev", "giflib-tools"],
    "libarchive": ["libarchive13t64", "libarchive-dev", "libarchive-tools"],
    "libbz2": ["libbz2-1.0", "libbz2-dev", "bzip2"],
    "libcsv": ["libcsv3", "libcsv-dev"],
    "libexif": ["libexif12", "libexif-dev"],
    "libjpeg-turbo": ["libjpeg-turbo8", "libjpeg-turbo8-dev", "libturbojpeg", "libturbojpeg0-dev", "libjpeg-turbo-progs"],
    "libjson": ["libjson-c5", "libjson-c-dev"],
    "liblzma": ["liblzma5", "liblzma-dev", "xz-utils"],
    "libpng": ["libpng16-16t64", "libpng-dev", "libpng-tools"],
    "libsdl": ["libsdl2-2.0-0", "libsdl2-dev", "libsdl2-tests"],
    "libsodium": ["libsodium23", "libsodium-dev"],
    "libtiff": ["libtiff6", "libtiffxx6", "libtiff-dev", "libtiff-tools"],
    "libuv": ["libuv1t64", "libuv1-dev"],
    "libvips": ["libvips42t64", "libvips-dev", "libvips-tools", "gir1.2-vips-8.0"],
    "libwebp": ["libwebp7", "libwebpdemux2", "libwebpmux3", "libwebpdecoder3", "libsharpyuv0", "libwebp-dev", "libsharpyuv-dev", "webp"],
    "libxml": ["libxml2", "libxml2-dev", "libxml2-utils", "python3-libxml2"],
    "libyaml": ["libyaml-0-2", "libyaml-dev"],
    "libzstd": ["libzstd1", "libzstd-dev", "zstd"],
}
assert libraries == expected, libraries
text = Path("repositories.yml").read_text()
for forbidden in ["safe-debian", "SafeLibs", "safelibs", "base_url", "pin_priority", "artifact_globs", "override_packages", "relevant_cves"]:
    assert forbidden not in text, forbidden
for entry in manifest["libraries"]:
    library = entry["name"]
    assert (Path("tests") / entry["name"] / "testcases.yml").as_posix() == entry["testcases"]
    assert entry["apt_packages"] == expected_packages[library], library
    testcase_manifest = yaml.safe_load(Path(entry["testcases"]).read_text())
    assert testcase_manifest["apt_packages"] == expected_packages[library], library
PY
```

## Success Criteria

- `repositories.yml` is schema version 2, lists the 19 libraries in the fixed order, and contains only the canonical ordered `apt_packages` list for each library.
- Every library has a skeleton `tests/<library>/testcases.yml` whose `apt_packages` exactly match `repositories.yml`.
- Normal commands no longer stage port repositories, build SafeLibs packages, or consume SafeLibs archive metadata.
- Manifest, inventory, and testcase validation reject package-list drift and forbidden schema fields.
- All explicit phase 2 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Unit and audit checks above.
  - Confirm active commands do not mention port staging:

  ```bash
  rg -n "stage_port|stage-ports|build_safe|build-safe|safe-debian|safe_deb|safe-deb|safe deb|install_safe_debs|VALIDATOR_SAFE_DEB_DIR|check-remote-tags|--mode both|--mode safe|--safe-deb-root|--port-root|port_root|port-root|\\.work/ports|\\.work/build-safe" \
    Makefile test.sh .github/workflows tools/run_matrix.py tools/inventory.py README.md \
    || true
  ```

  Remaining matches must be in explicitly marked legacy documentation or pending later-phase files, not active normal workflow.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_02_manifest_inventory_cleanup` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

# Phase 04

## Phase Name

`media-validators`

## Implement Phase ID

`impl_04_media_validators`

## Preexisting Inputs

- `repositories.yml`
- `test.sh`
- `tools/import_port_assets.py`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `tests/_shared/common.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/entrypoint.sh`
- the phase-1-declared `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` entries for `libexif`, `libjpeg-turbo`, `libpng`, `libtiff`, `libvips`, and `libwebp` in `repositories.yml`
- read-only sibling repos `/home/yans/safelibs/port-libexif`, `/home/yans/safelibs/port-libjpeg-turbo`, `/home/yans/safelibs/port-libpng`, `/home/yans/safelibs/port-libtiff`, `/home/yans/safelibs/port-libvips`, and `/home/yans/safelibs/port-libwebp`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- `/home/yans/safelibs/port-libexif/dependents.json`
- `/home/yans/safelibs/port-libexif/relevant_cves.json`
- `/home/yans/safelibs/port-libjpeg-turbo/dependents.json`
- `/home/yans/safelibs/port-libjpeg-turbo/relevant_cves.json`
- `/home/yans/safelibs/port-libpng/dependents.json`
- `/home/yans/safelibs/port-libpng/relevant_cves.json`
- `/home/yans/safelibs/port-libtiff/dependents.json`
- `/home/yans/safelibs/port-libtiff/relevant_cves.json`
- `/home/yans/safelibs/port-libvips/dependents.json`
- `/home/yans/safelibs/port-libvips/relevant_cves.json`
- `/home/yans/safelibs/port-libwebp/dependents.json`
- `/home/yans/safelibs/port-libwebp/relevant_cves.json`

## New Outputs

- complete validator harness directories for `libexif`, `libjpeg-turbo`, `libpng`, `libtiff`, `libvips`, and `libwebp`

## File Changes

- `tests/libexif/**`
- `tests/libjpeg-turbo/**`
- `tests/libpng/**`
- `tests/libtiff/**`
- `tests/libvips/**`
- `tests/libwebp/**`

## Implementation Details

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

## Verification Phases

### `check_04_media_matrix`

- phase ID: `check_04_media_matrix`
- type: `check`
- bounce_target: `impl_04_media_validators`
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

### `check_04_media_review`

- phase ID: `check_04_media_review`
- type: `check`
- bounce_target: `impl_04_media_validators`
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
    "sample.jpg",
    "/tmp",
    "command -v vips",
    "command -v vipsthumbnail",
    "command -v vipsheader",
]:
    if token not in variables:
        raise SystemExit(f"libvips variables.sh missing token: {token}")
for token in ["@abs_top_srcdir@", "@abs_top_builddir@", "/tools/vips", "VIPS_SAFE_BUILD_DIR"]:
    if token in variables:
        raise SystemExit(f"libvips variables.sh kept build-tree token: {token}")
thumbnail_smoke = Path("tests/libvips/tests/upstream/test/test_thumbnail.sh").read_text()
if "variables.sh" not in thumbnail_smoke:
    raise SystemExit("libvips thumbnail smoke does not source generated variables.sh")
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

## Success Criteria

- Each media and imaging library passes original and safe runs.
- Special path and layout cases are normalized into the common validator contract, including the shared Dockerfile and entrypoint delegate pattern.
- `libvips` is narrowed to the fixed runtime-only contract from the source plan, including the exact manifest rewrite and the generated `tests/libvips/tests/upstream/test/variables.sh` bindings for `test_images`, `image`, `tmp`, and installed `vips` binaries.
- Preserved fixture JSON remains byte-identical to the sibling repo copies and validator-authored glue remains mode-blind.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

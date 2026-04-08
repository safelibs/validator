# Phase 05

## Phase Name

`archive-system-validators`

## Implement Phase ID

`impl_05_archive_system_validators`

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
- the phase-1-declared `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` entries for `libarchive`, `libbz2`, `liblzma`, `libsdl`, `libsodium`, and `libzstd` in `repositories.yml`
- read-only sibling repos `/home/yans/safelibs/port-libarchive`, `/home/yans/safelibs/port-libbz2`, `/home/yans/safelibs/port-liblzma`, `/home/yans/safelibs/port-libsdl`, `/home/yans/safelibs/port-libsodium`, and `/home/yans/safelibs/port-libzstd`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- `/home/yans/safelibs/port-libarchive/dependents.json`
- `/home/yans/safelibs/port-libarchive/relevant_cves.json`
- `/home/yans/safelibs/port-libbz2/dependents.json`
- `/home/yans/safelibs/port-libbz2/relevant_cves.json`
- `/home/yans/safelibs/port-liblzma/dependents.json`
- `/home/yans/safelibs/port-liblzma/relevant_cves.json`
- `/home/yans/safelibs/port-libsdl/dependents.json`
- `/home/yans/safelibs/port-libsdl/relevant_cves.json`
- `/home/yans/safelibs/port-libsodium/dependents.json`
- `/home/yans/safelibs/port-libsodium/relevant_cves.json`
- `/home/yans/safelibs/port-libzstd/dependents.json`
- `/home/yans/safelibs/port-libzstd/relevant_cves.json`

## New Outputs

- complete validator harness directories for `libarchive`, `libbz2`, `liblzma`, `libsdl`, `libsodium`, and `libzstd`

## File Changes

- `tests/libarchive/**`
- `tests/libbz2/**`
- `tests/liblzma/**`
- `tests/libsdl/**`
- `tests/libsodium/**`
- `tests/libzstd/**`

## Implementation Details

- Import the existing tracked harness source from sibling repos by consuming the phase-1 manifest metadata. Keep the declared tracked generated fixtures under `tests/<library>/tests/harness-source/generated/**/*` exactly where phase 1 projected them.
- Copy `dependents.json` and `relevant_cves.json` byte-for-byte from the sibling repos for every library in this batch.
- Fixed import scope by library:
- `libarchive`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `safe/generated/api_inventory.json`, `safe/generated/cve_matrix.json`, `safe/generated/link_compat_manifest.json`, `safe/generated/original_build_contract.json`, `safe/generated/original_package_metadata.json`, `safe/generated/original_c_build`, `safe/generated/original_link_objects`, `safe/generated/original_pkgconfig/libarchive.pc`, `safe/generated/pkgconfig/libarchive.pc`, `safe/generated/rust_test_manifest.json`, `safe/generated/test_manifest.json`, `original/libarchive-3.7.2`
- `libbz2`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
- `liblzma`: `safe/tests`, `safe/docker`, `safe/scripts`
- `libsdl`: `safe/tests`, `safe/debian/tests`, `safe/generated/dependent_regression_manifest.json`, `safe/generated/noninteractive_test_list.json`, `safe/generated/original_test_port_map.json`, `safe/generated/perf_workload_manifest.json`, `safe/generated/perf_thresholds.json`, `safe/generated/reports/perf-baseline-vs-safe.json`, `safe/generated/reports/perf-waivers.md`, `original/test`
- `libsodium`: `safe/tests`, `safe/docker`
- `libzstd`: `safe/tests`, `safe/debian/tests`, `safe/docker`, `safe/scripts`, `original/libzstd-1.5.5+dfsg2`
- `liblzma` is the key normalization case. Keep tracked dependent smoke sources from `safe/tests/dependents/**/*`, but do not import generated output under `safe/tests/generated/**/*`.
- Preserve package-smoke assets under `tests/<library>/tests/package/debian-tests/**/*` when they exist in the imported source. `libarchive`, `libbz2`, and `libzstd` are the explicit cases in this batch.
- Libraries that already ship `safe/docker/**/*` or `safe/scripts/**/*` should be rewritten only as far as needed to fit the validator `Dockerfile` and shared entrypoint contract.
- Fixed batch rewrites:
- `libarchive` must consume the copied validator-owned `tests/libarchive/tests/harness-source/generated/**/*` artifacts rather than reading from sibling `safe/generated/**/*`
- `libarchive` must rewrite any original-oracle or generated-build assumption so helper binaries compile from copied `original/libarchive-3.7.2/**/*` sources plus copied generated artifacts inside validator-owned scratch only
- `libbz2` must use copied upstream samples, headers, and source files from `original/**/*` rather than any sibling build output
- `liblzma` must not add any undeclared `original/**/*` dependency
- `libsdl` must consume the copied validator-owned `tests/libsdl/tests/harness-source/generated/**/*` artifacts, including the preserved perf manifests and report inputs
- `libsdl` must compile copied `original/test/**/*` sources and fixtures against the installed package surface
- `libsodium` must not add any undeclared `original/**/*` dependency
- `libzstd` must rewrite any current expectation of `safe/out/**/*` or non-imported build directories to validator-owned scratch while keeping all copied upstream tests and corpora under validator control
- Remove any runtime source-build logic from the final archive and system harnesses so containers exercise installed packages, not ad hoc source builds.

## Verification Phases

### `check_05_archive_system_matrix`

- phase ID: `check_05_archive_system_matrix`
- type: `check`
- bounce_target: `impl_05_archive_system_validators`
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

### `check_05_archive_system_review`

- phase ID: `check_05_archive_system_review`
- type: `check`
- bounce_target: `impl_05_archive_system_validators`
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

## Success Criteria

- Each archive, compression, and system library passes original and safe runs.
- The declared tracked generated sibling artifacts for `libarchive` and `libsdl` are imported into validator-owned `tests/*/tests/harness-source/generated/**/*` paths and consumed from there.
- `liblzma` keeps `safe/tests/generated` excluded.
- Shared Dockerfile and entrypoint delegation is preserved, preserved fixture JSON stays byte-identical, and validator-authored glue remains mode-blind.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

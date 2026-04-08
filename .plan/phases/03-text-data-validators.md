# Phase 03

## Phase Name

`text-data-validators`

## Implement Phase ID

`impl_03_text_data_validators`

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
- the phase-1-declared `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` entries for `cjson`, `giflib`, `libcsv`, `libjson`, `libxml`, and `libyaml` in `repositories.yml`
- read-only sibling repos `/home/yans/safelibs/port-cjson`, `/home/yans/safelibs/port-giflib`, `/home/yans/safelibs/port-libcsv`, `/home/yans/safelibs/port-libjson`, `/home/yans/safelibs/port-libxml`, and `/home/yans/safelibs/port-libyaml`, used only as the `tools/stage_port_repos.py --source-root` input and as the byte-identity baseline for preserved fixture JSON
- `/home/yans/safelibs/port-cjson/dependents.json`
- `/home/yans/safelibs/port-cjson/relevant_cves.json`
- `/home/yans/safelibs/port-giflib/dependents.json`
- `/home/yans/safelibs/port-giflib/relevant_cves.json`
- `/home/yans/safelibs/port-libcsv/dependents.json`
- `/home/yans/safelibs/port-libcsv/relevant_cves.json`
- `/home/yans/safelibs/port-libjson/dependents.json`
- `/home/yans/safelibs/port-libjson/relevant_cves.json`
- `/home/yans/safelibs/port-libxml/dependents.json`
- `/home/yans/safelibs/port-libxml/relevant_cves.json`
- `/home/yans/safelibs/port-libyaml/dependents.json`
- `/home/yans/safelibs/port-libyaml/relevant_cves.json`

## New Outputs

- complete validator harness directories for `cjson`, `giflib`, `libcsv`, `libjson`, `libxml`, and `libyaml`

## File Changes

- `tests/cjson/**`
- `tests/giflib/**`
- `tests/libcsv/**`
- `tests/libjson/**`
- `tests/libxml/**`
- `tests/libyaml/**`

## Implementation Details

- For every library in this phase, create:
- `tests/<library>/Dockerfile`
- `tests/<library>/docker-entrypoint.sh`
- `tests/<library>/tests/run.sh`
- `tests/<library>/tests/fixtures/dependents.json`
- `tests/<library>/tests/fixtures/relevant_cves.json`
- imported upstream, dependent, regression, and package assets under `tests/<library>/tests/`
- Use `tools/import_port_assets.py` plus the phase-1 manifest metadata to copy tracked assets into validator-owned paths, then hand-normalize them into:
- `tests/upstream/` for copied upstream suites
- `tests/dependents/` for real-application smokes
- `tests/cve/` for retained regression cases
- `tests/package/` for package-surface compile, install, and Debian autopkgtests
- `tests/fixtures/` for inventories and static data
- Fixed import scope by library:
- `cjson`: `safe/tests`, `safe/scripts`, `original/tests`, `original/fuzzing`, `original/test.c`, `original/cJSON.h`, `original/cJSON_Utils.h`
- `giflib`: `safe/tests`, `original/tests`, `original/pic`, `original/gif_lib.h`
- `libcsv`: `safe/tests`, `safe/debian/tests`, `original/examples`, `original/test_csv.c`, `original/csv.h`
- `libjson`: `safe/tests`, `safe/debian/tests`
- `libxml`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
- `libyaml`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/include`, `original/tests`, `original/examples`
- Derive each `Dockerfile` from the corresponding `port-<lib>/test-original.sh` runtime and package assumptions, but remove all host-repo assumptions.
- Translate library-specific host logic into `tests/<library>/tests/run.sh`, while keeping `/safedebs` installation and `VALIDATOR_TRACE` handling entirely inside the shared phase-2 entrypoint contract.
- Fixed batch rewrites:
- `cjson` compiles copied original test and fuzz inputs against the installed package surface inside the container
- `giflib` runs copied `original/tests` and `original/pic` corpora entirely from the validator tree
- `libcsv` compiles copied `original/examples` and `original/test_csv.c` sources against installed packages
- `libjson` replaces the missing `original/build/*` baseline with validator-owned package-surface coverage built from copied `safe/tests/package/**/*` assets plus copied `safe/debian/tests/unit-test`
- `libxml` rewrites any expectation of `original/.libs/**/*` or `safe/target/stage/**/*` so helper binaries compile against installed headers and run from copied `original/**` fixtures
- `libyaml` compiles copied `original/tests` and `original/examples` sources against the installed package surface
- Remove any runtime source-build steps from translated harnesses. Original mode must run against distro-packaged libraries baked into the image. Safe mode must run against the same image after `/safedebs` is installed by the shared entrypoint.
- Preserve existing inventories and CVE selections exactly by byte-identical copies of the sibling repo JSON files into validator-owned fixtures instead of regenerating or reformatting them.

## Verification Phases

### `check_03_text_data_matrix`

- phase ID: `check_03_text_data_matrix`
- type: `check`
- bounce_target: `impl_03_text_data_validators`
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

### `check_03_text_data_review`

- phase ID: `check_03_text_data_review`
- type: `check`
- bounce_target: `impl_03_text_data_validators`
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

## Success Criteria

- Each imported text or data library passes both original and safe runs through `test.sh`.
- Every harness uses the shared Dockerfile and entrypoint delegate contract.
- Validator-authored harness glue remains mode-blind.
- `dependents.json` and `relevant_cves.json` remain byte-identical to the sibling repo fixtures.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

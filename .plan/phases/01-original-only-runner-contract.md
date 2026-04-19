# 1. Original-Only Runner and Testcase Contract

## Phase Name

Original-Only Runner and Testcase Contract

## Implement Phase ID

`impl_phase_01_original_only_runner_contract`

## Preexisting Inputs

- Existing inputs must be consumed in place. Do not refetch, restage, rediscover, or regenerate checked-in migration artifacts unless this phase explicitly names the update as a new output.
- Existing workflow-generation diagnostics: `workflow.yaml`, `.plan/workflow-structure.yaml`, `.plan/phases/*`, and `.plan/plan-before-cleanup.md`; these must not be imported or used as prompt/workflow source inputs.
- `.plan/goal.md`
- `repositories.yml`
- `test.sh`
- `tools/run_matrix.py`
- `tools/proof.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/run_library_tests.sh`
- `tests/_shared/runtime_helpers.sh`
- `unit/test_run_matrix.py`
- `unit/test_proof.py`
- `unit/fixtures/demo-*`

## New Outputs

- New `tools/testcases.py` module.
- New `unit/test_testcases.py`.
- New original-only unit fixtures under `unit/fixtures/original-only-manifest.yml`, `unit/fixtures/original-only-tests/`, and `unit/fixtures/original-override-debs/`.
- New compact dependent-fixture unit coverage for the existing `dependents`, `runtime_dependents`/`build_time_dependents`, `packages`, and `selected_applications` schema shapes.
- Reworked `tools/run_matrix.py` original-only runner.
- Reworked `tools/proof.py` and `tools/verify_proof_artifacts.py` foundation for original-only artifacts.
- New `tests/_shared/install_override_debs.sh`.

## File Changes

- Modify `test.sh`.
- Modify `tools/run_matrix.py`.
- Add `tools/testcases.py`.
- Modify `tools/proof.py`.
- Modify `tools/verify_proof_artifacts.py`.
- Add `tests/_shared/install_override_debs.sh`.
- Modify `tests/_shared/run_library_tests.sh`.
- Keep `tests/_shared/runtime_helpers.sh`; add only generic helper functions.
- Modify `unit/test_run_matrix.py`.
- Modify `unit/test_proof.py`.
- Add `unit/test_testcases.py`.
- Add fixture files under `unit/fixtures/original-only-*`.
- Leave all real `tests/<library>/` trees unchanged in this phase except shared helper references in fixture-only paths.

## Implementation Details

### Phase Scope Notes

This phase owns the original-only runner, testcase manifest loader, proof-validation foundation, and generic override package capability. Treat `workflow.yaml`, `.plan/workflow-structure.yaml`, `.plan/phases/*`, and `.plan/plan-before-cleanup.md` as diagnostic history only; they are not prompt or workflow source inputs. Preserve `.plan/goal.md`, existing unit fixtures, and runner/proof modules in place while replacing safe/both behavior with original-only behavior.

Add `tools/testcases.py` with these public APIs:

```python
@dataclass(frozen=True)
class Testcase:
    id: str
    title: str
    description: str
    kind: str
    command: list[str]
    timeout_seconds: int
    tags: tuple[str, ...]
    client_application: str | None = None
    requires: tuple[str, ...] = ()

@dataclass(frozen=True)
class TestcaseManifest:
    library: str
    schema_version: int
    apt_packages: tuple[str, ...]
    testcases: tuple[Testcase, ...]

def validate_case_id(value: str) -> str: ...
def load_testcase_manifest(path: Path, *, library: str) -> TestcaseManifest: ...
def load_manifests(config: dict[str, Any], *, tests_root: Path) -> dict[str, TestcaseManifest]: ...
def extract_dependent_identifiers(payload: dict[str, Any]) -> set[str]: ...
def load_dependent_identifiers(path: Path) -> set[str]: ...
def testcase_result_sort_key(result: dict[str, Any]) -> tuple[str, str]: ...
```

Manifest schema for `tests/<library>/testcases.yml`:

```yaml
schema_version: 1
library: cjson
apt_packages:
  - libcjson1
  - libcjson-dev
testcases:
  - id: source-parse-print-roundtrip
    title: Parse and print JSON round trip
    description: Compiles a small C program against the Ubuntu libcjson headers and verifies parse, mutate, and print behavior.
    kind: source
    command:
      - bash
      - -x
      - /validator/tests/cjson/tests/cases/source/parse-print-roundtrip.sh
    timeout_seconds: 300
    tags:
      - api
      - parser
```

Validation rules:

- `schema_version` must be `1`.
- `library` must match the directory and manifest entry.
- `testcases` must be a list. An empty list is allowed only for phase 2 skeleton manifests and `--check-manifest-only`; `tools/run_matrix.py`, `tools/verify_proof_artifacts.py`, and full `tools/testcases.py --check` must reject selected libraries with zero testcases.
- `id` must match `^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$`.
- IDs are unique per library.
- `kind` must be `source` or `usage`.
- `title` and `description` must be non-empty semantic text.
- `command` must be a non-empty list of strings. The first element must be an executable name or absolute container path; command elements must not contain NUL bytes, backslashes, `..` path segments, or repository-host absolute paths; and any `/validator/...` path must stay under `/validator/tests/<library>/`.
- `timeout_seconds` must be an integer between `1` and `7200`.
- `apt_packages` must be non-empty because the repository validates Ubuntu apt-installed originals.
- `load_manifests()` must compare each testcase manifest's `apt_packages` to the selected `repositories.yml` entry and reject any mismatch, including different order, missing packages, extra packages, or spelling differences. `repositories.yml` is canonical for Dockerfile installation, runner result metadata, and proof metadata; the duplicate list in `testcases.yml` exists only to make testcase manifests self-documenting.
- A `kind: source` testcase exercises only the canonical library package surface declared in `apt_packages`: runtime libraries, development headers, first-party CLIs/tools, first-party test binaries, or first-party language bindings from the same validated source package. Source cases may compile local harness programs against the canonical headers and may use generic test helpers, compilers, shells, and checked-in fixtures, but they must not use downstream client applications or non-canonical language wrappers. Source cases must omit `client_application` or set it to null.
- `kind: usage` cases must define a non-empty `client_application` that matches a normalized identifier from `tests/<library>/tests/fixtures/dependents.json` using `load_dependent_identifiers()`.
- A `kind: usage` testcase exercises a dependent client application, downstream language wrapper, or package outside the canonical `apt_packages` list. The dependent package may be installed in the library Dockerfile as a test dependency, but it must not be copied into `repositories.yml` `apt_packages`, result JSON `apt_packages`, proof package lists, or site package displays. Examples that must be usage cases, not source cases, are `exif` for `libexif`, `xsltproc` for `libxml`, and `pyvips` for `libvips`, because those are dependent-client surfaces unless they appear in the canonical package list for that library.
- `extract_dependent_identifiers()` must support every existing dependent fixture shape without rewriting the fixtures. It must concatenate object entries from top-level `dependents`, `runtime_dependents`, `build_time_dependents`, `packages`, and `selected_applications` lists when those lists exist. For each entry object, it must collect non-empty string identifiers from scalar keys `name`, `source_package`, `package`, `binary_package`, `runtime_package`, `software_name`, and `slug`; list keys `packages`, `binary_examples`, `related_packages`, and `used_by`; nested `package_dependencies[*].package`; and nested `dependency_paths[*].binary_package` and `dependency_paths[*].source_package`. Trim whitespace, drop empty values, and preserve exact spelling for manifest comparison. This explicitly covers the existing `libjpeg-turbo` `runtime_dependents`/`build_time_dependents` shape, the existing `libzstd` top-level `packages` shape, the existing `libvips` `selected_applications` shape, and the standard top-level `dependents` shape used by the other libraries.

Rework `tools/run_matrix.py`:

- Remove final support for `--mode safe` and `--mode both`. During phase 1 unit migration, accept only absent `--mode` or `--mode original`; any `safe` or `both` value raises `ValidatorError`.
- Replace `--safe-deb-root` with `--override-deb-root`. Validate layout as `<override-deb-root>/<library>/*.deb`.
- Keep `--library`, `--record-casts`, `--config`, `--tests-root`, `--artifact-root`, and `--list-libraries`.
- Do not import or call `tools.build_safe_debs`.
- Build one Docker image per library from `tests/<library>/Dockerfile`.
- If `--override-deb-root` is provided, mount the selected library leaf `<override-deb-root>/<library>` read-only at `/override-debs` for every testcase in that library. If it is absent, do not mount `/override-debs`.
- Run each testcase command separately with Docker and enforce the testcase `timeout_seconds` value. A timeout must mark only that testcase as `failed`, record the timeout in its log and result `error`, continue with the remaining cases, and contribute to the aggregate non-zero runner exit.
- When `--record-casts` is used, allocate a TTY and write `artifacts/casts/<library>/<case-id>.cast`.
- Write per-case logs to `artifacts/logs/<library>/<case-id>.log`.
- Write per-case results to `artifacts/results/<library>/<case-id>.json`.
- Write per-library summary to `artifacts/results/<library>/summary.json`.
- Every result JSON must include:

```json
{
  "schema_version": 2,
  "library": "cjson",
  "mode": "original",
  "testcase_id": "source-parse-print-roundtrip",
  "title": "Parse and print JSON round trip",
  "description": "Compiles a small C program...",
  "kind": "source",
  "client_application": null,
  "tags": ["api", "parser"],
  "requires": [],
  "status": "passed",
  "started_at": "2026-04-18T00:00:00Z",
  "finished_at": "2026-04-18T00:00:01Z",
  "duration_seconds": 1.0,
  "result_path": "results/cjson/source-parse-print-roundtrip.json",
  "log_path": "logs/cjson/source-parse-print-roundtrip.log",
  "cast_path": "casts/cjson/source-parse-print-roundtrip.cast",
  "exit_code": 0,
  "command": ["bash", "-x", "..."],
  "apt_packages": ["libcjson1", "libcjson-dev"],
  "override_debs_installed": false
}
```

- Result `status` must be exactly `passed` or `failed`. `started_at` and `finished_at` must be non-empty UTC ISO-8601 strings ending in `Z`; `duration_seconds` must be a finite non-negative number; `exit_code` must be an integer; `apt_packages` must exactly equal the canonical ordered list from `repositories.yml`; `result_path` must equal `results/<library>/<case-id>.json`; `log_path` must equal `logs/<library>/<case-id>.log` and point at an existing file; and `cast_path`, when present, must equal `casts/<library>/<case-id>.cast` and point at an existing asciinema v2 file.
- Summary JSON must include `schema_version: 2`, `library`, `mode: original`, and totals for `cases`, `source_cases`, `usage_cases`, `passed`, `failed`, `casts`, and `duration_seconds`.
- Continue after testcase failure and return non-zero only after all selected cases are attempted.
- Preserve existing `stream_process_with_cast()` but make it per testcase and not safe-specific.
- Result path, log path, and cast path must be artifact-root-relative, POSIX-style, traversal-safe, and deterministic from `(library, testcase_id)`.

Rework `tools/proof.py`:

- Keep reusable path and asciinema validation helpers.
- Rename safe-specific concepts to original-only testcase concepts.
- Validate `schema_version == 2`, `mode == "original"`, result identity, exact `apt_packages` equality against `repositories.yml`, required metadata types, log existence, and cast existence when `--record-casts` is expected.
- Implement result validation as a pure read-only operation. Do not call `tools.host_harness.write_summary()` on real artifact paths and do not normalize artifacts by writing them back to disk.

Override support:

- Add `tests/_shared/install_override_debs.sh` that looks for `/override-debs/*.deb`; if missing or empty, logs a neutral "no override packages found; continuing with apt originals" message.
- When present, run `apt-get update`, then install the concrete sorted list of `/override-debs/*.deb` files with `apt-get install -y /override-debs/<file>.deb ...` or `dpkg -i /override-debs/<file>.deb ...` followed by `apt-get -f install -y` in a deterministic way.
- The runner must mount a per-case temporary status directory at `/validator/status`; when override packages are installed, `install_override_debs.sh` writes `/validator/status/override-installed` so the runner can set `override_debs_installed` accurately in result JSON.
- No code path may call these packages safe, unsafe, or replacement in generated result/proof/site labels.

## Verification Phases

`check_phase_01_runner_unit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_01_original_only_runner_contract`
- Purpose: verify testcase manifest parsing, original-only CLI behavior, per-case result writing, cast validation, override `.deb` root validation, strict `passed`/`failed` status validation, rejection of `skipped`/`warned`/`excluded` statuses, and aggregate failure behavior.
- Commands:

```bash
python3 -m unittest \
  unit.test_testcases \
  unit.test_run_matrix \
  unit.test_proof \
  -v
```

`check_phase_01_fixture_matrix_smoke`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_01_original_only_runner_contract`
- Purpose: run the small fixture matrix through the new original-only runner and verify that each testcase has a result JSON, log, and cast.
- Commands:

```bash
rm -rf /tmp/validator-phase01-artifacts
python3 tools/run_matrix.py \
  --config unit/fixtures/original-only-manifest.yml \
  --tests-root unit/fixtures/original-only-tests \
  --artifact-root /tmp/validator-phase01-artifacts \
  --record-casts
python3 - <<'PY'
from pathlib import Path
import json

root = Path("/tmp/validator-phase01-artifacts")
results = sorted((root / "results").glob("*/*.json"))
assert results, "no testcase result json files"
for path in results:
    if path.name == "summary.json":
        continue
    payload = json.loads(path.read_text())
    assert payload["mode"] == "original", path
    assert payload["result_path"] == path.relative_to(root).as_posix(), path
    assert payload["cast_path"], path
    assert (root / payload["cast_path"]).is_file(), path
    assert (root / payload["log_path"]).is_file(), path
PY
```

## Success Criteria

- The runner, proof helpers, and unit fixtures use the original-only testcase contract with result schema version 2.
- The runner accepts only absent `--mode` or `--mode original`, rejects `safe` and `both`, and supports only generic `--override-deb-root` override packages.
- Each selected testcase writes deterministic result, log, and optional asciinema cast paths, and statuses are exactly `passed` or `failed`.
- Override `.deb` installation is optional, generic, and never labeled safe, unsafe, or replacement.
- All explicit phase 1 verification phases pass, and any remaining grep matches are intentional legacy test names scheduled for later removal.
- Additional source-plan verification notes must be satisfied:

  - Unit tests listed above.
  - Fixture matrix smoke listed above.
  - Targeted source grep:

  ```bash
  rg -n "safe|unsafe|safedebs|safe-deb|safe_deb|safe deb|install_safe_debs|VALIDATOR_SAFE_DEB_DIR|safe_workloads|--mode both|--mode safe|--safe-deb-root" \
    tools/run_matrix.py tools/proof.py tools/verify_proof_artifacts.py tests/_shared unit/fixtures \
    || true
  ```

  Any grep match must be an intentional legacy test name scheduled for later removal, not final runner behavior.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_01_original_only_runner_contract` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

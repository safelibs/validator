# 5. Usage-Based Dependent Client Testcases

## Phase Name

Usage-Based Dependent Client Testcases

## Implement Phase ID

`impl_phase_05_usage_case_catalogs`

## Preexisting Inputs

- `.plan/goal.md`
- `repositories.yml` v2
- `tests/<library>/testcases.yml` with source cases from phase 4
- `test.sh`
- `tools/testcases.py`
- `tools/verify_proof_artifacts.py`
- `unit/test_testcases.py`
- Existing `tests/<library>/tests/fixtures/dependents.json` for all 19 libraries.
- Existing imported dependent harness ideas in `tests/_shared/phase4_host_harness.py`.
- Existing `artifacts/downstream/<library>/<mode>/summary.json` as migration diagnostics only.
- Existing apt package lists in current Dockerfiles.

## New Outputs

- Usage entries in every `tests/<library>/testcases.yml`.
- `tests/<library>/tests/cases/usage/*.sh` scripts.
- Sanitized compact `tests/<library>/tests/fixtures/dependents.json` files that retain only dependent-client identifiers and package names needed by final usage cases.
- Optional shared helper functions for usage tests.
- Updated Dockerfiles with dependent-client apt packages.

## File Changes

For every library:

- Modify `tests/<library>/testcases.yml`.
- Add `tests/<library>/tests/cases/usage/*.sh`.
- Modify `tests/<library>/Dockerfile` to install the dependent applications and runtime packages needed by the usage cases.
- Modify or remove references to `tests/_shared/phase4_host_harness.py` after cases are migrated.

Shared and tooling:

- Modify `tests/_shared/runtime_helpers.sh` with generic helpers such as `validator_run_xvfb`, `validator_assert_contains`, and `validator_make_fixture`.
- Modify `tools/testcases.py` to validate usage-case dependent references and coverage thresholds.
- Modify `unit/test_testcases.py`.

## Implementation Details

### Phase Scope Notes

This phase owns dependent-client usage testcase metadata, usage scripts, sanitized dependent fixtures, and usage-related Docker dependencies. Consume existing `dependents.json`, `artifacts/downstream/**`, `tests/_shared/phase4_host_harness.py`, and current Dockerfile package knowledge as migration inputs only; do not scrape or rediscover new dependent inventories.

Coverage rules:

- Each library must have at least 8 usage cases.
- The full repository must have at least 155 usage cases and 250 total cases after phase 5.
- Usage cases must be based on identifiers returned by `load_dependent_identifiers()` from existing `dependents.json` entries. Do not rediscover, scrape, or normalize new dependent inventories outside the repository.
- During phase 5, rewrite each `tests/<library>/tests/fixtures/dependents.json` into a compact sanitized JSON fixture derived only from the existing checked-in dependent inventory and the chosen final usage cases. The final fixture shape must be:

```json
{
  "schema_version": 1,
  "library": "libvips",
  "dependents": [
    {
      "name": "pyvips",
      "packages": ["python3-pyvips"],
      "description": "Python image-processing binding used by a usage testcase."
    }
  ]
}
```

- The sanitized `dependents.json` schema permits only `schema_version`, `library`, and `dependents` at the top level. Each dependent object permits only `name`, `source_package`, `package`, `binary_package`, `packages`, and `description`. `packages` must be a list of strings. `name` or one of the package fields must match every `client_application` used by the library's usage testcases. The final sanitized fixtures must not contain path inventories, vendored port paths, ranking notes, `considered_but_excluded`, `excluded_same_source_packages`, SafeLibs repository paths, or any safe/unsafe/excluded vocabulary. This keeps the fixtures as active validation inputs while allowing the final language audit to scan `tests/**` without special-casing raw historical inventories.
- A usage testcase is one client-workload behavior, not a broad aggregate script. For clients with compile and runtime behavior, create two testcase IDs such as `usage-gdal-compile-json-c` and `usage-gdal-runtime-json-c`.
- Case descriptions must say what the client does semantically, for example "Runs gdalinfo against a GeoJSON fixture to exercise json-c parsing through GDAL" instead of "runs dependent test".
- Move downstream tools and wrappers out of the source catalog. `libexif` usage cases may cover the `exif` CLI, `libxml` usage cases may cover `xsltproc` if the dependent fixture exposes an identifier for it, and `libvips` usage cases may cover `pyvips`; each such case must set `kind: usage` and a matching `client_application`.

Usage case patterns:

- Compile/link dependent sample against the original library development package.
- Run apt-installed CLI client on a checked-in fixture.
- Run Python/Ruby/Perl bindings listed in the dependent inventory when apt packages are available.
- Run GUI/client apps under `xvfb-run` only with hosted-compatible patterns already present in the project.
- For service-like clients, start the service on loopback, run one request, collect logs, then shut it down.

Do not:

- Fetch dependencies from the network during testcase execution.
- Build or install SafeLibs packages.
- Compare original and safe behavior.
- Reuse "safe regression" wording in IDs, titles, descriptions, logs, or site data.

## Verification Phases

`check_phase_05_usage_catalog_unit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_05_usage_case_catalogs`
- Purpose: validate dependent-client case coverage, semantic descriptions, fixture references, and executable scripts.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 155 \
  --min-cases 250
python3 - <<'PY'
from pathlib import Path
import yaml
from tools.testcases import load_dependent_identifiers

manifest = yaml.safe_load(Path("repositories.yml").read_text())
for entry in manifest["libraries"]:
    library = entry["name"]
    dependents_path = Path(entry["fixtures"]["dependents"])
    names = load_dependent_identifiers(dependents_path)
    cases = yaml.safe_load(Path(entry["testcases"]).read_text())["testcases"]
    usage = [case for case in cases if case["kind"] == "usage"]
    assert len(usage) >= 8, f"{library} needs at least 8 usage cases"
    for case in usage:
        client = case.get("client_application")
        assert client in names, (library, case["id"], client)
PY
```

`check_phase_05_usage_matrix_smoke`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_05_usage_case_catalogs`
- Purpose: run representative dependent-client workloads across command-line, library binding, media, GUI/headless, and service-style clients.
- Commands:

```bash
rm -rf /tmp/validator-phase05-artifacts
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase05-artifacts \
  --record-casts \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase05-artifacts \
  --proof-output /tmp/validator-phase05-artifacts/proof/original-validation-proof.json \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp \
  --min-usage-cases 48 \
  --require-casts
```

## Success Criteria

- Every library has at least eight usage testcases, with at least 155 usage cases and 250 total cases across the repository.
- Each usage testcase has a `client_application` that matches the sanitized dependent fixture for that library.
- `dependents.json` fixtures are compact active validation inputs and contain no historical path inventories or safe/unsafe/excluded vocabulary.
- Dockerfiles install needed dependent-client packages as test dependencies, not canonical `apt_packages`.
- All explicit phase 5 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Catalog and smoke checks above.
  - Review generated manifests:

  ```bash
  python3 tools/testcases.py --config repositories.yml --tests-root tests --list-summary
  ```

  The summary must show all 19 libraries, at least 95 source cases, at least 155 usage cases, and at least 250 cases total.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_05_usage_case_catalogs` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

# 8. Documentation, Cleanup, and Final Acceptance

## Phase Name

Documentation, Cleanup, and Final Acceptance

## Implement Phase ID

`impl_phase_08_docs_cleanup_final_acceptance`

## Preexisting Inputs

- `.plan/goal.md`
- `README.md`
- `.gitignore`
- `Makefile`
- `repositories.yml`
- `test.sh`
- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`
- `scripts/verify-site.sh`
- `tools/__init__.py`
- `tools/inventory.py`
- `tools/run_matrix.py`
- `tools/testcases.py`
- `tools/proof.py`
- `tools/verify_proof_artifacts.py`
- `tools/render_site.py`
- `tools/host_harness.py` as a retired migration input to delete if still present.
- `tools/stage_port_repos.py` as a retired migration input to delete if still present.
- `tools/build_safe_debs.py` as a retired migration input to delete if still present.
- `tools/import_port_assets.py` as a retired migration input to delete if still present.
- `tools/verify_imported_assets.py` as a retired migration input to delete if still present.
- `tests/_shared/install_override_debs.sh`
- `tests/_shared/install_safe_debs.sh` as a retired migration input to delete if still present.
- `tests/_shared/run_library_tests.sh`
- `tests/_shared/runtime_helpers.sh`
- `tests/_shared/phase4_host_harness.py` as a retired migration input to delete if still present.
- `tests/` including all `tests/<library>/testcases.yml`, `tests/<library>/tests/cases/source/*.sh`, `tests/<library>/tests/cases/usage/*.sh`, `tests/<library>/tests/fixtures/dependents.json`, `tests/<library>/tests/fixtures/relevant_cves.json`, `tests/<library>/tests/harness-source/**`, `tests/<library>/tests/tagged-port/original/**`, and `tests/<library>/tests/tagged-port/safe/**`.
- Explicit retired migration inputs to remove or consume before acceptance:
  - `tests/cjson/tests/fixtures/relevant_cves.json`, `tests/cjson/tests/harness-source/`, `tests/cjson/tests/tagged-port/safe/`
  - `tests/giflib/tests/fixtures/relevant_cves.json`, `tests/giflib/tests/harness-source/`, `tests/giflib/tests/tagged-port/safe/`
  - `tests/libarchive/tests/fixtures/relevant_cves.json`, `tests/libarchive/tests/harness-source/`, `tests/libarchive/tests/tagged-port/safe/`
  - `tests/libbz2/tests/fixtures/relevant_cves.json`, `tests/libbz2/tests/harness-source/`, `tests/libbz2/tests/tagged-port/safe/`
  - `tests/libcsv/tests/fixtures/relevant_cves.json`, `tests/libcsv/tests/harness-source/`, `tests/libcsv/tests/tagged-port/safe/`
  - `tests/libexif/tests/fixtures/relevant_cves.json`, `tests/libexif/tests/harness-source/`, `tests/libexif/tests/tagged-port/safe/`
  - `tests/libjpeg-turbo/tests/fixtures/relevant_cves.json`, `tests/libjpeg-turbo/tests/harness-source/`, `tests/libjpeg-turbo/tests/tagged-port/safe/`
  - `tests/libjson/tests/fixtures/relevant_cves.json`, `tests/libjson/tests/harness-source/`, `tests/libjson/tests/tagged-port/safe/`
  - `tests/liblzma/tests/fixtures/relevant_cves.json`, `tests/liblzma/tests/harness-source/`, `tests/liblzma/tests/tagged-port/safe/`
  - `tests/libpng/tests/fixtures/relevant_cves.json`, `tests/libpng/tests/harness-source/`, `tests/libpng/tests/tagged-port/safe/`
  - `tests/libsdl/tests/fixtures/relevant_cves.json`, `tests/libsdl/tests/harness-source/`, `tests/libsdl/tests/tagged-port/safe/`
  - `tests/libsodium/tests/fixtures/relevant_cves.json`, `tests/libsodium/tests/harness-source/`, `tests/libsodium/tests/tagged-port/safe/`
  - `tests/libtiff/tests/fixtures/relevant_cves.json`, `tests/libtiff/tests/harness-source/`, `tests/libtiff/tests/tagged-port/safe/`
  - `tests/libuv/tests/fixtures/relevant_cves.json`, `tests/libuv/tests/harness-source/`, `tests/libuv/tests/tagged-port/safe/`
  - `tests/libvips/tests/fixtures/relevant_cves.json`, `tests/libvips/tests/harness-source/`, `tests/libvips/tests/tagged-port/safe/`
  - `tests/libwebp/tests/fixtures/relevant_cves.json`, `tests/libwebp/tests/harness-source/`, `tests/libwebp/tests/tagged-port/safe/`
  - `tests/libxml/tests/fixtures/relevant_cves.json`, `tests/libxml/tests/harness-source/`, `tests/libxml/tests/tagged-port/safe/`
  - `tests/libyaml/tests/fixtures/relevant_cves.json`, `tests/libyaml/tests/harness-source/`, `tests/libyaml/tests/tagged-port/safe/`
  - `tests/libzstd/tests/fixtures/relevant_cves.json`, `tests/libzstd/tests/harness-source/`, `tests/libzstd/tests/tagged-port/safe/`
- `unit/` including original-only tests plus retired safe-mode tests that must be removed or rewritten by final acceptance.
- `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, and `artifacts/proof/` as generated artifacts to overwrite through explicit commands.
- `artifacts/downstream/` and `artifacts/debs/` as legacy generated artifacts to remove during cleanup.
- `site/` as generated output to overwrite through explicit render commands and then manually review.

## New Outputs

- Updated `README.md`.
- Final original-only generated artifacts under `artifacts/results`, `artifacts/logs`, `artifacts/casts`, `artifacts/proof`.
- Final rendered `site/`.
- Cleaned active code and tests with no safe/unsafe validation model.
- Removed `tests/<library>/tests/harness-source/**` migration trees after copying useful original-only logic into neutral testcase scripts.
- Removed `tests/<library>/tests/tagged-port/safe/**` directories after copying useful migration logic into neutral source or usage testcase scripts.
- Removed legacy generated `artifacts/downstream/**` and `artifacts/debs/**` trees from the repository.

## File Changes

- Modify `README.md`.
- Modify `.gitignore`.
- Modify `Makefile`.
- Modify `tools/*` only for final cleanup discovered during acceptance.
- Modify `tests/*` only for final script or manifest fixes discovered during acceptance.
- Remove obsolete unit fixtures and tests that only validate safe-mode behavior.
- Delete retired host-harness files after migration: `tools/host_harness.py` and `tests/_shared/phase4_host_harness.py`.
- Delete `tests/<library>/tests/harness-source/**` for all 19 libraries after migration; final testcases must live under `tests/<library>/tests/cases/`.
- Delete `tests/<library>/tests/tagged-port/safe/**` for all 19 libraries after phase 4 and phase 5 migrations.
- Delete legacy generated `artifacts/downstream/**` and `artifacts/debs/**`; override `.deb` support is external input only and must not rely on checked-in `.deb` files.

## Implementation Details

### Phase Scope Notes

This phase owns documentation, final cleanup, final generated artifacts, and acceptance review. Consume all prior implementation outputs plus remaining migration artifacts in place; final cleanup deletes retired host-harness tooling, safe snapshots, harness-source migration trees, relevant CVE fixtures, legacy downstream/deb artifacts, and safe-mode tests after useful neutral data has been migrated. Historical SafeLibs references are allowed only in excluded `inventory/*.json` snapshots if those snapshots are retained as documented historical data.

README must document:

- Purpose: thorough validation of original Ubuntu apt packages.
- Repository layout.
- Testcase manifest schema.
- How to run all tests and selected libraries.
- How to generate proof and render/verify the site.
- How generic override `.deb` support works:

```bash
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --override-deb-root /path/to/override-debs \
  --record-casts
```

- Make clear override `.deb` support is not used by normal repository CI or proof thresholds.
- How GitHub Pages publication works on `main`.

`.gitignore` ignores generated runtime output:

- `artifacts/logs/`
- `artifacts/casts/`
- `artifacts/results/`
- `artifacts/proof/`
- `artifacts/downstream/`
- `artifacts/debs/`
- `artifacts/.workspace/`
- `site/`

Do not ignore checked-in testcase manifests, source fixtures, or case scripts.

Final cleanup rules:

- Remove old SafeLibs proof names such as `hosted-validator-proof.json`.
- Remove safe-mode unit tests or rewrite them to original/override tests.
- Delete retired host-harness tooling that exists only to compare original and replacement package behavior.
- Remove active references to `.work/ports` from docs, workflows, and normal commands.
- Remove active references to `.work/build-safe`, `--port-root`, `port_root`, `port-root`, `stage_port`, `stage-ports`, `build_safe`, and `build-safe` from docs, workflows, normal commands, active tests, and scripts. Historical `inventory/*.json` snapshots may retain old port metadata only because the final source audits explicitly exclude `inventory/**`.
- Remove `tests/*/tests/harness-source/` migration directories after source and usage scripts have been migrated into `tests/*/tests/cases/`.
- Remove `tests/*/tests/tagged-port/safe/` directories after copying useful migration content into neutral testcase scripts.
- Delete `tests/*/tests/fixtures/relevant_cves.json` after extracting useful neutral testcase fixture data. The final manifest and proof must not reference CVE fixtures.
- Rewrite `tests/*/tests/fixtures/dependents.json` into the sanitized schema from phase 5 so active usage-case fixture data contains only dependent-client identifiers and package names.
- Remove checked-in `artifacts/downstream/` and `artifacts/debs/` legacy outputs.
- Remove any final `skipped`, `warned`, or `excluded` status handling and any proof exclusion CLI or data model; hosted-compatible testcases must either pass or fail.
- Keep historical `inventory/*.json` only if documented as legacy snapshots; otherwise delete them in a focused cleanup commit.

## Verification Phases

`check_phase_08_docs_and_language_audit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_08_docs_cleanup_final_acceptance`
- Purpose: verify user-facing documentation and active code no longer describe safe/unsafe mode semantics, no active code accepts skipped/warned/excluded statuses or proof exclusions, and generic override `.deb` support remains documented.
- Commands:

```bash
python3 -m unittest discover -s unit -v
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 155 \
  --min-cases 250
python3 - <<'PY'
from pathlib import Path
import json

def active_files():
    roots = [
        Path("README.md"),
        Path("Makefile"),
        Path("test.sh"),
        Path("repositories.yml"),
        Path("tools"),
        Path("tests"),
        Path("scripts"),
        Path(".github/workflows"),
        Path("unit"),
    ]
    for root in roots:
        if root.is_file():
            yield root
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            parts = path.parts
            if "tagged-port" in parts and "original" in parts:
                continue
            yield path

safe_language_tokens = [
    "safelibs",
    "safe mode",
    "unsafe mode",
    "--mode both",
    "--mode safe",
    "--safe-deb-root",
    "safe-deb",
    "safe-deb-root",
    "safe_deb",
    "safe deb",
    "safe debs",
    "safe workloads",
    "safe_workloads",
    "safedebs",
    "safe_debs",
    "install_safe_debs",
    "validator_safe_deb_dir",
    "validator_tagged_root",
    "host_harness",
    "hosted-validator-proof",
    "min-safe-workloads",
    "safe_packages",
    "unsafe_packages",
    ".work/ports",
    ".work/build-safe",
    "--port-root",
    "port_root",
    "port-root",
    "stage_port",
    "stage-ports",
    "build_safe",
    "build-safe",
]
status_contract_tokens = [
    "skipped",
    "warned",
    "excluded",
    "exclude-library",
    "exclude_library",
    "--exclude-library",
]
schema_tokens = [
    "override_packages",
    "verify_packages",
]

for path in active_files():
    text = path.read_text(errors="ignore").lower()
    for token in safe_language_tokens:
        assert token not in text, f"{path} contains {token}"
    if "unit" not in path.parts:
        for token in schema_tokens + status_contract_tokens:
            assert token not in text, f"{path} contains {token}"

unit_text = "\n".join(path.read_text(errors="ignore").lower() for path in Path("unit").rglob("test_*.py"))
for token in schema_tokens + status_contract_tokens:
    assert token in unit_text, f"unit tests must include rejection coverage for {token}"
assert "override" in Path("README.md").read_text().lower()
relevant_cve_files = list(Path("tests").glob("*/tests/fixtures/relevant_cves.json"))
assert not relevant_cve_files, f"retired CVE fixture files remain: {relevant_cve_files[:5]}"
allowed_dependent_top_keys = {"schema_version", "library", "dependents"}
allowed_dependent_keys = {"name", "source_package", "package", "binary_package", "packages", "description"}
for dependents_path in Path("tests").glob("*/tests/fixtures/dependents.json"):
    payload = json.loads(dependents_path.read_text())
    assert set(payload) <= allowed_dependent_top_keys, dependents_path
    assert payload.get("schema_version") == 1, dependents_path
    assert payload.get("library") == dependents_path.parts[1], dependents_path
    dependents = payload.get("dependents")
    assert isinstance(dependents, list) and dependents, dependents_path
    for entry in dependents:
        assert isinstance(entry, dict), dependents_path
        assert set(entry) <= allowed_dependent_keys, (dependents_path, entry)
        assert any(isinstance(entry.get(key), str) and entry[key].strip() for key in ["name", "source_package", "package", "binary_package"]) or any(isinstance(value, str) and value.strip() for value in entry.get("packages", [])), (dependents_path, entry)
        if "packages" in entry:
            assert isinstance(entry["packages"], list) and all(isinstance(value, str) and value.strip() for value in entry["packages"]), (dependents_path, entry)
safe_snapshot_dirs = list(Path("tests").glob("*/tests/tagged-port/safe"))
assert not safe_snapshot_dirs, f"safe tagged-port snapshots remain after migration: {safe_snapshot_dirs[:5]}"
for legacy_artifact in [Path("artifacts/downstream"), Path("artifacts/debs")]:
    assert not legacy_artifact.exists(), f"legacy generated artifact tree remains: {legacy_artifact}"
for retired_file in [
    Path("tools/host_harness.py"),
    Path("tools/stage_port_repos.py"),
    Path("tools/build_safe_debs.py"),
    Path("tools/import_port_assets.py"),
    Path("tools/verify_imported_assets.py"),
    Path("tests/_shared/install_safe_debs.sh"),
    Path("tests/_shared/phase4_host_harness.py"),
    Path("unit/test_build_safe_debs.py"),
    Path("unit/test_stage_port_repos.py"),
    Path("unit/test_import_port_assets.py"),
    Path("unit/test_verify_imported_assets.py"),
]:
    assert not retired_file.exists(), f"retired file remains: {retired_file}"
for retired_dir in Path("tests").glob("*/tests/harness-source"):
    assert not retired_dir.exists(), f"retired harness-source migration tree remains: {retired_dir}"
PY
```

Then run the final source audit from the plan. This audit is part of `check_phase_08_docs_and_language_audit`, not a separate workflow phase:

```bash
if rg -ni "SafeLibs|safelibs|safe mode|unsafe mode|--mode both|--mode safe|--safe-deb-root|safe-deb|safe-deb-root|safe_deb|safe deb|safe debs|safe workloads|safe_workloads|safedebs|safe_debs|install_safe_debs|VALIDATOR_SAFE_DEB_DIR|VALIDATOR_TAGGED_ROOT|SafeLibs replacement|build_safe|build-safe|stage_port|stage-ports|host_harness|hosted-validator-proof|min-safe-workloads|safe_packages|unsafe_packages|\\.work/ports|\\.work/build-safe|--port-root|port_root|port-root" \
  README.md Makefile test.sh repositories.yml tools tests scripts .github/workflows unit \
  -g '!tests/**/tests/tagged-port/original/**' \
  -g '!inventory/**'; then
  exit 1
fi
if find tests -path '*/tests/fixtures/relevant_cves.json' -print -quit | grep -q .; then
  exit 1
fi
if rg -ni "override_packages|verify_packages|skipped|warned|excluded|exclude-library|exclude_library|--exclude-library" \
  README.md Makefile test.sh repositories.yml tools tests scripts .github/workflows \
  -g '!tests/**/tests/tagged-port/original/**' \
  -g '!inventory/**'; then
  exit 1
fi
```

The checker must enforce the final token allowance rules: unit tests may contain `override_packages`, `verify_packages`, `skipped`, `warned`, `excluded`, `exclude-library`, and `exclude_library` only as explicit negative tests proving those fields, statuses, and proof-exclusion options are rejected. Unit tests must not contain old mode, safe-deb, or port-staging interface names such as `--mode safe`, `--mode both`, `--safe-deb-root`, `safe_deb`, `safe-deb`, `safe deb`, `install_safe_debs`, `VALIDATOR_SAFE_DEB_DIR`, `VALIDATOR_TAGGED_ROOT`, `.work/ports`, `.work/build-safe`, `--port-root`, `port_root`, `stage_port`, or `build_safe`. The only allowed historical SafeLibs references after cleanup are the excluded `inventory/*.json` snapshots if retained as documented historical data.

`check_phase_08_full_original_matrix_acceptance`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_08_docs_cleanup_final_acceptance`
- Purpose: run the complete original-only matrix, proof generation, site render, and site verification.
- Commands:

```bash
rm -rf artifacts/results artifacts/logs artifacts/casts artifacts/proof artifacts/downstream artifacts/debs site
set +e
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --record-casts
matrix_exit_code=$?
set -e
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --proof-output artifacts/proof/original-validation-proof.json \
  --min-source-cases 95 \
  --min-usage-cases 155 \
  --min-cases 250 \
  --require-casts
python3 tools/render_site.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --proof-path artifacts/proof/original-validation-proof.json \
  --output-root site
bash scripts/verify-site.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifacts-root artifacts \
  --proof-path artifacts/proof/original-validation-proof.json \
  --site-root site
python3 - <<'PY'
from pathlib import Path
import json

proof = json.loads(Path("artifacts/proof/original-validation-proof.json").read_text())
site = json.loads(Path("site/site-data.json").read_text())
statuses = set()
for library in proof["libraries"]:
    for case in library["testcases"]:
        statuses.add(case["status"])
        for forbidden_key in ["skipped", "warned", "excluded"]:
            assert forbidden_key not in case, (library["library"], case["testcase_id"], forbidden_key)
    for forbidden_key in ["skipped", "warned", "excluded"]:
        assert forbidden_key not in library["totals"], (library["library"], forbidden_key)
for row in site["testcases"]:
    statuses.add(row["status"])
for forbidden_key in ["skipped", "warned", "excluded"]:
    assert forbidden_key not in proof["totals"], forbidden_key
assert statuses <= {"passed", "failed"}, statuses
assert statuses, "no testcase statuses found"
PY
if [ "$matrix_exit_code" -ne 0 ]; then
  exit "$matrix_exit_code"
fi
```

`check_phase_08_manual_site_acceptance`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_08_docs_cleanup_final_acceptance`
- Purpose: manually inspect the final site and verify usability, no text overlap, no broken player, and no safe/unsafe conceptual leakage.
- Commands:

```bash
test -f site/index.html
nohup python3 -m http.server 8765 --directory site >/tmp/validator-phase08-site-server.log 2>&1 &
echo $! >/tmp/validator-phase08-site-server.pid
printf 'Manual/Playwright review URL: http://127.0.0.1:8765\n'
```

Checker instructions must then use Playwright to review desktop and mobile widths, open at least three library sections, filter by `source` and `usage`, play at least three casts from different libraries, and inspect that failed cases, if any, are visible and understandable. The checker must kill the PID in `/tmp/validator-phase08-site-server.pid` before yielding.

## Success Criteria

- README and command docs describe original Ubuntu apt package validation and generic optional override `.deb` support only.
- Retired SafeLibs, host-harness, CVE fixture, safe snapshot, downstream artifact, and `.deb` artifact files are removed or isolated as allowed.
- Final active code, tests, workflows, manifests, and site output contain no safe/unsafe validation model or skipped/warned/excluded status contract.
- Final source audit passes with the unit-test-only token allowance rules above, and any retained historical SafeLibs references are limited to excluded `inventory/*.json` snapshots.
- The full original-only matrix, proof generation, site render, site verification, and manual/Playwright site acceptance complete.
- Final site review confirms all 19 libraries are present; every testcase has a semantic title, description, status, and log link; source/usage filters and search by library, title, description, tag, and client application work; cast links play from served `site/` evidence paths; failures remain visible; and the visible site does not describe safe/unsafe modes or safe workload proof.
- All explicit phase 8 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Docs/language audit, full matrix acceptance, and manual site acceptance above.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_08_docs_cleanup_final_acceptance` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

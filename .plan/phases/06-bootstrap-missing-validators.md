# Phase 06

## Phase Name

`bootstrap-missing-validators`

## Implement Phase ID

`impl_06_bootstrap_missing_validators`

## Preexisting Inputs

- `repositories.yml`
- `Makefile`
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
- the phase-1-declared `validator.build_root`, `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` entries for `glib`, `libcurl`, `libgcrypt`, `libjansson`, and `libuv` in `repositories.yml`
- `/home/yans/safelibs/port-glib/original`
- `/home/yans/safelibs/port-libcurl/original`
- `/home/yans/safelibs/port-libgcrypt/original/libgcrypt20-1.10.3`
- `/home/yans/safelibs/port-libjansson/original/jansson-2.14`
- `/home/yans/safelibs/port-libuv/original`

## New Outputs

- complete validator harness directories for `glib`, `libcurl`, `libgcrypt`, `libjansson`, and `libuv`
- validator-authored `dependents.json` and `relevant_cves.json` fixtures for those five libraries

## File Changes

- `tests/glib/**`
- `tests/libcurl/**`
- `tests/libgcrypt/**`
- `tests/libjansson/**`
- `tests/libuv/**`
- `Makefile`
- `repositories.yml`
- `tools/build_safe_debs.py`

## Implementation Details

- Use the `source-debian-original` build mode from phase 1 to build replacement `.deb` packages from the imported upstream and Debian source trees for these five libraries.
- The staged build copy under `.work/` must receive the exact validator-only version suffix `+validatorbootstrap1`.
- Use `tools/import_port_assets.py` plus the phase-1 `validator.build_root`, `validator.import_roots`, `validator.import_excludes`, and `validator.runtime_fixture_paths` metadata to project the selected upstream and Debian test subsets into validator-owned paths before writing each bootstrap harness.
- Create validator-owned `tests/<library>/Dockerfile`, `docker-entrypoint.sh`, and `tests/run.sh` for each bootstrap library.
- Source material by library:
- `glib`: `debian/tests`, `tests/`, `glib/tests/`, `gio/tests/`, `gobject/tests/`, `fuzzing/`
- `libcurl`: `debian/tests`, `tests/`, `tests/data`, local server helpers, and hermetic subsets of `runtests.pl`
- `libgcrypt`: `tests/` plus Debian control metadata for required packages
- `libjansson`: `test/bin`, `test/run-suites`, `test/suites`, `test/scripts`, and `test/ossfuzz`
- `libuv`: `test/` and Debian package metadata
- Every bootstrap harness must still use the same shared Dockerfile and entrypoint contract as mature libraries. Bootstrap-specific mode branching is not allowed in library-local files.
- Generate new validator-owned `tests/<library>/tests/fixtures/dependents.json` fixtures from existing source and local package metadata because sibling repos do not provide them.
- The bootstrap `dependents.json` schema is fixed:
- top-level keys exactly `schema_version`, `library`, `generated_at_utc`, `ubuntu_release`, `provenance`, and `dependents`
- `schema_version = 1`
- `library` equals the current library name
- `generated_at_utc` is a non-empty UTC timestamp string
- `ubuntu_release = "24.04"`
- `provenance` contains exactly `source_paths`, `package_metadata_commands`, and `selection_policy`, each a non-empty list of non-empty strings
- every dependent entry contains exactly `package`, `source_package`, `selection_reason`, `dependency_relationships`, `smoke_test`, `notes`, and `evidence`
- `dependency_relationships` contains exactly `compile_time`, `runtime`, and `autopkgtest`
- `smoke_test` contains exactly `kind`, `command`, and `expected_exit_code`, where `kind` is one of `cli`, `autopkgtest`, or `library-provided-script`
- `evidence` contains exactly `source_paths`, `package_metadata`, `autopkgtest_references`, and `selection_commands`
- `source_paths` and `selection_commands` must be non-empty for every dependent
- keep at least one dependent entry per bootstrap library and check each generated fixture into git for later phases to consume
- Generate `tests/<library>/tests/fixtures/relevant_cves.json` from Debian patch names, changelog references, and tracked upstream regression or fuzz inputs when possible.
- The bootstrap `relevant_cves.json` schema is fixed:
- top-level keys exactly `schema_version`, `library`, `generated_at_utc`, `provenance`, `selection_policy`, `relevant_cves`, and `reviewed_but_excluded`
- `schema_version = 1`
- `library` equals the current library name
- `generated_at_utc` is a non-empty UTC timestamp string
- `selection_policy` is a non-empty list of non-empty strings
- `provenance` contains exactly `source_paths`, `debian_references`, `upstream_regression_inputs`, and `notes`
- every retained CVE entry contains exactly `id`, `summary`, `why_relevant_to_rust`, `evidence`, and `porting_actions`
- every excluded entry contains exactly `id` and `reason`
- if `relevant_cves` is empty, `provenance.notes` must explicitly explain why
- Record bootstrap safe runs as `replacement_provenance=bootstrap-original-source`. That distinction belongs in results and the site, not in the tests themselves.

## Verification Phases

### `check_06_bootstrap_matrix`

- phase ID: `check_06_bootstrap_matrix`
- type: `check`
- bounce_target: `impl_06_bootstrap_missing_validators`
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

### `check_06_bootstrap_review`

- phase ID: `check_06_bootstrap_review`
- type: `check`
- bounce_target: `impl_06_bootstrap_missing_validators`
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

## Success Criteria

- All five bootstrap libraries pass original and safe runs through the same validator contract used by mature libraries.
- At least one built bootstrap `.deb` proves the exact `+validatorbootstrap1` version suffix.
- Newly created fixtures match the fixed bootstrap JSON schemas.
- Validator-authored bootstrap harness glue remains mode-blind across `Dockerfile`, `docker-entrypoint.sh`, and non-imported helper files.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

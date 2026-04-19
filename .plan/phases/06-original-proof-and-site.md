# 6. Original-Only Proof and Playable GitHub Pages Site

## Phase Name

Original-Only Proof and Playable GitHub Pages Site

## Implement Phase ID

`impl_phase_06_original_proof_and_site`

## Preexisting Inputs

- `.plan/goal.md`
- `repositories.yml` v2
- `test.sh`
- `tests/<library>/testcases.yml` populated with source and usage cases
- `artifacts/results`, `artifacts/logs`, and `artifacts/casts` as runtime outputs created only by `tools/run_matrix.py`
- `tools/proof.py`
- `tools/verify_proof_artifacts.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `unit/test_proof.py`
- `unit/test_render_site.py`
- Original-only runner and testcase manifests from earlier phases, used by the phase 6 smoke commands to create fresh `/tmp/validator-phase06-*` scratch artifacts.
- Existing `site/` as generated output to replace.

## New Outputs

- Original-only proof schema `artifacts/proof/original-validation-proof.json`.
- Original-only `site/site-data.json`.
- `site/index.html`, `site/library/<library>.html`, and generated `site/assets/player.js` and `site/assets/site.css`.
- Copied evidence files under `site/evidence/logs/<library>/<testcase-id>.log` and `site/evidence/casts/<library>/<testcase-id>.cast`.
- A site verifier that proves site data exactly matches proof plus deterministic hrefs and that every copied evidence file matches its source artifact.

## File Changes

- Modify `tools/proof.py`.
- Modify `tools/verify_proof_artifacts.py`.
- Modify `tools/render_site.py`.
- Modify `scripts/verify-site.sh`.
- Modify `unit/test_proof.py`.
- Modify `unit/test_render_site.py`.
- Modify `.gitignore` only for generated site/proof paths.

## Implementation Details

### Phase Scope Notes

This phase owns proof version 2, site rendering, evidence copying, and the read-only site verifier. Existing `artifacts/results`, `artifacts/logs`, and `artifacts/casts` are runtime outputs produced only by `tools/run_matrix.py`; proof generation may read them and write only the requested proof JSON, while site rendering may read proof/evidence and write only the requested site output. Phase 6 smoke verifiers create fresh `/tmp/validator-phase06-*` artifacts rather than relying on prior verifier scratch output.

Proof schema version 2:

```json
{
  "proof_version": 2,
  "suite": {
    "name": "ubuntu-24.04-original-apt",
    "image": "ubuntu:24.04",
    "apt_suite": "noble"
  },
  "totals": {
    "libraries": 19,
    "cases": 250,
    "source_cases": 95,
    "usage_cases": 155,
    "passed": 250,
    "failed": 0,
    "casts": 250
  },
  "libraries": [
    {
      "library": "cjson",
      "apt_packages": ["libcjson1", "libcjson-dev"],
      "totals": {"cases": 10, "source_cases": 5, "usage_cases": 5, "passed": 10, "failed": 0, "casts": 10},
      "testcases": [
        {
          "testcase_id": "source-parse-print-roundtrip",
          "title": "Parse and print JSON round trip",
          "description": "Compiles a small C program against the Ubuntu libcjson headers and verifies parse, mutate, and print behavior.",
          "kind": "source",
          "mode": "original",
          "client_application": null,
          "tags": ["api", "parser"],
          "requires": [],
          "status": "passed",
          "result_path": "results/cjson/source-parse-print-roundtrip.json",
          "log_path": "logs/cjson/source-parse-print-roundtrip.log",
          "cast_path": "casts/cjson/source-parse-print-roundtrip.cast",
          "cast_events": 42,
          "cast_bytes": 1200,
          "cast_duration_seconds": 2.31,
          "duration_seconds": 2.4,
          "exit_code": 0
        }
      ]
    }
  ]
}
```

`tools.proof.build_proof()` signature:

```python
def build_proof(
    manifest: dict[str, Any],
    *,
    artifact_root: Path,
    tests_root: Path,
    libraries: list[str] | None = None,
    min_cases: int = 0,
    min_source_cases: int = 0,
    min_usage_cases: int = 0,
    require_casts: bool = False,
) -> dict[str, Any]: ...
```

Proof rules:

- Included libraries follow manifest order.
- Every manifest testcase must have exactly one result JSON.
- Every result must match manifest metadata for library, testcase ID, title, description, kind, command, tags, requires, client application, canonical `apt_packages`, and original mode. Before result comparison, proof generation must load the testcase manifests through `tools/testcases.load_manifests()` so any `apt_packages` mismatch between `repositories.yml` and `tests/<library>/testcases.yml` fails proof validation.
- Every result must pass strict schema validation: `schema_version == 2`, `status in {"passed", "failed"}`, non-empty UTC `started_at` and `finished_at`, finite non-negative `duration_seconds`, integer `exit_code`, exact `result_path == "results/<library>/<testcase-id>.json"`, exact `log_path == "logs/<library>/<testcase-id>.log"`, and exact `cast_path == "casts/<library>/<testcase-id>.cast"` when casts are required.
- `tools/proof.py`, `tools/verify_proof_artifacts.py`, and `unit/test_proof.py` must contain explicit negative coverage proving that `skipped`, `warned`, `excluded`, null status, empty status, and any other status outside `passed`/`failed` are rejected. Do not implement proof exclusions, `--exclude-library`, exclusion lists, warning-only statuses, or skipped-case totals.
- Normal proof generation must require `override_debs_installed == false`; override `.deb` capability is covered by unit/fixture tests and is not part of proof, CI, Pages, or acceptance thresholds.
- Every result must have an existing log.
- If `require_casts` is true, every result must have an existing asciinema v2 cast.
- Cast parser must reject invalid headers, empty event streams, non-output events, non-monotonic timestamps, and non-string payloads.
- Totals are computed only from validated testcase results.
- Proof JSON must be deterministic: no absolute paths and no current timestamp.
- `tools/verify_proof_artifacts.py --proof-output` may be absolute or relative, but it must resolve inside `--artifact-root`.
- `tools/verify_proof_artifacts.py` must not rewrite result JSON, logs, casts, downstream summaries, `.deb` artifacts, or testcase manifests. It writes only `--proof-output`.

Site requirements:

- The first viewport is the actual validation dashboard, not a marketing page.
- Show library summary cards, global pass/fail counts, source/usage counts, and cast coverage.
- Provide search by library, testcase title, description, tag, and client application.
- Provide filters for status and kind.
- Each library has a detail section or page listing every testcase with semantic description, status, duration, log link, and a "Play" control.
- The player loads cast files on demand through deterministic hrefs, supports play, pause, restart, and speed selection, and displays terminal output in a fixed-size responsive panel.
- Use restrained, readable design with no nested cards, no decorative orbs, no one-note palette, and no text overlap on mobile.
- `tools/render_site.py` must accept `--config`, `--tests-root`, `--artifact-root`, `--proof-path`, and `--output-root`. It must not require or accept `--results-root` in the final workflow; testcase rows are derived from the validated proof, not by independently rediscovering result files.
- `tools/render_site.py` must copy every referenced log and cast from `--artifact-root` into deterministic evidence paths under `--output-root`, specifically `evidence/logs/<library>/<testcase-id>.log` and `evidence/casts/<library>/<testcase-id>.cast`. It must overwrite those copied files on each render, write no files outside `--output-root`, and never mutate `--artifact-root`.
- `site-data.json` must be deterministic and contain exactly this top-level shape:

```json
{
  "schema_version": 1,
  "proof": {},
  "testcases": []
}
```

- `site_data["proof"]` must equal the proof manifest after adding only deterministic `log_href` and `cast_href` fields to each proof testcase that has `log_path` and `cast_path`. These hrefs point to the copied evidence files inside `site_root`, not to files under `artifacts_root`.
- `site_data["testcases"]` must be a flat list derived from the proof in manifest order. Each row must contain exactly `library`, `testcase_id`, `mode`, `title`, `description`, `kind`, `client_application`, `tags`, `status`, `duration_seconds`, `result_path`, `log_path`, `cast_path`, `log_href`, and `cast_href`.
- `log_href` and `cast_href` must be relative from `site_root` to copied files under `site_root/evidence/`, must resolve inside `site_root`, and must point at existing files included in the Pages artifact. `cast_href` is non-null for every final testcase because final acceptance uses `--require-casts`.

`scripts/verify-site.sh` must:

- Accept exactly these final CLI inputs: `--config <repositories.yml>`, `--tests-root <tests-dir>`, `--artifacts-root <artifacts-dir>`, `--proof-path <proof-json>`, `--site-root <site-dir>`, and optional repeated `--library <name>` selections. It must not accept `--results-root`, `--exclude-library`, or any safe-mode compatibility argument.
- Load `repositories.yml` from `--config`, load testcase manifests through `tools/testcases.load_manifests()` using `--tests-root`, and load the existing proof from `--proof-path`.
- Determine the verifier library set from the proof unless `--library` is supplied. Reject duplicate or unknown library names in both the proof and optional CLI selections. If no `--library` arguments are supplied, set the selected libraries to `proof["libraries"][*]["library"]` in proof order and rebuild proof for exactly that set. If `--library` arguments are supplied, require their ordered list to equal `proof["libraries"][*]["library"]` exactly before rebuilding proof. This rule is mandatory for subset smoke proofs in phases 6 and 7; `verify-site.sh` must never infer "all 19 libraries" for a subset proof.
- Rebuild expected proof from artifacts and require exact equality with the proof file. This comparison must include every proof library, library totals, testcase order, testcase metadata, result paths, log paths, cast paths, cast metrics, durations, exit codes, and aggregate totals.
- Rebuild expected proof with `artifact_root=--artifacts-root`, `tests_root=--tests-root`, `libraries=<selected proof libraries>`, and `require_casts=True`. It must not refetch, rediscover, or regenerate testcase manifests, result JSON, logs, casts, downstream summaries, or `.deb` artifacts.
- Rebuild expected site data from the proof and require exact equality after deterministic href enrichment. This comparison must reject missing, stale, reordered, or altered proof rows and testcase rows.
- Build expected testcase rows from the proof's testcase entries and require exact normalized equality for `library`, `testcase_id`, `mode`, `title`, `description`, `kind`, `client_application`, `tags`, `status`, `duration_seconds`, `result_path`, `log_path`, `cast_path`, `log_href`, and `cast_href`.
- Verify every `log_href` and `cast_href` resolves inside `site_root`, points to an existing copied evidence file, and corresponds byte-for-byte to the source file identified by the proof testcase's `log_path` or `cast_path` under `artifacts_root`.
- Verify every testcase row appears in HTML with `data-library`, `data-testcase-id`, and `data-player-cast`.
- Verify rendered HTML contains no final user-facing safe/unsafe/safe-workload language.
- Perform no writes.

## Verification Phases

`check_phase_06_site_unit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_06_original_proof_and_site`
- Purpose: verify proof schema, cast parsing, site data generation, HTML escaping, player wiring, site verifier behavior, exact `passed`/`failed` status handling, and rejection of skipped, warned, excluded, or proof-excluded testcase states.
- Commands:

```bash
python3 -m unittest \
  unit.test_proof \
  unit.test_render_site \
  unit.test_testcases \
  -v
```

`check_phase_06_render_verify_smoke`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_06_original_proof_and_site`
- Purpose: create a compact original-only smoke artifact set, generate proof from it, render the site, and verify all case rows and playable cast references without depending on scratch output from an earlier phase or verifier.
- Commands:

```bash
rm -rf /tmp/validator-phase06-artifacts /tmp/validator-phase06-site
set +e
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --record-casts \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp
matrix_exit_code=$?
set -e
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --proof-output /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp \
  --min-source-cases 30 \
  --min-usage-cases 48 \
  --min-cases 78 \
  --require-casts
python3 tools/render_site.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --proof-path /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --output-root /tmp/validator-phase06-site
bash scripts/verify-site.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifacts-root /tmp/validator-phase06-artifacts \
  --proof-path /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --site-root /tmp/validator-phase06-site
python3 - <<'PY'
from pathlib import Path
html = Path("/tmp/validator-phase06-site/index.html").read_text()
assert "data-player-cast" in html
assert "Original Library Validation" in html
assert "Safe" not in html
assert "safe workload" not in html.lower()
PY
if [ "$matrix_exit_code" -ne 0 ]; then
  exit "$matrix_exit_code"
fi
```

`check_phase_06_playwright_site_review`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_06_original_proof_and_site`
- Purpose: visually and interactively verify that the site is usable, responsive, and can play a testcase cast on demand.
- Commands:

```bash
rm -rf /tmp/validator-phase06-artifacts /tmp/validator-phase06-site
set +e
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --record-casts \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp
matrix_exit_code=$?
set -e
printf '%s\n' "$matrix_exit_code" >/tmp/validator-phase06-matrix-exit-code
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --proof-output /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --library libjson \
  --library libjpeg-turbo \
  --library libsdl \
  --library libsodium \
  --library libvips \
  --library libwebp \
  --min-source-cases 30 \
  --min-usage-cases 48 \
  --min-cases 78 \
  --require-casts
python3 tools/render_site.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase06-artifacts \
  --proof-path /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --output-root /tmp/validator-phase06-site
bash scripts/verify-site.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifacts-root /tmp/validator-phase06-artifacts \
  --proof-path /tmp/validator-phase06-artifacts/proof/original-validation-proof.json \
  --site-root /tmp/validator-phase06-site
nohup python3 -m http.server 8765 --directory /tmp/validator-phase06-site >/tmp/validator-phase06-site-server.log 2>&1 &
echo $! >/tmp/validator-phase06-site-server.pid
python3 - <<'PY'
print("Open http://127.0.0.1:8765 for Playwright/manual review")
PY
```

Checker instructions must use Playwright to open `http://127.0.0.1:8765`, verify the library list, search/filter behavior, testcase detail expansion, and at least one play/pause/scrub interaction in the cast player. Include Playwright commands directly in the checker prompt. Kill the PID in `/tmp/validator-phase06-site-server.pid` before yielding. After review, fail with the code in `/tmp/validator-phase06-matrix-exit-code` if that code is nonzero. Failed testcase rows must remain visible on the generated site before the verifier reports the aggregate failure.

## Success Criteria

- Proof generation validates schema version 2 result artifacts strictly and writes only the requested proof JSON under the artifact root.
- Proof totals and testcase rows are deterministic, original-only, and contain only `passed` or `failed` statuses.
- The rendered site derives from validated proof data, copies all referenced logs and casts into `site/evidence/**`, and never mutates artifacts.
- `scripts/verify-site.sh` is read-only and proves proof, site data, HTML rows, and copied evidence match exactly.
- All explicit phase 6 verification phases pass, including Playwright review with server cleanup.
- Additional source-plan verification notes must be satisfied:

  - Unit, render, site, and Playwright checks above.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_06_original_proof_and_site` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

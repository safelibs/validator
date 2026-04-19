# 7. Original-Only CI and GitHub Pages

## Phase Name

Original-Only CI and GitHub Pages

## Implement Phase ID

`impl_phase_07_ci_pages_original_only`

## Preexisting Inputs

- `.plan/goal.md`
- `repositories.yml` v2
- `test.sh`
- `tools/verify_proof_artifacts.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `tests/<library>/testcases.yml` populated with source and usage cases
- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`
- `Makefile`
- `README.md`
- Original-only runner, testcase manifests, proof, and site renderer from prior phases.

## New Outputs

- CI workflow that runs unit tests, testcase manifest checks, smoke matrix, proof, render, and site verification.
- Pages workflow that runs the full original-only matrix on `main`, renders the site, deploys Pages, and reports aggregate matrix failure after deployment.

## File Changes

- Modify `.github/workflows/ci.yml`.
- Modify `.github/workflows/pages.yml`.
- Modify `Makefile` for workflow command mappings.
- Modify `README.md` command snippets.

## Implementation Details

### Phase Scope Notes

This phase owns CI and Pages workflow command wiring. It consumes the original-only runner, testcase manifests, proof builder, site renderer, and verifier from prior phases and must remove active port staging, safe package builds, dual-mode runs, proof exclusions, and hosted safe-workload language from workflow files and README snippets.

CI requirements:

- `preflight`: install `python3-yaml`, run unit tests and testcase manifest validation.
- `matrix-smoke`: run a representative subset on pull requests and pushes with `set +e`, capture `matrix_exit_code`, generate proof/site artifacts from produced results, and fail only after proof/site verification if the matrix exit code is nonzero.
- `full-matrix`: on push to `main`, run all libraries original-only with `--record-casts` using the same capture-then-publish ordering.
- Do not stage port repositories, create `.work/ports`, create `.work/build-safe`, pass `--port-root`, or invoke any `stage_port`/`build_safe` command.
- Do not build or upload SafeLibs `.deb` packages.
- Do not exclude libarchive because of old safe-mode privileged concerns. If a proposed libarchive FUSE testcase cannot run on hosted CI, replace it with a hosted-compatible libarchive testcase before final acceptance; do not model it as skipped.

Pages requirements:

- Trigger on push to `main` and `workflow_dispatch`.
- Run full original-only matrix with `set +e` and capture `matrix_exit_code`.
- Always generate proof and render site from produced result artifacts. Stop only when proof or site validation fails.
- Upload and deploy the rendered `site/` directory when proof/site validation succeeds. The uploaded Pages artifact must include `site/evidence/**` so log links and cast playback work without fetching files from artifact-root-relative paths or any path outside the deployed site.
- After deployment, fail the `report-status` job if any testcase failed.
- Site includes failed testcases instead of hiding them.

## Verification Phases

`check_phase_07_workflow_audit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_07_ci_pages_original_only`
- Purpose: statically verify CI and Pages workflows are original-only, run proof/site generation, and do not stage ports or build SafeLibs packages.
- Commands:

```bash
python3 - <<'PY'
from pathlib import Path
for workflow in [Path(".github/workflows/ci.yml"), Path(".github/workflows/pages.yml")]:
    text = workflow.read_text()
    required = [
        "python3 -m unittest discover -s unit -v",
        "bash test.sh",
        "--record-casts",
        "tools/verify_proof_artifacts.py",
        "tools/render_site.py",
        "scripts/verify-site.sh",
        "set +e",
        "matrix_exit_code",
    ]
    for token in required:
        assert token in text, f"{workflow} missing {token}"
    forbidden = [
        "stage_port_repos.py",
        "build_safe_debs.py",
        "SafeLibs",
        "safelibs",
        ".work/ports",
        ".work/build-safe",
        "--port-root",
        "port_root",
        "port-root",
        "stage_port",
        "stage-ports",
        "build_safe",
        "build-safe",
        "VALIDATOR_TAGGED_ROOT",
        "--mode both",
        "--mode safe",
        "--safe-deb-root",
        "safe-deb",
        "safe_deb",
        "safe deb",
        "safe_debs",
        "install_safe_debs",
        "VALIDATOR_SAFE_DEB_DIR",
        "--results-root",
        "hosted-validator-proof",
        "host_harness",
        "libarchive requires a privileged",
        "min-safe-workloads",
        "skip",
        "skipped",
        "warned",
        "excluded",
        "exclude-library",
        "exclude_library",
    ]
    for token in forbidden:
        assert token not in text, f"{workflow} still contains {token}"
PY
```

`check_phase_07_local_ci_simulation`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_07_ci_pages_original_only`
- Purpose: run the commands used by the hosted smoke workflow locally on a representative subset.
- Commands:

```bash
rm -rf /tmp/validator-phase07-artifacts /tmp/validator-phase07-site
python3 -m unittest discover -s unit -v
set +e
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase07-artifacts \
  --record-casts \
  --library cjson \
  --library libarchive \
  --library libuv \
  --library libwebp
matrix_exit_code=$?
set -e
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase07-artifacts \
  --proof-output /tmp/validator-phase07-artifacts/proof/original-validation-proof.json \
  --library cjson \
  --library libarchive \
  --library libuv \
  --library libwebp \
  --min-source-cases 20 \
  --min-usage-cases 32 \
  --min-cases 52 \
  --require-casts
python3 tools/render_site.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-phase07-artifacts \
  --proof-path /tmp/validator-phase07-artifacts/proof/original-validation-proof.json \
  --output-root /tmp/validator-phase07-site
bash scripts/verify-site.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifacts-root /tmp/validator-phase07-artifacts \
  --proof-path /tmp/validator-phase07-artifacts/proof/original-validation-proof.json \
  --site-root /tmp/validator-phase07-site
if [ "$matrix_exit_code" -ne 0 ]; then
  exit "$matrix_exit_code"
fi
```

## Success Criteria

- CI and Pages workflows run original-only validation, unit checks, proof generation, site rendering, and site verification.
- Workflows capture matrix failure, still produce proof/site artifacts when possible, and report aggregate failure after artifact/site availability.
- No workflow stages ports, builds SafeLibs `.deb` packages, passes safe-mode arguments, or models skipped/warned/excluded cases.
- Pages deployment includes self-contained evidence files under the rendered site.
- All explicit phase 7 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Workflow audit and local CI simulation above.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_07_ci_pages_original_only` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

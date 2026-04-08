# Phase 07

## Phase Name

`ci-pages-publish`

## Implement Phase ID

`impl_07_ci_pages_publish`

## Preexisting Inputs

- `README.md`
- `Makefile`
- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- `repositories.yml`
- `test.sh`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `unit/test_inventory.py`
- `unit/test_stage_port_repos.py`
- `unit/test_build_safe_debs.py`
- `unit/test_import_port_assets.py`
- `unit/test_run_matrix.py`
- `unit/test_render_site.py`
- `tests/_shared/common.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/entrypoint.sh`
- checked-in harness directories `tests/cjson`, `tests/giflib`, `tests/glib`, `tests/libarchive`, `tests/libbz2`, `tests/libcsv`, `tests/libcurl`, `tests/libexif`, `tests/libgcrypt`, `tests/libjansson`, `tests/libjpeg-turbo`, `tests/libjson`, `tests/liblzma`, `tests/libpng`, `tests/libsdl`, `tests/libsodium`, `tests/libtiff`, `tests/libuv`, `tests/libvips`, `tests/libwebp`, `tests/libxml`, `tests/libyaml`, and `tests/libzstd`
- local sibling repos `/home/yans/safelibs/port-cjson`, `/home/yans/safelibs/port-giflib`, `/home/yans/safelibs/port-glib`, `/home/yans/safelibs/port-libarchive`, `/home/yans/safelibs/port-libbz2`, `/home/yans/safelibs/port-libcsv`, `/home/yans/safelibs/port-libcurl`, `/home/yans/safelibs/port-libexif`, `/home/yans/safelibs/port-libgcrypt`, `/home/yans/safelibs/port-libjansson`, `/home/yans/safelibs/port-libjpeg-turbo`, `/home/yans/safelibs/port-libjson`, `/home/yans/safelibs/port-liblzma`, `/home/yans/safelibs/port-libpng`, `/home/yans/safelibs/port-libsdl`, `/home/yans/safelibs/port-libsodium`, `/home/yans/safelibs/port-libtiff`, `/home/yans/safelibs/port-libuv`, `/home/yans/safelibs/port-libvips`, `/home/yans/safelibs/port-libwebp`, `/home/yans/safelibs/port-libxml`, `/home/yans/safelibs/port-libyaml`, and `/home/yans/safelibs/port-libzstd`
- `/home/yans/safelibs/apt-repo/.github/workflows/ci.yml`
- `/home/yans/safelibs/apt-repo/.github/workflows/pages.yml`
- `/home/yans/safelibs/apt-repo/scripts/verify-in-ubuntu-docker.sh`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`
- authenticated `gh` access with permission to create and inspect repositories under `safelibs`

## New Outputs

- GitHub Actions workflows for CI and Pages
- idempotent public-repo publication script
- updated repository `README.md`
- pushed public repo `safelibs/validator`

## File Changes

- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`
- `scripts/publish-public.sh`
- `README.md`
- `Makefile`

## Implementation Details

- Create `.github/workflows/ci.yml` for Ubuntu 24.04.
- It must define `preflight`, `unit-tests`, `matrix-smoke`, and `full-matrix` jobs.
- `unit-tests` always runs `python3 -m unittest discover -s unit -v`.
- Expose `GH_TOKEN` from `SAFELIBS_REPO_TOKEN` only in `preflight`, `matrix-smoke`, and `full-matrix`.
- `preflight` must emit a boolean output indicating whether `SAFELIBS_REPO_TOKEN` is present.
- Every secret-gated job must begin with `rm -rf .work/ports artifacts site`.
- `matrix-smoke` runs only on pull requests when the repo token is available.
- `matrix-smoke` stages exactly `giflib`, `libpng`, `libjson`, `libvips`, and `libjansson` into `.work/ports`, runs both modes for those libraries in that exact order in one `test.sh` invocation, and uses that fixed subset because it covers the manifest build-path classes `safe-debian`, `checkout-artifacts`, omitted-mode default-to-docker, explicit `mode: docker`, and bootstrap `source-debian-original`.
- `matrix-smoke` must capture `matrix_exit_code`, render `site/`, verify it with `scripts/verify-site.sh`, upload both `artifacts/` and `site/` with `if: ${{ always() }}`, and only then fail the job if `matrix_exit_code` is non-zero.
- `full-matrix` runs only on pushes to `main` when the repo token is available.
- `full-matrix` stages the full manifest-pinned repo set into `.work/ports`, runs the complete validator matrix with `--record-casts`, captures `matrix_exit_code`, renders and verifies the site, uploads `artifacts/` and `site/` with `if: ${{ always() }}`, and only then fails the job if `matrix_exit_code` is non-zero.
- Every secret-gated CI job must use `python3 tools/stage_port_repos.py --config repositories.yml --dest-root .work/ports` so CI never depends on `/home/yans/safelibs`.
- Create `.github/workflows/pages.yml` for GitHub Pages deployment.
- It must trigger on `push` to `main` and `workflow_dispatch`.
- It must declare top-level `permissions` with `contents: read`, `pages: write`, and `id-token: write`.
- The `build` job must check out the repo, export `GH_TOKEN` from `SAFELIBS_REPO_TOKEN`, fail fast when the secret is missing, install `python3-yaml`, `jq`, and `asciinema`, verify `docker` and `gh`, run `actions/configure-pages`, begin with `rm -rf .work/ports artifacts site`, stage the full manifest-pinned repo set into `.work/ports`, run the full matrix with `--record-casts`, capture `matrix_exit_code`, render and verify the site, upload `site/` with `actions/upload-pages-artifact`, and expose `matrix_exit_code` as a job output.
- Define a separate `deploy` job that depends on `build`, targets the `github-pages` environment, and uses `actions/deploy-pages`.
- Define a final `report-status` job with exact dependency line `needs: [build, deploy]`, read `needs.build.outputs.matrix_exit_code`, and fail the workflow if it is non-zero so the published report site still exists even when some validator runs failed.
- Defer only matrix test failures. Missing secrets, staging failures, render failures, verify-site failures, or Pages upload failures must still fail the `build` job immediately.
- The Pages workflow must rebuild the site from scratch inside CI instead of relying on `/home/yans/safelibs` or on artifacts from a previous local run.
- Implement `scripts/publish-public.sh` as an idempotent repo-publication command. It must create `safelibs/validator` as a public repo if it does not already exist, fail clearly if the existing remote repo is not public, reconcile `origin`, push `main`, and fail clearly if `gh auth` is missing or lacks permission.
- Update `README.md` with prerequisites, local commands, clone-backed staging defaults, optional `PORT_SOURCE_ROOT` override, artifact layout, and GitHub Pages output description.

## Verification Phases

### `check_07_full_matrix`

- phase ID: `check_07_full_matrix`
- type: `check`
- bounce_target: `impl_07_ci_pages_publish`
- purpose: run the full local validator matrix, render the final site, and verify Pages-ready output
- commands:

```bash
set -euo pipefail
rm -rf .work/check07 artifacts site
python3 -m unittest discover -s unit -v
mkdir -p .work/check07
python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check07 --dest-root .work/check07/ports
matrix_rc=0
bash test.sh --port-root .work/check07/ports --artifact-root artifacts --mode both --record-casts || matrix_rc=$?
python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site
bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site
exit "$matrix_rc"
```

### `check_07_release_publish_review`

- phase ID: `check_07_release_publish_review`
- type: `check`
- bounce_target: `impl_07_ci_pages_publish`
- purpose: review the GitHub workflows, publication script, Pages deployment topology, and pushed public repo state without depending on generated `site/` output from another verifier
- commands:

```bash
git diff --check HEAD^ HEAD
python3 - <<'PY'
from pathlib import Path
required = [
    Path(".github/workflows/ci.yml"),
    Path(".github/workflows/pages.yml"),
    Path("scripts/publish-public.sh"),
    Path("README.md"),
    Path("Makefile"),
]
missing = [str(path) for path in required if not path.exists()]
if missing:
    raise SystemExit(missing)
PY
python3 - <<'PY'
from pathlib import Path

ci = Path(".github/workflows/ci.yml").read_text()
pages = Path(".github/workflows/pages.yml").read_text()

ci_required = [
    "preflight:",
    "unit-tests:",
    "matrix-smoke:",
    "full-matrix:",
    "SAFELIBS_REPO_TOKEN",
    "GH_TOKEN: ${{ secrets.SAFELIBS_REPO_TOKEN }}",
    "python3 -m unittest discover -s unit -v",
    "python3 tools/stage_port_repos.py --config repositories.yml",
    "--dest-root .work/ports",
    "rm -rf .work/ports artifacts site",
    "--artifact-root artifacts",
    "matrix_exit_code",
    "always()",
    "bash test.sh --port-root .work/ports",
    "--library giflib",
    "--library libpng",
    "--library libjson",
    "--library libvips",
    "--library libjansson",
    "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
    "scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
    "actions/upload-artifact@",
]
for token in ci_required:
    if token not in ci:
        raise SystemExit(f"ci.yml missing: {token}")

pages_required = [
    "build:",
    "deploy:",
    "report-status:",
    "permissions:",
    "contents: read",
    "pages: write",
    "id-token: write",
    "Validate deployment secrets",
    "GH_TOKEN: ${{ secrets.SAFELIBS_REPO_TOKEN }}",
    "actions/configure-pages@",
    "actions/upload-pages-artifact@",
    "actions/deploy-pages@",
    "environment:",
    "github-pages",
    "needs: [build, deploy]",
    "python3 tools/stage_port_repos.py --config repositories.yml",
    "--dest-root .work/ports",
    "rm -rf .work/ports artifacts site",
    "--artifact-root artifacts",
    "matrix_exit_code",
    "needs.build.outputs.matrix_exit_code",
    "bash test.sh --port-root .work/ports --artifact-root artifacts --mode both --record-casts",
    "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
    "scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
]
for token in pages_required:
    if token not in pages:
        raise SystemExit(f"pages.yml missing: {token}")
PY
rg -n 'gh repo (view|create)|git remote (add|set-url)|git push' scripts/publish-public.sh
rg -n '^publish-public:' Makefile
rg -n 'make unit|make stage-ports|make test|make render-site|make verify-site|make publish-public|PORT_SOURCE_ROOT|GitHub clone|asciinema|artifacts/casts|site/casts|GitHub Pages' README.md
! rg -n '/home/yans/safelibs' README.md
test "$(gh repo view safelibs/validator --json visibility --jq '.visibility')" = "PUBLIC"
gh repo view safelibs/validator --json name,visibility,url
git remote get-url origin
python3 - <<'PY'
import re
import subprocess

remote = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
if not re.search(r'[:/]safelibs/validator(?:\\.git)?$', remote):
    raise SystemExit(remote)
PY
git ls-remote --heads origin main
```

## Success Criteria

- The full local matrix passes from a freshly staged manifest-pinned `port-root`, renders the final site, and verifies Pages-ready output.
- CI and Pages workflows both render and verify the site from produced results before surfacing deferred matrix failures.
- `scripts/publish-public.sh` is idempotent, `origin` points at `github.com/safelibs/validator`, and the public repo exists with `main` pushed.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

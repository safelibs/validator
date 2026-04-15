# SafeLibs Validator

This repository stages tagged `port-*` repositories, runs the validator matrix against the checked-in 19-library manifest, renders a static report, and publishes the result to a public GitHub Pages site.

## Prerequisites

- Ubuntu or another host with `bash`, `git`, `python3`, Docker, and the Python `yaml` module available.
- Auth for private `port-*` repositories through either `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`.
- Optional local sibling clones under `/home/yans/safelibs` when you want `tools/stage_port_repos.py --source-root /home/yans/safelibs` to clone from local sources before fetching missing tags.
- `gh` authenticated if you want to run `make inventory` or `make publish-public` without exporting `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`.

The private-repo auth contract is uniform across local runs, CI, and Pages:

- Prefer `GH_TOKEN`.
- Fall back to `SAFELIBS_REPO_TOKEN`.
- If neither is set locally, the tools fall back to the caller's authenticated `gh` session when possible.
- GitHub Actions jobs that need private `port-*` access export both `GH_TOKEN` and `SAFELIBS_REPO_TOKEN` from the `SAFELIBS_REPO_TOKEN` secret before invoking `gh`, `tools/inventory.py`, or `tools/stage_port_repos.py`.

## Common Commands

Run hermetic unit coverage:

```bash
make unit
```

Verify the checked-in manifest can still reach every tagged private repo:

```bash
python3 tools/inventory.py --config repositories.yml --check-remote-tags
```

Stage the full manifest from private repos:

```bash
python3 tools/stage_port_repos.py \
  --config repositories.yml \
  --workspace .work \
  --dest-root .work/ports
```

Stage from local sibling clones instead of cloning directly from GitHub:

```bash
python3 tools/stage_port_repos.py \
  --config repositories.yml \
  --source-root /home/yans/safelibs \
  --workspace .work \
  --dest-root .work/ports
```

Run the matrix and capture artifacts:

```bash
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --port-root .work/ports \
  --artifact-root artifacts \
  --mode both \
  --record-casts
```

Render and verify the static report:

```bash
python3 tools/render_site.py \
  --results-root artifacts/results \
  --artifacts-root artifacts \
  --output-root site

bash scripts/verify-site.sh \
  --config repositories.yml \
  --results-root artifacts/results \
  --site-root site
```

## Safe Deb Layout

`test.sh` also accepts an optional `--safe-deb-root` matrix root. The layout must be:

```text
<safe-deb-root>/<library>/*.deb
```

Each library leaf is mounted into the runtime container as `/safedebs`, so every `tests/<library>/docker-entrypoint.sh` sees only that library's `.deb` files.

## Artifact Locations

- `artifacts/debs/<library>/`: built or copied safe packages for each library.
- `artifacts/results/<library>/*.json`: one result JSON per attempted matrix run.
- `artifacts/logs/<library>/*.log`: captured run logs.
- `artifacts/casts/<library>/safe.cast`: safe-mode terminal capture when `--record-casts` is enabled.
- `site/`: rendered static report for local review or GitHub Pages publication.

## Publication

`make publish-public` wraps `scripts/publish-public.sh`:

```bash
make publish-public
```

That script:

- resolves auth through `GH_TOKEN`, then `SAFELIBS_REPO_TOKEN`, then the local `gh` session,
- runs `python3 tools/inventory.py --config repositories.yml --check-remote-tags`,
- creates `safelibs/validator` with `gh repo create safelibs/validator --public` when needed,
- verifies `gh repo view safelibs/validator --json visibility,nameWithOwner,url` reports a public repository,
- reconciles `origin`,
- and pushes local `main`.

After publication, `git remote get-url origin` should resolve to `safelibs/validator`, and GitHub Pages deployment is driven by `.github/workflows/pages.yml` on pushes to `main` or manual `workflow_dispatch`.

## GitHub Pages

The Pages workflow rebuilds the full matrix on `main`, uploads the rendered `site/` output, deploys it with `actions/deploy-pages`, and only then reports aggregate matrix failure through the follow-up `report-status` job. That keeps publication available even when a validator run fails while still surfacing a failing workflow conclusion.

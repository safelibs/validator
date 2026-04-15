# Validators for SafeLibs

The SafeLibs projects aims to rewrite loadbearing libraries in memory safe languages.
To support this, we need to have thorough testsets of actual applications dependent on these libraries.
This repository has these test sets.

## Structure

For each libary `LIBNAME`:

- `tests/LIBNAME/Dockerfile`: defines a docker image that installs LIBNAME and the relevant dependent applications. The "original" version of `LIBNAME` (e.g. from the normal apt repos) is installed.
- `tests/LIBNAME/docker-entrypoint.sh`: The entrypoint. It should install all replacement debs from `/safedebs/*.deb` (which will be specified with `-v` to `docker run`) if provided, then run the tests and exits cleanly if they all pass.
- `tests/LIBNAME/tests/`: The tests. They should make sure that the libraries work. The tests should not know or depend on which version (safe or original) of the library they're running on. It is a violation to check.
- `test.sh`: runs all the tests (or a specific `LIBNAME` test if needed)

## Evidence

The CI of this repository:

- runs tests for both the original and the safe version
- reports the results
- records an asciicinema of the safe version runs (tests should run with `bash -x` for viewability)
- publishes a github pages of the result (if on main branch)

## Failures

Not all the tests might pass on the safe version (in case of rust translation errors, for example).
This is expected.
Such failures should be pointed out in the test case results page.

## Errata

- No changes can be made to either the original library or the safe library; both must be used as is.
- The tests cannot check whether they are running against the original or safe library. Doing so is forbidden.
- The tests must check functionality, not security.

## Current Validator Docs

The operational documentation that had replaced this README is preserved below.

### SafeLibs Validator

This repository stages tagged `port-*` repositories, runs the validator matrix against the checked-in 19-library manifest, renders a static report, and publishes the result to a public GitHub Pages site.

#### Prerequisites

- Ubuntu or another host with `bash`, `git`, `python3`, Docker, and the Python `yaml` module available.
- Optional local sibling clones under `/home/yans/safelibs` when you want `tools/stage_port_repos.py --source-root /home/yans/safelibs` to clone from local sources before fetching missing tags.
- `gh` authenticated if you want to run `make inventory`.

The `port-*` repositories are public, so `tools/inventory.py` and `tools/stage_port_repos.py` work without credentials. When `GH_TOKEN` (or the legacy `SAFELIBS_REPO_TOKEN` fallback) is set, or the caller has an authenticated `gh` session, the tools use it to raise GitHub API and git rate limits — otherwise they fall back to anonymous `https://github.com/...` URLs.

#### Common Commands

Run hermetic unit coverage:

```bash
make unit
```

Verify the checked-in manifest can still reach every tagged port repo:

```bash
python3 tools/inventory.py --config repositories.yml --check-remote-tags
```

Stage the full manifest from the port repos:

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

Refresh and verify checked-in imported mirrors. When `libuv` is in scope, the full-manifest stage is not enough by itself: restage `libuv` from the local sibling clone immediately afterward so `.work/build-safe/libuv/source/safe/target/release/libuv.a` is present for the `safe/prebuilt` import contract.

```bash
python3 tools/stage_port_repos.py \
  --config repositories.yml \
  --workspace .work \
  --dest-root .work/ports

python3 tools/stage_port_repos.py \
  --config repositories.yml \
  --source-root /home/yans/safelibs \
  --workspace .work \
  --dest-root .work/ports \
  --libraries libuv

for library in giflib libcsv libjpeg-turbo libjson liblzma libpng libsdl libsodium libuv libvips libwebp libyaml libzstd; do
  python3 tools/import_port_assets.py \
    --config repositories.yml \
    --library "$library" \
    --port-root .work/ports \
    --workspace .work \
    --dest-root .
done

python3 tools/verify_imported_assets.py \
  --config repositories.yml \
  --port-root .work/ports \
  --tests-root tests
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

#### Safe Deb Layout

`test.sh` also accepts an optional `--safe-deb-root` matrix root. The layout must be:

```text
<safe-deb-root>/<library>/*.deb
```

Each library leaf is mounted into the runtime container as `/safedebs`, so every `tests/<library>/docker-entrypoint.sh` sees only that library's `.deb` files.

#### Artifact Locations

- `artifacts/debs/<library>/`: built or copied safe packages for each library.
- `artifacts/results/<library>/*.json`: one result JSON per attempted matrix run.
- `artifacts/logs/<library>/*.log`: captured run logs.
- `artifacts/casts/<library>/safe.cast`: safe-mode terminal capture when `--record-casts` is enabled.
- `site/`: rendered static report for local review or GitHub Pages publication.

#### GitHub Pages

The Pages workflow rebuilds the full matrix on `main`, uploads the rendered `site/` output, deploys it with `actions/deploy-pages`, and only then reports aggregate matrix failure through the follow-up `report-status` job. That keeps publication available even when a validator run fails while still surfacing a failing workflow conclusion.

# Validator Matrix

This repository validates Ubuntu 24.04 library behavior in two modes: the
original Ubuntu apt packages, and the same reference tests with native `.deb`
assets from the safelibs port `04-test` releases installed as overrides. It
keeps Docker harnesses, testcase manifests, proof tooling, and a static evidence
site together so both package behaviors can be rerun and reviewed from one
checkout.

## Repository Layout

- `repositories.yml`: canonical v2 manifest for the 24 supported libraries.
- `tests/<library>/Dockerfile`: Ubuntu 24.04 harness image for one library.
- `tests/<library>/testcases.yml`: library-level metadata (apt packages and
  schema). Per-testcase metadata lives in the script files themselves.
- `tests/<library>/tests/cases/source/<id>.sh`: one source-facing testcase per
  file, self-describing via `@testcase` header directives.
- `tests/<library>/tests/cases/usage/<id>.sh`: one dependent-client testcase
  per file, self-describing via `@testcase` header directives.
- `tests/<library>/tests/fixtures/dependents.json`: compact dependent-client
  fixture data used by usage testcases.
- `tests/<library>/tests/fixtures/samples/`: small non-source sample inputs
  used by fixture-driven testcases.
- `tests/_shared/`: common package override and testcase runtime helpers.
- `tools/`: manifest, matrix, proof, and site rendering tools.
- `scripts/verify-site.sh`: deterministic site verification.
- `unit/`: unit tests for the tooling.
- `inventory/github-port-repos.json`: authoritative safelibs port repository
  list for resolving port `04-test` debs.
- `inventory/`: retained historical discovery snapshots; other normal
  validation commands do not read them.
- `artifacts/`: generated matrix logs, casts, results, and proof.
- `site/`: generated static review site.

## Manifest Schema

`repositories.yml` uses `schema_version: 2` and contains:

- `suite`: `name`, `image`, and `apt_suite` for the Ubuntu package suite.
- `libraries`: fixed-order entries with `name`, canonical `apt_packages`,
  `testcases`, and `fixtures.dependents`.

Each `tests/<library>/testcases.yml` uses `schema_version: 1` and contains
only library-level fields:

- `library`: the library name, matching `repositories.yml`.
- `apt_packages`: the exact canonical package list for that library.

Per-testcase metadata is discovered from the filesystem. Each script under
`tests/<library>/tests/cases/source/<id>.sh` or
`tests/<library>/tests/cases/usage/<id>.sh` declares its own metadata in a
header block of `# @<key>: <value>` directives placed immediately after the
shebang. The `id` is taken from the filename and the `kind` (`source` /
`usage`) from the parent directory.

```bash
#!/usr/bin/env bash
# @testcase: pngfix-fixture-handling
# @title: pngfix fixture handling
# @description: Runs pngfix against a checked-in PNGSuite fixture and validates output.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
...
```

Required directives are `@testcase`, `@title`, `@description`, `@timeout`
(integer seconds, 1..7200), and `@tags` (comma-separated, may be empty).
Usage testcases must additionally declare `@client: <client-application>`,
naming a client present in `tests/<library>/tests/fixtures/dependents.json`;
source testcases must not.

Dependent fixtures use `schema_version: 1`, `library`, and a non-empty
`dependents` list. Entries may include `name`, `source_package`, `package`,
`binary_package`, `packages`, and `description`.

## Running Tests

Run unit tests and manifest checks:

```bash
make unit
make check-testcases
```

Run the full original-package matrix with terminal casts:

```bash
RECORD_CASTS=1 make matrix-original
```

Fetch current port `04-test` debs, then run the same testcase matrix against
the override packages:

```bash
make fetch-port-debs
RECORD_CASTS=1 make matrix-port
```

Run selected libraries:

```bash
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --library cjson \
  --library libuv \
  --record-casts
```

Generate proof and render the site from completed matrix results:

```bash
python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --proof-output artifacts/proof/original-validation-proof.json \
  --min-source-cases 120 \
  --min-usage-cases 1683 \
  --min-cases 1803 \
  --require-casts

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --proof-output artifacts/proof/port-04-test-validation-proof.json \
  --mode port-04-test \
  --min-source-cases 120 \
  --min-usage-cases 1683 \
  --min-cases 1803 \
  --require-casts

python3 tools/render_site.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --proof-path artifacts/proof/original-validation-proof.json \
  --proof-path artifacts/proof/port-04-test-validation-proof.json \
  --output-root site

bash scripts/verify-site.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifacts-root artifacts \
  --proof-path artifacts/proof/original-validation-proof.json \
  --proof-path artifacts/proof/port-04-test-validation-proof.json \
  --site-root site
```

The same flow is available through Make targets:

```bash
REQUIRE_CASTS=1 MIN_SOURCE_CASES=120 MIN_USAGE_CASES=1683 MIN_CASES=1803 make proof-dual
make site-dual
make verify-site-dual
```

For a faster local representative run:

```bash
make matrix-smoke ARTIFACT_ROOT=/tmp/validator-smoke-artifacts
REQUIRE_CASTS=1 MIN_SOURCE_CASES=20 MIN_USAGE_CASES=41 MIN_CASES=61 \
  LIBRARIES="cjson libarchive libuv libwebp" \
  make proof ARTIFACT_ROOT=/tmp/validator-smoke-artifacts
make site ARTIFACT_ROOT=/tmp/validator-smoke-artifacts SITE_ROOT=/tmp/validator-smoke-site
LIBRARIES="cjson libarchive libuv libwebp" \
  make verify-site ARTIFACT_ROOT=/tmp/validator-smoke-artifacts SITE_ROOT=/tmp/validator-smoke-site
```

## Override Packages

The official port flow resolves repositories from
`inventory/github-port-repos.json`. For each selected library it resolves
`refs/tags/<library>/04-test`, derives release tag `build-<sha12>` from that
commit hash, downloads available native `amd64` or `all` `.deb` assets matching
the canonical `apt_packages`, and records omitted canonical packages as
`unported_original_packages` in
`artifacts/proof/port-04-test-debs-lock.json`.

If a port has no qualifying `04-test` release or no native canonical deb assets,
the lock records `port_unavailable_reason`, no debs, and all canonical packages
as unported. The port matrix records every testcase for that library as failed
without building a container, which makes the port show 0 passing while keeping
the original Ubuntu package results as the source of truth.

Port repositories and releases can be private. Authentication is read from
`GH_TOKEN`, `VALIDATOR_REPO_TOKEN`, or `gh auth token`.

Downloaded debs are cached under `artifacts/debs/port-04-test/` and are ignored
by git. The lock, port proof, and rendered site evidence are reproducibility
artifacts.

The matrix runner also keeps the generic local override hook. The root must be
laid out as `<override-deb-root>/<library>/*.deb`.

```bash
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --mode original \
  --override-deb-root /path/to/override-debs \
  --record-casts
```

## GitHub Pages

`.github/workflows/pages.yml` runs on pushes to `main` and on manual dispatch.
It runs unit tests, validates testcase manifests, fetches port debs, executes
the original and port matrices, generates original and port proofs, renders the
dual-mode `site/`, verifies the rendered output, and publishes the verified
site directory with GitHub Pages. Workflow success requires the original proof
and rendered site verification to pass; port proof failures remain published as
validation findings and do not by themselves fail the workflows.

## Variables

- `CONFIG`: manifest path, defaults to `repositories.yml`.
- `TESTS_ROOT`: harness root, defaults to `tests`.
- `ARTIFACT_ROOT`: result and proof root, defaults to `artifacts`.
- `SITE_ROOT`: rendered site root, defaults to `site`.
- `PROOF_OUTPUT`: proof path below `ARTIFACT_ROOT`, defaults to
  `proof/original-validation-proof.json`.
- `PROOF_PATH`: full proof path shared by proof, site, and site verification
  targets, defaults to `$(ARTIFACT_ROOT)/$(PROOF_OUTPUT)`.
- `PORT_REPOS`: port repo inventory, defaults to `inventory/github-port-repos.json`.
- `PORT_MODE`: port validation mode, defaults to `port-04-test`.
- `PORT_DEB_ROOT`: downloaded port deb root, defaults to
  `$(ARTIFACT_ROOT)/debs/$(PORT_MODE)`.
- `PORT_LOCK_PATH`: port deb lock path, defaults to
  `$(ARTIFACT_ROOT)/proof/$(PORT_MODE)-debs-lock.json`.
- `ORIGINAL_PROOF_PATH`, `PORT_PROOF_PATH`: proof inputs for dual-mode site
  rendering and verification.
- `LIBRARY`: optional single library selection for matrix and proof targets.
- `LIBRARIES`: optional space-separated library selections for matrix, proof,
  and site verification targets.
- `RECORD_CASTS`: set to any non-empty value to record casts during matrix runs.
- `REQUIRE_CASTS`: set to any non-empty value to require casts during proof
  generation.
- `MIN_SOURCE_CASES`, `MIN_USAGE_CASES`, `MIN_CASES`: optional proof count
  thresholds.

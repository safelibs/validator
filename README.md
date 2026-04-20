# Validator Matrix

This repository performs thorough validation of original Ubuntu 24.04 apt
library packages. It keeps Docker harnesses, testcase manifests, proof tooling,
and a static evidence site together so the package behavior can be rerun and
reviewed from one checkout.

## Repository Layout

- `repositories.yml`: canonical v2 manifest for the 19 supported libraries.
- `tests/<library>/Dockerfile`: Ubuntu 24.04 harness image for one library.
- `tests/<library>/testcases.yml`: source and usage testcase manifest.
- `tests/<library>/tests/cases/source/*.sh`: source-facing testcase scripts.
- `tests/<library>/tests/cases/usage/*.sh`: dependent-client testcase scripts.
- `tests/<library>/tests/fixtures/dependents.json`: compact dependent-client
  fixture data used by usage testcases.
- `tests/<library>/tests/fixtures/samples/`: small non-source sample inputs
  used by fixture-driven testcases.
- `tests/_shared/`: common package override and testcase runtime helpers.
- `tools/`: manifest, matrix, proof, and site rendering tools.
- `scripts/verify-site.sh`: deterministic site verification.
- `unit/`: unit tests for the tooling.
- `inventory/`: retained historical discovery snapshots; normal validation
  commands do not read them.
- `artifacts/`: generated matrix logs, casts, results, and proof.
- `site/`: generated static review site.

## Manifest Schema

`repositories.yml` uses `schema_version: 2` and contains:

- `suite`: `name`, `image`, and `apt_suite` for the Ubuntu package suite.
- `libraries`: fixed-order entries with `name`, canonical `apt_packages`,
  `testcases`, and `fixtures.dependents`.

Each `tests/<library>/testcases.yml` uses `schema_version: 1` and contains:

- `library`: the library name, matching `repositories.yml`.
- `apt_packages`: the exact canonical package list for that library.
- `testcases`: entries with `id`, `title`, `description`, `kind`, `command`,
  `timeout_seconds`, `tags`, optional `requires`, and `client_application` for
  usage cases.

`kind` is either `source` or `usage`. Source cases must run a script under
`tests/<library>/tests/cases/source/`; usage cases must run a script under
`tests/<library>/tests/cases/usage/` and name a client present in
`tests/<library>/tests/fixtures/dependents.json`.

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
RECORD_CASTS=1 make matrix
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
```

The same flow is available through Make targets:

```bash
REQUIRE_CASTS=1 MIN_SOURCE_CASES=95 MIN_USAGE_CASES=155 MIN_CASES=250 make proof
make site
make verify-site
```

For a faster local representative run:

```bash
make matrix-smoke ARTIFACT_ROOT=/tmp/validator-smoke-artifacts
REQUIRE_CASTS=1 MIN_SOURCE_CASES=20 MIN_USAGE_CASES=32 MIN_CASES=52 \
  LIBRARIES="cjson libarchive libuv libwebp" \
  make proof ARTIFACT_ROOT=/tmp/validator-smoke-artifacts
make site ARTIFACT_ROOT=/tmp/validator-smoke-artifacts SITE_ROOT=/tmp/validator-smoke-site
LIBRARIES="cjson libarchive libuv libwebp" \
  make verify-site ARTIFACT_ROOT=/tmp/validator-smoke-artifacts SITE_ROOT=/tmp/validator-smoke-site
```

## Override Packages

The matrix runner can install caller-provided replacement `.deb` files before
executing testcases. The root must be laid out as
`<override-deb-root>/<library>/*.deb`.

```bash
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root artifacts \
  --override-deb-root /path/to/override-debs \
  --record-casts
```

This is a generic local validation hook. Normal repository CI and proof
thresholds validate the original Ubuntu apt packages and require
`override_debs_installed` to be false in proof inputs.

## GitHub Pages

`.github/workflows/pages.yml` runs on pushes to `main` and on manual dispatch.
It runs unit tests, validates testcase manifests, executes the full matrix,
generates `artifacts/proof/original-validation-proof.json`, renders `site/`,
verifies the rendered output, and publishes the verified `site/` directory with
GitHub Pages.

## Variables

- `CONFIG`: manifest path, defaults to `repositories.yml`.
- `TESTS_ROOT`: harness root, defaults to `tests`.
- `ARTIFACT_ROOT`: result and proof root, defaults to `artifacts`.
- `SITE_ROOT`: rendered site root, defaults to `site`.
- `PROOF_OUTPUT`: proof path below `ARTIFACT_ROOT`, defaults to
  `proof/original-validation-proof.json`.
- `PROOF_PATH`: full proof path shared by proof, site, and site verification
  targets, defaults to `$(ARTIFACT_ROOT)/$(PROOF_OUTPUT)`.
- `LIBRARY`: optional single library selection for matrix and proof targets.
- `LIBRARIES`: optional space-separated library selections for matrix, proof,
  and site verification targets.
- `RECORD_CASTS`: set to any non-empty value to record casts during matrix runs.
- `REQUIRE_CASTS`: set to any non-empty value to require casts during proof
  generation.
- `MIN_SOURCE_CASES`, `MIN_USAGE_CASES`, `MIN_CASES`: optional proof count
  thresholds.

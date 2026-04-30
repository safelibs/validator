# Agent Guide

This file orients agents (LLM or human) working in the `validator` repository.
For end-user documentation, see `README.md`. This guide focuses on layout,
conventions, and the constraints that are easy to miss.

## What this repo does

Validates Ubuntu 24.04 library behavior in two modes:

1. `original` — stock Ubuntu apt packages from the suite declared in
   `repositories.yml`.
2. `port-04-test` — the same testcases against native `.deb` assets from the
   safelibs port `04-test` releases, installed as overrides.

Both modes reuse identical testcases, harnesses, proof tooling, and the static
evidence site, so the two package behaviors are directly comparable.

24 libraries are in scope. The list and order are fixed in `repositories.yml`.

## Repository layout

```
repositories.yml             canonical v2 manifest (suite + 24 libraries)
Makefile                     entry points for unit, matrix, proof, site
test.sh                      thin wrapper around tools/run_matrix.py
conftest.py                  pytest collection guard for generated workspaces
workflow.yaml                generated CI workflow snapshot

tests/<library>/             one harness per library
  Dockerfile                   Ubuntu 24.04 image for the library
  docker-entrypoint.sh         in-container runner
  host-run.sh                  host-side runner invoked by the matrix
  testcases.yml                library-level metadata only (schema_version: 1)
  tests/cases/source/<id>.sh   one source-facing testcase per file
  tests/cases/usage/<id>.sh    one dependent-client testcase per file
  tests/fixtures/dependents.json   dependent-client fixture data
  tests/fixtures/samples/      small non-source sample inputs
tests/_shared/               package override + testcase runtime helpers

tools/                       Python tooling (manifest, matrix, proof, site)
scripts/verify-site.sh       deterministic site verification
unit/                        unittest suite for the tooling
inventory/                   port repo inventory + historical snapshots
artifacts/                   generated matrix logs, casts, results, proof
site/                        generated static review site
```

`artifacts/` and `site/` are produced by the tooling. Do not hand-edit them.

## Testcases: one per file, self-describing

A testcase is exactly one shell script. Two strict rules:

- **One testcase per file.** Do not pack multiple cases into one script.
- **The script is self-describing.** Metadata lives in `# @<key>: <value>`
  directives in a header block placed immediately after the shebang. There is
  no per-testcase metadata in `testcases.yml`.

The testcase `id` is the filename stem; the `kind` (`source` or `usage`) comes
from the parent directory.

Required directives:

- `@testcase` — must equal the filename stem.
- `@title`
- `@description`
- `@timeout` — integer seconds in `[1, 7200]`.
- `@tags` — comma-separated, may be empty.

Usage testcases must additionally declare `@client: <name>`, where `<name>` is
present in `tests/<library>/tests/fixtures/dependents.json`. Source testcases
must not declare `@client`.

Example:

```bash
#!/usr/bin/env bash
# @testcase: pngfix-fixture-handling
# @title: pngfix fixture handling
# @description: Runs pngfix against a checked-in PNGSuite fixture and validates output.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
...
```

Naming conventions in practice:

- Source cases: short, behavior-oriented stems
  (e.g. `pngfix-fixture-handling.sh`, `read-write-c-api-smoke.sh`).
- Usage cases: prefixed with `usage-`, then the dependent client and the
  specific operation
  (e.g. `usage-netpbm-batch11-pngtopam-pamfile.sh`).

`tools/testcases.py --check` enforces these rules and counts thresholds.

## Manifest schemas

`repositories.yml` (`schema_version: 2`):

- `suite`: `name`, `image`, `apt_suite`.
- `libraries`: fixed-order entries with `name`, canonical `apt_packages`,
  `testcases`, and `fixtures.dependents`.

`tests/<library>/testcases.yml` (`schema_version: 1`):

- `library` — must match `repositories.yml`.
- `apt_packages` — must equal the canonical list verbatim.

`tests/<library>/tests/fixtures/dependents.json` (`schema_version: 1`):

- `library`, plus a non-empty `dependents` list whose entries may include
  `name`, `source_package`, `package`, `binary_package`, `packages`,
  `description`.

## Unit tests (Python tooling)

- Live under `unit/`, run via `make unit` (`python3 -m unittest discover -s unit -v`).
- Use `unittest`, not pytest assertions, but pytest also collects them.
- Filenames follow `test_<module>.py`; class methods follow `test_<behavior>`.
- Fixtures and sample manifests live in `unit/fixtures/`.
- `conftest.py` excludes `.work/` and `artifacts/.workspace/` from collection,
  so generated container workspaces will not be picked up.

`make check-testcases` enforces manifest + testcase header consistency and
must pass before any matrix run.

## Running things

Common entry points (see `README.md` for the full list):

```bash
make unit                  # python tooling tests
make check-testcases       # manifest + header lint
make matrix-original       # full original-package matrix
make fetch-port-debs       # download port 04-test debs
make matrix-port           # port matrix against fetched debs
make proof-dual            # generate both proofs
make site-dual             # render the dual-mode site
make verify-site-dual      # deterministic site re-render check
make matrix-smoke          # fast representative subset
```

Set `RECORD_CASTS=1` to record asciinema casts during matrix runs;
`REQUIRE_CASTS=1` to require them during proof generation.

## Conventions worth respecting

- Per-testcase metadata lives in the script header, never in YAML.
- Library order in `repositories.yml` is canonical; do not reorder.
- `apt_packages` in `tests/<library>/testcases.yml` must match the manifest
  exactly. If you change one, change the other.
- Port debs are fetched from the GitHub *latest release* of the repo named in
  `inventory/github-port-repos.json`, not from a phase tag.
- A library with no published port release is recorded with
  `port_unavailable_reason` and counted as 0-passing in the port matrix; the
  original results remain the source of truth.
- Authentication for private port repos: `GH_TOKEN`, `VALIDATOR_REPO_TOKEN`,
  or `gh auth token`, in that order.
- `artifacts/debs/port-04-test/` is gitignored; the lock, proofs, and rendered
  site are reproducibility artifacts and are tracked.

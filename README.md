# Validator Matrix

This repository validates Ubuntu 24.04 original library packages with checked-in
Docker harnesses, testcase manifests, result proof generation, and static site
rendering.

## Manifest

`repositories.yml` is the canonical v2 manifest. It lists the 19 supported
libraries in fixed order, the original Ubuntu binary packages in validation
scope, each library's testcase manifest, the checked-in original source
snapshot, and the dependent-application fixture.

Each `tests/<library>/testcases.yml` mirrors the canonical package list from
`repositories.yml`. Phase 2 intentionally leaves `testcases: []` empty; later
catalog phases populate source and usage cases.

## Commands

Run unit tests:

```bash
make unit
```

Check manifest and testcase package metadata:

```bash
make check-testcases
```

Run the original-package matrix after testcase manifests contain executable
cases:

```bash
make matrix
```

Generate proof and site artifacts from completed matrix results:

```bash
make proof
make site
make verify-site
```

Useful variables:

- `CONFIG`: manifest path, defaults to `repositories.yml`.
- `TESTS_ROOT`: harness root, defaults to `tests`.
- `ARTIFACT_ROOT`: result and proof root, defaults to `artifacts`.
- `SITE_ROOT`: rendered site root, defaults to `site`.
- `LIBRARY`: optional single library selection for matrix and proof targets.
- `RECORD_CASTS`: set to any non-empty value to require or record casts where
  the command supports them.

# Safe-Side Upstream Harness

This directory is the phase-1 source of truth for reused upstream tests.

- `manifest.toml` records the machine-parsed contract for every safe-side entry.
- `build_helpers.sh` builds the non-installed helper binaries against the staged safe library in `safe/target/stage`.
- `run_makefile_tests.sh` is the one allowed direct reuse of an upstream makefile body because `original/Makefile.tests` resolves helper binaries through `xml2-config` instead of `$(top_builddir)`.
- `run_doc_examples.sh` ports the `doc/examples` regression body without relying on the upstream top-builddir executable paths.
- `run_target_body.sh` is the extension point for the remaining safe-side ports from `original/Makefile.am`.

Phase 1 establishes the manifest structure and the helper build/staging contract. Later phases extend the same manifest and target-body runner in place instead of replacing them.

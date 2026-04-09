# Validator Implementation Plan

## Context

`README.md:1-23` defines the product to build: one validator harness per in-scope library under `tests/<library>/`, a top-level `test.sh` that can run original and safe matrices, tests that stay implementation-blind, safe-mode cast capture with `bash -x`, and GitHub Pages publication of the results.

The tracked runtime repository is still effectively empty. `git ls-files` on April 9, 2026 shows only `README.md` plus the stale seven-phase generated artifacts under `.plan/`; no validator runtime, no `tests/` tree, no `tools/` package, no CI workflows, and no publication remote are tracked yet. The current worktree also contains untracked scratch from failed attempts, including `.plan/plan.md`, `.plan/findings.md`, `.plan/goal.md`, `.work/`, and a stale candidate `workflow.yaml`. `git remote -v` is empty on April 9, 2026, and `gh repo view safelibs/validator --json nameWithOwner,isPrivate,url,visibility` currently fails because the public destination repository does not exist yet.

The tracked generated planning artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml` are stale, and any existing worktree `workflow.yaml` is equally stale scratch from the failed attempt. They still encode an older 23/24-library bootstrap-and-publication-tag design. This file is the authoritative plan. Any regenerated workflow artifacts must be rewritten to the exact 6-phase topology in this file, and the superseded `shared-matrix`, `bootstrap-missing-validators`, and `07-ci-pages-publish` artifacts must not remain in the final repository. Matching a kept filename is not enough: same-name files such as `.plan/phases/01-inventory-scaffold.md`, `.plan/phases/04-media-validators.md`, and `.plan/workflow-structure.yaml` are also stale inputs right now and phase 06 must overwrite their committed contents instead of treating them as already correct.

The goal text says `github.com/safelibs/repos-*`, but the live org inventory on April 9, 2026 uses `port-*` repositories. `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef` shows 24 `port-*` repositories and no `repos-*` repositories. Phase 01 must preserve both facts in the checked-in inventory:

- `goal_repo_family: repos-*`
- `verified_repo_family: port-*`

Scope is dynamic. The in-scope library set is every `port-*` repository whose remote advertises `refs/tags/<library>/04-test` at implementation time. Phase 01 is the only phase allowed to discover that set from live GitHub state. Later phases must consume the checked-in inventory and `repositories.yml` that phase 01 writes.

As of April 9, 2026, the live selected set is 19 libraries:

- `cjson`
- `giflib`
- `libarchive`
- `libbz2`
- `libcsv`
- `libexif`
- `libjpeg-turbo`
- `libjson`
- `liblzma`
- `libpng`
- `libsdl`
- `libsodium`
- `libtiff`
- `libuv`
- `libvips`
- `libwebp`
- `libxml`
- `libyaml`
- `libzstd`

As of April 9, 2026, these 5 repositories are explicitly out of scope because they do not publish `refs/tags/<library>/04-test` yet:

- `glib`
- `libc6`
- `libcurl`
- `libgcrypt`
- `libjansson`

`/home/yans/safelibs/apt-repo/repositories.yml:1-327` remains the authoritative source for build metadata on the 17 tagged libraries it already manages: `cjson`, `giflib`, `libarchive`, `libbz2`, `libcsv`, `libjpeg-turbo`, `libjson`, `liblzma`, `libpng`, `libsdl`, `libsodium`, `libtiff`, `libvips`, `libwebp`, `libxml`, `libyaml`, and `libzstd`. Validator must copy those entries' `github_repo`, optional `verify_packages`, and full `build` mapping verbatim while still selecting scope dynamically from the live `04-test` tags.

Two tagged libraries are in scope even though `apt-repo` does not manage them:

- `libexif`
- `libuv`

Their remote `04-test` tags already contain mature validator inputs, including `dependents.json`, `relevant_cves.json`, `test-original.sh`, `safe/debian/control`, and tracked safe-test material. They should be treated as mature tagged imports, not as bootstrap-from-HEAD projects.

Local sibling worktrees under `/home/yans/safelibs/port-*` are clone sources only. They are not authoritative for ref selection. The selected ref is always `refs/tags/<library>/04-test` from the manifest. Local staging must therefore create clean detached clones and check out the manifest ref. If the detached clone created from `--source-root` does not already contain that tag locally, the staging tool must fetch only that exact tag from the manifest's GitHub repository URL into the detached clone before checkout. It must not rely on the inherited `origin` of a local-path clone, because cloning `/home/yans/safelibs/port-libuv` produces `origin=/home/yans/safelibs/port-libuv`, which cannot supply the remote-only tag. `port-libuv` is the concrete case that makes this mandatory.

The live `port-*` repositories are private, and the current workstation's `gh auth status` reports `Git operations protocol: ssh`. Validator automation must therefore use one explicit private-repo auth contract instead of assuming SSH keys or ambient git credential helpers. Resolve an effective GitHub token by preferring `GH_TOKEN` and falling back to `SAFELIBS_REPO_TOKEN`; when such a token exists, all git access to `github.com/safelibs/port-*` must use token-authenticated HTTPS URLs of the form `https://x-access-token:<token>@github.com/<github_repo>.git`, and all `gh` commands must run with `GH_TOKEN` exported. If neither env var is present, local developer commands may fall back to `git@github.com:<github_repo>.git` and the caller's existing interactive SSH or git credentials, but CI, Pages, and other non-interactive automation must not depend on SSH keys or `gh auth setup-git`.

All repository `unit/` tests must be hermetic and secret-free. They must rely only on checked-in fixtures plus temporary directories, temporary git repositories, and temporary bare remotes created during the test run, and they must pass with `GH_TOKEN` and `SAFELIBS_REPO_TOKEN` unset. They must not require `gh`, live GitHub, `/home/yans/safelibs`, or private `port-*` tags. Real sibling-clone and private-remote coverage belongs only in the smoke verifiers and the secret-gated matrix jobs.

Because scope is limited to already-published remote `04-test` tags, the plan must not introduce validator-managed snapshot tags, `validator.publication_tag`, `inventory/non-apt-ref-status.json`, or any source-ref publication step. CI, Pages, and public-repo publication only need to verify that the manifest's `04-test` tags are still remotely reachable.

The artifact flow is:

1. Capture raw GitHub inventory and the filtered tagged subset into `inventory/`.
2. Write `repositories.yml` from that tagged subset plus copied `apt-repo` build metadata.
3. Stage clean detached tag checkouts under `.work/ports/`.
4. Build or copy safe `.deb` artifacts under `artifacts/debs/<library>/`.
5. Import tracked harness inputs from staged tagged repos into validator-owned `tests/<library>/`.
6. Run the original and safe matrix and emit `artifacts/results/`, `artifacts/logs/`, and `artifacts/casts/`.
7. Render `site/`, verify that it matches the matrix outputs, create the public `safelibs/validator` repo, push `main`, and publish GitHub Pages.

## Generated Workflow Contract

- Use one linear top-level `phases:` list in order. Do not emit `parallel_groups`.
- Keep the generated workflow inline-only and self-contained. Do not use `include`, `prompt_file`, `workflow_file`, `workflow_dir`, or `checks`.
- Every verifier must be an explicit top-level `check` phase with exactly one fixed `bounce_target`.
- Every verifier must immediately follow the implement phase it verifies.
- No verifier may use `bounce_targets`.
- If a verifier needs to run tests, Docker, `gh`, git, build steps, or any other commands, write those commands directly into that verifier's instructions.
- No verifier may depend on `.work/` scratch state created by another verifier. If a review phase needs runtime artifacts, it must create its own scratch directory and regenerate the exact inputs it inspects inside that same verifier.
- All generated automation that reads private `port-*` repos must use the explicit auth contract from this plan: export `GH_TOKEN` from `SAFELIBS_REPO_TOKEN` in CI/Pages, let the tools form token-authenticated HTTPS git URLs, and do not rely on SSH keys or `gh auth setup-git`.
- Every explicit raw `gh` command in a generated verifier or workflow step must inline the auth fallback: preserve a pre-set `GH_TOKEN`, otherwise export `GH_TOKEN="$SAFELIBS_REPO_TOKEN"` when that fallback exists, and leave `GH_TOKEN` unset when neither env var is present so local interactive `gh` auth still works.
- Phase 01 is the only phase that may discover live scope from GitHub. Later phases must consume the checked-in `inventory/github-repo-list.json`, `inventory/github-port-repos.json`, and `repositories.yml` instead of rediscovering scope.
- Later phases may stage clean clones from those existing manifest refs, but they must not re-query GitHub to redefine the library set.
- Phases 01 through 05 must not edit `workflow.yaml`, `.plan/workflow-structure.yaml`, or any file under `.plan/phases/`. Those stale generated workflow artifacts remain reference inputs until phase 06, and phase 06 alone owns rewriting, renaming, deleting, and staging the final generated workflow file set.
- All planned `unit/` tests and the generated `unit-tests` CI job must stay hermetic and secret-free: use checked-in fixtures plus temporary directories/repositories only, run with `GH_TOKEN` and `SAFELIBS_REPO_TOKEN` unset, and never require `/home/yans/safelibs`, `gh`, live GitHub, or private tags. Live sibling-repo and remote-tag coverage belongs only in smoke verifiers and the secret-gated matrix jobs.
- The generated workflow must not introduce `inventory/non-apt-ref-status.json`, `validator.publication_tag`, `tools/publish_source_refs.py`, or any ref-publication/tag-push phase.
- Every implement prompt in the generated workflow, and the corresponding generated phase document, must include the exact sentence `Commit all phase work to git before yielding.`
- Each implement phase must leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.
- The generated phase-02 through phase-05 prompts must preserve implementation-blind tests: the shared runner may export `VALIDATOR_LIBRARY`, `VALIDATOR_LIBRARY_ROOT`, and `VALIDATOR_TAGGED_ROOT`, but it must not export `VALIDATOR_MODE` or any other explicit safe/original selector into `tests/<library>/tests/run.sh`.
- The generated phase-02 through phase-06 prompts must preserve the fixed aggregate matrix contract: `tools/run_matrix.py` and `test.sh` must attempt every requested library/mode run in order, keep going after individual build or test failures, emit one JSON result per attempted run, and return a non-zero exit only after the requested matrix finishes when any run failed.
- The generated phase-03 through phase-06 verifier prompts must explicitly run a shared imported-asset fidelity checker against freshly staged manifest refs. Comparing only `dependents.json`, `relevant_cves.json`, or a few spot-check paths is insufficient.
- Regenerate `.plan/workflow-structure.yaml`, `workflow.yaml`, and `.plan/phases/*.md` from this file. Here `regenerate` means overwrite the committed contents of the kept generated files so they match this plan's current contract; reusing a stale same-name file without rewriting its prompt body is a failure. The final generated artifact set must use only the phase IDs and file names defined here.
- Treat the currently checked-in `.plan/workflow-structure.yaml` and `.plan/phases/*.md`, plus any existing worktree `workflow.yaml`, as stale inputs that phase 06 must replace. Clean `HEAD` does not currently track `workflow.yaml`, so phase 06 must create a tracked `workflow.yaml` instead of assuming one already exists. The verifier reads those committed generated files, not `.plan/plan.md` alone.
- Phase 06 must update the git index to the exact final generated-file set under `.plan/phases/`, `.plan/workflow-structure.yaml`, and `workflow.yaml`. After that phase's commit, `git ls-files .plan/phases .plan/workflow-structure.yaml workflow.yaml` must resolve exactly to:
  - `.plan/workflow-structure.yaml`
  - `.plan/phases/01-inventory-scaffold.md`
  - `.plan/phases/02-shared-runner-reporting.md`
  - `.plan/phases/03-data-text-validators.md`
  - `.plan/phases/04-media-validators.md`
  - `.plan/phases/05-system-archive-validators.md`
  - `.plan/phases/06-ci-pages-publish.md`
  - `workflow.yaml`
  and no obsolete generated workflow file may remain tracked or present in the worktree under its old name.
- The regenerated workflow artifacts must mirror this file's tagged-only six-phase contract, not merely rename the old seven-phase bootstrap topology. They must explicitly carry the 19-library tagged-only scope, `inventory.tag_probe_rule: refs/tags/{library}/04-test`, `validator.imports`, `validator.import_excludes`, the mature tagged handling of `libexif` and `libuv`, the fixed `tests/<library>/tests/run.sh` runtime contract, the exact `--safe-deb-root` host layout of `<safe-deb-root>/<library>/*.deb` mounted as `/safedebs` inside each library container, and they must not reintroduce stale bootstrap-only prompt content such as `source-debian-original`, `+validatorbootstrap1`, or `validator.runtime_fixture_paths`.
- `workflow.yaml` and the six kept `.plan/phases/*.md` files must both replace the stale prompt bodies, not just the filenames and IDs. The generated phase docs and the corresponding implement prompts in `workflow.yaml` must encode these exact batch assignments:
  - phase 03: `cjson`, `libcsv`, `libjson`, `libxml`, `libyaml`
  - phase 04: `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libsdl`, `libtiff`, `libvips`, `libwebp`
  - phase 05: `libarchive`, `libbz2`, `liblzma`, `libsodium`, `libuv`, `libzstd`
- The generated workflow artifacts must not contain stage/import/test commands, harness paths, or manifest scope for the out-of-scope untagged libraries `glib`, `libc6`, `libcurl`, `libgcrypt`, or `libjansson`.
- Use this exact generated phase document set:
  - `.plan/phases/01-inventory-scaffold.md`
  - `.plan/phases/02-shared-runner-reporting.md`
  - `.plan/phases/03-data-text-validators.md`
  - `.plan/phases/04-media-validators.md`
  - `.plan/phases/05-system-archive-validators.md`
  - `.plan/phases/06-ci-pages-publish.md`
- Delete these obsolete generated phase documents from the final repository:
  - `.plan/phases/02-shared-matrix-reporting.md`
  - `.plan/phases/03-text-data-validators.md`
  - `.plan/phases/05-archive-system-validators.md`
  - `.plan/phases/06-bootstrap-missing-validators.md`
  - `.plan/phases/07-ci-pages-publish.md`
- Use this exact final topology and phase IDs:
  - `impl_01_inventory_scaffold`
  - `check_01_inventory_scaffold_smoke`
  - `check_01_inventory_scaffold_review`
  - `impl_02_shared_runner_reporting`
  - `check_02_shared_runner_smoke`
  - `check_02_shared_runner_review`
  - `impl_03_data_text_validators`
  - `check_03_data_text_matrix`
  - `check_03_data_text_review`
  - `impl_04_media_validators`
  - `check_04_media_matrix`
  - `check_04_media_review`
  - `impl_05_system_archive_validators`
  - `check_05_system_archive_matrix`
  - `check_05_system_archive_review`
  - `impl_06_ci_pages_publish`
  - `check_06_full_matrix`
  - `check_06_release_review`

## Implementation Phases

### 1. Inventory Scaffold

**Phase Name**

`inventory-scaffold`

**Implement Phase ID**

`impl_01_inventory_scaffold`

**Verification Phases**

- `check_01_inventory_scaffold_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: prove hermetic phase-01 unit coverage, dynamic `04-test` scope selection, clean local and remote staging at manifest tags, tag-fetch-into-clone behavior, non-mutating build-mode coverage, and tag-rooted asset imports before any validator harnesses exist.
  - commands it should run:
    - `rm -rf .work/check01`
    - `mkdir -p .work/check01`
    - `env -u GH_TOKEN -u SAFELIBS_REPO_TOKEN python3 -m unittest unit.test_inventory unit.test_stage_port_repos unit.test_build_safe_debs unit.test_import_port_assets unit.test_verify_imported_assets -v`
    - |
      if [ -n "${GH_TOKEN:-}" ]; then
        export GH_TOKEN
      elif [ -n "${SAFELIBS_REPO_TOKEN:-}" ]; then
        export GH_TOKEN="$SAFELIBS_REPO_TOKEN"
      else
        unset GH_TOKEN || true
      fi
      gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef > .work/check01/github-repo-list.json
    - `python3 tools/inventory.py --github-json .work/check01/github-repo-list.json --apt-config /home/yans/safelibs/apt-repo/repositories.yml --write-filtered .work/check01/github-port-repos.json --write-config .work/check01/repositories.yml --verify-scope`
    - `python3 tools/inventory.py --config .work/check01/repositories.yml --check-remote-tags`
    - `python3 tools/stage_port_repos.py --config .work/check01/repositories.yml --source-root /home/yans/safelibs --workspace .work/check01 --dest-root .work/check01/ports --libraries giflib libpng libjson libvips libexif libuv libarchive liblzma libsdl libzstd`
    - `python3 tools/stage_port_repos.py --config .work/check01/repositories.yml --workspace .work/check01 --dest-root .work/check01/ports-gh --libraries giflib libuv`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library giflib --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/giflib`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library libpng --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libpng`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library libjson --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libjson`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library libvips --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libvips`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library libexif --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libexif`
    - `python3 tools/build_safe_debs.py --config .work/check01/repositories.yml --library libuv --port-root .work/check01/ports --workspace .work/check01 --output .work/check01/debs/libuv`
    - `for lib in giflib libpng libjson libvips libexif libuv; do test -z "$(git -C .work/check01/ports/$lib status --porcelain)"; done`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libarchive --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library liblzma --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libsdl --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libzstd --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libvips --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libexif --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/import_port_assets.py --config .work/check01/repositories.yml --library libuv --port-root .work/check01/ports --workspace .work/check01 --dest-root .work/check01/imported`
    - `python3 tools/verify_imported_assets.py --config .work/check01/repositories.yml --port-root .work/check01/ports --tests-root .work/check01/imported/tests --libraries libarchive liblzma libsdl libzstd libvips libexif libuv`
    - `test -f .work/check01/ports/libuv/safe/debian/control`
    - `test -f .work/check01/ports-gh/libuv/safe/debian/control`
    - `ls .work/check01/debs/giflib/*.deb >/dev/null`
    - `ls .work/check01/debs/libpng/*.deb >/dev/null`
    - `ls .work/check01/debs/libjson/*.deb >/dev/null`
    - `ls .work/check01/debs/libvips/*.deb >/dev/null`
    - `ls .work/check01/debs/libexif/*.deb >/dev/null`
    - `ls .work/check01/debs/libuv/*.deb >/dev/null`
    - `test -f .work/check01/imported/tests/libarchive/tests/tagged-port/safe/generated/link_compat_manifest.json`
    - `test -f .work/check01/imported/tests/libarchive/tests/tagged-port/original/libarchive-3.7.2/libarchive/test/test_acl_nfs4.c`
    - `test -f .work/check01/imported/tests/liblzma/tests/tagged-port/safe/tests/dependents/boost_iostreams_smoke.cpp`
    - `test -f .work/check01/imported/tests/liblzma/tests/tagged-port/safe/tests/upstream/bcj_test.c`
    - `test ! -e .work/check01/imported/tests/liblzma/tests/tagged-port/safe/tests/generated`
    - `test -f .work/check01/imported/tests/libsdl/tests/tagged-port/safe/upstream-tests/installed-tests/debian/tests/installed-tests`
    - `test -f .work/check01/imported/tests/libzstd/tests/tagged-port/safe/scripts/run-full-suite.sh`
    - `test -f .work/check01/imported/tests/libzstd/tests/tagged-port/original/libzstd-1.5.5+dfsg2/tests/Makefile`
    - `find .work/check01/imported/tests/libvips/tests/tagged-port/safe/vendor -type f | grep -q .`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/include/uv.h`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/test/run-tests.c`
    - `cmp -s .work/check01/imported/tests/libexif/tests/fixtures/relevant_cves.json .work/check01/ports/libexif/relevant_cves.json`
    - `cmp -s .work/check01/imported/tests/libuv/tests/fixtures/dependents.json .work/check01/ports/libuv/dependents.json`
- `check_01_inventory_scaffold_review`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: review the checked-in 19-library tagged snapshot and scope-selection contract, exact filtered inventory row schema and ordering, fixed `inventory.tag_probe_rule`, preserved `archive` metadata, copied `apt-repo` build metadata, uniform per-library fixture-copy mappings, exact per-library import lists, all-empty `validator.import_excludes`, and the absence of the obsolete publication-tag model without re-probing live tags.
  - commands it should run:
    - `git diff --check HEAD^ HEAD`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json
      import yaml

      raw = json.loads(Path("inventory/github-repo-list.json").read_text())
      filtered = json.loads(Path("inventory/github-port-repos.json").read_text())
      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      apt_manifest = yaml.safe_load(Path("/home/yans/safelibs/apt-repo/repositories.yml").read_text())
      if manifest.get("archive") != apt_manifest.get("archive"):
          raise SystemExit("archive mapping mismatch")
      inventory = manifest.get("inventory")
      if not isinstance(inventory, dict):
          raise SystemExit("inventory mapping missing")
      required_inventory = {
          "gh_repo_list_command": "gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef",
          "tag_probe_rule": "refs/tags/{library}/04-test",
          "raw_snapshot": "inventory/github-repo-list.json",
          "filtered_snapshot": "inventory/github-port-repos.json",
          "goal_repo_family": "repos-*",
          "verified_repo_family": "port-*",
      }
      for key, expected in required_inventory.items():
          if inventory.get(key) != expected:
              raise SystemExit(f"inventory {key} mismatch: {inventory.get(key)!r}")
      if not inventory.get("verified_at"):
          raise SystemExit("inventory verified_at missing")
      tag_probe_rule = inventory["tag_probe_rule"]
      if "{library}" not in tag_probe_rule:
          raise SystemExit(f"tag_probe_rule must contain {{library}}: {tag_probe_rule!r}")

      expected_names = [
          "cjson",
          "giflib",
          "libarchive",
          "libbz2",
          "libcsv",
          "libexif",
          "libjpeg-turbo",
          "libjson",
          "liblzma",
          "libpng",
          "libsdl",
          "libsodium",
          "libtiff",
          "libuv",
          "libvips",
          "libwebp",
          "libxml",
          "libyaml",
          "libzstd",
      ]
      raw_port_lookup = {}
      raw_repos_family = []
      for repo in raw:
          name = repo["name"]
          if name.startswith("repos-"):
              raw_repos_family.append(name)
          if not name.startswith("port-"):
              continue
          library = name.removeprefix("port-")
          raw_port_lookup[library] = {
              "nameWithOwner": repo["nameWithOwner"],
              "url": repo["url"],
              "default_branch": (repo.get("defaultBranchRef") or {}).get("name"),
          }
      if raw_repos_family:
          raise SystemExit(f"raw snapshot must not contain repos-* repositories: {raw_repos_family}")
      filtered_names = [row["library"] for row in filtered]
      manifest_names = [entry["name"] for entry in manifest["repositories"]]
      if filtered_names != sorted(filtered_names):
          raise SystemExit(f"filtered inventory must be sorted by library: {filtered_names}")
      if filtered_names != expected_names:
          raise SystemExit(f"filtered scope mismatch: {filtered_names}")
      if manifest_names != sorted(manifest_names):
          raise SystemExit(f"manifest repositories must be sorted by library: {manifest_names}")
      if manifest_names != expected_names:
          raise SystemExit(f"manifest scope mismatch: {manifest_names}")

      required_filtered_keys = {"library", "nameWithOwner", "url", "default_branch", "tag_ref"}
      for row in filtered:
          if set(row) != required_filtered_keys:
              raise SystemExit(f"{row.get('library', '<unknown>')} filtered row schema mismatch: {sorted(row)}")
          expected_repo = raw_port_lookup.get(row["library"])
          if expected_repo is None:
              raise SystemExit(f"{row['library']} missing from raw port inventory")
          for key in ["nameWithOwner", "url", "default_branch"]:
              if row[key] != expected_repo[key]:
                  raise SystemExit(f"{row['library']} {key} mismatch: {row[key]!r}")
          expected_tag = tag_probe_rule.format(library=row["library"])
          if row["tag_ref"] != expected_tag:
              raise SystemExit(f"{row['library']} tag_ref mismatch: {row['tag_ref']}")

      apt_entries = {entry["name"]: entry for entry in apt_manifest["repositories"]}
      non_apt_expected = {"libexif", "libuv"}
      for entry in manifest["repositories"]:
          name = entry["name"]
          expected_tag = tag_probe_rule.format(library=name)
          if entry["ref"] != expected_tag:
              raise SystemExit(f"{name} ref mismatch: {entry['ref']}")
          if entry["validator"]["sibling_repo"] != f"port-{name}":
              raise SystemExit(f"{name} sibling_repo mismatch")
          if "import_roots" in entry["validator"]:
              raise SystemExit(f"{name} must not define validator.import_roots")
          imports = entry["validator"].get("imports")
          if not isinstance(imports, list) or not imports:
              raise SystemExit(f"{name} validator.imports missing")
          if any(not isinstance(path, str) or not path or path.startswith("/") for path in imports):
              raise SystemExit(f"{name} validator.imports must be non-empty repo-relative strings")
          import_excludes = entry["validator"].get("import_excludes")
          if import_excludes != []:
              raise SystemExit(f"{name} validator.import_excludes must be [] in this scoped plan: {import_excludes!r}")
          fixtures = entry.get("fixtures")
          if not isinstance(fixtures, dict):
              raise SystemExit(f"{name} fixtures mapping missing")
          if fixtures["dependents"]["source"] != "copy-staged-root":
              raise SystemExit(f"{name} dependents source mismatch")
          if fixtures["relevant_cves"]["source"] != "copy-staged-root":
              raise SystemExit(f"{name} relevant_cves source mismatch")
          if "publication_tag" in entry["validator"]:
              raise SystemExit(f"{name} unexpectedly defines publication_tag")
          if name in apt_entries:
              for key in ["github_repo", "build", "verify_packages"]:
                  if entry.get(key) != apt_entries[name].get(key):
                      raise SystemExit(f"{name} {key} mismatch")
          elif name in non_apt_expected:
              build = entry["build"]
              if build != {"mode": "safe-debian", "artifact_globs": ["*.deb"]}:
                  raise SystemExit(f"{name} build mismatch: {build}")
          else:
              raise SystemExit(f"unexpected non-apt entry: {name}")

      must_include = {
          "libarchive": {"original/libarchive-3.7.2", "safe/generated", "safe/tests"},
          "liblzma": {"safe/docker", "safe/scripts", "safe/tests/dependents", "safe/tests/extra", "safe/tests/upstream"},
          "libsdl": {"safe/upstream-tests", "safe/generated", "safe/tests"},
          "libuv": {"safe/include", "safe/test", "safe/scripts"},
          "libvips": {"safe/vendor", "safe/tests"},
          "libzstd": {"original/libzstd-1.5.5+dfsg2", "safe/scripts", "safe/tests"},
      }
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      for name, expected_paths in must_include.items():
          imports = set(by_name[name]["validator"]["imports"])
          missing = expected_paths - imports
          if missing:
              raise SystemExit(f"{name} missing import paths: {sorted(missing)}")
      if "safe/tests" in by_name["liblzma"]["validator"]["imports"]:
          raise SystemExit("liblzma must split safe/tests into exact subpaths instead of importing safe/tests as a whole")

      if Path("inventory/non-apt-ref-status.json").exists():
          raise SystemExit("inventory/non-apt-ref-status.json must not exist")
      if "glib" in manifest_names or "libc6" in manifest_names or "libcurl" in manifest_names or "libgcrypt" in manifest_names or "libjansson" in manifest_names:
          raise SystemExit("out-of-scope untagged libraries leaked into the manifest")
      PY

**Preexisting Inputs**

- `README.md`
- current planning artifacts under `.plan/`
- stale generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, for reference only
- `/home/yans/safelibs/apt-repo/repositories.yml`
- `/home/yans/safelibs/apt-repo/tools/build_site.py`
- `/home/yans/safelibs/apt-repo/tests/test_build_site.py`
- every sibling `port-*` repo under `/home/yans/safelibs/`, for live inventory generation, staging smoke coverage, and manual local runs only
- authenticated GitHub access for the private `port-*` repos, provided either by existing local `gh` or git credentials or by an effective token resolved from `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`, for live inventory generation and smoke verification only

**New Outputs**

- `.gitignore`
- `Makefile`
- `inventory/github-repo-list.json`
- `inventory/github-port-repos.json`
- `repositories.yml`
- `tools/__init__.py`
- `tools/github_auth.py`
- `tools/inventory.py`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `tools/import_port_assets.py`
- `tools/verify_imported_assets.py`
- `unit/__init__.py`
- `unit/test_inventory.py`
- `unit/test_stage_port_repos.py`
- `unit/test_build_safe_debs.py`
- `unit/test_import_port_assets.py`
- `unit/test_verify_imported_assets.py`

**Implementation Details**

- Phase 01 is the only phase allowed to query live GitHub state to define scope.
- Create `inventory/github-repo-list.json` as the checked-in raw output of `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef`.
- Create `inventory/github-port-repos.json` as the checked-in filtered subset of only those `port-*` repos whose remote exposes `refs/tags/<library>/04-test`. The file itself must be sorted by `library`, and each row must be exactly these fields copied from the raw snapshot plus the derived tag: `library`, `nameWithOwner`, `url`, `default_branch`, and `tag_ref`.
- Create `repositories.yml` as validator's canonical manifest by extending the `apt-repo` schema instead of replacing it. Preserve the top-level `archive` mapping from `/home/yans/safelibs/apt-repo/repositories.yml`, then add:
  - an `inventory` mapping with `verified_at`, `gh_repo_list_command`, `tag_probe_rule`, `raw_snapshot`, `filtered_snapshot`, `goal_repo_family`, and `verified_repo_family`
  - `inventory.tag_probe_rule` must be the exact literal `refs/tags/{library}/04-test`. `tools/inventory.py` and later verifiers must derive each expected remote tag by formatting that template with the manifest library name instead of hard-coding a second rule elsewhere.
  - a `repositories` list in sorted library order from `inventory/github-port-repos.json`
- For the 17 selected libraries already present in `apt-repo`, copy `github_repo`, optional `verify_packages`, and the full `build` mapping verbatim from `/home/yans/safelibs/apt-repo/repositories.yml`, set `ref` to `refs/tags/<library>/04-test`, and add the common validator and fixture mappings required below.
- Add validator-owned entries only for `libexif` and `libuv`. Both must use:
  - `github_repo: safelibs/port-<library>`
  - `ref: refs/tags/<library>/04-test`
  - `build: {mode: safe-debian, artifact_globs: ["*.deb"]}`
  - `validator.sibling_repo: port-<library>`
  - `validator.imports`
  - `validator.import_excludes`
  - `fixtures.dependents.source: copy-staged-root`
  - `fixtures.relevant_cves.source: copy-staged-root`
- Add `validator.sibling_repo`, `validator.imports`, `validator.import_excludes`, `fixtures.dependents.source: copy-staged-root`, and `fixtures.relevant_cves.source: copy-staged-root` to every manifest entry, not just the validator-owned non-`apt-repo` entries, so later phases can stage, import, and verify fixtures without inventing per-library rules.
- `validator.imports` must be an explicit per-library list of exact repo-relative tracked paths from `refs/tags/<library>/04-test`. Do not use a coarse allowlist such as `validator.import_roots`. If a library needs versioned tarball roots or uncommon safe-side paths, record the exact path that exists in the tag, such as `original/libarchive-3.7.2`, `original/libzstd-1.5.5+dfsg2`, `safe/upstream-tests`, `safe/include`, or `safe/test-extra`.
- `validator.import_excludes` is an additional per-library repo-relative denylist that applies only after `validator.imports` expands a declared directory import. It must not duplicate the fixed global ignore set. In this scoped 19-library plan every manifest entry must set `validator.import_excludes: []`.
- When a library needs only part of a tracked directory, express the kept descendants directly in `validator.imports` instead of importing the parent and excluding children. The concrete required case is `liblzma`: its manifest entry must list `safe/docker`, `safe/scripts`, `safe/tests/dependents`, `safe/tests/extra`, and `safe/tests/upstream`, and it must not import `safe/tests` or rely on `validator.import_excludes` to drop `safe/tests/generated`.
- `tools/github_auth.py` must centralize private GitHub access for the validator tools. It must:
  - resolve an effective token by preferring `GH_TOKEN` and falling back to `SAFELIBS_REPO_TOKEN`
  - export a public helper named `github_git_url` that turns a manifest `github_repo` such as `safelibs/port-libuv` into a git URL, using `https://x-access-token:<token>@github.com/<github_repo>.git` when a token exists and `git@github.com:<github_repo>.git` only for local interactive fallback. The helper name is fixed because validator-side git access must route through one shared manifest-derived URL helper.
  - ensure git subprocesses run with `GIT_TERMINAL_PROMPT=0` so missing credentials fail fast instead of hanging for input
- `tools/inventory.py` must provide manifest loading, GitHub inventory loading, tagged-scope selection, `apt-repo` metadata merge, and a remote-tag reachability check that later CI phases can reuse. The minimum CLI modes are:
  - generate mode: `--github-json <path> --apt-config <path> --write-filtered <path> --write-config <path> [--verify-scope]`
  - remote-tag check mode: `--config <path> --check-remote-tags`
- `--verify-scope` is a generate-mode self-check, not a no-op logging flag. It is valid only when `--github-json`, `--apt-config`, `--write-filtered`, and `--write-config` are all present, and it must fail the generate command if any assertion below is false.
- When `--verify-scope` is set, `tools/inventory.py` must immediately recompute the expected tagged scope from the supplied raw GitHub snapshot by probing every `port-*` repo row with `inventory.tag_probe_rule`, then compare the freshly written `--write-filtered` and `--write-config` outputs against that derived scope. The required checks are:
  - the selected library set is exactly the `port-*` repos whose remote exposes `refs/tags/<library>/04-test`
  - the filtered JSON is sorted by `library` and every row contains exactly `library`, `nameWithOwner`, `url`, `default_branch`, and `tag_ref`
  - the written `inventory` mapping contains `gh_repo_list_command`, `raw_snapshot`, `filtered_snapshot`, `goal_repo_family: repos-*`, `verified_repo_family: port-*`, `tag_probe_rule: refs/tags/{library}/04-test`, and a non-empty `verified_at`
  - the manifest repository list is sorted by library name and every entry uses `ref: inventory.tag_probe_rule.format(library=<entry name>)`
- `check_01_inventory_scaffold_smoke` owns the live GitHub re-probe of `04-test` tags. `check_01_inventory_scaffold_review` must stay deterministic by validating only the committed `inventory/github-repo-list.json`, `inventory/github-port-repos.json`, and `repositories.yml` against this plan's current 19-library tagged scope and the copied `apt-repo` metadata; it must not rediscover scope from the network a second time.
- `tools/inventory.py --check-remote-tags` must require `--config`, iterate every manifest entry in manifest order, derive each expected ref from `inventory.tag_probe_rule`, probe the matching private repo with `tools/github_auth.py`, and exit non-zero if any manifest tag is unreachable.
- All phase-01 `unit/` tests must remain hermetic and secret-free. They must use only checked-in fixture files plus temporary directories, temporary git repositories, temporary bare remotes, and mocks created inside the test process. They must not shell out to `gh`, read `/home/yans/safelibs`, contact live GitHub, or require `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`. The live sibling-repo and private-remote coverage in this phase belongs only in `check_01_inventory_scaffold_smoke`.
- `tools/stage_port_repos.py` must stage clean detached clones under `.work/`, and its CLI must be `--config <path> --workspace <path> --dest-root <path> [--source-root <path>] [--libraries <library> ...]`.
  - `--dest-root` is always a root directory, and the tool must stage each selected checkout at `<dest-root>/<library>/`
  - when `--libraries` is omitted, the tool must stage every manifest library in manifest order
  - any remote clone or fetch needed for private `port-*` access must use `tools/github_auth.py` rather than anonymous HTTPS, SSH assumptions, or inherited local-path remotes
  - with `--source-root /home/yans/safelibs`, clone from the sibling repo without touching the live worktree
  - when the stage source is a sibling clone, do not rely on the detached clone's inherited local-path `origin` for missing-tag fetches; derive a GitHub fetch source from `github_repo` and use that remote URL instead
  - if the detached clone does not already contain the manifest tag, fetch only that exact tag from the manifest's GitHub repository into the clone before checkout
  - without `--source-root`, clone from the manifest's GitHub repository and check out the manifest tag
  - fail deterministically if the manifest tag cannot be checked out
  - `unit/test_stage_port_repos.py` must model both a `libexif`-shaped sibling clone that already has the tag locally and a `libuv`-shaped sibling clone that does not, but it must do so with temporary fixture repos and a temporary bare remote created inside the test rather than `/home/yans/safelibs` or live GitHub. The `libuv`-shaped case must prove the tool fetches from the manifest-derived remote URL rather than the inherited local-path `origin`.
- `tools/build_safe_debs.py` must adapt the `apt-repo` build dispatcher from `/home/yans/safelibs/apt-repo/tools/build_site.py` without destructive repo resets. Its CLI is fixed as `--config <path> --library <name> --port-root <path> --workspace <path> --output <path>`. It must support:
  - `safe-debian`
  - `checkout-artifacts`
  - explicit `docker`
  - omitted `build.mode`, which must behave like `docker`
- `--port-root` is a root directory that already contains the staged tag checkout at `<port-root>/<library>/`.
- `--workspace` is a scratch root for build-only temporary directories and logs. The tool must create its per-library scratch underneath `--workspace` instead of writing into the staged checkout.
- `--output` is the library-specific artifact directory. The tool must recreate it on each run and leave the resulting `.deb` files directly under that path.
- Before any build `setup` or build command runs, copy `<port-root>/<library>/` into a per-library scratch source tree under `--workspace`. All build commands, setup hooks, and artifact collection must operate on that scratch copy so `<port-root>/<library>/` remains a pristine staged tag checkout for later fidelity verification.
- For `checkout-artifacts`, copy files matching `artifact_globs` from the configured build workdir in the scratch copy into `--output` without running Docker.
- For `safe-debian`, default the build workdir to `safe/`, honor manifest `packages`, `setup`, and optional `rustup_toolchain`, run the equivalent of the borrowed `safe-debian` build script, and collect the declared `artifact_globs` into `--output`.
- For explicit `docker` mode and omitted `build.mode`, default the build workdir to `.`, require a non-empty manifest `build.command`, run that command in the borrowed containerized build environment, and collect the declared `artifact_globs` into `--output`.
- Fail if the selected library is absent from the manifest, the staged checkout is missing, the configured workdir is missing, the build mode is unsupported, or no declared artifacts are produced.
- Preserve the borrowed environment contract used by existing build scripts:
  - `SAFEAPTREPO_SOURCE`
  - `SAFEAPTREPO_OUTPUT`
  - `SAFEDEBREPO_SOURCE`
  - `SAFEDEBREPO_OUTPUT`
- `tools/import_port_assets.py` must copy only declared tracked inputs from the staged tag checkout, and its CLI must be `--config <path> --library <name> --port-root <path> --workspace <path> [--dest-root <path>]`.
  - `--dest-root` defaults to the repository root `.`
  - regardless of which root is supplied, the tool must write the library import under `<dest-root>/tests/<library>/...`, which is why phase-01 smoke can target `.work/check01/imported`
  - copy `dependents.json` and `relevant_cves.json` into `tests/<library>/tests/fixtures/`
  - copy `test-original.sh` into `tests/<library>/tests/harness-source/original-test-script.sh`
  - copy `safe/debian/control` into `tests/<library>/tests/harness-source/debian/control`
  - mirror every manifest-declared `validator.imports` path under `tests/<library>/tests/tagged-port/<source>` while preserving the original `safe/` or `original/` path prefix
  - apply the fixed global ignore set to every copied tree, then apply `validator.import_excludes` as additional repo-relative subtree exclusions; because the scoped manifest keeps every `validator.import_excludes` empty, no current library may depend on per-entry pruning for correctness
  - preserve imported files byte-for-byte; validator-owned wrapper scripts must adapt to them instead of rewriting them
- `tools/verify_imported_assets.py` must be the shared fidelity checker reused by phases 01 and 03 through 06. Its CLI must be `--config <path> --port-root <path> [--tests-root <path>] [--libraries <library> ...]`.
  - `--tests-root` defaults to `tests`
  - when `--libraries` is omitted, verify every manifest library in manifest order
  - for each selected library, compare these validator-side imports against the staged checkout byte-for-byte:
    - `tests/<library>/tests/fixtures/dependents.json` versus `<port-root>/<library>/dependents.json`
    - `tests/<library>/tests/fixtures/relevant_cves.json` versus `<port-root>/<library>/relevant_cves.json`
    - `tests/<library>/tests/harness-source/original-test-script.sh` versus `<port-root>/<library>/test-original.sh`
    - `tests/<library>/tests/harness-source/debian/control` versus `<port-root>/<library>/safe/debian/control`
    - every manifest-declared `validator.imports` path mirrored under `tests/<library>/tests/tagged-port/`
  - expand directory imports with the same fixed global ignore set and `validator.import_excludes` behavior as `tools/import_port_assets.py`, so the verifier checks the exact mirrored tree rather than a hand-maintained spot-check list
  - fail on missing files, content drift, or extra mirrored files under `tests/<library>/tests/tagged-port/` that are outside the manifest-declared imported tree
- `unit/test_build_safe_debs.py` must cover `safe-debian`, `checkout-artifacts`, explicit `docker`, omitted-mode default-to-`docker`, and the requirement that the staged checkout under `--port-root/<library>/` remains clean after a build completes.
- `unit/test_verify_imported_assets.py` must cover file imports, directory imports, extra-file detection under `tests/tagged-port`, and harness-source or fixture drift.
- Use global import exclusions for `.git/`, `.pc/`, `__pycache__/`, `node_modules/`, `.libs/`, `build/`, `build-*`, `.checker-build*`, `config.log`, `config.status`, `*.deb`, `*.ddeb`, and `*.udeb`. Keep this list tool-owned; do not copy it into `validator.import_excludes`.
- Create `Makefile` targets for at least `unit`, `inventory`, `stage-ports`, `build-safe`, `import-assets`, and `clean`.

**Verification**

- Run both `check_01_inventory_scaffold_smoke` and `check_01_inventory_scaffold_review`.
- Treat any stale hard-coded library list, wrong `inventory.tag_probe_rule`, wrong `04-test` ref, any no-op or partial `--verify-scope` implementation that does not compare the generated filtered scope and manifest against the raw-snapshot-derived tagged subset, any phase-01 review that redefines scope from fresh live tag probes instead of validating the committed snapshot, wrong copied `archive` or `apt-repo` metadata, missing per-entry `fixtures.dependents.source` or `fixtures.relevant_cves.source`, wrong filtered inventory row schema or ordering, non-empty `validator.import_excludes`, any phase-01 `unit/` test that depends on `/home/yans/safelibs`, live GitHub, `gh`, or auth tokens, missing exact-tag fetch from the manifest GitHub remote when a sibling clone lacks the tag locally, any `tools/build_safe_debs.py` run that mutates the staged checkout under `--port-root`, missing exact per-library import paths, missing reusable imported-asset fidelity verifier, imported scratch directory, or reintroduced publication-tag contract as failure.

### 2. Shared Runner / Reporting

**Phase Name**

`shared-runner-reporting`

**Implement Phase ID**

`impl_02_shared_runner_reporting`

**Verification Phases**

- `check_02_shared_runner_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_runner_reporting`
  - purpose: prove the shared matrix runner, aggregate failure contract, result schema, safe-mode trace capture, and static-site renderer work before real library harnesses are added.
  - commands it should run:
    - `rm -rf .work/check02`
    - `mkdir -p .work/check02`
    - `python3 -m unittest unit.test_run_matrix unit.test_render_site -v`
    - `test -d unit/fixtures/demo-debs/demo`
    - `ls unit/fixtures/demo-debs/demo/*.deb >/dev/null`
    - `python3 tools/run_matrix.py --config unit/fixtures/demo-manifest.yml --tests-root unit/fixtures/demo-tests --artifact-root .work/check02/artifacts --safe-deb-root unit/fixtures/demo-debs --mode both --record-casts`
    - |
      set +e
      python3 tools/run_matrix.py --config unit/fixtures/demo-failure-manifest.yml --tests-root unit/fixtures/demo-failure-tests --artifact-root .work/check02/failure-artifacts --safe-deb-root unit/fixtures/demo-failure-debs --mode both --record-casts
      matrix_exit_code=$?
      set -e
      test "$matrix_exit_code" -ne 0
    - `python3 tools/render_site.py --results-root .work/check02/artifacts/results --artifacts-root .work/check02/artifacts --output-root .work/check02/site`
    - `bash scripts/verify-site.sh --config unit/fixtures/demo-manifest.yml --results-root .work/check02/artifacts/results --site-root .work/check02/site`
    - `bash test.sh --config repositories.yml --list-libraries > .work/check02/libraries.txt`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      expected = [entry["name"] for entry in yaml.safe_load(Path("repositories.yml").read_text())["repositories"]]
      actual = Path(".work/check02/libraries.txt").read_text().splitlines()
      if actual != expected:
          raise SystemExit(f"library listing mismatch: {actual}")
      PY
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      failure_root = Path(".work/check02/failure-artifacts/results")
      fail_original = json.loads((failure_root / "demo-fail" / "original.json").read_text())
      pass_original = json.loads((failure_root / "demo-pass" / "original.json").read_text())
      fail_safe = json.loads((failure_root / "demo-fail" / "safe.json").read_text())
      pass_safe = json.loads((failure_root / "demo-pass" / "safe.json").read_text())
      if fail_original["status"] == "passed":
          raise SystemExit("demo-fail original run must fail in the aggregate-failure fixture")
      if fail_safe["status"] == "passed":
          raise SystemExit("demo-fail safe run must fail in the aggregate-failure fixture")
      if pass_original["status"] != "passed" or pass_safe["status"] != "passed":
          raise SystemExit("demo-pass runs must still execute and pass after demo-fail fails")
      PY
    - `find .work/check02/artifacts/casts -name 'safe.cast' | grep -q .`
    - `find .work/check02/failure-artifacts/casts -name 'safe.cast' | grep -q .`
    - `test -f .work/check02/site/index.html`
- `check_02_shared_runner_review`
  - type: `check`
  - fixed `bounce_target`: `impl_02_shared_runner_reporting`
  - purpose: review the shared runner CLI, the exact `--safe-deb-root` directory contract, the result schema, the shared entrypoint contract, the aggregate-failure behavior, and the site-verification invariants using fresh demo runs created inside this verifier.
  - commands it should run:
    - `rm -rf .work/check02-review`
    - `mkdir -p .work/check02-review`
    - `git diff --check HEAD^ HEAD`
    - `test -f test.sh && test -f tools/run_matrix.py && test -f tools/render_site.py && test -f scripts/verify-site.sh`
    - `test -f tests/_shared/install_safe_debs.sh && test -f tests/_shared/run_library_tests.sh`
    - `python3 tools/run_matrix.py --config unit/fixtures/demo-manifest.yml --tests-root unit/fixtures/demo-tests --artifact-root .work/check02-review/artifacts --safe-deb-root unit/fixtures/demo-debs --mode both --record-casts`
    - `python3 tools/render_site.py --results-root .work/check02-review/artifacts/results --artifacts-root .work/check02-review/artifacts --output-root .work/check02-review/site`
    - `bash scripts/verify-site.sh --config unit/fixtures/demo-manifest.yml --results-root .work/check02-review/artifacts/results --site-root .work/check02-review/site`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      safe_results = list(Path(".work/check02-review/artifacts/results").glob("*/safe.json"))
      if len(safe_results) != 1:
          raise SystemExit(f"expected exactly one demo safe result, found {safe_results}")
      safe_result = json.loads(safe_results[0].read_text())
      required = {
          "library",
          "mode",
          "status",
          "started_at",
          "finished_at",
          "duration_seconds",
          "log_path",
          "cast_path",
      }
      if set(safe_result) < required:
          raise SystemExit(f"result schema mismatch: {set(safe_result)}")

      run_matrix = Path("tools/run_matrix.py").read_text()
      if "bash -x" not in run_matrix:
          raise SystemExit("safe-mode bash -x trace missing")

      demo_deb_root = Path("unit/fixtures/demo-debs")
      demo_deb_dirs = sorted(path.name for path in demo_deb_root.iterdir() if path.is_dir())
      if demo_deb_dirs != ["demo"]:
          raise SystemExit(f"demo safe-deb root must use per-library subdirectories, found {demo_deb_dirs}")
      if not list((demo_deb_root / "demo").glob("*.deb")):
          raise SystemExit("demo safe-deb root must contain .deb files under unit/fixtures/demo-debs/demo/")

      install_script = Path("tests/_shared/install_safe_debs.sh").read_text()
      if "/safedebs" not in install_script:
          raise SystemExit("safe-deb installer must target /safedebs")

      shared_runner = Path("tests/_shared/run_library_tests.sh").read_text()
      if "set -euo pipefail" not in shared_runner:
          raise SystemExit("shared test runner must be strict-shell")
      if 'tests/$library/tests/run.sh' not in shared_runner and 'tests/${library}/tests/run.sh' not in shared_runner:
          raise SystemExit("shared runner must dispatch to tests/<library>/tests/run.sh")
      for required_name in ["VALIDATOR_LIBRARY", "VALIDATOR_LIBRARY_ROOT", "VALIDATOR_TAGGED_ROOT"]:
          if required_name not in shared_runner:
              raise SystemExit(f"shared runner missing {required_name}")
      if "VALIDATOR_MODE" in shared_runner:
          raise SystemExit("shared runner must not expose VALIDATOR_MODE to library tests")
      PY
    - |
      set +e
      python3 tools/run_matrix.py --config unit/fixtures/demo-failure-manifest.yml --tests-root unit/fixtures/demo-failure-tests --artifact-root .work/check02-review/failure-artifacts --safe-deb-root unit/fixtures/demo-failure-debs --mode both --record-casts
      matrix_exit_code=$?
      set -e
      test "$matrix_exit_code" -ne 0
    - |
      python3 - <<'PY'
      from pathlib import Path
      import json

      failure_root = Path(".work/check02-review/failure-artifacts/results")
      expected = {
          ("demo-fail", "original"),
          ("demo-fail", "safe"),
          ("demo-pass", "original"),
          ("demo-pass", "safe"),
      }
      actual = {(path.parent.name, path.stem) for path in failure_root.glob("*/*.json")}
      if actual != expected:
          raise SystemExit(f"aggregate-failure fixture results mismatch: {sorted(actual)}")
      for library, mode in expected:
          payload = json.loads((failure_root / library / f"{mode}.json").read_text())
          if payload["library"] != library or payload["mode"] != mode:
              raise SystemExit(f"wrong identity in {library}/{mode}: {payload}")
      if json.loads((failure_root / "demo-fail" / "original.json").read_text())["status"] == "passed":
          raise SystemExit("demo-fail original run must fail")
      if json.loads((failure_root / "demo-pass" / "safe.json").read_text())["status"] != "passed":
          raise SystemExit("demo-pass safe run must complete successfully despite earlier failure")
      PY
    - `find .work/check02-review/artifacts/casts -name 'safe.cast' | grep -q .`
    - `find .work/check02-review/failure-artifacts/casts -name 'safe.cast' | grep -q .`
    - `test -f .work/check02-review/site/index.html`

**Preexisting Inputs**

- all outputs from phase 01
- `README.md`
- `/home/yans/safelibs/website/package.json`
- `/home/yans/safelibs/website/scripts/build.mjs`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`

**New Outputs**

- `test.sh`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `scripts/verify-site.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/run_library_tests.sh`
- `unit/test_run_matrix.py`
- `unit/test_render_site.py`
- `unit/fixtures/demo-manifest.yml`
- `unit/fixtures/demo-debs/demo/*.deb`
- `unit/fixtures/demo-tests/**`
- `unit/fixtures/demo-failure-manifest.yml`
- `unit/fixtures/demo-failure-debs/demo-pass/*.deb`
- `unit/fixtures/demo-failure-debs/demo-fail/*.deb`
- `unit/fixtures/demo-failure-tests/**`

**Implementation Details**

- `test.sh` must be a thin CLI wrapper over `tools/run_matrix.py`. It must support:
  - `--config`
  - `--tests-root`
  - `--port-root`
  - `--artifact-root`
  - `--safe-deb-root`
  - `--mode`
  - `--record-casts`
  - repeated `--library`
- `--list-libraries`
- When `--library` is omitted, both `test.sh` and `tools/run_matrix.py` must select every manifest library in manifest order. `--list-libraries` must print that same ordered library list and exit without running any build or test work.
- `tools/run_matrix.py` must orchestrate original and safe runs per library and write explicit JSON results under `<artifact-root>/results/<library>/<mode>.json`.
- The main phase-02 demo fixture is fixed: `unit/fixtures/demo-manifest.yml` must define exactly one library named `demo`, `unit/fixtures/demo-tests/` must contain only that library's harness, and `unit/fixtures/demo-debs/` must contain exactly one safe-deb leaf directory at `unit/fixtures/demo-debs/demo/`.
- `tools/run_matrix.py` and `test.sh` must treat the selected matrix as one aggregate run: they must attempt every requested library/mode pair in order, continue after individual build or test failures, emit the JSON result for every attempted run, and return a non-zero process exit only after the full requested matrix finishes when any attempted run failed.
- A failed run must still emit its `<artifact-root>/results/<library>/<mode>.json`, write its log, and, for safe mode when `--record-casts` is enabled, preserve the cast captured up to the failure point so CI and Pages can publish a complete partial-failure report.
- Every run must write its log at `<artifact-root>/logs/<library>/<mode>.log`. When `--record-casts` is enabled for a safe run, that run must also write `<artifact-root>/casts/<library>/safe.cast`. Original runs never produce a cast file.
- Every result JSON must include at least `library`, `mode`, `status`, `started_at`, `finished_at`, `duration_seconds`, `log_path`, and `cast_path`. `log_path` and `cast_path` must be artifact-root-relative paths that point at the log and cast files for that run, and `cast_path` must be `null` whenever no cast file is produced.
- `--safe-deb-root` is a matrix-level host directory, not a single-library leaf. Its exact required layout is `<safe-deb-root>/<library>/*.deb` for every selected library that will run in safe mode.
- When `--safe-deb-root` is supplied, `tools/run_matrix.py` must resolve the per-library leaf directory at `<safe-deb-root>/<library>/`, fail clearly if that leaf is missing or contains no `.deb` files, and mount that leaf into the library container as `/safedebs`.
- Passing a leaf directory that contains `.deb` files directly to `--safe-deb-root` is invalid. `tools/run_matrix.py` must reject that ambiguous shape instead of guessing.
- When `--safe-deb-root` is omitted and `--port-root` is supplied, `tools/run_matrix.py` must call `tools/build_safe_debs.py` once per selected library, place the resulting packages under `<artifact-root>/debs/<library>/`, and mount that per-library leaf into the library container as `/safedebs` for the safe run.
- Safe-mode runs must record an asciinema cast and must execute the test command under `bash -x` so the cast shows the commands being run.
- Original and safe runs must use the same validator-owned test command and the same shared-library test interface. The only allowed mode difference is whether replacement `.deb` packages are installed before the tests start.
- `tests/_shared/install_safe_debs.sh` must install every `.deb` mounted under `/safedebs` when that directory is present and skip cleanly when it is absent. The container only ever sees the single-library leaf directory mounted at `/safedebs`.
- `tests/_shared/run_library_tests.sh` must be the single shared runtime entrypoint that every library-specific `docker-entrypoint.sh` delegates to after any optional safe-deb installation.
- The shared runtime contract is fixed and validator-owned:
  - every library must provide an executable `tests/<library>/tests/run.sh`
  - `tests/_shared/run_library_tests.sh` must locate that file and execute it
  - before execution it must export at least `VALIDATOR_LIBRARY`, `VALIDATOR_LIBRARY_ROOT`, and `VALIDATOR_TAGGED_ROOT=$VALIDATOR_LIBRARY_ROOT/tests/tagged-port`
  - it must not export `VALIDATOR_MODE` or any other explicit safe/original selector into `tests/<library>/tests/run.sh`
- Library `tests/<library>/tests/run.sh` files may invoke imported scripts or compile imported sources from `tests/<library>/tests/tagged-port`, but they must not rewrite the mirrored tag inputs in place.
- `tools/render_site.py` must render a deterministic static site from the matrix results and cast paths.
- `scripts/verify-site.sh` must verify that the rendered site covers exactly the libraries and modes present in the result JSON and that every referenced cast or log path exists.
- Add small self-contained demo fixtures under `unit/fixtures/`, including a checked-in dummy safe-deb tree at `unit/fixtures/demo-debs/demo/*.deb`, so phase 02 can exercise the shared runner and renderer without depending on real port staging yet.
- Add a second self-contained failure fixture under `unit/fixtures/demo-failure-*` with exactly two libraries, `demo-fail` then `demo-pass`, so phase 02 can prove the matrix continues through a failing library and returns one aggregate non-zero exit only after both libraries and both modes are attempted.
- `unit/test_run_matrix.py` must cover both the accepted matrix-root safe-deb layout (`unit/fixtures/demo-debs/<library>/*.deb`), rejection of a single-library leaf passed directly as `--safe-deb-root`, and the aggregate-failure fixture that verifies continuation plus one final non-zero exit status.

**Verification**

- Run both `check_02_shared_runner_smoke` and `check_02_shared_runner_review`.
- Treat any runner that changes the test command between original and safe mode, aborts the requested matrix on the first failing run, omits safe-mode `bash -x`, skips the fixed `tests/<library>/tests/run.sh` contract, accepts an ambiguous `--safe-deb-root` layout, writes incomplete result JSON, or renders a site that diverges from the matrix results as failure.

### 3. Data / Text Validators

**Phase Name**

`data-text-validators`

**Implement Phase ID**

`impl_03_data_text_validators`

**Verification Phases**

- `check_03_data_text_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_03_data_text_validators`
  - purpose: prove the data/text library batch works in both modes with imported tag-backed fixtures and validator-owned harnesses.
  - commands it should run:
    - `rm -rf .work/check03`
    - `mkdir -p .work/check03`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check03 --dest-root .work/check03/ports --libraries cjson libcsv libjson libxml libyaml`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check03/ports --artifact-root .work/check03/artifacts --mode both --record-casts --library cjson --library libcsv --library libjson --library libxml --library libyaml`
    - `python3 tools/render_site.py --results-root .work/check03/artifacts/results --artifacts-root .work/check03/artifacts --output-root .work/check03/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check03/artifacts/results --site-root .work/check03/site`
    - `for lib in cjson libcsv libjson libxml libyaml; do test -f .work/check03/artifacts/results/$lib/original.json && test -f .work/check03/artifacts/results/$lib/safe.json && test -f .work/check03/artifacts/casts/$lib/safe.cast; done`
- `check_03_data_text_review`
  - type: `check`
  - fixed `bounce_target`: `impl_03_data_text_validators`
  - purpose: review full imported-asset fidelity, shared-entrypoint usage, and the special build-mode contract inside the data/text batch.
  - commands it should run:
    - `rm -rf .work/check03-review`
    - `mkdir -p .work/check03-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check03-review --dest-root .work/check03-review/ports --libraries cjson libcsv libjson libxml libyaml`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check03-review/ports --tests-root tests --libraries cjson libcsv libjson libxml libyaml`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libcsv"]["build"]["mode"] != "checkout-artifacts":
          raise SystemExit("libcsv must remain checkout-artifacts")
      PY
    - `for lib in cjson libcsv libjson libxml libyaml; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in cjson libcsv libjson libxml libyaml; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`

**Preexisting Inputs**

- all outputs from phases 01 and 02
- staged tag-backed inputs for `cjson`, `libcsv`, `libjson`, `libxml`, and `libyaml` as defined in `repositories.yml`

**New Outputs**

- `tests/cjson/**`
- `tests/libcsv/**`
- `tests/libjson/**`
- `tests/libxml/**`
- `tests/libyaml/**`

**Implementation Details**

- This phase covers exactly:
  - `cjson`
  - `libcsv`
  - `libjson`
  - `libxml`
  - `libyaml`
- For each library:
  - import fixtures and harness inputs only through `tools/import_port_assets.py`
  - create a validator-owned `tests/<library>/Dockerfile`
  - create a validator-owned `tests/<library>/docker-entrypoint.sh`
  - create a validator-owned executable `tests/<library>/tests/run.sh`
  - keep all library tests under `tests/<library>/tests/`
  - keep imported tag content under `tests/<library>/tests/tagged-port/` and preserve those files byte-for-byte
  - make `tests/<library>/docker-entrypoint.sh` invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`
- The tests must remain implementation-blind. They may validate behavior and package presence, but they must not branch on "safe" versus "original", and they must not depend on a mode-specific environment variable because none is part of the shared runner contract.
- Preserve the manifest-declared build mode. In this batch, `libcsv` must keep its checked-in-artifact path instead of rebuilding packages.

**Verification**

- Run both `check_03_data_text_matrix` and `check_03_data_text_review`.
- Treat any fixture drift, harness-source drift, or mirrored-import drift from the staged tag, any batch library omission, any missing `tests/<library>/tests/run.sh`, any per-library entrypoint that bypasses `tests/_shared/install_safe_debs.sh` or `tests/_shared/run_library_tests.sh`, or any validator-owned test harness that branches on run mode as failure.

### 4. Media Validators

**Phase Name**

`media-validators`

**Implement Phase ID**

`impl_04_media_validators`

**Verification Phases**

- `check_04_media_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: prove the media-library batch works in both modes, including the non-`apt-repo` tagged `libexif` path and the special docker/check-out-artifacts cases.
  - commands it should run:
    - `rm -rf .work/check04`
    - `mkdir -p .work/check04`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check04 --dest-root .work/check04/ports --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check04/ports --artifact-root .work/check04/artifacts --mode both --record-casts --library giflib --library libexif --library libjpeg-turbo --library libpng --library libsdl --library libtiff --library libvips --library libwebp`
    - `python3 tools/render_site.py --results-root .work/check04/artifacts/results --artifacts-root .work/check04/artifacts --output-root .work/check04/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check04/artifacts/results --site-root .work/check04/site`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do test -f .work/check04/artifacts/results/$lib/original.json && test -f .work/check04/artifacts/results/$lib/safe.json && test -f .work/check04/artifacts/casts/$lib/safe.cast; done`
- `check_04_media_review`
  - type: `check`
  - fixed `bounce_target`: `impl_04_media_validators`
  - purpose: review full imported-asset fidelity, generated/vendor imports, and the special build-mode contract inside the media batch.
  - commands it should run:
    - `rm -rf .work/check04-review`
    - `mkdir -p .work/check04-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check04-review --dest-root .work/check04-review/ports --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check04-review/ports --tests-root tests --libraries giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libpng"]["build"]["mode"] != "checkout-artifacts":
          raise SystemExit("libpng must remain checkout-artifacts")
      if by_name["libvips"]["build"]["mode"] != "docker":
          raise SystemExit("libvips must remain explicit docker")
      if by_name["libexif"]["build"]["mode"] != "safe-debian":
          raise SystemExit("libexif must remain safe-debian")
      PY
    - `test -f tests/libsdl/tests/tagged-port/safe/upstream-tests/installed-tests/usr/share/installed-tests/SDL2/testautomation.test`
    - `find tests/libvips/tests/tagged-port/safe/vendor -type f | grep -q .`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in giflib libexif libjpeg-turbo libpng libsdl libtiff libvips libwebp; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`

**Preexisting Inputs**

- all outputs from phases 01 through 03
- staged tag-backed inputs for `giflib`, `libexif`, `libjpeg-turbo`, `libpng`, `libsdl`, `libtiff`, `libvips`, and `libwebp` as defined in `repositories.yml`

**New Outputs**

- `tests/giflib/**`
- `tests/libexif/**`
- `tests/libjpeg-turbo/**`
- `tests/libpng/**`
- `tests/libsdl/**`
- `tests/libtiff/**`
- `tests/libvips/**`
- `tests/libwebp/**`

**Implementation Details**

- This phase covers exactly:
  - `giflib`
  - `libexif`
  - `libjpeg-turbo`
  - `libpng`
  - `libsdl`
  - `libtiff`
  - `libvips`
  - `libwebp`
- Import fixtures and harness inputs only through `tools/import_port_assets.py`.
- Treat `libexif` as a mature tagged import from `refs/tags/libexif/04-test`, not as a bootstrap case.
- Preserve `libpng`'s checked-in-artifact path and `libvips`'s explicit docker build path from the manifest.
- Create validator-owned `tests/<library>/tests/run.sh` for every library in this batch and keep imported tag mirrors under `tests/<library>/tests/tagged-port/`.
- Make every `tests/<library>/docker-entrypoint.sh` in this batch invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`.
- The tests in this batch must remain implementation-blind and must not read any explicit safe/original mode selector from the shared runner contract.
- Preserve tracked generated or vendor inputs when present. In particular, `libsdl` and `libvips` must carry forward their manifest-declared generated/vendor imports rather than regenerating them in validator.

**Verification**

- Run both `check_04_media_matrix` and `check_04_media_review`.
- Treat any fixture drift, harness-source drift, or lost mirrored tagged inputs, any missing `tests/<library>/tests/run.sh`, any per-library entrypoint that bypasses `tests/_shared/install_safe_debs.sh` or `tests/_shared/run_library_tests.sh`, any validator-owned test harness that branches on run mode, or any build-mode regression for `libpng`, `libvips`, or `libexif` as failure.

### 5. System / Archive Validators

**Phase Name**

`system-archive-validators`

**Implement Phase ID**

`impl_05_system_archive_validators`

**Verification Phases**

- `check_05_system_archive_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_05_system_archive_validators`
  - purpose: prove the remaining tagged libraries work in both modes, including the non-`apt-repo` tagged `libuv` path.
  - commands it should run:
    - `rm -rf .work/check05`
    - `mkdir -p .work/check05`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check05 --dest-root .work/check05/ports --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check05/ports --artifact-root .work/check05/artifacts --mode both --record-casts --library libarchive --library libbz2 --library liblzma --library libsodium --library libuv --library libzstd`
    - `python3 tools/render_site.py --results-root .work/check05/artifacts/results --artifacts-root .work/check05/artifacts --output-root .work/check05/site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root .work/check05/artifacts/results --site-root .work/check05/site`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do test -f .work/check05/artifacts/results/$lib/original.json && test -f .work/check05/artifacts/results/$lib/safe.json && test -f .work/check05/artifacts/casts/$lib/safe.cast; done`
- `check_05_system_archive_review`
  - type: `check`
  - fixed `bounce_target`: `impl_05_system_archive_validators`
  - purpose: review full imported-asset fidelity, `libuv`'s mature-tagged import contract, `liblzma`'s split test-import contract, and final batch completeness.
  - commands it should run:
    - `rm -rf .work/check05-review`
    - `mkdir -p .work/check05-review`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check05-review --dest-root .work/check05-review/ports --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - `git diff --check HEAD^ HEAD`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check05-review/ports --tests-root tests --libraries libarchive libbz2 liblzma libsodium libuv libzstd`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import yaml

      manifest = yaml.safe_load(Path("repositories.yml").read_text())
      names = [entry["name"] for entry in manifest["repositories"]]
      if "glib" in names or "libc6" in names or "libcurl" in names or "libgcrypt" in names or "libjansson" in names:
          raise SystemExit("out-of-scope untagged libraries must not reappear")

      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      if by_name["libuv"]["ref"] != "refs/tags/libuv/04-test":
          raise SystemExit("libuv must be pinned to refs/tags/libuv/04-test")
      if by_name["libuv"]["build"]["mode"] != "safe-debian":
          raise SystemExit("libuv must remain safe-debian")
      PY
    - `test -f tests/libarchive/tests/tagged-port/original/libarchive-3.7.2/libarchive/test/test_acl_nfs4.c`
    - `test -f tests/liblzma/tests/tagged-port/safe/tests/dependents/boost_iostreams_smoke.cpp`
    - `test -f tests/liblzma/tests/tagged-port/safe/tests/upstream/bcj_test.c`
    - `test ! -e tests/liblzma/tests/tagged-port/safe/tests/generated`
    - `test -f tests/libuv/tests/tagged-port/safe/test/run-tests.c`
    - `test -f tests/libzstd/tests/tagged-port/safe/scripts/run-full-suite.sh`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do test -f tests/$lib/Dockerfile && test -f tests/$lib/docker-entrypoint.sh && test -f tests/$lib/tests/run.sh && test -d tests/$lib/tests/tagged-port && grep -F "tests/_shared/install_safe_debs.sh" tests/$lib/docker-entrypoint.sh >/dev/null && grep -F "tests/_shared/run_library_tests.sh" tests/$lib/docker-entrypoint.sh >/dev/null; done`
    - `for lib in libarchive libbz2 liblzma libsodium libuv libzstd; do ! grep -n "VALIDATOR_MODE" tests/$lib/docker-entrypoint.sh tests/$lib/tests/run.sh >/dev/null; done`

**Preexisting Inputs**

- all outputs from phases 01 through 04
- staged tag-backed inputs for `libarchive`, `libbz2`, `liblzma`, `libsodium`, `libuv`, and `libzstd` as defined in `repositories.yml`

**New Outputs**

- `tests/libarchive/**`
- `tests/libbz2/**`
- `tests/liblzma/**`
- `tests/libsodium/**`
- `tests/libuv/**`
- `tests/libzstd/**`

**Implementation Details**

- This phase covers exactly:
  - `libarchive`
  - `libbz2`
  - `liblzma`
  - `libsodium`
  - `libuv`
  - `libzstd`
- Import fixtures and harness inputs only through `tools/import_port_assets.py`.
- Treat `libuv` as a mature tagged import from `refs/tags/libuv/04-test`, not as a bootstrap-from-HEAD project.
- Preserve tag-rooted fixture copying for every library in this batch.
- `liblzma` must consume the exact phase-01 imports `safe/docker`, `safe/scripts`, `safe/tests/dependents`, `safe/tests/extra`, and `safe/tests/upstream`; it must not depend on `validator.import_excludes` to prune `safe/tests/generated` after import.
- Create validator-owned `tests/<library>/tests/run.sh` for every library in this batch and keep imported tag mirrors under `tests/<library>/tests/tagged-port/`.
- Make every `tests/<library>/docker-entrypoint.sh` in this batch invoke `tests/_shared/install_safe_debs.sh` before delegating runtime execution to `tests/_shared/run_library_tests.sh`.
- The tests in this batch must remain implementation-blind and must not read any explicit safe/original mode selector from the shared runner contract.
- Do not add any validator logic for out-of-scope untagged repos in this phase.

**Verification**

- Run both `check_05_system_archive_matrix` and `check_05_system_archive_review`.
- Treat any attempt to reintroduce out-of-scope untagged repos, any `libuv` ref drift away from `refs/tags/libuv/04-test`, any `liblzma` import of `safe/tests/generated`, any missing `tests/<library>/tests/run.sh`, any per-library entrypoint that bypasses `tests/_shared/install_safe_debs.sh` or `tests/_shared/run_library_tests.sh`, any validator-owned test harness that branches on run mode, or any fixture, harness-source, or mirrored-import mismatch against the staged tags as failure.

### 6. CI / Pages / Publish

**Phase Name**

`ci-pages-publish`

**Implement Phase ID**

`impl_06_ci_pages_publish`

**Verification Phases**

- `check_06_full_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_06_ci_pages_publish`
  - purpose: run the full validator implementation locally against the checked-in tagged scope, render the report site, and verify the full output set plus imported-asset fidelity across all selected libraries.
  - commands it should run:
    - `python3 -m unittest discover -s unit -v`
    - `rm -rf .work/check06 artifacts site`
    - `python3 tools/stage_port_repos.py --config repositories.yml --source-root /home/yans/safelibs --workspace .work/check06 --dest-root .work/check06/ports`
    - `bash test.sh --config repositories.yml --tests-root tests --port-root .work/check06/ports --artifact-root artifacts --mode both --record-casts`
    - `python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site`
    - `bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site`
    - `python3 tools/verify_imported_assets.py --config repositories.yml --port-root .work/check06/ports --tests-root tests`
- `check_06_release_review`
  - type: `check`
  - fixed `bounce_target`: `impl_06_ci_pages_publish`
  - purpose: review CI/Pages workflows, README and Makefile operator contracts, public-repo publication logic, enforced public visibility and `origin` reconciliation, remote tag reachability checks, and the final checked-in generated workflow artifacts so `workflow.yaml` and the kept phase docs both carry the same tagged-only six-phase contract instead of the stale seven-phase bootstrap design.
  - commands it should run:
    - `git diff --check HEAD^ HEAD`
    - `test -f .github/workflows/ci.yml && test -f .github/workflows/pages.yml && test -f scripts/publish-public.sh && test -f README.md && test -f Makefile`
    - `test -f .plan/workflow-structure.yaml && test -f workflow.yaml`
    - |
      python3 - <<'PY'
      from pathlib import Path
      import re
      import subprocess
      import yaml

      def workflow_on(doc, name):
          if "on" in doc:
              return doc["on"]
          if True in doc:
              return doc[True]
          raise SystemExit(f"{name} workflow missing trigger block")

      def needs_list(job):
          needs = job.get("needs", [])
          if needs is None:
              return []
          if isinstance(needs, str):
              return [needs]
          return list(needs)

      def job_text(job):
          chunks = [yaml.safe_dump(job, sort_keys=True)]
          for step in job.get("steps", []):
              if not isinstance(step, dict):
                  continue
              for key in ["name", "id", "if", "uses", "run"]:
                  if step.get(key) is not None:
                      chunks.append(str(step[key]))
              if step.get("with") is not None:
                  chunks.append(yaml.safe_dump(step["with"], sort_keys=True))
          return "\n".join(chunks)

      ci_text = Path(".github/workflows/ci.yml").read_text()
      pages_text = Path(".github/workflows/pages.yml").read_text()
      readme_text = Path("README.md").read_text()
      makefile_text = Path("Makefile").read_text()
      publish_public_text = Path("scripts/publish-public.sh").read_text()
      workflow_structure_text = Path(".plan/workflow-structure.yaml").read_text()
      workflow_text = Path("workflow.yaml").read_text()
      ci = yaml.safe_load(ci_text)
      pages = yaml.safe_load(pages_text)
      workflow_structure = yaml.safe_load(workflow_structure_text)
      workflow_rendered = yaml.safe_load(workflow_text)
      expected_phases = [
          ("impl_01_inventory_scaffold", "implement", None),
          ("check_01_inventory_scaffold_smoke", "check", "impl_01_inventory_scaffold"),
          ("check_01_inventory_scaffold_review", "check", "impl_01_inventory_scaffold"),
          ("impl_02_shared_runner_reporting", "implement", None),
          ("check_02_shared_runner_smoke", "check", "impl_02_shared_runner_reporting"),
          ("check_02_shared_runner_review", "check", "impl_02_shared_runner_reporting"),
          ("impl_03_data_text_validators", "implement", None),
          ("check_03_data_text_matrix", "check", "impl_03_data_text_validators"),
          ("check_03_data_text_review", "check", "impl_03_data_text_validators"),
          ("impl_04_media_validators", "implement", None),
          ("check_04_media_matrix", "check", "impl_04_media_validators"),
          ("check_04_media_review", "check", "impl_04_media_validators"),
          ("impl_05_system_archive_validators", "implement", None),
          ("check_05_system_archive_matrix", "check", "impl_05_system_archive_validators"),
          ("check_05_system_archive_review", "check", "impl_05_system_archive_validators"),
          ("impl_06_ci_pages_publish", "implement", None),
          ("check_06_full_matrix", "check", "impl_06_ci_pages_publish"),
          ("check_06_release_review", "check", "impl_06_ci_pages_publish"),
      ]
      expected_phase_docs = [
          "01-inventory-scaffold.md",
          "02-shared-runner-reporting.md",
          "03-data-text-validators.md",
          "04-media-validators.md",
          "05-system-archive-validators.md",
          "06-ci-pages-publish.md",
      ]
      expected_tracked_generated = [
          ".plan/phases/01-inventory-scaffold.md",
          ".plan/phases/02-shared-runner-reporting.md",
          ".plan/phases/03-data-text-validators.md",
          ".plan/phases/04-media-validators.md",
          ".plan/phases/05-system-archive-validators.md",
          ".plan/phases/06-ci-pages-publish.md",
          ".plan/workflow-structure.yaml",
          "workflow.yaml",
      ]
      obsolete_generated = [
          ".plan/phases/02-shared-matrix-reporting.md",
          ".plan/phases/03-text-data-validators.md",
          ".plan/phases/05-archive-system-validators.md",
          ".plan/phases/06-bootstrap-missing-validators.md",
          ".plan/phases/07-ci-pages-publish.md",
      ]
      expected_phase_doc_ids = {
          "01-inventory-scaffold.md": "impl_01_inventory_scaffold",
          "02-shared-runner-reporting.md": "impl_02_shared_runner_reporting",
          "03-data-text-validators.md": "impl_03_data_text_validators",
          "04-media-validators.md": "impl_04_media_validators",
          "05-system-archive-validators.md": "impl_05_system_archive_validators",
          "06-ci-pages-publish.md": "impl_06_ci_pages_publish",
      }
      expected_phase_doc_verifiers = {
          "01-inventory-scaffold.md": ["check_01_inventory_scaffold_smoke", "check_01_inventory_scaffold_review"],
          "02-shared-runner-reporting.md": ["check_02_shared_runner_smoke", "check_02_shared_runner_review"],
          "03-data-text-validators.md": ["check_03_data_text_matrix", "check_03_data_text_review"],
          "04-media-validators.md": ["check_04_media_matrix", "check_04_media_review"],
          "05-system-archive-validators.md": ["check_05_system_archive_matrix", "check_05_system_archive_review"],
          "06-ci-pages-publish.md": ["check_06_full_matrix", "check_06_release_review"],
      }
      expected_phase_batches = {
          "03-data-text-validators.md": ["cjson", "libcsv", "libjson", "libxml", "libyaml"],
          "04-media-validators.md": ["giflib", "libexif", "libjpeg-turbo", "libpng", "libsdl", "libtiff", "libvips", "libwebp"],
          "05-system-archive-validators.md": ["libarchive", "libbz2", "liblzma", "libsodium", "libuv", "libzstd"],
      }
      expected_rendered_prompt_batches = {
          "impl_03_data_text_validators": ["cjson", "libcsv", "libjson", "libxml", "libyaml"],
          "impl_04_media_validators": ["giflib", "libexif", "libjpeg-turbo", "libpng", "libsdl", "libtiff", "libvips", "libwebp"],
          "impl_05_system_archive_validators": ["libarchive", "libbz2", "liblzma", "libsodium", "libuv", "libzstd"],
      }
      scoped_libraries = sorted({
          "cjson",
          "giflib",
          "libarchive",
          "libbz2",
          "libcsv",
          "libexif",
          "libjpeg-turbo",
          "libjson",
          "liblzma",
          "libpng",
          "libsdl",
          "libsodium",
          "libtiff",
          "libuv",
          "libvips",
          "libwebp",
          "libxml",
          "libyaml",
          "libzstd",
      })
      smoke_libraries = ["giflib", "libpng", "libjson", "libvips", "libuv"]
      if set(ci["jobs"]) != {"preflight", "unit-tests", "matrix-smoke", "full-matrix"}:
          raise SystemExit(f"unexpected ci jobs: {set(ci['jobs'])}")
      if set(pages["jobs"]) != {"build", "deploy", "report-status"}:
          raise SystemExit(f"unexpected pages jobs: {set(pages['jobs'])}")
      ci_on = workflow_on(ci, "ci")
      if not isinstance(ci_on, dict) or set(ci_on) != {"push", "pull_request"}:
          raise SystemExit(f"ci workflow triggers mismatch: {ci_on!r}")
      pages_on = workflow_on(pages, "pages")
      if not isinstance(pages_on, dict) or set(pages_on) != {"push", "workflow_dispatch"}:
          raise SystemExit(f"pages workflow triggers mismatch: {pages_on!r}")
      if (pages_on["push"] or {}).get("branches") != ["main"]:
          raise SystemExit(f"pages workflow push branches mismatch: {pages_on['push']!r}")
      if pages.get("permissions") != {"contents": "read", "pages": "write", "id-token": "write"}:
          raise SystemExit(f"pages workflow permissions mismatch: {pages.get('permissions')!r}")
      for workflow_name, text in {"ci": ci_text, "pages": pages_text}.items():
          for required in ["SAFELIBS_REPO_TOKEN", "GH_TOKEN"]:
              if required not in text:
                  raise SystemExit(f"{workflow_name} workflow missing private-repo auth token reference: {required}")
          if "python3 tools/inventory.py --config repositories.yml --check-remote-tags" not in text:
              raise SystemExit(f"{workflow_name} workflow missing remote-tag reachability check")
          if "gh auth setup-git" in text:
              raise SystemExit(f"{workflow_name} workflow must not rely on gh auth setup-git")
      preflight = ci["jobs"]["preflight"]
      preflight_text = job_text(preflight)
      preflight_outputs = preflight.get("outputs") or {}
      if not {"has_repo_token", "remote_tags_ok"} <= set(preflight_outputs):
          raise SystemExit(f"preflight outputs mismatch: {preflight_outputs}")
      for required in [
          "has_repo_token",
          "remote_tags_ok",
          "python3 tools/inventory.py --config repositories.yml --check-remote-tags",
          "has_repo_token=false",
          "remote_tags_ok=false",
      ]:
          if required not in preflight_text:
              raise SystemExit(f"preflight job missing required contract token: {required}")
      unit_tests = ci["jobs"]["unit-tests"]
      unit_tests_text = job_text(unit_tests)
      if needs_list(unit_tests):
          raise SystemExit(f"unit-tests must not depend on other jobs: {needs_list(unit_tests)}")
      for required in ["python3 -m unittest discover -s unit -v"]:
          if required not in unit_tests_text:
              raise SystemExit(f"unit-tests missing required contract token: {required}")
      for forbidden in ["SAFELIBS_REPO_TOKEN", "GH_TOKEN", "gh ", "tools/stage_port_repos.py", "/home/yans/safelibs"]:
          if forbidden in unit_tests_text:
              raise SystemExit(f"unit-tests must stay secret-free and local-only; found {forbidden!r}")
      for job_name in ["matrix-smoke", "full-matrix"]:
          job = ci["jobs"][job_name]
          gate = str(job.get("if", ""))
          job_needs = needs_list(job)
          for required_need in ["preflight", "unit-tests"]:
              if required_need not in job_needs:
                  raise SystemExit(f"{job_name} must depend on {required_need}")
          for required in [
              "needs.preflight.outputs.has_repo_token",
              "needs.preflight.outputs.remote_tags_ok",
          ]:
              if required not in gate:
                  raise SystemExit(f"{job_name} missing preflight gate token: {required}")
          if "rm -rf .work/ports artifacts site" not in job_text(job):
              raise SystemExit(f"{job_name} must clear .work/ports, artifacts, and site before secret-gated work")
      matrix_smoke_text = job_text(ci["jobs"]["matrix-smoke"])
      for library in smoke_libraries:
          if f"--library {library}" not in matrix_smoke_text:
              raise SystemExit(f"matrix-smoke missing scoped library {library}")
      for library in sorted(set(scoped_libraries) - set(smoke_libraries)):
          if f"--library {library}" in matrix_smoke_text:
              raise SystemExit(f"matrix-smoke must not include non-smoke library {library}")
      full_matrix_text = job_text(ci["jobs"]["full-matrix"])
      full_matrix_gate = str(ci["jobs"]["full-matrix"].get("if", ""))
      for required in ["github.event_name", "push", "github.ref", "refs/heads/main"]:
          if required not in full_matrix_gate:
              raise SystemExit(f"full-matrix must be gated to pushes on main: missing {required}")
      for required in [
          "python3 tools/stage_port_repos.py --config repositories.yml",
          "bash test.sh --config repositories.yml --tests-root tests --port-root .work/ports --artifact-root artifacts --mode both --record-casts",
          "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
          "bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
          "matrix_exit_code",
          "matrix_exit_code=$?",
          "actions/upload-artifact",
          "artifacts",
          "site",
      ]:
          if required not in full_matrix_text:
              raise SystemExit(f"full-matrix missing required contract token: {required}")
      if "always()" not in full_matrix_text:
          raise SystemExit("full-matrix must upload artifacts before failing on matrix_exit_code")
      if "$GITHUB_OUTPUT" not in full_matrix_text and "$GITHUB_ENV" not in full_matrix_text:
          raise SystemExit("full-matrix must persist matrix_exit_code for later failure handling")
      if not re.search(r"matrix_exit_code.*(?:exit 1|exit \"?\$matrix_exit_code\"?)", full_matrix_text, re.S):
          raise SystemExit("full-matrix must fail after uploads using the saved aggregate matrix_exit_code")
      build_text = job_text(pages["jobs"]["build"])
      build_outputs = pages["jobs"]["build"].get("outputs") or {}
      if "matrix_exit_code" not in build_outputs:
          raise SystemExit(f"pages build outputs mismatch: {build_outputs}")
      for required in [
          "rm -rf .work/ports artifacts site",
          "python3 tools/inventory.py --config repositories.yml --check-remote-tags",
          "python3 tools/stage_port_repos.py --config repositories.yml",
          "bash test.sh --config repositories.yml --tests-root tests --port-root .work/ports --artifact-root artifacts --mode both --record-casts",
          "python3 tools/render_site.py --results-root artifacts/results --artifacts-root artifacts --output-root site",
          "bash scripts/verify-site.sh --config repositories.yml --results-root artifacts/results --site-root site",
          "matrix_exit_code",
          "matrix_exit_code=$?",
          "$GITHUB_OUTPUT",
          "actions/upload-pages-artifact",
      ]:
          if required not in build_text:
              raise SystemExit(f"pages build job missing required contract token: {required}")
      if "build" not in needs_list(pages["jobs"]["deploy"]):
          raise SystemExit("pages deploy job must depend on build")
      if "actions/deploy-pages" not in job_text(pages["jobs"]["deploy"]):
          raise SystemExit("pages deploy job must use actions/deploy-pages")
      report_status_text = job_text(pages["jobs"]["report-status"])
      report_status_needs = needs_list(pages["jobs"]["report-status"])
      if "build" not in report_status_needs or "deploy" not in report_status_needs:
          raise SystemExit("report-status must depend on both build and deploy so Pages publishes before failure reporting")
      if "needs.build.outputs.matrix_exit_code" not in report_status_text:
          raise SystemExit("report-status must consume needs.build.outputs.matrix_exit_code")
      if "matrix_exit_code" not in report_status_text:
          raise SystemExit("report-status must consume matrix_exit_code")
      if not re.search(r"matrix_exit_code.*(?:exit 1|-ne 0|!= ['\"]?0)", report_status_text, re.S):
          raise SystemExit("report-status must fail when matrix_exit_code is non-zero")
      if re.search(r"matrix_exit_code.*(?:exit 1|-ne 0|!= ['\"]?0)", build_text, re.S):
          raise SystemExit("pages build job must not fail on matrix_exit_code; report-status owns post-deploy failure")
      phase_docs = sorted(path.name for path in Path(".plan/phases").glob("*.md"))
      if phase_docs != expected_phase_docs:
          raise SystemExit(f"unexpected phase docs: {phase_docs}")
      tracked_generated = sorted(
          subprocess.check_output(
              ["git", "ls-files", ".plan/phases", ".plan/workflow-structure.yaml", "workflow.yaml"],
              text=True,
          ).splitlines()
      )
      if tracked_generated != expected_tracked_generated:
          raise SystemExit(f"tracked generated file set mismatch: {tracked_generated}")
      for path in obsolete_generated:
          if Path(path).exists():
              raise SystemExit(f"obsolete generated file still exists in worktree: {path}")
          if subprocess.run(
              ["git", "ls-files", "--error-unmatch", path],
              stdout=subprocess.DEVNULL,
              stderr=subprocess.DEVNULL,
          ).returncode == 0:
              raise SystemExit(f"obsolete generated file still tracked: {path}")

      structure_phases = [
          (phase["id"], phase["type"], phase.get("bounce_target"))
          for phase in workflow_structure["phases"]
      ]
      rendered_phases = [
          (phase["id"], phase["type"], phase.get("bounce_target"))
          for phase in workflow_rendered["phases"]
      ]
      if structure_phases != expected_phases:
          raise SystemExit(f"workflow structure mismatch: {structure_phases}")
      if rendered_phases != expected_phases:
          raise SystemExit(f"rendered workflow mismatch: {rendered_phases}")

      rendered_phase_map = {phase["id"]: phase for phase in workflow_rendered["phases"]}
      phase_doc_texts = {
          name: (Path(".plan/phases") / name).read_text()
          for name in expected_phase_docs
      }
      commit_sentence = "Commit all phase work to git before yielding."
      for phase_id, phase_type, _ in expected_phases:
          if phase_type != "implement":
              continue
          prompt = str(rendered_phase_map.get(phase_id, {}).get("prompt", ""))
          if prompt.count(commit_sentence) != 1:
              raise SystemExit(f"{phase_id} prompt must contain the commit-before-yield sentence exactly once")
      for name, text in phase_doc_texts.items():
          if text.count(commit_sentence) != 1:
              raise SystemExit(f"{name} must contain the commit-before-yield sentence exactly once")
      for name, impl_id in expected_phase_doc_ids.items():
          text = phase_doc_texts[name]
          if text.count("**Preexisting Inputs**") != 1 or text.count("**New Outputs**") != 1:
              raise SystemExit(f"{name} must keep exactly one Preexisting Inputs heading and one New Outputs heading")
          if impl_id not in text:
              raise SystemExit(f"{name} missing implement phase id {impl_id}")
          if text.count("type: `check`") != len(expected_phase_doc_verifiers[name]):
              raise SystemExit(f"{name} must define every verifier with explicit type: check metadata")
          if text.count(f"fixed `bounce_target`: `{impl_id}`") != len(expected_phase_doc_verifiers[name]):
              raise SystemExit(f"{name} must define every verifier with fixed bounce_target {impl_id}")
          for verifier_id in expected_phase_doc_verifiers[name]:
              if verifier_id not in text:
                  raise SystemExit(f"{name} missing verifier id {verifier_id}")
      for name in [
          "03-data-text-validators.md",
          "04-media-validators.md",
          "05-system-archive-validators.md",
          "06-ci-pages-publish.md",
      ]:
          if "tools/verify_imported_assets.py" not in phase_doc_texts[name]:
              raise SystemExit(f"{name} must carry the imported-asset fidelity verifier")
      for phase_id in [
          "check_03_data_text_review",
          "check_04_media_review",
          "check_05_system_archive_review",
          "check_06_full_matrix",
      ]:
          prompt = str(rendered_phase_map.get(phase_id, {}).get("prompt", ""))
          if "tools/verify_imported_assets.py" not in prompt:
              raise SystemExit(f"{phase_id} prompt must run tools/verify_imported_assets.py")
      for name, libraries in expected_phase_batches.items():
          text = phase_doc_texts[name]
          for library in libraries:
              if library not in text:
                  raise SystemExit(f"{name} missing scoped library {library}")
      for phase_id, libraries in expected_rendered_prompt_batches.items():
          prompt = str(rendered_phase_map.get(phase_id, {}).get("prompt", ""))
          for library in libraries:
              if library not in prompt:
                  raise SystemExit(f"{phase_id} prompt missing scoped library {library}")

      combined_phase_docs = "\n".join(phase_doc_texts[name] for name in expected_phase_docs)
      required_generated_tokens = [
          "inventory.tag_probe_rule",
          "validator.imports",
          "validator.import_excludes",
          "refs/tags/libexif/04-test",
          "refs/tags/libuv/04-test",
          "tests/<library>/tests/run.sh",
          "<safe-deb-root>/<library>/*.deb",
          "<artifact-root>/debs/<library>/",
          "/safedebs",
          "VALIDATOR_LIBRARY_ROOT",
      ]
      for required in required_generated_tokens:
          if required not in workflow_text:
              raise SystemExit(f"workflow.yaml missing required contract token: {required}")
          if required not in combined_phase_docs:
              raise SystemExit(f"phase docs missing required contract token: {required}")

      for forbidden in [
          "impl_02_shared_matrix_reporting",
          "shared-matrix-reporting",
          "impl_06_bootstrap_missing_validators",
          "bootstrap-missing-validators",
          "impl_07_ci_pages_publish",
          "source-debian-original",
          "+validatorbootstrap1",
          "validator.runtime_fixture_paths",
      ]:
          if forbidden in workflow_text:
              raise SystemExit(f"workflow.yaml still carries stale generated contract token: {forbidden}")
          if forbidden in combined_phase_docs:
              raise SystemExit(f"phase docs still carry stale generated contract token: {forbidden}")
      for forbidden_library in ["glib", "libc6", "libcurl", "libgcrypt", "libjansson"]:
          for forbidden_token in [
              f"--library {forbidden_library}",
              f"tests/{forbidden_library}/",
              f"port-{forbidden_library}",
              f"refs/tags/{forbidden_library}/04-test",
          ]:
              if forbidden_token in workflow_text:
                  raise SystemExit(f"workflow.yaml still scopes forbidden library token: {forbidden_token}")
              if forbidden_token in combined_phase_docs:
                  raise SystemExit(f"phase docs still scope forbidden library token: {forbidden_token}")

      for forbidden_yaml_token in [
          "parallel_groups:",
          "include:",
          "prompt_file:",
          "workflow_file:",
          "workflow_dir:",
          "checks:",
          "bounce_targets:",
      ]:
          if forbidden_yaml_token in workflow_structure_text:
              raise SystemExit(f".plan/workflow-structure.yaml unexpectedly contains {forbidden_yaml_token}")
          if forbidden_yaml_token in workflow_text:
              raise SystemExit(f"workflow.yaml unexpectedly contains {forbidden_yaml_token}")

      for required in [
          "publish-public:",
          "unit:",
          "inventory:",
          "stage-ports:",
          "build-safe:",
          "import-assets:",
          "clean:",
      ]:
          if required not in makefile_text:
              raise SystemExit(f"Makefile missing required target: {required}")
      if "scripts/publish-public.sh" not in makefile_text:
          raise SystemExit("Makefile publish-public target must invoke scripts/publish-public.sh")
      for required in [
          "GH_TOKEN",
          "SAFELIBS_REPO_TOKEN",
          "--source-root",
          "<safe-deb-root>/<library>/*.deb",
          "artifacts/",
          "site/",
          "make publish-public",
          "GitHub Pages",
      ]:
          if required not in readme_text:
              raise SystemExit(f"README.md missing required operator-guide token: {required}")
      for required in [
          "GH_TOKEN",
          "SAFELIBS_REPO_TOKEN",
          "python3 tools/inventory.py --config repositories.yml --check-remote-tags",
          "gh repo view safelibs/validator",
          "gh repo create safelibs/validator",
          "--public",
          "visibility",
          "git remote get-url origin",
          "git push",
      ]:
          if required not in publish_public_text:
              raise SystemExit(f"scripts/publish-public.sh missing required publication token: {required}")
      if "git remote add origin" not in publish_public_text and "git remote set-url origin" not in publish_public_text:
          raise SystemExit("scripts/publish-public.sh must reconcile origin with git remote add/set-url")
      PY
    - `python3 tools/inventory.py --config repositories.yml --check-remote-tags`
    - `test ! -e inventory/non-apt-ref-status.json`
    - `test ! -e tools/publish_source_refs.py && test ! -e unit/test_publish_source_refs.py`
    - |
      if [ -n "${GH_TOKEN:-}" ]; then
        export GH_TOKEN
      elif [ -n "${SAFELIBS_REPO_TOKEN:-}" ]; then
        export GH_TOKEN="$SAFELIBS_REPO_TOKEN"
      else
        unset GH_TOKEN || true
      fi
      python3 - <<'PY'
      import json
      import os
      import re
      import subprocess

      repo = json.loads(
          subprocess.check_output(
              ["gh", "repo", "view", "safelibs/validator", "--json", "visibility,nameWithOwner,url"],
              text=True,
              env=os.environ,
          )
      )
      if repo["nameWithOwner"] != "safelibs/validator":
          raise SystemExit(f"unexpected published repo target: {repo}")
      if str(repo["visibility"]).upper() != "PUBLIC":
          raise SystemExit(f"safelibs/validator must be public, found {repo['visibility']}")

      origin = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
      allowed_patterns = [
          r"git@github\.com:safelibs/validator(?:\.git)?",
          r"https://github\.com/safelibs/validator(?:\.git)?",
          r"https://x-access-token:[^@]+@github\.com/safelibs/validator(?:\.git)?",
      ]
      if not any(re.fullmatch(pattern, origin) for pattern in allowed_patterns):
          raise SystemExit(f"origin must point to safelibs/validator, found {origin!r}")

      remote_line = subprocess.check_output(
          ["git", "ls-remote", "--heads", "origin", "main"],
          text=True,
          env=os.environ,
      ).strip()
      if not remote_line:
          raise SystemExit("origin must advertise refs/heads/main")
      remote_sha, remote_ref = remote_line.split()
      if remote_ref != "refs/heads/main":
          raise SystemExit(f"unexpected remote ref from origin: {remote_ref}")
      local_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
      if remote_sha != local_sha:
          raise SystemExit(f"origin main must match local HEAD: {remote_sha} != {local_sha}")
      PY

**Preexisting Inputs**

- all outputs from phases 01 through 05
- current stale generated workflow artifacts under `.plan/`, plus any existing worktree `workflow.yaml`; clean `HEAD` does not track `workflow.yaml`, so phase 06 must create it while replacing any stale worktree copy
- `/home/yans/safelibs/apt-repo/.github/workflows/ci.yml`
- `/home/yans/safelibs/apt-repo/.github/workflows/pages.yml`
- `/home/yans/safelibs/apt-repo/scripts/verify-in-ubuntu-docker.sh`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`
- authenticated GitHub access with permission to inspect private `port-*` repos and create `safelibs/validator`, provided either by an existing local login or by `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`

**New Outputs**

- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`
- `.plan/workflow-structure.yaml`
- `.plan/phases/01-inventory-scaffold.md`
- `.plan/phases/02-shared-runner-reporting.md`
- `.plan/phases/03-data-text-validators.md`
- `.plan/phases/04-media-validators.md`
- `.plan/phases/05-system-archive-validators.md`
- `.plan/phases/06-ci-pages-publish.md`
- `workflow.yaml`
- `scripts/publish-public.sh`
- updated `README.md`
- public GitHub repo `safelibs/validator`

**Implementation Details**

- Every workflow job or script step that may touch private `port-*` repos must use the plan's shared auth contract:
  - set both `GH_TOKEN` and `SAFELIBS_REPO_TOKEN` from `${{ secrets.SAFELIBS_REPO_TOKEN }}` in GitHub Actions before invoking `gh`, `tools/inventory.py`, or `tools/stage_port_repos.py`
  - let the tools perform git access through token-authenticated HTTPS URLs derived from `github_repo`
  - do not rely on SSH keys, inherited local developer auth state, or `gh auth setup-git`
- Create `.github/workflows/ci.yml` on Ubuntu 24.04 with four jobs:
  - `preflight`
  - `unit-tests`
  - `matrix-smoke`
  - `full-matrix`
- The CI workflow itself must trigger on both `push` and `pull_request`.
- `preflight` must:
  - detect whether the effective token is present by checking `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`
  - when the token is present, run `python3 tools/inventory.py --config repositories.yml --check-remote-tags`
  - when the token is absent, skip remote-tag probing, report `remote_tags_ok=false`, and still succeed so public pull requests can reach `unit-tests`
  - expose booleans `has_repo_token` and `remote_tags_ok`
- `unit-tests` must:
  - run `python3 -m unittest discover -s unit -v`
  - avoid `GH_TOKEN`, `SAFELIBS_REPO_TOKEN`, `gh`, and `tools/stage_port_repos.py`
  - depend only on checked-in unit fixtures plus temporary directories/repositories created during the test run; do not rely on `/home/yans/safelibs`, live GitHub, or private tags
  - run on every CI trigger regardless of whether `preflight` found a token
- `matrix-smoke` and `full-matrix` must both depend on `preflight` and `unit-tests`.
- `matrix-smoke` must run only when preflight succeeds and must stage and run exactly:
  - `giflib`
  - `libpng`
  - `libjson`
  - `libvips`
  - `libuv`
- That fixed subset must cover every runtime/build-path class validator cares about in this scoped plan:
  - `safe-debian`
  - `checkout-artifacts`
  - omitted-mode default-to-`docker`
  - explicit `docker`
  - non-`apt-repo` tagged `safe-debian`
- `matrix-smoke` and `full-matrix` must only touch private staging when both `has_repo_token` and `remote_tags_ok` are `true`.
- `matrix-smoke` may let the job fail on the aggregate exit code from `bash test.sh`, but because `test.sh` is aggregate, that non-zero exit may only happen after the smoke subset completes.
- `full-matrix` must run on pushes to `main` when the token and remote-tag checks both pass. It must stage the full manifest, run `bash test.sh --config repositories.yml --tests-root tests --port-root .work/ports --artifact-root artifacts --mode both --record-casts`, capture `matrix_exit_code=$?` without aborting the job before later steps, persist that saved code for later steps, render the site, verify it, upload `artifacts/` and `site/`, and fail only after artifact upload by exiting with the saved aggregate `matrix_exit_code` when it is non-zero.
- Every secret-gated job must begin with `rm -rf .work/ports artifacts site`.
- Create `.github/workflows/pages.yml` with:
  - triggers on `push` to `main` and `workflow_dispatch`
  - top-level `permissions` for `contents: read`, `pages: write`, and `id-token: write`
  - `build` job that validates secrets, runs the same remote-tag reachability check, stages the full manifest, runs the full matrix, captures `matrix_exit_code=$?` without aborting the job, renders the site, verifies it, uploads the Pages artifact, exports `matrix_exit_code` as a job output, and still exits successfully so publication can continue
  - `deploy` job using `actions/deploy-pages`
  - `report-status` job that depends on both `build` and `deploy`, runs only after deployment finishes, and fails if `matrix_exit_code` is non-zero
- Implement `scripts/publish-public.sh` so it:
  - resolves auth with the same `GH_TOKEN` then `SAFELIBS_REPO_TOKEN` rule as `tools/github_auth.py`; if only `SAFELIBS_REPO_TOKEN` is set, export `GH_TOKEN` from it before running `gh`
  - if neither env var is set, rely on the caller's existing local authenticated session and fail clearly if private tag inspection or repo creation auth is unavailable
  - runs `python3 tools/inventory.py --config repositories.yml --check-remote-tags`
  - creates `safelibs/validator` as a public repo if it does not exist
  - fails if an existing `safelibs/validator` repo is not public
  - reconciles the local `origin` remote
  - pushes `main`
  - leaves the repository in a state where `gh repo view safelibs/validator --json visibility,nameWithOwner,url` reports `visibility=PUBLIC`, `git remote get-url origin` resolves to `safelibs/validator`, and `git ls-remote --heads origin main` matches `git rev-parse HEAD`
- Treat the currently checked-in `.plan/workflow-structure.yaml` and `.plan/phases/*.md`, plus any existing worktree `workflow.yaml`, as stale phase-06 deliverables that must be replaced before the repo is published. Do not assume `workflow.yaml` already exists in a clean checkout; phase 06 must create and commit the tracked file. Do not leave the old seven-phase files in the tree and expect reviewers to infer the intended workflow from `.plan/plan.md`.
- Regenerate `.plan/workflow-structure.yaml`, `workflow.yaml`, and the six phase documents under `.plan/phases/` so the checked-in generated workflow artifacts exactly match this plan's topology, filenames, verifier wiring, and tagged-only implementation contract.
- Rewrite every kept generated phase document in place, including same-name files that already exist under stale content, then stage the exact final generated-file set in git before the phase-06 commit. A partial rename that leaves old prompt bodies in `.plan/phases/01-inventory-scaffold.md`, `.plan/phases/04-media-validators.md`, `.plan/workflow-structure.yaml`, or `workflow.yaml` is still wrong.
- The regenerated workflow artifacts must explicitly encode the scoped 19-library tagged-only model, exact `inventory.tag_probe_rule`, exact `validator.imports`, all-empty `validator.import_excludes`, the mature tagged handling of `libexif` and `libuv`, the fixed `tests/<library>/tests/run.sh` runtime contract, the exact `--safe-deb-root` host layout `<safe-deb-root>/<library>/*.deb` mounted as `/safedebs`, the exact phase-03/04/05 batch lists from this plan, and the exact sentence `Commit all phase work to git before yielding.` exactly once in each implement prompt and the corresponding kept phase document. Renaming stale seven-phase bootstrap artifacts without rewriting their prompts is a failure.
- The regenerated workflow artifacts must not carry stale prompt content for `glib`, `libc6`, `libcurl`, `libgcrypt`, or `libjansson` in any stage/import/test command, harness path, or manifest-scope list.
- Delete `.plan/phases/02-shared-matrix-reporting.md`, `.plan/phases/03-text-data-validators.md`, `.plan/phases/05-archive-system-validators.md`, `.plan/phases/06-bootstrap-missing-validators.md`, and `.plan/phases/07-ci-pages-publish.md` in the same phase-06 commit that regenerates the six kept phase documents.
- Update `Makefile` so `publish-public` wraps `scripts/publish-public.sh`.
- Update `README.md` from the current vision-only text to an operator guide that documents prerequisites, local commands, artifact locations, the private-repo auth contract (`GH_TOKEN` or `SAFELIBS_REPO_TOKEN`), optional `--source-root`, the exact optional `--safe-deb-root` layout `<safe-deb-root>/<library>/*.deb`, `make publish-public`, and Pages publication.
- Do not add any source-ref publication or tag-push tooling in this phase. The manifest already depends only on published remote `04-test` tags.

**Verification**

- Run both `check_06_full_matrix` and `check_06_release_review`.
- Treat any CI or Pages workflow that depends on unpublished local refs, omits the `preflight` token/output gate, leaves `unit-tests` undefined, secret-gated, or dependent on `/home/yans/safelibs`, live GitHub, or private tags, fails to make `matrix-smoke` and `full-matrix` depend on `unit-tests`, widens or changes the fixed `matrix-smoke` library subset, lets `full-matrix` or Pages `build` stop before render/verify/upload on a non-zero aggregate matrix exit, misses the Pages trigger/permissions/`actions/deploy-pages`/`report-status` contract, lets `report-status` run before `deploy`, fails the Pages `build` job on `matrix_exit_code` before publication, relies on SSH or `gh auth setup-git` for private `port-*` access, omits the README operator guide or `publish-public` Makefile target, reintroduces publication-tag tooling, lets `workflow.yaml` drift from the kept phase docs on the tagged-only six-phase contract, or leaves any mismatch between rendered site coverage and matrix outputs as failure.

## Critical Files

- `README.md`: replace the placeholder vision-only text with a real operator guide, prerequisites, local commands, artifact layout, the private-repo auth contract via `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`, the exact `--safe-deb-root` layout `<safe-deb-root>/<library>/*.deb`, publication steps, and Pages notes.
- `.gitignore`: ignore `.work/`, `artifacts/`, `site/`, and other scratch paths while preserving tracked validator fixtures and inventory artifacts.
- `Makefile`: stable entrypoints for inventory capture, staging, safe builds, matrix runs, site rendering, verification, cleanup, and public-repo publication.
- `inventory/github-repo-list.json`: checked-in raw `gh repo list safelibs` snapshot.
- `inventory/github-port-repos.json`: checked-in filtered tagged `port-*` snapshot, sorted by `library` and storing exactly `library`, `nameWithOwner`, `url`, `default_branch`, and `tag_ref` for each selected library.
- `repositories.yml`: central manifest containing archive metadata, checked-in inventory proof, `inventory.tag_probe_rule: refs/tags/{library}/04-test`, the dynamically selected tagged library set, copied `apt-repo` build metadata, validator-owned `libexif` and `libuv` entries, exact per-library import lists, uniform `fixtures.dependents.source` and `fixtures.relevant_cves.source` mappings on every entry, and the required all-empty `validator.import_excludes` lists.
- `tools/github_auth.py`: shared GitHub auth helper that resolves `GH_TOKEN` then `SAFELIBS_REPO_TOKEN`, emits token-authenticated HTTPS git URLs when a token exists and SSH git URLs only for local fallback, and makes git auth failures non-interactive.
- `tools/inventory.py`: GitHub inventory loading, dynamic tagged-scope selection, manifest generation, and remote-tag reachability checks.
- `tools/stage_port_repos.py`: non-destructive clean staging from local sibling repos or remote GitHub clones at the manifest's tag refs, including sibling-clone cases that must fetch missing tags from the manifest GitHub remote rather than the inherited local-path `origin`.
- `tools/build_safe_debs.py`: build dispatcher with the fixed `--config --library --port-root --workspace --output` CLI for `safe-debian`, `checkout-artifacts`, and `docker`, including omitted-mode default-to-`docker` and scratch-copy builds that do not mutate the staged checkout under `--port-root`.
- `tools/import_port_assets.py`: manifest-driven importer that copies only declared tracked inputs from staged tags into canonical validator destinations and mirrors manifest-declared tag paths under `tests/<library>/tests/tagged-port/`.
- `tools/verify_imported_assets.py`: shared verifier that compares validator-side fixtures, harness-source files, and mirrored `tests/tagged-port/` imports against freshly staged manifest refs byte-for-byte.
- `tools/run_matrix.py`: matrix orchestration, matrix-root safe-deb source selection via `<safe-deb-root>/<library>/*.deb`, per-run result emission, aggregate failure-tolerant execution that finishes the requested matrix before returning a final non-zero exit, and safe-mode cast capture.
- `tools/render_site.py`: report rendering and cast publication into `site/`.
- `scripts/verify-site.sh`: verification that the static site matches the matrix results and artifact paths exactly.
- `.plan/workflow-structure.yaml`, the exact six phase documents under `.plan/phases/`, and tracked `workflow.yaml`: regenerated workflow artifacts that must match this exact 6-phase tagged-only contract, replace the stale bootstrap-era artifacts in place, rewrite same-name stale files instead of preserving them, carry the exact commit-before-yield sentence in every implement prompt, and become the exact tracked generated-file set in git.
- `.github/workflows/ci.yml`: CI on `push` and `pull_request` with hermetic secret-free `unit-tests`, `preflight`, a representative smoke matrix that depends on both, and a full matrix that captures one aggregate `matrix_exit_code` only after the runner finishes.
- `.github/workflows/pages.yml`: Pages build, deploy, and status reporting on the full matrix.
- `scripts/publish-public.sh`: public-repo creation, `origin` reconciliation, and push flow for `safelibs/validator`.
- `tests/_shared/install_safe_debs.sh` and `tests/_shared/run_library_tests.sh`: shared runtime contract that every library entrypoint must reuse, with installation delegated to `tests/_shared/install_safe_debs.sh` before dispatching through `tests/_shared/run_library_tests.sh` to `tests/<library>/tests/run.sh`.
- `tests/<library>/**` for all 19 selected libraries: validator-owned Docker harnesses, copied fixtures, mirrored tagged inputs under `tests/tagged-port/`, validator-owned `tests/run.sh`, and validator-owned tests.

## Exit Criteria

The implementation passes only if:

- `repositories.yml` and `inventory/github-port-repos.json` contain exactly the `port-*` repos whose remote exposes `refs/tags/<library>/04-test` at implementation time, and they exclude `glib`, `libc6`, `libcurl`, `libgcrypt`, and `libjansson` until those repos publish `04-test`.
- `inventory/github-port-repos.json` is sorted by `library`, each row contains exactly `library`, `nameWithOwner`, `url`, `default_branch`, and `tag_ref`, and `repositories.yml` preserves the top-level `archive` mapping from `/home/yans/safelibs/apt-repo/repositories.yml`.
- `repositories.yml` contains `inventory.tag_probe_rule: refs/tags/{library}/04-test`, every manifest entry uses `ref: inventory.tag_probe_rule.format(library=<entry name>)`, every manifest entry sets `fixtures.dependents.source: copy-staged-root` and `fixtures.relevant_cves.source: copy-staged-root`, and `python3 tools/inventory.py --config repositories.yml --check-remote-tags` succeeds.
- Validator automation resolves private-repo auth by preferring `GH_TOKEN` and falling back to `SAFELIBS_REPO_TOKEN`; CI and Pages export both from the same secret, private git operations use token-authenticated HTTPS URLs derived from `github_repo`, and no workflow depends on SSH keys or `gh auth setup-git`.
- Every manifest entry defines an exact `validator.imports` list, every manifest entry sets `validator.import_excludes: []`, validator does not use `validator.import_roots`, and `liblzma` splits `safe/tests` into exact imported subpaths instead of importing `safe/tests` wholesale.
- When staging from `/home/yans/safelibs/port-*`, any missing manifest tag is fetched from the manifest's GitHub repository into the detached clone rather than from the inherited local-path `origin`, and `libuv` proves that path works.
- `tools/build_safe_debs.py` uses the fixed `--config --library --port-root --workspace --output` CLI, copies `<port-root>/<library>/` into build scratch before running setup or build commands, and leaves the staged checkout clean after each build.
- `tools/verify_imported_assets.py` proves, in phase 01 and again in phases 03 through 06 against freshly staged checkouts, that copied fixtures under `tests/<library>/tests/fixtures/`, copied harness-source files under `tests/<library>/tests/harness-source/`, and mirrored tag inputs under `tests/<library>/tests/tagged-port/` preserve the staged tag's relative paths and remain byte-for-byte copies of the manifest-declared sources.
- No `dependents.json` or `relevant_cves.json` is regenerated inside validator for this scoped plan.
- Every selected library has a validator-owned Docker harness, a validator-owned `tests/<library>/tests/run.sh`, a validator-owned `docker-entrypoint.sh` that reuses `tests/_shared/install_safe_debs.sh` before `tests/_shared/run_library_tests.sh`, runs in both original and safe mode through that shared contract, and emits explicit result JSON plus a safe-mode cast.
- The shared runner exposes library identity and paths to `tests/<library>/tests/run.sh`, but it does not expose an explicit safe/original mode selector such as `VALIDATOR_MODE`.
- `test.sh` and `tools/run_matrix.py` treat `--safe-deb-root` only as a matrix root with layout `<safe-deb-root>/<library>/*.deb`, mount the selected leaf as `/safedebs`, and reject a single-library leaf passed directly as `--safe-deb-root`.
- `test.sh` and `tools/run_matrix.py` attempt every requested library/mode run in order, continue after individual failures, emit one result JSON per attempted run, and return one aggregate non-zero exit only after the requested matrix completes when any attempted run failed.
- Safe-mode runs execute under `bash -x`.
- The rendered site covers the same library/mode matrix as `artifacts/results/`.
- `.github/workflows/ci.yml` and `.github/workflows/pages.yml` stage only manifest-declared remote tags and do not depend on unpublished local refs.
- `.github/workflows/ci.yml` triggers on `push` and `pull_request`, defines a hermetic secret-free `unit-tests` job running `python3 -m unittest discover -s unit -v` without `/home/yans/safelibs`, live GitHub, or private-tag dependencies, and makes both `matrix-smoke` and `full-matrix` depend on `preflight` and `unit-tests`.
- `.github/workflows/pages.yml` publishes from `build` to `deploy` first, and only then lets `report-status` fail on a non-zero `matrix_exit_code`; `report-status` must depend on both `build` and `deploy`.
- `.plan/workflow-structure.yaml`, the exact six kept phase documents under `.plan/phases/`, and tracked `workflow.yaml` all encode the exact 6-phase tagged-only contract from this file, use only the renamed six-document phase set, carry `inventory.tag_probe_rule`, `validator.imports`, `validator.import_excludes`, the exact `--safe-deb-root` layout `<safe-deb-root>/<library>/*.deb` mounted as `/safedebs`, carry the exact phase-03/04/05 library batches from this plan, include `Commit all phase work to git before yielding.` once per implement prompt in both `workflow.yaml` and the kept phase docs, and contain no stale seven-phase/bootstrap contract terms or out-of-scope library scope such as `source-debian-original`, `+validatorbootstrap1`, `validator.runtime_fixture_paths`, `tests/glib/`, or `port-libcurl`.
- `git ls-files .plan/phases .plan/workflow-structure.yaml workflow.yaml` resolves to exactly the six kept phase documents, `.plan/workflow-structure.yaml`, and tracked `workflow.yaml`; no obsolete generated workflow file remains tracked or present in the worktree under its old name.
- `scripts/publish-public.sh` creates or reuses a public `safelibs/validator` repo, reconciles local `origin` to that repo, and leaves `origin` advertising `refs/heads/main` at the local `HEAD` commit.
- The final repository does not contain `inventory/non-apt-ref-status.json`, `validator.publication_tag`, `tools/publish_source_refs.py`, or any source-ref publication step.

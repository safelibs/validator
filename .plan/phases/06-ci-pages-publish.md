# Phase 06

**Phase Name**

`ci-pages-publish`

**Implement Phase ID**

`impl_06_ci_pages_publish`

**Preexisting Inputs**

- `.gitignore`
- `README.md`
- `Makefile`
- `inventory/`
- `repositories.yml`
- `tools/`
- `test.sh`
- `scripts/verify-site.sh`
- `tests/`
- `unit/`
- `.plan/plan.md`
- stale generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`
- any existing worktree `workflow.yaml`
- `/home/yans/safelibs/apt-repo/.github/workflows/ci.yml`
- `/home/yans/safelibs/apt-repo/.github/workflows/pages.yml`
- `/home/yans/safelibs/apt-repo/scripts/verify-in-ubuntu-docker.sh`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`
- authenticated GitHub access with permission to inspect private `port-*` repos and create `safelibs/validator`, provided by an existing local login or by `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`

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

**File Changes**

- Create `.github/workflows/ci.yml` and `.github/workflows/pages.yml`.
- Rewrite `.plan/workflow-structure.yaml` and the six kept phase documents under `.plan/phases/`.
- Create tracked `workflow.yaml` and `scripts/publish-public.sh`.
- Update `README.md` and `Makefile`.
- Delete `.plan/phases/02-shared-matrix-reporting.md`, `.plan/phases/03-text-data-validators.md`, `.plan/phases/05-archive-system-validators.md`, `.plan/phases/06-bootstrap-missing-validators.md`, and `.plan/phases/07-ci-pages-publish.md`.
- Create or reuse the public GitHub repo `safelibs/validator` and reconcile `origin`.

**Implementation Details**

- Every workflow job or script step that may touch private `port-*` repos must use the shared auth contract:
  - set both `GH_TOKEN` and `SAFELIBS_REPO_TOKEN` from `${{ secrets.SAFELIBS_REPO_TOKEN }}` in GitHub Actions before invoking `gh`, `tools/inventory.py`, or `tools/stage_port_repos.py`
  - let the tools perform git access through token-authenticated HTTPS URLs derived from `github_repo`
  - do not rely on SSH keys, inherited local developer auth state, or `gh auth setup-git`
- Create `.github/workflows/ci.yml` on Ubuntu 24.04 with four jobs:
  - `preflight`
  - `unit-tests`
  - `matrix-smoke`
  - `full-matrix`
- The CI workflow must trigger on both `push` and `pull_request`.
- `preflight` must:
  - detect whether the effective token is present by checking `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`
  - when the token is present, run `python3 tools/inventory.py --config repositories.yml --check-remote-tags`
  - when the token is absent, skip remote-tag probing, report `remote_tags_ok=false`, and still succeed so public pull requests can reach `unit-tests`
  - expose booleans `has_repo_token` and `remote_tags_ok`
- `unit-tests` must:
  - run `python3 -m unittest discover -s unit -v`
  - avoid `GH_TOKEN`, `SAFELIBS_REPO_TOKEN`, `gh`, and `tools/stage_port_repos.py`
  - depend only on checked-in unit fixtures plus temporary directories or repositories created during the test run
  - run on every CI trigger regardless of whether `preflight` found a token
- `matrix-smoke` and `full-matrix` must both depend on `preflight` and `unit-tests`.
- `matrix-smoke` must run only when preflight succeeds and must stage and run exactly:
  - `giflib`
  - `libpng`
  - `libjson`
  - `libvips`
  - `libuv`
- That fixed subset must cover `safe-debian`, `checkout-artifacts`, omitted-mode default-to-`docker`, explicit `docker`, and non-`apt-repo` tagged `safe-debian`.
- `matrix-smoke` and `full-matrix` must touch private staging only when both `has_repo_token` and `remote_tags_ok` are `true`.
- `matrix-smoke` may fail on the aggregate exit code from `bash test.sh`, but because `test.sh` is aggregate, that non-zero exit may only happen after the smoke subset completes.
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
- Treat the currently checked-in `.plan/workflow-structure.yaml` and `.plan/phases/*.md`, plus any existing worktree `workflow.yaml`, as stale phase-06 deliverables that must be replaced before the repo is published.
- Regenerate `.plan/workflow-structure.yaml`, `workflow.yaml`, and the six phase documents under `.plan/phases/` so the checked-in generated workflow artifacts exactly match this plan's topology, filenames, verifier wiring, and tagged-only implementation contract.
- Rewrite every kept generated phase document in place, including same-name files that already exist under stale content, then stage the exact final generated-file set in git before the phase-06 commit.
- The regenerated workflow artifacts must explicitly encode:
  - the scoped 19-library tagged-only model
  - `inventory.tag_probe_rule: refs/tags/{library}/04-test`
  - the exact per-library `validator.imports` lists from `Fixed Library Contract`
  - all-empty `validator.import_excludes`
  - the mature tagged handling of `libexif` and `libuv`
  - the exact per-library `tests/<library>/tests/run.sh` runtime bullets from `Fixed Library Contract`
  - the exact `--safe-deb-root` host layout `<safe-deb-root>/<library>/*.deb` mounted as `/safedebs`
  - the exact phase-03, phase-04, and phase-05 batch lists from this plan
  - the required commit-before-yield sentence exactly once in each implement prompt and the corresponding kept phase document
- The regenerated workflow artifacts must not carry stale prompt content for `glib`, `libc6`, `libcurl`, `libgcrypt`, or `libjansson` in any stage, import, test command, harness path, or manifest-scope list.
- Delete the obsolete generated phase documents in the same phase-06 commit that regenerates the kept phase documents.
- Update `Makefile` so `publish-public` wraps `scripts/publish-public.sh`.
- Update `README.md` from the current vision-only text to an operator guide that documents prerequisites, local commands, artifact locations, the private-repo auth contract (`GH_TOKEN` or `SAFELIBS_REPO_TOKEN`), optional `--source-root`, the exact optional `--safe-deb-root` layout `<safe-deb-root>/<library>/*.deb`, `make publish-public`, and Pages publication.
- Do not add any source-ref publication or tag-push tooling in this phase.

**Verification Phases**

- `check_06_full_matrix`
  - type: `check`
  - fixed `bounce_target`: `impl_06_ci_pages_publish`
  - purpose: run the full validator locally against the checked-in tagged scope, render the site, and verify the full output set plus imported-asset fidelity across all selected libraries.
  - commands:
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
  - purpose: review CI/Pages workflows, README and Makefile operator contracts, public-repo publication logic, enforced public visibility and `origin` reconciliation, remote-tag reachability checks, and the final generated workflow artifacts so `workflow.yaml` and the kept phase docs carry the same tagged-only six-phase contract.
  - commands:
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
      commit_sentence = "Commit all phase work to git before " + "yielding."
      preexisting_heading = "**Preexisting " + "Inputs**"
      new_outputs_heading = "**New " + "Outputs**"
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
          if text.count(preexisting_heading) != 1 or text.count(new_outputs_heading) != 1:
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
          "safe/generated/noninteractive_test_list.json",
          "safe/test-extra",
          "safe/scripts/run-dependent-matrix.sh",
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

**Success Criteria**

- Both `check_06_full_matrix` and `check_06_release_review` pass.
- CI and Pages workflows enforce the shared private-repo auth contract, keep `unit-tests` hermetic and secret-free, gate secret-requiring jobs through `preflight`, preserve aggregate matrix behavior, and publish Pages before `report-status` fails on a non-zero `matrix_exit_code`.
- `scripts/publish-public.sh`, `README.md`, and `Makefile` reflect the operator contract for local runs, exact `<safe-deb-root>/<library>/*.deb` layout, remote-tag verification, public-repo publication, and Pages deployment.
- `.plan/workflow-structure.yaml`, the six kept phase docs, and `workflow.yaml` all encode the same tagged-only six-phase contract, exact verifier wiring, exact phase batches, exact `validator.imports` and `tests/<library>/tests/run.sh` runtime bullets, and no stale seven-phase or out-of-scope library content.
- The final repository leaves no obsolete generated workflow file in the worktree or index, does not reintroduce publication-tag tooling, and leaves `origin` advertising `refs/heads/main` at local `HEAD`.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

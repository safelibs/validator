# Phase 01

**Phase Name**

`inventory-scaffold`

**Implement Phase ID**

`impl_01_inventory_scaffold`

**Preexisting Inputs**

- `.plan/plan.md`
- stale generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, for reference only
- `README.md`
- `/home/yans/safelibs/apt-repo/repositories.yml`
- `/home/yans/safelibs/apt-repo/tools/build_site.py`
- `/home/yans/safelibs/apt-repo/tests/test_build_site.py`
- sibling `port-*` clone sources under `/home/yans/safelibs/`
- authenticated GitHub access for private `port-*` repos, provided by an existing local login or an effective token from `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`

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

**File Changes**

- Create `.gitignore` and `Makefile`.
- Create the checked-in inventory artifacts `inventory/github-repo-list.json`, `inventory/github-port-repos.json`, and `repositories.yml`.
- Create shared auth, inventory, staging, safe-build, import, and fidelity-verification tooling under `tools/`.
- Create hermetic unit coverage for inventory, staging, safe-build, import, and fidelity verification under `unit/`.

**Implementation Details**

- Treat the currently checked-in generated workflow artifacts under `.plan/phases/*.md` and `.plan/workflow-structure.yaml`, plus any existing worktree `workflow.yaml`, as stale reference inputs during phases 01 through 05.
- Do not rewrite, rename, delete, or stage changes to those generated workflow artifacts in this phase; only phase 06 may replace the generated workflow file set.
- Phase 01 is the only phase allowed to query live GitHub state to define scope.
- Create `inventory/github-repo-list.json` as the checked-in raw output of `gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef`.
- Create `inventory/github-port-repos.json` as the checked-in filtered subset of only those `port-*` repos whose remote exposes `refs/tags/<library>/04-test`. The file must be sorted by `library`, and each row must contain exactly `library`, `nameWithOwner`, `url`, `default_branch`, and `tag_ref`.
- Create `repositories.yml` as validator's canonical manifest by extending the `apt-repo` schema instead of replacing it. Preserve the top-level `archive` mapping from `/home/yans/safelibs/apt-repo/repositories.yml`, then add:
  - an `inventory` mapping with `verified_at`, `gh_repo_list_command`, `tag_probe_rule`, `raw_snapshot`, `filtered_snapshot`, `goal_repo_family`, and `verified_repo_family`
  - the exact literal `inventory.tag_probe_rule: refs/tags/{library}/04-test`
  - a `repositories` list in sorted library order from `inventory/github-port-repos.json`
- Preserve both repo-family facts in checked-in inventory:
  - `goal_repo_family: repos-*`
  - `verified_repo_family: port-*`
- Copy `github_repo`, optional `verify_packages`, and the full `build` mapping verbatim from `/home/yans/safelibs/apt-repo/repositories.yml` for the 17 selected libraries already present there.
- Add validator-owned manifest entries only for `libexif` and `libuv`, with:
  - `github_repo: safelibs/port-<library>`
  - `ref: refs/tags/<library>/04-test`
  - `build: {mode: safe-debian, artifact_globs: ["*.deb"]}`
  - `validator.sibling_repo: port-<library>`
  - `validator.imports`
  - `validator.import_excludes`
  - `fixtures.dependents.source: copy-staged-root`
  - `fixtures.relevant_cves.source: copy-staged-root`
- Add `validator.sibling_repo`, `validator.imports`, `validator.import_excludes`, `fixtures.dependents.source: copy-staged-root`, and `fixtures.relevant_cves.source: copy-staged-root` to every manifest entry.
- Write the exact `validator.imports` mapping below into `repositories.yml`, keep every list in the listed order, and set `validator.import_excludes: []` for every entry:
  - `cjson`: `safe/tests`, `safe/scripts`, `original/tests`, `original/fuzzing`, `original/test.c`, `original/cJSON.h`, `original/cJSON_Utils.h`
  - `giflib`: `safe/tests`, `original/tests`, `original/pic`, `original/gif_lib.h`
  - `libarchive`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `safe/generated/api_inventory.json`, `safe/generated/cve_matrix.json`, `safe/generated/link_compat_manifest.json`, `safe/generated/original_build_contract.json`, `safe/generated/original_package_metadata.json`, `safe/generated/original_c_build`, `safe/generated/original_link_objects`, `safe/generated/original_pkgconfig/libarchive.pc`, `safe/generated/pkgconfig/libarchive.pc`, `safe/generated/rust_test_manifest.json`, `safe/generated/test_manifest.json`, `original/libarchive-3.7.2`
  - `libbz2`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
  - `libcsv`: `safe/tests`, `safe/debian/tests`, `original/examples`, `original/test_csv.c`, `original/csv.h`
  - `libexif`: `safe/tests`, `original/libexif`, `original/test`, `original/contrib/examples`
  - `libjpeg-turbo`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/testimages`
  - `libjson`: `safe/tests`, `safe/debian/tests`
  - `liblzma`: `safe/docker`, `safe/scripts`, `safe/tests/dependents`, `safe/tests/extra`, `safe/tests/upstream`
  - `libpng`: `safe/tests`, `original/tests`, `original/contrib/pngsuite`, `original/contrib/testpngs`, `original/png.h`, `original/pngconf.h`, `original/pngtest.png`
  - `libsdl`: `safe/tests`, `safe/debian/tests`, `safe/generated/dependent_regression_manifest.json`, `safe/generated/noninteractive_test_list.json`, `safe/generated/original_test_port_map.json`, `safe/generated/perf_workload_manifest.json`, `safe/generated/perf_thresholds.json`, `safe/generated/reports/perf-baseline-vs-safe.json`, `safe/generated/reports/perf-waivers.md`, `safe/upstream-tests`, `original/test`
  - `libsodium`: `safe/tests`, `safe/docker`
  - `libtiff`: `safe/test`, `safe/scripts`, `original/test`
  - `libuv`: `safe/docker`, `safe/include`, `safe/prebuilt`, `safe/scripts`, `safe/test`, `safe/test-extra`
  - `libvips`: `safe/tests/dependents`, `safe/tests/upstream`, `safe/vendor/pyvips-3.1.1`, `original/test`, `original/examples`
  - `libwebp`: `safe/tests`, `original/examples`, `original/tests/public_api_test.c`
  - `libxml`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original`
  - `libyaml`: `safe/tests`, `safe/debian/tests`, `safe/scripts`, `original/include`, `original/tests`, `original/examples`
  - `libzstd`: `safe/tests`, `safe/debian/tests`, `safe/docker`, `safe/scripts`, `original/libzstd-1.5.5+dfsg2`
- `tools/github_auth.py` must centralize private GitHub access. It must:
  - resolve an effective token by preferring `GH_TOKEN` and falling back to `SAFELIBS_REPO_TOKEN`
  - export a helper named `github_git_url` that turns `github_repo` into a token-authenticated HTTPS URL when a token exists and `git@github.com:<github_repo>.git` only for local interactive fallback
  - ensure git subprocesses run with `GIT_TERMINAL_PROMPT=0`
- `tools/inventory.py` must provide manifest loading, GitHub inventory loading, tagged-scope selection, `apt-repo` metadata merge, and a reusable remote-tag reachability check. The minimum CLI modes are:
  - generate mode: `--github-json <path> --apt-config <path> --write-filtered <path> --write-config <path> [--verify-scope]`
  - remote-tag check mode: `--config <path> --check-remote-tags`
- `--verify-scope` is a real generate-mode self-check. It must fail if the filtered scope or manifest diverges from the tagged subset implied by the supplied raw snapshot, if the filtered JSON schema or ordering is wrong, if `inventory` metadata is incomplete, or if manifest entries do not use `ref: inventory.tag_probe_rule.format(library=<entry name>)`.
- `tools/inventory.py --check-remote-tags` must require `--config`, iterate manifest entries in manifest order, derive each expected ref from `inventory.tag_probe_rule`, probe the matching private repo with `tools/github_auth.py`, and exit non-zero if any manifest tag is unreachable.
- `tools/stage_port_repos.py` must stage clean detached clones under `.work/` with CLI `--config <path> --workspace <path> --dest-root <path> [--source-root <path>] [--libraries <library> ...]`.
  - `--dest-root` is always a root directory, and each staged checkout must land at `<dest-root>/<library>/`
  - omit `--libraries` to stage every manifest library in manifest order
  - use `tools/github_auth.py` for every remote clone or fetch
  - with `--source-root /home/yans/safelibs`, clone from the sibling repo without touching the live worktree
  - if the detached clone created from `--source-root` does not already contain the manifest tag, fetch only that exact tag from the manifest GitHub repo instead of relying on the inherited local-path `origin`
  - without `--source-root`, clone from the manifest GitHub repo and check out the manifest tag
  - fail deterministically if the manifest tag cannot be checked out
- `tools/build_safe_debs.py` must adapt the `apt-repo` build dispatcher from `/home/yans/safelibs/apt-repo/tools/build_site.py` without destructive resets. Its fixed CLI is `--config <path> --library <name> --port-root <path> --workspace <path> --output <path>`.
  - support `safe-debian`, `checkout-artifacts`, explicit `docker`, and omitted `build.mode` behaving like `docker`
  - copy `<port-root>/<library>/` into per-library scratch under `--workspace` before running setup or build commands
  - recreate `--output` on each run and leave resulting `.deb` files directly under that path
  - preserve `SAFEAPTREPO_SOURCE`, `SAFEAPTREPO_OUTPUT`, `SAFEDEBREPO_SOURCE`, and `SAFEDEBREPO_OUTPUT`
  - fail when the library is missing, the staged checkout is missing, the configured workdir is missing, the build mode is unsupported, or no declared artifacts are produced
- `tools/import_port_assets.py` must copy only declared tracked inputs from the staged tag checkout with CLI `--config <path> --library <name> --port-root <path> --workspace <path> [--dest-root <path>]`.
  - `--dest-root` defaults to `.`
  - always write imports under `<dest-root>/tests/<library>/...`
  - copy `dependents.json` and `relevant_cves.json` into `tests/<library>/tests/fixtures/`
  - copy `test-original.sh` into `tests/<library>/tests/harness-source/original-test-script.sh`
  - copy `safe/debian/control` into `tests/<library>/tests/harness-source/debian/control`
  - mirror every manifest-declared `validator.imports` path under `tests/<library>/tests/tagged-port/<source>`
  - keep every other imported tracked path under `tests/<library>/tests/tagged-port/`
  - preserve imported files byte-for-byte
- `tools/verify_imported_assets.py` must be the shared fidelity checker reused by phases 01 and 03 through 06. Its CLI is `--config <path> --port-root <path> [--tests-root <path>] [--libraries <library> ...]`.
  - compare fixtures, harness-source files, and every manifest-declared mirrored import path byte-for-byte against the staged checkout
  - require `tests/<library>/tests/fixtures/` to contain exactly `dependents.json` and `relevant_cves.json`
  - require `tests/<library>/tests/harness-source/` to contain exactly `original-test-script.sh` and `debian/control`
  - require `tests/<library>/tests/tagged-port/` to contain exactly the expanded manifest-declared mirrored tree and nothing else
  - fail on missing files, content drift, or extra imported files
- Keep all phase-01 `unit/` tests hermetic and secret-free. They must use only checked-in fixtures plus temporary directories, temporary git repositories, temporary bare remotes, and mocks created inside the test process. They must not shell out to `gh`, read `/home/yans/safelibs`, contact live GitHub, or require `GH_TOKEN` or `SAFELIBS_REPO_TOKEN`.
- `unit/test_stage_port_repos.py` must model both a `libexif`-shaped sibling clone that already has the tag locally and a `libuv`-shaped sibling clone that does not, using temporary fixture repos and a temporary bare remote created during the test.
- `unit/test_build_safe_debs.py` must cover `safe-debian`, `checkout-artifacts`, explicit `docker`, omitted-mode default-to-`docker`, and the requirement that the staged checkout under `--port-root/<library>/` remains clean.
- `unit/test_verify_imported_assets.py` must cover file imports, directory imports, extra-file detection under `tests/tagged-port`, extra-file detection under `tests/fixtures` and `tests/harness-source`, and harness-source or fixture drift.
- Use global import exclusions for `.git/`, `.pc/`, `__pycache__/`, `node_modules/`, `.libs/`, `build/`, `build-*`, `.checker-build*`, `config.log`, `config.status`, `*.deb`, `*.ddeb`, and `*.udeb`. Keep this list tool-owned instead of copying it into `validator.import_excludes`.
- Create `Makefile` targets for at least `unit`, `inventory`, `stage-ports`, `build-safe`, `import-assets`, and `clean`.

**Verification Phases**

- `check_01_inventory_scaffold_smoke`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: verify hermetic phase-01 unit coverage, live `04-test` scope selection, clean local and remote tag staging, exact-tag fetch behavior, non-mutating build coverage, and tag-rooted asset imports.
  - commands:
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
    - `test -f .work/check01/imported/tests/libsdl/tests/tagged-port/safe/generated/noninteractive_test_list.json`
    - `test -f .work/check01/imported/tests/libsdl/tests/tagged-port/safe/generated/original_test_port_map.json`
    - `test -f .work/check01/imported/tests/libsdl/tests/tagged-port/safe/upstream-tests/installed-tests/debian/tests/installed-tests`
    - `test -f .work/check01/imported/tests/libzstd/tests/tagged-port/safe/scripts/run-full-suite.sh`
    - `test -f .work/check01/imported/tests/libzstd/tests/tagged-port/original/libzstd-1.5.5+dfsg2/tests/Makefile`
    - `find .work/check01/imported/tests/libvips/tests/tagged-port/safe/vendor -type f | grep -q .`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/docker/dependents.Dockerfile`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/include/uv.h`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/prebuilt/x86_64-unknown-linux-gnu/libuv_safe_runtime_support.a`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/test/run-tests.c`
    - `test -f .work/check01/imported/tests/libuv/tests/tagged-port/safe/test-extra/run-regressions.c`
    - `cmp -s .work/check01/imported/tests/libexif/tests/fixtures/relevant_cves.json .work/check01/ports/libexif/relevant_cves.json`
    - `cmp -s .work/check01/imported/tests/libuv/tests/fixtures/dependents.json .work/check01/ports/libuv/dependents.json`
- `check_01_inventory_scaffold_review`
  - type: `check`
  - fixed `bounce_target`: `impl_01_inventory_scaffold`
  - purpose: review the checked-in 19-library tagged snapshot, filtered inventory schema and ordering, fixed `inventory.tag_probe_rule`, preserved `archive` metadata, copied `apt-repo` build metadata, uniform fixture mappings, exact per-library `validator.imports`, all-empty `validator.import_excludes`, and the absence of the obsolete publication-tag model.
  - commands:
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

      expected_imports = {
          "cjson": [
              "safe/tests",
              "safe/scripts",
              "original/tests",
              "original/fuzzing",
              "original/test.c",
              "original/cJSON.h",
              "original/cJSON_Utils.h",
          ],
          "giflib": [
              "safe/tests",
              "original/tests",
              "original/pic",
              "original/gif_lib.h",
          ],
          "libarchive": [
              "safe/tests",
              "safe/debian/tests",
              "safe/scripts",
              "safe/generated/api_inventory.json",
              "safe/generated/cve_matrix.json",
              "safe/generated/link_compat_manifest.json",
              "safe/generated/original_build_contract.json",
              "safe/generated/original_package_metadata.json",
              "safe/generated/original_c_build",
              "safe/generated/original_link_objects",
              "safe/generated/original_pkgconfig/libarchive.pc",
              "safe/generated/pkgconfig/libarchive.pc",
              "safe/generated/rust_test_manifest.json",
              "safe/generated/test_manifest.json",
              "original/libarchive-3.7.2",
          ],
          "libbz2": [
              "safe/tests",
              "safe/debian/tests",
              "safe/scripts",
              "original",
          ],
          "libcsv": [
              "safe/tests",
              "safe/debian/tests",
              "original/examples",
              "original/test_csv.c",
              "original/csv.h",
          ],
          "libexif": [
              "safe/tests",
              "original/libexif",
              "original/test",
              "original/contrib/examples",
          ],
          "libjpeg-turbo": [
              "safe/tests",
              "safe/debian/tests",
              "safe/scripts",
              "original/testimages",
          ],
          "libjson": [
              "safe/tests",
              "safe/debian/tests",
          ],
          "liblzma": [
              "safe/docker",
              "safe/scripts",
              "safe/tests/dependents",
              "safe/tests/extra",
              "safe/tests/upstream",
          ],
          "libpng": [
              "safe/tests",
              "original/tests",
              "original/contrib/pngsuite",
              "original/contrib/testpngs",
              "original/png.h",
              "original/pngconf.h",
              "original/pngtest.png",
          ],
          "libsdl": [
              "safe/tests",
              "safe/debian/tests",
              "safe/generated/dependent_regression_manifest.json",
              "safe/generated/noninteractive_test_list.json",
              "safe/generated/original_test_port_map.json",
              "safe/generated/perf_workload_manifest.json",
              "safe/generated/perf_thresholds.json",
              "safe/generated/reports/perf-baseline-vs-safe.json",
              "safe/generated/reports/perf-waivers.md",
              "safe/upstream-tests",
              "original/test",
          ],
          "libsodium": [
              "safe/tests",
              "safe/docker",
          ],
          "libtiff": [
              "safe/test",
              "safe/scripts",
              "original/test",
          ],
          "libuv": [
              "safe/docker",
              "safe/include",
              "safe/prebuilt",
              "safe/scripts",
              "safe/test",
              "safe/test-extra",
          ],
          "libvips": [
              "safe/tests/dependents",
              "safe/tests/upstream",
              "safe/vendor/pyvips-3.1.1",
              "original/test",
              "original/examples",
          ],
          "libwebp": [
              "safe/tests",
              "original/examples",
              "original/tests/public_api_test.c",
          ],
          "libxml": [
              "safe/tests",
              "safe/debian/tests",
              "safe/scripts",
              "original",
          ],
          "libyaml": [
              "safe/tests",
              "safe/debian/tests",
              "safe/scripts",
              "original/include",
              "original/tests",
              "original/examples",
          ],
          "libzstd": [
              "safe/tests",
              "safe/debian/tests",
              "safe/docker",
              "safe/scripts",
              "original/libzstd-1.5.5+dfsg2",
          ],
      }
      by_name = {entry["name"]: entry for entry in manifest["repositories"]}
      for name, expected_paths in expected_imports.items():
          actual_paths = by_name[name]["validator"]["imports"]
          if actual_paths != expected_paths:
              raise SystemExit(f"{name} validator.imports mismatch: {actual_paths!r}")

      if Path("inventory/non-apt-ref-status.json").exists():
          raise SystemExit("inventory/non-apt-ref-status.json must not exist")
      if "glib" in manifest_names or "libc6" in manifest_names or "libcurl" in manifest_names or "libgcrypt" in manifest_names or "libjansson" in manifest_names:
          raise SystemExit("out-of-scope untagged libraries leaked into the manifest")
      PY

**Success Criteria**

- Both `check_01_inventory_scaffold_smoke` and `check_01_inventory_scaffold_review` pass.
- Scope is selected only from live `refs/tags/<library>/04-test` tags during phase 01, and later phases can consume the checked-in `inventory/github-repo-list.json`, `inventory/github-port-repos.json`, and `repositories.yml` without rediscovering scope.
- `repositories.yml` preserves the copied `apt-repo` `archive` mapping, exact `validator.imports`, all-empty `validator.import_excludes`, and the required uniform fixture mappings on every entry.
- The staging flow fetches an exact missing tag from the manifest GitHub remote instead of inheriting a local-path `origin`, `tools/build_safe_debs.py` leaves staged checkouts clean, and `tools/verify_imported_assets.py` rejects content drift or extra files under `tests/fixtures/`, `tests/harness-source/`, and `tests/tagged-port/`.
- No stale hard-coded library list, wrong `inventory.tag_probe_rule`, wrong `04-test` ref, no-op `--verify-scope`, reintroduced publication-tag contract, or non-hermetic phase-01 `unit/` test remains.

**Git Commit Requirement**

Commit all phase work to git before yielding.
Leave exactly one new commit atop the incoming branch state before yielding so every verifier that runs `git diff --check HEAD^ HEAD` reviews the full phase diff rather than only the tail of a multi-commit stack.

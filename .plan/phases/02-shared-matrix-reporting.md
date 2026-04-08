# Phase 02

## Phase Name

`shared-matrix-reporting`

## Implement Phase ID

`impl_02_shared_matrix_reporting`

## Preexisting Inputs

- `README.md`
- `Makefile`
- `repositories.yml`
- `tools/stage_port_repos.py`
- `tools/build_safe_debs.py`
- `/home/yans/safelibs/website/package.json`
- `/home/yans/safelibs/website/scripts/build.mjs`
- `/home/yans/safelibs/website/.github/workflows/deploy.yml`

## New Outputs

- top-level matrix runner `test.sh`
- shared shell helpers under `tests/_shared/`
- result collection and site generation tools
- tracked site source templates and static assets
- unit tests for result rendering and matrix orchestration

## File Changes

- `Makefile`
- `test.sh`
- `tools/run_matrix.py`
- `tools/render_site.py`
- `unit/test_run_matrix.py`
- `unit/test_render_site.py`
- `tests/_shared/common.sh`
- `tests/_shared/install_safe_debs.sh`
- `tests/_shared/entrypoint.sh`
- `site-src/index.html.template`
- `site-src/library.html.template`
- `site-src/styles.css`
- `site-src/script.js`
- `scripts/verify-site.sh`

## Implementation Details

- Extend `Makefile` with stable targets `unit`, `stage-ports`, `test`, `test-one`, `render-site`, `verify-site`, and `clean`. `stage-ports` must refresh `.work/ports` via `tools/stage_port_repos.py --config repositories.yml --dest-root .work/ports`, adding `--source-root "$PORT_SOURCE_ROOT"` only when `PORT_SOURCE_ROOT` is non-empty; when `PORT_SOURCE_ROOT` is unset it must rely on authenticated GitHub clones so `make stage-ports`, `make test`, and `make test-one` work from a clean public checkout. `test` and `test-one` must call that staging step before invoking `bash test.sh --port-root .work/ports ...`.
- Implement `test.sh` as the single entrypoint for local and CI execution. It must support `--config repositories.yml`, `--tests-root <path>` with default `tests`, repeatable `--library <name>`, `--mode original|safe|both`, `--port-root <path>`, `--artifact-root <dir>`, `--safe-deb-root <dir>` with a default under `<artifact-root>/debs`, and `--record-casts`.
- `test.sh` must exit with the aggregated matrix status from `tools/run_matrix.py` only after every requested `<library, mode>` pair has either produced its result artifacts or been marked failed in result JSON.
- `test.sh` must treat `--port-root` as an already-staged manifest-pinned scratch root; when omitted, default to `.work/ports` only if that directory already exists, otherwise fail with a clear message pointing the caller to `tools/stage_port_repos.py` or `make stage-ports`. It must never silently fall back to `/home/yans/safelibs`.
- Implement `tools/run_matrix.py` with typed result objects such as `RunRequest` and `RunResult`.
- In safe mode, `tools/run_matrix.py` must call `tools/build_safe_debs.py` before container execution, write replacement packages to `<artifact-root>/debs/<library>/` or the configured safe-deb root, reuse that directory if it is already populated for the current library, and mount it at `/safedebs`.
- `tools/run_matrix.py` must accept `--tests-root <path>` with default `tests` and resolve the harness for each requested library from `<tests-root>/<library>/`.
- `tools/run_matrix.py` must invoke `docker build` with the repository root as the build context and `-f <tests-root>/<library>/Dockerfile` so both checked-in `tests/<library>` harnesses and phase-local smoke fixtures can `COPY` shared files from the same repo root. It must build `<tests-root>/<library>/Dockerfile` and run `<tests-root>/<library>/docker-entrypoint.sh`.
- `tools/run_matrix.py` must mount `/safedebs` only in safe mode, after the replacement packages already exist on the host.
- `tools/run_matrix.py` must pass `VALIDATOR_TRACE=1` into the container only for safe-mode runs that also enable `--record-casts`; it must pass `VALIDATOR_TRACE=0` for every other run. This boolean environment variable is the only runner-to-entrypoint tracing contract.
- `tools/run_matrix.py` must wrap safe-mode container execution in `asciinema rec` when `--record-casts` is enabled, while still relying on `VALIDATOR_TRACE=1` inside the container to select `bash -x`.
- `tools/run_matrix.py` must emit `<artifact-root>/results/<library>/<mode>.json`, `<artifact-root>/logs/<library>/<mode>.log`, and `<artifact-root>/casts/<library>/safe.cast`.
- `tools/run_matrix.py` must record `replacement_provenance` as `archive-original` for original-mode runs, `safe-port` for mature safe builds, and `bootstrap-original-source` for bootstrap safe builds.
- `tools/run_matrix.py` must write one result JSON per requested `<library, mode>` pair even when package build, Docker image build, asciinema capture, or container execution fails; each result JSON must include at least `library`, `mode`, `status`, `replacement_provenance`, `exit_code`, `duration_seconds`, and `log_path`, and recorded safe runs must also include `cast_path`.
- `tools/run_matrix.py` must use `status: passed` for successful runs and `status: failed` for any run that produced a terminal non-zero outcome after artifact capture; report rendering must consume those explicit statuses instead of inferring failure from missing files.
- `tools/run_matrix.py` must never stop at the first failing library or mode; it must continue through the full requested matrix, flush all result JSON, log, and cast artifacts that can be produced, and return a non-zero process exit only after the requested matrix is complete.
- `tools/run_matrix.py` must require every caller to supply a staged scratch root via `--port-root` or by prepopulating `.work/ports` for `test.sh`; it must never resolve live sibling repos itself.
- Implement `tests/_shared/common.sh`, `tests/_shared/install_safe_debs.sh`, and `tests/_shared/entrypoint.sh` so every library harness follows one exact contract.
- `tests/_shared/entrypoint.sh` must expose `validator_entrypoint <run_script>` and be the only container-side code allowed to inspect `VALIDATOR_TRACE`.
- `validator_entrypoint` must call `tests/_shared/install_safe_debs.sh` to install `/safedebs/*.deb` if present, then execute `<run_script>` under `bash -x` when `VALIDATOR_TRACE=1` and plain `bash` otherwise.
- Every later `tests/<library>/docker-entrypoint.sh` must be a thin wrapper that sources `/validator/tests/_shared/entrypoint.sh` and calls `validator_entrypoint "/validator/tests/<library>/tests/run.sh" "$@"`.
- Every later `tests/<library>/Dockerfile` must copy both `tests/_shared` and `tests/<library>` into `/validator/tests/` and set `ENTRYPOINT ["/validator/tests/<library>/docker-entrypoint.sh"]`.
- No library-local `Dockerfile`, `docker-entrypoint.sh`, or `tests/**/*` may inspect mode, `/safedebs`, `VALIDATOR_TRACE`, `bash -x`, or `asciinema`; all mode awareness lives in `tools/run_matrix.py` and `tests/_shared/entrypoint.sh`.
- Every shared and library-local harness must assume the Docker image already contains the distro-packaged original library, so runtime harnesses never rebuild the library from source inside the container.
- Implement `tools/render_site.py` to generate a static report site from JSON results. It must write `site/index.html`, `site/libraries/<library>.html`, `site/report.json`, `site/casts/<library>/safe.cast` for every result JSON whose `cast_path` is `casts/<library>/safe.cast`, and the copied static assets from `site-src/`.
- `tools/render_site.py` must accept `--results-root`, `--artifacts-root`, and `--output-root`; it must render passed and failed runs into the report, copy published cast files from `<artifacts-root>/casts/` into `site/casts/`, keep the HTML and `site/report.json` links aligned with the relative `cast_path`, and refuse only malformed input or missing artifacts that a result JSON explicitly claims exist.
- `site/report.json` must carry every rendered run as explicit per-result data keyed by `library` and `mode` so verification can compare the exact rendered `<library, mode>` set against the expected coverage.
- Implement `scripts/verify-site.sh` to accept `--config <path>`, `--results-root <dir>`, `--site-root <dir>`, repeatable `--library <name>`, and repeatable `--mode <name>`.
- When `--library` is omitted, `scripts/verify-site.sh` must derive the expected library set from `repositories.yml`; when `--mode` is omitted it must require both `original` and `safe`.
- `scripts/verify-site.sh` must validate the generated site structure, the aggregate report JSON, the copied safe-mode cast files and links whenever a result JSON declares `cast_path`, and the exact expected `<library, mode>` coverage across both raw result JSON files and `site/report.json`, failing on any missing or unexpected pair.

## Verification Phases

### `check_02_shared_matrix_reporting_smoke`

- phase ID: `check_02_shared_matrix_reporting_smoke`
- type: `check`
- bounce_target: `impl_02_shared_matrix_reporting`
- purpose: prove the shared runner end to end, including the top-level CLI, safe-deb installation, trace propagation, failure-tolerant result emission, and site rendering, before real library harnesses are imported
- commands:

```bash
set -euo pipefail
rm -rf .work/check02
mkdir -p .work/check02
python3 -m unittest unit.test_run_matrix unit.test_render_site -v
python3 - <<'PY'
from pathlib import Path
import os
import stat
import subprocess
import textwrap
import yaml

root = Path(".work/check02")
ports = root / "ports"
tests_root = root / "tests"
packages_root = root / "packages"

def write_executable(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content))
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

for library, failing in [("demo-pass", False), ("demo-fail", True)]:
    repo_root = ports / f"port-{library}"
    repo_root.mkdir(parents=True, exist_ok=True)
    (repo_root / "placeholder").mkdir(parents=True, exist_ok=True)

    package_root = packages_root / library
    (package_root / "DEBIAN").mkdir(parents=True, exist_ok=True)
    (package_root / "opt" / "validator-demo").mkdir(parents=True, exist_ok=True)
    (package_root / "DEBIAN" / "control").write_text(textwrap.dedent(f"""\
        Package: validator-{library}
        Version: 1.0
        Section: misc
        Priority: optional
        Architecture: all
        Maintainer: SafeLibs <validator@example.com>
        Description: Validator smoke package for {library}
    """))
    (package_root / "opt" / "validator-demo" / f"{library}-replacement.txt").write_text("installed\n")
    subprocess.run(
        ["dpkg-deb", "--build", str(package_root), str(repo_root / f"{library}_1.0_all.deb")],
        check=True,
    )

    harness_root = tests_root / library
    write_executable(
        harness_root / "docker-entrypoint.sh",
        f"""\
        #!/usr/bin/env bash
        set -euo pipefail
        source /validator/tests/_shared/entrypoint.sh
        validator_entrypoint "/validator/tests/{library}/tests/run.sh" "$@"
        """,
    )
    write_executable(
        harness_root / "tests" / "run.sh",
        f"""\
        #!/usr/bin/env bash
        set -euo pipefail
        echo trace_{library.replace('-', '_')}
        if [ -f /opt/validator-demo/{library}-replacement.txt ]; then
          echo replacement_present
        else
          echo replacement_absent
        fi
        test -f /opt/validator-demo/base.txt
        {'exit 7' if failing else 'echo completed'}
        """,
    )
    (harness_root / "Dockerfile").write_text(textwrap.dedent(f"""\
        FROM ubuntu:24.04
        RUN mkdir -p /opt/validator-demo && printf 'base\\n' > /opt/validator-demo/base.txt
        COPY tests/_shared /validator/tests/_shared
        COPY .work/check02/tests/{library} /validator/tests/{library}
        ENTRYPOINT ["/validator/tests/{library}/docker-entrypoint.sh"]
    """))

manifest = {
    "inventory": {
        "verified_at": "2026-04-07T00:00:00Z",
        "gh_repo_list_command": "synthetic-demo",
        "raw_snapshot": "inventory/demo.json",
        "filtered_snapshot": "inventory/demo-port.json",
        "goal_repo_family": "repos-*",
        "verified_repo_family": "port-*",
    },
    "repositories": [
        {
            "name": "demo-pass",
            "github_repo": "safelibs/port-demo-pass",
            "ref": "refs/heads/main",
            "build": {"mode": "checkout-artifacts", "workdir": ".", "artifact_globs": ["*.deb"]},
            "validator": {
                "harness_origin": "existing-port-harness",
                "sibling_repo": "port-demo-pass",
                "build_root": ".",
                "import_roots": ["placeholder"],
                "import_excludes": [],
                "runtime_fixture_paths": [],
            },
        },
        {
            "name": "demo-fail",
            "github_repo": "safelibs/port-demo-fail",
            "ref": "refs/heads/main",
            "build": {"mode": "checkout-artifacts", "workdir": ".", "artifact_globs": ["*.deb"]},
            "validator": {
                "harness_origin": "existing-port-harness",
                "sibling_repo": "port-demo-fail",
                "build_root": ".",
                "import_roots": ["placeholder"],
                "import_excludes": [],
                "runtime_fixture_paths": [],
            },
        }
    ],
}
Path(".work/check02/demo-repositories.yml").write_text(yaml.safe_dump(manifest, sort_keys=False))
PY
matrix_rc=0
bash test.sh \
  --config .work/check02/demo-repositories.yml \
  --tests-root .work/check02/tests \
  --port-root .work/check02/ports \
  --artifact-root .work/check02/artifacts \
  --mode both \
  --record-casts \
  --library demo-pass \
  --library demo-fail || matrix_rc=$?
python3 tools/render_site.py --results-root .work/check02/artifacts/results --artifacts-root .work/check02/artifacts --output-root .work/check02/site
bash scripts/verify-site.sh --config .work/check02/demo-repositories.yml --results-root .work/check02/artifacts/results --site-root .work/check02/site --library demo-pass --library demo-fail --mode original --mode safe
python3 - <<'PY'
from pathlib import Path
import json

artifacts = Path(".work/check02/artifacts")
expected = {
    ("demo-pass", "original"): ("passed", "archive-original", "replacement_absent", False),
    ("demo-pass", "safe"): ("passed", "safe-port", "replacement_present", True),
    ("demo-fail", "original"): ("failed", "archive-original", "replacement_absent", False),
    ("demo-fail", "safe"): ("failed", "safe-port", "replacement_present", True),
}
for (library, mode), (status, provenance, replacement_marker, traced) in expected.items():
    result_path = artifacts / "results" / library / f"{mode}.json"
    if not result_path.exists():
        raise SystemExit(f"missing result: {result_path}")
    result = json.loads(result_path.read_text())
    if result["status"] != status:
        raise SystemExit(f"{library} {mode} status mismatch: {result['status']!r}")
    if result["replacement_provenance"] != provenance:
        raise SystemExit(f"{library} {mode} provenance mismatch: {result['replacement_provenance']!r}")
    if (status == "passed" and result["exit_code"] != 0) or (status == "failed" and result["exit_code"] == 0):
        raise SystemExit(f"{library} {mode} exit_code mismatch: {result['exit_code']}")
    log_path = artifacts / result["log_path"]
    log_text = log_path.read_text()
    if replacement_marker not in log_text:
        raise SystemExit(f"{library} {mode} missing {replacement_marker} in {log_path}")
    trace_line = f"+ echo trace_{library.replace('-', '_')}"
    if traced and trace_line not in log_text:
        raise SystemExit(f"{library} {mode} missing traced log line")
    if not traced and trace_line in log_text:
        raise SystemExit(f"{library} {mode} unexpectedly traced")
    if mode == "safe":
        cast_path = artifacts / result["cast_path"]
        if not cast_path.exists():
            raise SystemExit(f"missing cast: {cast_path}")
        site_cast = Path(".work/check02/site") / result["cast_path"]
        if not site_cast.exists():
            raise SystemExit(f"missing published cast: {site_cast}")
PY
test "$matrix_rc" -ne 0
```

### `check_02_shared_matrix_reporting_review`

- phase ID: `check_02_shared_matrix_reporting_review`
- type: `check`
- bounce_target: `impl_02_shared_matrix_reporting`
- purpose: review that manifest-pinned scratch roots, portable clone-first helper targets, mode awareness, and publication paths are explicit, and that `VALIDATOR_TRACE` is the only runner-to-entrypoint trace signal
- commands:

```bash
git diff --check HEAD^ HEAD
rg -n 'VALIDATOR_TRACE|validator_entrypoint|/safedebs|bash -x|asciinema|replacement_provenance|cast_path|site/casts|exit_code|tests-root' test.sh tools/run_matrix.py tools/render_site.py tests/_shared scripts/verify-site.sh
rg -n '^stage-ports:|^test-one:|PORT_SOURCE_ROOT|\.work/ports|stage_port_repos.py|tests-root' Makefile test.sh tools/run_matrix.py
! rg -n '/home/yans/safelibs' Makefile test.sh tools/run_matrix.py
python3 - <<'PY'
from pathlib import Path
required = [
    Path("test.sh"),
    Path("tools/run_matrix.py"),
    Path("tools/render_site.py"),
    Path("tests/_shared/common.sh"),
    Path("tests/_shared/install_safe_debs.sh"),
    Path("tests/_shared/entrypoint.sh"),
    Path("site-src/styles.css"),
    Path("site-src/script.js"),
    Path("site-src/index.html.template"),
    Path("site-src/library.html.template"),
    Path("scripts/verify-site.sh"),
]
missing = [str(path) for path in required if not path.exists()]
if missing:
    raise SystemExit(missing)
PY
```

## Success Criteria

- `bash test.sh` drives `tools/run_matrix.py` end to end against the phase-local two-library smoke manifest before any real library harnesses are added.
- Matrix execution continues after an individual run fails, writes explicit failing result JSON, and returns a non-zero exit only after the requested matrix is complete.
- Safe smoke runs install generated `.deb` fixtures, propagate `VALIDATOR_TRACE=1` only when cast recording is enabled, and still publish copied `site/casts/<library>/safe.cast` files even when one smoke library fails.
- The renderer copies recorded safe-mode casts into `site/casts/`, the published links match the `cast_path` values stored in results, and `scripts/verify-site.sh` enforces exact expected `<library, mode>` coverage from a provided config and result set.
- Manifest-pinned staging, `/safedebs`, `VALIDATOR_TRACE`, and every other mode-aware behavior live only in the shared runner and entrypoint layer.

## Git Commit Requirement

The implementer must commit all phase work to git before yielding. The phase must end with exactly one commit on `HEAD`.

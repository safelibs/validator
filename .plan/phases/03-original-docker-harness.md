# 3. Shared Harness, Dockerfiles, and Entrypoints

## Phase Name

Shared Harness, Dockerfiles, and Entrypoints

## Implement Phase ID

`impl_phase_03_original_docker_harness`

## Preexisting Inputs

- `.plan/goal.md`
- `repositories.yml` v2 from phase 2
- `tests/<library>/testcases.yml` skeletons from phase 2
- All 19 `tests/<library>/Dockerfile`.
- All 19 `tests/<library>/docker-entrypoint.sh`.
- All 19 `tests/<library>/host-run.sh`.
- All 19 `tests/<library>/tests/run.sh`.
- `tests/_shared/install_override_debs.sh`.
- `tests/_shared/run_library_tests.sh`.
- `tests/_shared/runtime_helpers.sh`.
- Existing apt package knowledge embedded in current Dockerfiles.

## New Outputs

- Original-only Dockerfiles for all 19 libraries.
- Generic entrypoints that install override `.deb` files and then dispatch testcases.
- Removed active dependency on `host-run.sh` for normal validation.

## File Changes

For every library in the fixed 19-library list:

- Modify `tests/<library>/Dockerfile`.
- Modify `tests/<library>/docker-entrypoint.sh`.
- Modify `tests/<library>/tests/run.sh`.
- Delete or replace `tests/<library>/host-run.sh` with a short compatibility error explaining host-harness mode is retired. Retain it only for a documented host-only original testcase requirement.

Shared files:

- Modify `tests/_shared/run_library_tests.sh`.
- Modify `tests/_shared/runtime_helpers.sh` only for generic helpers.
- Delete `tests/_shared/install_safe_debs.sh` after all Dockerfiles reference `install_override_debs.sh`.

## Implementation Details

### Phase Scope Notes

This phase owns the Dockerfiles, entrypoints, and shared testcase dispatcher for original apt package validation. Consume the existing 19 library Docker/host/test harness files in place, replacing active safe-deb installation and host-harness branching with generic override installation and single-testcase dispatch.

Dockerfile requirements:

- Base image remains `ubuntu:24.04`.
- `DEBIAN_FRONTEND=noninteractive`.
- Install every original apt package declared in the exact `repositories.yml` `apt_packages` list for that library, in addition to any test dependencies needed by that library's cases. The canonical list is not inferred from the Dockerfile; the Dockerfile must conform to the manifest.
- Install common tools as needed: `bash`, `build-essential`, `ca-certificates`, `coreutils`, `file`, `pkg-config`, `python3`, `jq`, `xvfb`, `dbus-x11`, etc. Keep library-specific dependencies scoped to the library Dockerfile. If a tool such as `xz-utils` or `zstd` is also the package under validation for `liblzma` or `libzstd`, it belongs in that library's `apt_packages`; when the same tool is only a helper for another library, it is a Dockerfile test dependency only.
- Add compilers, generic build tools, dependent applications, codec dependencies, and third-party language bindings to Dockerfile test dependencies only. Add them to `apt_packages` only when explicitly listed in the phase 2 canonical package map.
- Copy `_shared/`, the library directory, and no external staged port checkout.
- Mark the entrypoint, shared helpers, and case scripts executable. During phase 3, case directories may still be empty skeletons, so Dockerfiles must tolerate missing `tests/cases/source` and `tests/cases/usage` directories; phase 4 and phase 5 add the real scripts.

Entrypoint requirements:

```bash
#!/usr/bin/env bash
set -euo pipefail

/validator/tests/_shared/install_override_debs.sh
exec /validator/tests/_shared/run_library_tests.sh <library> "$@"
```

`run_library_tests.sh` must:

- Set these exact environment variables before executing the testcase command:
  - `VALIDATOR_LIBRARY=<library>`
  - `VALIDATOR_LIBRARY_ROOT=/validator/tests/<library>`
  - `VALIDATOR_TESTCASE_ID=<testcase-id>`
  - `VALIDATOR_SOURCE_ROOT=/validator/tests/<library>/tests/tagged-port/original`
  - `VALIDATOR_FIXTURE_ROOT=/validator/tests/<library>/tests/fixtures`
- Require this argv shape from the runner: `<testcase-id> -- <command> [args...]`.
- Validate that `<testcase-id>` matches the same ID grammar as the manifest and export it as `VALIDATOR_TESTCASE_ID`.
- Execute exactly the command after `--` and no other testcase command. The runner, not this shell helper, is responsible for loading `testcases.yml` and choosing the command.
- Retain no safe/original branch. The environment is always original apt package validation.
- Do not export `VALIDATOR_TAGGED_ROOT` in the final helper. Any temporary migration alias must equal `VALIDATOR_SOURCE_ROOT` and must be removed by phase 8. Final source and usage scripts must use `VALIDATOR_SOURCE_ROOT`.

Privileged or GUI cases:

- Use testcase `requires` values such as `xvfb`, `dbus`, `fuse`, or `network`.
- The runner may translate `requires: ["fuse"]` into documented Docker args for local checks. Hosted CI must use hosted-compatible cases only; do not model FUSE or other unsupported hosted cases as skipped in the final manifest.

## Verification Phases

`check_phase_03_dockerfile_audit`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_03_original_docker_harness`
- Purpose: ensure every library Dockerfile and entrypoint is original-only, installs apt packages, and supports generic override `.deb` mounting.
- Commands:

```bash
python3 tools/testcases.py --config repositories.yml --tests-root tests --check-manifest-only
python3 - <<'PY'
from pathlib import Path
import yaml

manifest = yaml.safe_load(Path("repositories.yml").read_text())
for entry in manifest["libraries"]:
    library = entry["name"]
    dockerfile = Path("tests") / library / "Dockerfile"
    entrypoint = Path("tests") / library / "docker-entrypoint.sh"
    assert dockerfile.is_file(), dockerfile
    assert entrypoint.is_file(), entrypoint
    docker_text = dockerfile.read_text()
    entry_text = entrypoint.read_text()
    for package in entry["apt_packages"]:
        assert package in docker_text, f"{library} missing {package}"
    assert "install_override_debs.sh" in entry_text, entrypoint
    forbidden = [
        "install_safe_debs",
        "/safedebs",
        "VALIDATOR_SAFE_DEB_DIR",
        "safe_deb",
        "safe-deb",
        "safe deb",
        "--mode both",
        "--mode safe",
    ]
    for token in forbidden:
        assert token not in docker_text + entry_text, f"{library} contains {token}"
PY
```

`check_phase_03_targeted_image_smoke`

- Type: `check`
- Fixed `bounce_target`: `impl_phase_03_original_docker_harness`
- Purpose: build representative library images and run the generic entrypoint/dispatcher with a synthetic original-only package-presence command. Full real testcase execution starts in phase 4 after source case catalogs exist.
- Commands:

```bash
python3 - <<'PY'
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid
import yaml

manifest = yaml.safe_load(Path("repositories.yml").read_text())
entries = {entry["name"]: entry for entry in manifest["libraries"]}
for library in ["cjson", "libpng", "libxml"]:
    entry = entries[library]
    tag = f"validator-phase03-{library}-{uuid.uuid4().hex[:12]}".replace("_", "-")
    tempdir = Path(tempfile.mkdtemp(prefix=f"validator-phase03-{library}-"))
    try:
        shutil.copytree(Path("tests") / "_shared", tempdir / "_shared")
        shutil.copytree(Path("tests") / library, tempdir / library)
        subprocess.run(
            ["docker", "build", "--tag", tag, "--file", str(tempdir / library / "Dockerfile"), str(tempdir)],
            check=True,
        )
        package_checks = " && ".join(f"dpkg-query -W {package}" for package in entry["apt_packages"])
        subprocess.run(
            [
                "docker", "run", "--rm", tag,
                f"/validator/tests/{library}/docker-entrypoint.sh",
                "harness-smoke", "--", "bash", "-lc", package_checks,
            ],
            check=True,
        )
    finally:
        subprocess.run(["docker", "image", "rm", "--force", tag], check=False)
        shutil.rmtree(tempdir, ignore_errors=True)
PY
```

## Success Criteria

- Every Dockerfile installs the canonical original apt packages for its library plus only scoped test dependencies.
- Every entrypoint installs optional generic override `.deb` files and dispatches a single testcase through the shared helper.
- `run_library_tests.sh` exports the final original-only environment variables and has no safe/original branch.
- Normal validation no longer depends on host-run harness behavior.
- All explicit phase 3 verification phases pass.
- Additional source-plan verification notes must be satisfied:

  - Dockerfile audit and targeted smoke above.
  - Manual review that no Dockerfile installs a package from `artifacts/debs`, `.work/ports`, `.work/build-safe`, any `--port-root` staging path, or a SafeLibs apt repository.

## Git Commit Requirement

The implementer must commit all work for `impl_phase_03_original_docker_harness` to git before yielding. The commit must include this phase's scoped file changes and any generated artifacts explicitly required by the phase, and must not include unrelated cleanup or regenerated history.

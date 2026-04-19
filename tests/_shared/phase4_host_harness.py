#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


LOG_MARKER_LIBRARIES = {
    "cjson",
    "giflib",
    "libarchive",
    "libbz2",
    "libcsv",
    "libjson",
    "libyaml",
}

SPLIT_BASELINE_SELECTED: dict[str, list[str]] = {
    "cjson": [
        "original:test",
        "original:parse_examples",
        "original:parse_number",
        "original:parse_hex4",
        "original:parse_string",
        "original:parse_array",
        "original:parse_object",
        "original:parse_value",
        "original:print_string",
        "original:print_number",
        "original:print_array",
        "original:print_object",
        "original:print_value",
        "original:misc_tests",
        "original:parse_with_opts",
        "original:compare_tests",
        "original:cjson_add",
        "original:readme_examples",
        "original:minify_tests",
        "original:public_api_coverage",
        "original:json_patch_tests",
        "original:old_utils_tests",
        "original:misc_utils_tests",
        "safe-regression:core_layout_smoke",
        "safe-regression:dependents_config_roundtrip_smoke",
        "safe-regression:dependents_parse_payloads_smoke",
        "safe-regression:dependents_roundtrip_shapes_smoke",
        "legacy-probe:core_hooks_smoke",
        "legacy-probe:number_cve_2023_26819",
        "legacy-probe:json_pointer_cve_2025_57052",
        "safe-regression:locale_parse_print_smoke",
        "perf:parse_print_bench:parse",
        "perf:parse_print_bench:print-unformatted",
        "perf:parse_print_bench:print-buffered",
        "perf:parse_print_bench:minify",
        "perf:utils_patch_bench:apply",
        "perf:utils_patch_bench:generate",
        "perf:utils_patch_bench:merge",
    ],
    "giflib": ["test", "gif2rgb-regress", "safe-header-regress", "link-compat-regress"],
    "libbz2": [
        "sample1-decompress",
        "sample2-decompress",
        "sample3-decompress",
        "public_api_test",
        "debian-test:compress",
        "debian-test:compare",
        "debian-test:grep",
        "debian-test:link-with-shared",
        "debian-test:bzexe-test",
    ],
    "libcsv": [
        "test_csv",
        "example:csvtest",
        "example:csvinfo",
        "example:csvvalid",
        "example:csvfix",
        "safe-probe:abi_edges",
        "safe-probe:allocator_failures",
        "safe-probe:layout_probe",
        "safe-probe:public_header_smoke",
        "debian-test:build-examples",
    ],
    "libexif": [
        "run-original-test-suite.sh",
        "run-package-build.sh",
        "run-cve-regressions.sh",
        "run-export-compare.sh",
    ],
    "libjpeg-turbo": [
        "prepare-installed-usr-root",
        "make-tjexample-shim",
        "safe-script:run-debian-autopkgtests.sh",
        "safe-script:run-progs-smoke.sh",
        "translated-safe-test:compat_from_safe_tests",
        "translated-safe-test:skip_scanlines_rejects_two_pass_quantization",
        "translated-safe-test:skip_scanlines_handles_merged_upsampling_regression_path",
        "translated-safe-test:jcstest_ported",
    ],
    "libsdl": [
        "debian-tests-build",
        "debian-tests-deprecated-use",
        "debian-tests-cmake",
        "validate-original-test-port-map",
        "testver",
        "testqsort",
        "testfilesystem",
        "testplatform",
        "installed-test:testautomation",
        "installed-test:testatomic",
        "installed-test:testerror",
        "installed-test:testevdev",
        "installed-test:testthread",
        "installed-test:testlocale",
        "installed-test:testplatform",
        "installed-test:testpower",
        "installed-test:testfilesystem",
        "installed-test:testtimer",
        "installed-test:testver",
        "installed-test:testqsort",
        "installed-test:testaudioinfo",
        "installed-test:testsurround",
        "installed-test:testkeys",
        "installed-test:testbounds",
        "installed-test:testdisplayinfo",
        "validate-generated-manifests-and-reports",
    ],
    "libyaml": [
        "test-version",
        "test-reader",
        "test-api",
        "run-scanner",
        "run-parser",
        "run-loader",
        "run-emitter",
        "run-dumper",
        "run-parser-test-suite",
        "run-emitter-test-suite",
        "example-deconstructor",
        "example-deconstructor-alt",
        "example-reformatter",
        "example-reformatter-alt",
        "safe-fixture:abi_layout",
        "safe-fixture:document_api_exports",
        "safe-fixture:emitter_api_exports",
        "safe-fixture:event_api_exports",
        "safe-fixture:parser_input_api",
        "safe-fixture:private_parser_exports",
        "debian-tests-upstream-tests",
    ],
}

LIBJSON_SELECTED = [
    "compile:bind9",
    "compile:frr",
    "compile:sway",
    "compile:gdal",
    "compile:nvme-cli",
    "compile:ndctl",
    "compile:daxctl",
    "compile:bluez-meshd",
    "compile:syslog-ng",
    "compile:ttyd",
    "compile:tlog",
    "compile:pd-purest-json",
    "runtime:bind9",
    "runtime:frr",
    "runtime:sway",
    "runtime:gdal",
    "runtime:nvme-cli",
    "runtime:ndctl",
    "runtime:daxctl",
    "runtime:bluez-meshd",
    "runtime:syslog-ng",
    "runtime:ttyd",
    "runtime:tlog",
    "runtime:pd-purest-json",
]

LIBJPEG_SELECTED = [
    "compile:dcm2niix",
    "compile:krita",
    "compile:libreoffice",
    "compile:opencv",
    "compile:timg",
    "compile:vips",
    "compile:webkit2gtk",
    "compile:xpra",
    "runtime:dcm2niix",
    "runtime:eog",
    "runtime:gimp",
    "runtime:gphoto2",
    "runtime:krita",
    "runtime:libcamera-tools",
    "runtime:libopencv-imgcodecs406t64",
    "runtime:libreoffice-core",
    "runtime:libvips42t64",
    "runtime:libwebkit2gtk-4.1-0",
    "runtime:openjdk-17-jre-headless",
    "runtime:python3-pil",
    "runtime:timg",
    "runtime:tracker-extract",
    "runtime:xpra",
]

LIBSDL_SELECTED = [
    "qemu",
    "ffmpeg",
    "scrcpy",
    "love",
    "pygame",
    "scummvm",
    "supertuxkart",
    "tuxpaint",
    "openttd",
    "0ad",
    "imgui",
    "libtcod",
]

LIBSODIUM_SELECTED = [
    "minisign",
    "shadowsocks-libev",
    "libtoxcore2",
    "qtox",
    "fastd",
    "curvedns",
    "nix-bin",
    "libzmq5",
    "vim",
    "php8.3-cli",
    "python3-nacl",
    "ruby-rbnacl",
    "r-cran-sodium",
    "librust-libsodium-sys-dev",
    "libtoxcore-dev",
    "libzmq3-dev",
]

LIBEXIF_COMPILE = [
    "exif",
    "exiftran",
    "eog-plugin-exif-display",
    "eog-plugin-map",
    "tracker-extract",
    "Shotwell",
    "FoxtrotGPS",
    "gphoto2",
    "GTKam",
    "MiniDLNA",
    "Gerbera",
    "ruby-exif",
    "libexif-gtk3",
    "CamlImages",
    "ImageMagick",
]

LIBEXIF_RUNTIME = [
    "exif",
    "exiftran",
    "eog-plugin-exif-display",
    "eog-plugin-map",
    "tracker-extract",
    "Shotwell",
    "FoxtrotGPS",
    "gphoto2",
    "GTKam",
    "MiniDLNA",
    "Gerbera",
    "ruby-exif",
    "libexif-gtk3",
    "CamlImages",
]


@dataclass(frozen=True)
class HarnessEnv:
    library: str
    mode: str
    root: Path
    downstream_dir: Path
    raw_dir: Path
    console_log: Path
    results_json: Path
    summary_json: Path
    artifact_root: Path
    baseline_image: str | None


def load_env(library: str) -> HarnessEnv:
    mode = os.environ["VALIDATOR_MODE"]
    root = Path(os.environ["VALIDATOR_HARNESS_ROOT"]).resolve()
    downstream = Path(os.environ["VALIDATOR_DOWNSTREAM_DIR"]).resolve()
    raw = downstream / "raw"
    raw.mkdir(parents=True, exist_ok=True)
    (root / ".validator").mkdir(parents=True, exist_ok=True)
    return HarnessEnv(
        library=library,
        mode=mode,
        root=root,
        downstream_dir=downstream,
        raw_dir=raw,
        console_log=raw / "console.log",
        results_json=raw / "results.json",
        summary_json=downstream / "summary.json",
        artifact_root=Path(os.environ["VALIDATOR_ARTIFACT_ROOT"]).resolve(),
        baseline_image=os.environ.get("VALIDATOR_BASELINE_IMAGE"),
    )


def die(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def run_captured(command: list[str], *, log_path: Path, cwd: Path, env: dict[str, str] | None = None) -> int:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    with log_path.open("w", encoding="utf-8", errors="replace") as log_file:
        proc = subprocess.Popen(
            command,
            cwd=str(cwd),
            env=merged_env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
            bufsize=1,
        )
        assert proc.stdout is not None
        for line in proc.stdout:
            sys.stdout.write(line)
            log_file.write(line)
        return proc.wait()


def find_one(pattern: str) -> Path:
    matches = sorted(Path(path) for path in Path().glob(pattern) if Path(path).is_file())
    if len(matches) != 1:
        raise RuntimeError(f"expected exactly one package matching {pattern}, found {len(matches)}")
    return matches[0]


def find_one_under(root: Path, pattern: str) -> Path:
    matches = sorted(root.glob(pattern))
    matches = [path for path in matches if path.is_file()]
    if len(matches) != 1:
        raise RuntimeError(f"expected exactly one package matching {root / pattern}, found {len(matches)}")
    return matches[0]


def replace_shell_function(path: Path, name: str, replacement: str) -> None:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    start = None
    function_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*\(\) \{\s*$")
    for index, line in enumerate(lines):
        if line.strip() == f"{name}() {{":
            start = index
            break
    if start is None:
        raise RuntimeError(f"missing shell function {name} in {path}")
    end = len(lines)
    for index in range(start + 1, len(lines)):
        if function_re.match(lines[index]):
            end = index
            break
    new_lines = replacement.rstrip("\n").splitlines(keepends=False)
    lines[start:end] = [line + "\n" for line in new_lines]
    path.write_text("".join(lines), encoding="utf-8")


def replace_exact(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"missing expected text in {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def write_runtime_helpers(env: HarnessEnv) -> None:
    helper = env.root / ".validator" / "validator" / "tests" / "_shared" / "runtime_helpers.sh"
    helper.parent.mkdir(parents=True, exist_ok=True)
    helper.write_text(
        """#!/usr/bin/env bash
set -euo pipefail

validator_multiarch() {
  if command -v dpkg-architecture >/dev/null 2>&1; then
    dpkg-architecture -qDEB_HOST_MULTIARCH
  else
    gcc -print-multiarch
  fi
}

validator_require_file() {
  local path=$1
  [[ -f "$path" ]] || {
    printf 'missing required file: %s\\n' "$path" >&2
    exit 1
  }
}

validator_require_dir() {
  local path=$1
  [[ -d "$path" ]] || {
    printf 'missing required directory: %s\\n' "$path" >&2
    exit 1
  }
}

validator_copy_tree() {
  local source=$1
  local dest=$2
  mkdir -p "$(dirname "$dest")"
  cp -a "$source" "$dest"
}

validator_copy_file() {
  local source=$1
  local dest=$2
  mkdir -p "$(dirname "$dest")"
  cp -a "$source" "$dest"
}

validator_make_tool_shims() {
  local dest_dir=$1
  shift

  mkdir -p "$dest_dir"
  while (($#)); do
    local tool=$1
    local target
    shift

    target=$(command -v "$tool") || {
      printf 'missing required command: %s\\n' "$tool" >&2
      exit 1
    }
    ln -sf "$target" "$dest_dir/$tool"
  done
}
""",
        encoding="utf-8",
    )
    helper.chmod(0o755)


def run_baseline(env: HarnessEnv, selected: list[str]) -> int:
    if not env.baseline_image:
        write_baseline_summary(env, selected, 1, "setup", "missing VALIDATOR_BASELINE_IMAGE")
        return 1
    write_runtime_helpers(env)
    checked_in_tests = Path(__file__).resolve().parents[1] / env.library / "tests"
    if checked_in_tests.is_dir():
        shutil.copytree(checked_in_tests, env.root / "tests", dirs_exist_ok=True)
    launcher = env.root / ".validator" / f"{env.library}-baseline-run.sh"
    shutil.copy2(env.root / "tests" / "run.sh", launcher)
    launcher.chmod(0o755)
    if env.library == "libbz2":
        replace_exact(
            launcher,
            '  -o "$work_root/public_api_test"\n"$work_root/public_api_test"\n',
            '  -o "$work_root/public_api_test"\n( cd "$work_root" && ./public_api_test )\n',
        )
    if env.library == "libsdl":
        replace_exact(
            launcher,
            'while IFS= read -r exec_path; do\n',
            'pushd "$work_root" >/dev/null\nwhile IFS= read -r exec_path; do\n',
        )
        replace_exact(
            launcher,
            'done <"$work_root/installed-tests.txt"\n',
            'done <"$work_root/installed-tests.txt"\npopd >/dev/null\n',
        )
    command = [
        "docker",
        "run",
        "--rm",
        "-i",
        "--mount",
        f"type=bind,src={env.root},dst=/work",
        "--mount",
        f"type=bind,src={env.root / '.validator' / 'validator'},dst=/validator,readonly",
        "-e",
        "VALIDATOR_TAGGED_ROOT=/work",
        "-e",
        "VALIDATOR_LIBRARY_ROOT=/work",
        env.baseline_image,
        "bash",
        f"/work/.validator/{env.library}-baseline-run.sh",
    ]
    status = run_captured(command, log_path=env.console_log, cwd=env.root)
    write_baseline_summary(env, selected, status, "command", None)
    return status


def normalize_notes(*parts: Any) -> list[str]:
    notes: list[str] = []
    for part in parts:
        if not part:
            continue
        if isinstance(part, list):
            notes.extend(str(item).strip() for item in part if str(item).strip())
        else:
            text = str(part).strip()
            if text:
                notes.append(text)
    return notes


def write_summary(
    env: HarnessEnv,
    *,
    report_format: str,
    expected: int,
    selected: list[str],
    passed: list[str],
    failed: list[str],
    warned: list[str],
    skipped: list[str],
    artifacts: dict[str, str],
    notes: str | list[str] | None = None,
) -> None:
    status = "failed" if failed or warned or (not selected and expected) else "passed"
    payload: dict[str, Any] = {
        "summary_version": 1,
        "library": env.library,
        "mode": env.mode,
        "status": status,
        "report_format": report_format,
        "expected_dependents": expected,
        "selected_dependents": selected,
        "passed_dependents": passed,
        "failed_dependents": failed,
        "warned_dependents": warned,
        "skipped_dependents": skipped,
        "artifacts": artifacts,
    }
    if notes:
        payload["notes"] = notes
    write_json(env.summary_json, payload)


def write_baseline_summary(
    env: HarnessEnv,
    selected: list[str],
    exit_code: int,
    failure_mode: str,
    setup_note: str | None,
) -> None:
    passed: list[str] = []
    failed: list[str] = []
    skipped: list[str] = []
    selected_for_summary = list(selected)
    notes: list[str] = []
    if failure_mode == "setup":
        selected_for_summary = []
        notes = normalize_notes(setup_note or f"The {env.library} baseline wrapper failed before launching the scratch-local baseline launcher.")
    elif exit_code == 0:
        passed = list(selected)
    else:
        failed = selected[:1]
        skipped = selected[1:]
        notes = normalize_notes(f"The scratch-local {env.library} baseline launcher exited non-zero; consult raw/console.log.")
    status_by_id = {item: "skipped" for item in selected}
    for item in passed:
        status_by_id[item] = "passed"
    for item in failed:
        status_by_id[item] = "failed"
    write_json(
        env.results_json,
        {
            "schema_version": 1,
            "library": env.library,
            "mode": env.mode,
            "report_format": "validator-wrapper-baseline",
            "exit_code": exit_code,
            "failure_mode": failure_mode,
            "selected_dependents": selected,
            "workloads": [{"id": item, "status": status_by_id[item]} for item in selected],
        },
    )
    write_summary(
        env,
        report_format="validator-wrapper-baseline",
        expected=len(selected),
        selected=selected_for_summary,
        passed=passed,
        failed=failed,
        warned=[],
        skipped=skipped,
        artifacts={"console_log": str(env.console_log), "results_json": str(env.results_json)},
        notes=notes[0] if len(notes) == 1 else notes or None,
    )


def finalize_log_marker(
    env: HarnessEnv,
    *,
    selected: list[str],
    markers: list[str],
    exit_code: int,
    failure_mode: str = "command",
    cjson_failure_classification: bool = False,
    setup_note: str | None = None,
) -> None:
    lines = env.console_log.read_text(encoding="utf-8", errors="replace").splitlines() if env.console_log.is_file() else []
    observed: list[dict[str, Any]] = []
    next_index = 0
    for lineno, line in enumerate(lines, start=1):
        while next_index < len(markers) and markers[next_index] in line:
            observed.append({"id": selected[next_index], "marker": markers[next_index], "line": lineno})
            next_index += 1
    observed_ids = [item["id"] for item in observed]
    failed_from_classification = None
    if cjson_failure_classification:
        pattern = re.compile(r"failure classification: dependent=(\S+)")
        for line in lines:
            match = pattern.search(line)
            if match:
                failed_from_classification = match.group(1)
    passed: list[str] = []
    failed: list[str] = []
    skipped: list[str] = []
    selected_for_summary = list(selected)
    notes = []
    if failure_mode == "setup":
        selected_for_summary = []
        notes = normalize_notes(setup_note or f"The {env.library} host wrapper failed before launching ./test-original.sh.")
    elif exit_code == 0 and observed_ids == selected:
        passed = list(selected)
    elif failed_from_classification in selected and exit_code != 0:
        index = selected.index(str(failed_from_classification))
        passed = selected[:index]
        failed = [selected[index]]
        skipped = selected[index + 1 :]
        notes = normalize_notes(f"The imported {env.library} harness reported failure classification for {failed_from_classification}.")
    elif not observed_ids:
        failed = selected[:1]
        skipped = selected[1:]
        notes = normalize_notes(f"The imported {env.library} harness failed before the first workload marker.")
    elif exit_code == 0:
        passed = list(observed_ids)
        if len(observed_ids) < len(selected):
            failed = [selected[len(observed_ids)]]
            skipped = selected[len(observed_ids) + 1 :]
        notes = normalize_notes(f"The imported {env.library} harness exited successfully without emitting the full marker sequence.")
    else:
        passed = observed_ids[:-1]
        failed = observed_ids[-1:]
        skipped = selected[len(observed_ids) :]
        notes = normalize_notes(f"The imported {env.library} harness stopped after starting a workload.")
    status_by_id = {item: "skipped" for item in selected}
    for item in passed:
        status_by_id[item] = "passed"
    for item in failed:
        status_by_id[item] = "failed"
    write_json(
        env.results_json,
        {
            "schema_version": 1,
            "library": env.library,
            "mode": env.mode,
            "report_format": "imported-log-marker",
            "exit_code": exit_code,
            "failure_mode": failure_mode,
            "selected_dependents": selected,
            "observed_markers": observed,
            "workloads": [
                {"id": item, "status": status_by_id[item], "marker": markers[index]}
                for index, item in enumerate(selected)
            ],
        },
    )
    write_summary(
        env,
        report_format="imported-log-marker",
        expected=len(selected),
        selected=selected_for_summary,
        passed=passed,
        failed=failed,
        warned=[],
        skipped=skipped,
        artifacts={"console_log": str(env.console_log), "results_json": str(env.results_json)},
        notes=notes[0] if len(notes) == 1 else notes or None,
    )


def dependents_list(env: HarnessEnv, key: str) -> list[str]:
    data = read_json(env.root / "dependents.json")
    return [entry[key] for entry in data["dependents"]]


def patch_cjson(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_and_install_safe_cjson_packages",
        r'''
build_and_install_safe_cjson_packages() {
  local dist_dir="$ROOT/safe/dist"
  local runtime_deb=""
  local dev_deb=""

  log "Installing validator-built safe cJSON packages"
  runtime_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libcjson1_*.deb' | LC_ALL=C sort | head -n1)"
  dev_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libcjson-dev_*.deb' | LC_ALL=C sort | head -n1)"
  [[ -n "$runtime_deb" ]] || die "missing validator-built libcjson1 package under $dist_dir"
  [[ -n "$dev_deb" ]] || die "missing validator-built libcjson-dev package under $dist_dir"

  run_logged /tmp/cjson-package-install.log dpkg -i "$runtime_deb" "$dev_deb"
  ldconfig
  assert_safe_packages_installed
}
''',
    )


def patch_giflib(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_safe_packages",
        r'''
build_safe_packages() {
  local dist_dir="$ROOT/safe/dist"

  log_step "Installing validator-built safe Debian packages"
  SAFE_RUNTIME_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libgif7_*.deb' | LC_ALL=C sort | head -n1)"
  SAFE_DEV_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libgif-dev_*.deb' | LC_ALL=C sort | head -n1)"
  [[ -n "$SAFE_RUNTIME_DEB" ]] || die "missing validator-built libgif7 package under $dist_dir"
  [[ -n "$SAFE_DEV_DEB" ]] || die "missing validator-built libgif-dev package under $dist_dir"

  SAFE_RUNTIME_DBGSYM=""
  SAFE_CHANGES_FILE=""
  SAFE_BUILDINFO_FILE=""
  SAFE_RUNTIME_PACKAGE="$(dpkg-deb -f "$SAFE_RUNTIME_DEB" Package)"
  SAFE_RUNTIME_VERSION="$(dpkg-deb -f "$SAFE_RUNTIME_DEB" Version)"
  SAFE_DEV_PACKAGE="$(dpkg-deb -f "$SAFE_DEV_DEB" Package)"
  SAFE_DEV_VERSION="$(dpkg-deb -f "$SAFE_DEV_DEB" Version)"

  [[ "$SAFE_RUNTIME_PACKAGE" == "libgif7" ]] || die "unexpected runtime package name: $SAFE_RUNTIME_PACKAGE"
  [[ "$SAFE_DEV_PACKAGE" == "libgif-dev" ]] || die "unexpected development package name: $SAFE_DEV_PACKAGE"
  [[ "$SAFE_DEV_VERSION" == "$SAFE_RUNTIME_VERSION" ]] || die "development package version mismatch"

  export SAFE_RUNTIME_DEB SAFE_DEV_DEB
  export SAFE_RUNTIME_DBGSYM SAFE_CHANGES_FILE SAFE_BUILDINFO_FILE
  export SAFE_RUNTIME_PACKAGE SAFE_RUNTIME_VERSION
  export SAFE_DEV_PACKAGE SAFE_DEV_VERSION
}
''',
    )


def patch_libarchive(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_and_install_local_libarchive",
        r'''
build_and_install_local_libarchive() {
  local dist_dir="$ROOT/safe/dist"

  log_step "Installing validator-built libarchive Debian packages"
  rm -rf "$RUNTIME_EXTRACT_ROOT"

  LIBARCHIVE_RUNTIME_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libarchive13t64_*.deb' | LC_ALL=C sort | head -n1)"
  LIBARCHIVE_DEV_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libarchive-dev_*.deb' | LC_ALL=C sort | head -n1)"
  LIBARCHIVE_TOOLS_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libarchive-tools_*.deb' | LC_ALL=C sort | head -n1)"
  [[ -n "$LIBARCHIVE_RUNTIME_DEB" ]] || die "missing validator-built libarchive13t64 package under $dist_dir"
  [[ -n "$LIBARCHIVE_DEV_DEB" ]] || die "missing validator-built libarchive-dev package under $dist_dir"
  [[ -n "$LIBARCHIVE_TOOLS_DEB" ]] || die "missing validator-built libarchive-tools package under $dist_dir"

  dpkg -i "$LIBARCHIVE_RUNTIME_DEB" "$LIBARCHIVE_DEV_DEB" "$LIBARCHIVE_TOOLS_DEB"
  ldconfig

  ACTIVE_LIBARCHIVE="$(ldconfig -p | awk '/libarchive\.so\.13 / && /x86-64/ { print $NF; exit }')"
  [[ -n "$ACTIVE_LIBARCHIVE" ]] || die "ldconfig did not report an active libarchive.so.13"
  ACTIVE_LIBARCHIVE="$(readlink -f "$ACTIVE_LIBARCHIVE")"

  dpkg-deb -x "$LIBARCHIVE_RUNTIME_DEB" "$RUNTIME_EXTRACT_ROOT"
  LIBARCHIVE_MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"
  cmp -s \
    "$ACTIVE_LIBARCHIVE" \
    "$(readlink -f "$RUNTIME_EXTRACT_ROOT/usr/lib/$LIBARCHIVE_MULTIARCH/$(basename "$ACTIVE_LIBARCHIVE")")" || {
      printf 'installed libarchive does not match the validator-built runtime package\n' >&2
      exit 1
    }

  assert_links_to_active_libarchive "$(command -v bsdtar)"
  assert_links_to_active_libarchive "$(command -v bsdcpio)"
}
''',
    )


def prepare_libarchive_original_build(env: HarnessEnv) -> None:
    dest = env.root / "original" / "libarchive-3.7.2" / "build"
    if (dest / "autogen.sh").is_file():
        return
    source = (
        Path(__file__).resolve().parents[2]
        / ".work"
        / "ports"
        / "libarchive"
        / "original"
        / "libarchive-3.7.2"
        / "build"
    )
    if not (source / "autogen.sh").is_file():
        raise RuntimeError(f"missing staged libarchive build/autogen.sh under {source}")
    shutil.copytree(source, dest, dirs_exist_ok=True)


def prepare_libbz2_packages(env: HarnessEnv) -> None:
    out_dir = env.root / "target" / "package" / "out"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest_lines = []
    for package in ["libbz2-1.0", "libbz2-dev", "bzip2", "bzip2-doc"]:
        deb = find_one_under(env.root / "safe" / "dist", f"{package}_*.deb")
        shutil.copy2(deb, out_dir / deb.name)
        manifest_lines.append(f"package:{package}={deb.name}")
    (out_dir / "package-manifest.txt").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")


def patch_libcsv(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_local_libcsv_packages",
        r'''
build_local_libcsv_packages() {
  local dist_dir="$ROOT/safe/dist"

  log "Using validator-built libcsv Debian packages"
  LOCAL_LIBCSV3_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libcsv3_*.deb' | LC_ALL=C sort | head -n1 || true)"
  LOCAL_LIBCSV_DEV_DEB="$(find "$dist_dir" -maxdepth 1 -type f -name 'libcsv-dev_*.deb' | LC_ALL=C sort | head -n1 || true)"

  [[ -n "$LOCAL_LIBCSV3_DEB" ]] || die "failed to locate validator-built libcsv3 package under $dist_dir"
  [[ -n "$LOCAL_LIBCSV_DEV_DEB" ]] || die "failed to locate validator-built libcsv-dev package under $dist_dir"
}
''',
    )


def patch_libjpeg(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_safe_packages",
        r'''
build_safe_packages() {
  local -a debs

  mapfile -t debs < <(find "$ROOT/safe/dist" -maxdepth 1 -type f -name '*.deb' | sort)
  ((${#debs[@]} > 0)) || die "validator safe/dist did not contain any .deb files"

  dpkg -i "${debs[@]}" >/tmp/libjpeg-safe-install.log 2>&1 || {
    cat /tmp/libjpeg-safe-install.log >&2
    exit 1
  }

  ldconfig

  assert_uses_local_soname /usr/bin/dcm2niix libturbojpeg.so.0
  assert_uses_local_soname /usr/lib/jvm/java-17-openjdk-amd64/lib/libjavajpeg.so libjpeg.so.8
}
''',
    )


def patch_libsdl(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_safe_sdl",
        r'''
build_safe_sdl() {
  log_step "Installing validator-built safe SDL Debian packages"

  local dist_dir="$ROOT/safe/dist"
  local runtime_deb dev_deb tests_deb installed_pc pkg_prefix
  runtime_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libsdl2-2.0-0_*_*.deb' | sort | tail -n1)"
  dev_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libsdl2-dev_*_*.deb' | sort | tail -n1)"
  tests_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libsdl2-tests_*_*.deb' | sort | tail -n1)"

  [[ -n "$runtime_deb" ]] || die "failed to locate validator-built libsdl2-2.0-0 package"
  [[ -n "$dev_deb" ]] || die "failed to locate validator-built libsdl2-dev package"
  [[ -n "$tests_deb" ]] || die "failed to locate validator-built libsdl2-tests package"

  apt-get install -y --no-install-recommends \
    "$runtime_deb" \
    "$dev_deb" \
    "$tests_deb" \
    >/tmp/libsdl-safe-install.log 2>&1 || {
      cat /tmp/libsdl-safe-install.log >&2 || true
      die "failed to install validator-built safe SDL Debian packages"
    }

  ldconfig

  SAFE_SDL_SO="$(readlink -f "/usr/lib/${MULTIARCH}/libSDL2-2.0.so.0")"
  SAFE_SDL_LIBDIR="/usr/lib/${MULTIARCH}"
  installed_pc="$(find "/usr/lib/${MULTIARCH}" -type f -path '*/pkgconfig/sdl2.pc' | sort | head -n1)"
  SAFE_SDL_PKGCONFIG_DIR="$(dirname "$installed_pc")"

  [[ -n "$SAFE_SDL_SO" && -f "$SAFE_SDL_SO" ]] || die "failed to locate installed safe libSDL2-2.0.so.0"
  [[ -n "$SAFE_SDL_PKGCONFIG_DIR" && -d "$SAFE_SDL_PKGCONFIG_DIR" ]] || die "failed to locate installed safe sdl2.pc"

  export LD_LIBRARY_PATH="$SAFE_SDL_LIBDIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export PKG_CONFIG_PATH="$SAFE_SDL_PKGCONFIG_DIR${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  pkg_prefix="$(pkg-config --variable=prefix sdl2)"
  pkg_prefix="$(readlink -f "$pkg_prefix")"
  [[ "$pkg_prefix" == "/usr" ]] || die "expected installed sdl2.pc prefix to resolve to /usr, found $pkg_prefix"
}
''',
    )


def patch_libsodium(env: HarnessEnv) -> None:
    replace_shell_function(
        env.root / "test-original.sh",
        "build_safe_libsodium_packages",
        r'''
build_safe_libsodium_packages() {
  local runtime_before
  local dev_before
  local runtime_after
  local dev_after
  local runtime_deb
  local dev_deb
  local dist_dir="$ROOT/safe/dist"

  log_step "Installing validator-built safe libsodium packages"
  runtime_before="$(dpkg-query -W -f='${Version}' libsodium23)"
  dev_before="$(dpkg-query -W -f='${Version}' libsodium-dev)"

  runtime_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libsodium23_*.deb' | sort | tail -n1)"
  dev_deb="$(find "$dist_dir" -maxdepth 1 -type f -name 'libsodium-dev_*.deb' | sort | tail -n1)"
  [[ -n "$runtime_deb" ]] || die "missing validator-built libsodium23 package under $dist_dir"
  [[ -n "$dev_deb" ]] || die "missing validator-built libsodium-dev package under $dist_dir"

  dpkg -i "$runtime_deb" "$dev_deb" >/tmp/libsodium-safe-install.log 2>&1
  ldconfig

  runtime_after="$(dpkg-query -W -f='${Version}' libsodium23)"
  dev_after="$(dpkg-query -W -f='${Version}' libsodium-dev)"
  [[ "$runtime_after" != "$runtime_before" ]] \
    || die "libsodium23 was not upgraded in place"
  [[ "$dev_after" != "$dev_before" ]] \
    || die "libsodium-dev was not upgraded in place"
  [[ "$runtime_after" == *+safelibs1 ]] \
    || die "libsodium23 did not upgrade to the safe package build"
  [[ "$dev_after" == *+safelibs1 ]] \
    || die "libsodium-dev did not upgrade to the safe package build"

  EXPECTED_LIBSODIUM_PATH="$(readlink -f "$(dpkg_libsodium_path)")"
  EXPECTED_LIBSODIUM_LIBDIR="$(pkgconfig_libdir)"
  [[ "$EXPECTED_LIBSODIUM_LIBDIR" == "$(dirname "$EXPECTED_LIBSODIUM_PATH")" ]] \
    || die "pkg-config libdir does not match the package-installed libsodium path"
  assert_active_libsodium_resolution
}
''',
    )


def patch_libyaml(env: HarnessEnv) -> None:
    old = r'''COPY safe /src/libyaml-safe/safe
COPY original /src/libyaml-safe/original

RUN cd /src/libyaml-safe \
 && bash safe/scripts/stage-install.sh /tmp/libyaml-safe-install \
 && bash safe/scripts/verify-link-objects.sh /tmp/libyaml-safe-install \
 && rm -f /etc/dpkg/dpkg.cfg.d/excludes \
 && bash safe/scripts/build-deb.sh \
 && apt-get install -y --allow-downgrades --no-install-recommends \
      /src/libyaml-safe/safe/out/debs/libyaml-0-2.deb \
      /src/libyaml-safe/safe/out/debs/libyaml-dev.deb \
      /src/libyaml-safe/safe/out/debs/libyaml-doc.deb \
 && ldconfig \
 && rm -rf /var/lib/apt/lists/*'''
    new = r'''COPY safe/dist /src/libyaml-safe/safe/dist

RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
 && apt-get install -y --allow-downgrades --no-install-recommends \
      /src/libyaml-safe/safe/dist/libyaml-0-2_*.deb \
      /src/libyaml-safe/safe/dist/libyaml-dev_*.deb \
      /src/libyaml-safe/safe/dist/libyaml-doc_*.deb \
 && ldconfig \
 && rm -rf /var/lib/apt/lists/*'''
    replace_exact(env.root / "test-original.sh", old, new)


def patch_libexif(env: HarnessEnv) -> None:
    old = 'PACKAGE_BUILD_ROOT="$DOWNSTREAM_PACKAGE_ROOT" bash "$ROOT/safe/tests/run-package-build.sh" >/dev/null'
    new = r'''if [[ ! -d "$DOWNSTREAM_PACKAGE_ROOT/artifacts" || ! -d "$DOWNSTREAM_PACKAGE_ROOT/root" ]]; then
  printf 'validated libexif package root is missing artifacts/ or root/: %s\n' "$DOWNSTREAM_PACKAGE_ROOT" >&2
  exit 1
fi'''
    replace_exact(env.root / "test-original.sh", old, new)


def prepare_libexif_package_root(env: HarnessEnv) -> Path:
    package_root = env.root / ".validator" / "libexif-package-root"
    if package_root.exists():
        shutil.rmtree(package_root)
    artifacts = package_root / "artifacts"
    merged = package_root / "root"
    artifacts.mkdir(parents=True)
    merged.mkdir(parents=True)
    for package in ["libexif12", "libexif-dev", "libexif-doc"]:
        deb = find_one_under(env.root / "safe" / "dist", f"{package}_*.deb")
        staged = artifacts / deb.name
        shutil.copy2(deb, staged)
        package_dir = package_root / package
        package_dir.mkdir(parents=True)
        subprocess.run(["dpkg-deb", "-x", str(staged), str(package_dir)], check=True)
        subprocess.run(["dpkg-deb", "-x", str(staged), str(merged)], check=True)
    (package_root / "metadata").mkdir()
    return package_root


def prepare_libjson_original_build(env: HarnessEnv) -> int:
    build_manifest = env.root / "original" / "build" / "cmake_install.cmake"
    if build_manifest.is_file():
        return 0
    command = [
        "docker",
        "run",
        "--rm",
        "-i",
        "-v",
        f"{env.root}:/work",
        "ubuntu:24.04",
        "bash",
        "-lc",
        "set -euo pipefail; "
        "export DEBIAN_FRONTEND=noninteractive; "
        "apt-get update >/tmp/libjson-original-apt.log; "
        "apt-get install -y --no-install-recommends build-essential ca-certificates cmake pkg-config >/tmp/libjson-original-install.log; "
        "cd /work/original; "
        "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON -DDISABLE_WERROR=ON; "
        "cmake --build build -j\"$(nproc)\"",
    ]
    return run_captured(command, log_path=env.console_log, cwd=env.root)


def giflib_selected_and_markers() -> tuple[list[str], list[str]]:
    selected = [
        "runtime:giflib-tools",
        "runtime:webp",
        "runtime:fbi",
        "runtime:mtpaint",
        "runtime:tracker-extract",
        "runtime:libextractor-plugin-gif",
        "runtime:libcamlimages-ocaml",
        "runtime:libgdal34t64",
        "source:gdal",
        "source:exactimage",
        "source:sail",
        "source:libwebp",
        "source:imlib2",
    ]
    markers = [
        "==> giflib-tools",
        "==> webp",
        "==> fbi",
        "==> mtpaint",
        "==> tracker-extract",
        "==> libextractor-plugin-gif",
        "==> libcamlimages-ocaml",
        "==> libgdal34t64",
        "==> gdal (source)",
        "==> exactimage (source)",
        "==> sail (source)",
        "==> libwebp (source)",
        "==> imlib2 (source)",
    ]
    return selected, markers


def libjson_markers(mode: str) -> list[str]:
    label = "original-source" if mode == "original" else "safe-package"
    return [
        f"==> Compiling BIND 9 against {label} json-c",
        f"==> Compiling FRRouting zebra against {label} json-c",
        f"==> Compiling Sway against {label} json-c",
        f"==> Compiling GDAL GeoJSON tools against {label} json-c",
        f"==> Compiling nvme-cli against {label} json-c",
        f"==> Compiling ndctl/daxctl against {label} json-c",
        f"==> Compiling ndctl/daxctl against {label} json-c",
        f"==> Compiling BlueZ mesh tools against {label} json-c",
        f"==> Compiling syslog-ng JSON plugin against {label} json-c",
        f"==> Compiling ttyd against {label} json-c",
        f"==> Compiling tlog-rec against {label} json-c",
        f"==> Compiling PuREST JSON externals against {label} json-c",
        "==> Testing BIND 9",
        "==> Testing FRRouting",
        "==> Testing Sway",
        "==> Testing GDAL",
        "==> Testing nvme-cli",
        "==> Testing ndctl",
        "==> Testing daxctl",
        "==> Testing BlueZ Mesh Daemon",
        "==> Testing syslog-ng",
        "==> Testing ttyd",
        "==> Testing tlog",
        "==> Testing PuREST JSON for Pure Data",
    ]


def libyaml_selected_and_markers() -> tuple[list[str], list[str]]:
    selected = [
        "libnetplan1",
        "python3-yaml",
        "ruby-psych",
        "php8.3-yaml",
        "suricata",
        "stubby",
        "ser2net",
        "h2o",
        "libcamera0.2",
        "libappstream5",
        "crystal",
        "libyaml-libyaml-perl",
    ]
    markers = ["==> netplan.io", *[f"==> {item}" for item in selected[1:]]]
    return selected, markers


def run_log_marker_library(env: HarnessEnv) -> int:
    if env.mode == "original" and env.library in SPLIT_BASELINE_SELECTED:
        return run_baseline(env, SPLIT_BASELINE_SELECTED[env.library])

    if env.library == "cjson":
        patch_cjson(env)
        selected = dependents_list(env, "source_package")
        markers = [f"{item}: " for item in selected]
        status = run_captured(["./test-original.sh"], log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status, cjson_failure_classification=True)
        return status
    if env.library == "giflib":
        patch_giflib(env)
        selected, markers = giflib_selected_and_markers()
        status = run_captured(["./test-original.sh"], log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    if env.library == "libarchive":
        selected = dependents_list(env, "binary_package")
        markers = [f"==> {item}" for item in selected]
        if env.mode == "safe":
            patch_libarchive(env)
            command = ["./test-original.sh", "--target", "safe"]
        else:
            prepare_libarchive_original_build(env)
            command = ["./test-original.sh", "--target", "original"]
        status = run_captured(command, log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    if env.library == "libbz2":
        prepare_libbz2_packages(env)
        selected = dependents_list(env, "binary_package")
        markers = [f"==> {item}" for item in selected]
        status = run_captured(["./test-original.sh"], log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    if env.library == "libcsv":
        patch_libcsv(env)
        selected = ["readstat", "tellico"]
        markers = ["readstat: ", "tellico: "]
        status = run_captured(["./test-original.sh"], log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    if env.library == "libjson":
        selected = list(LIBJSON_SELECTED)
        markers = libjson_markers(env.mode)
        if env.mode == "original":
            prep_status = prepare_libjson_original_build(env)
            if prep_status != 0:
                finalize_log_marker(env, selected=selected, markers=markers, exit_code=prep_status, failure_mode="setup")
                return prep_status
            command = ["./test-original.sh", "--mode", "original-source", "--checks", "all"]
            log_mode = "a"
        else:
            command = ["./test-original.sh", "--mode", "safe-package", "--checks", "all", "--package-dir", str(env.root / "safe" / "dist")]
            log_mode = "w"
        if log_mode == "a" and env.console_log.exists():
            with env.console_log.open("a", encoding="utf-8") as handle:
                handle.write("\n=== libjson original-source downstream run ===\n")
        status = run_captured(command, log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    if env.library == "libyaml":
        patch_libyaml(env)
        selected, markers = libyaml_selected_and_markers()
        status = run_captured(["./test-original.sh"], log_path=env.console_log, cwd=env.root)
        finalize_log_marker(env, selected=selected, markers=markers, exit_code=status)
        return status
    raise AssertionError(env.library)


def normalize_libjpeg(env: HarnessEnv, exit_code: int) -> None:
    report_dir = env.downstream_dir / "report"
    summary_path = report_dir / "summary.json"
    if not summary_path.is_file():
        write_summary(
            env,
            report_format="imported-report-dir",
            expected=len(LIBJPEG_SELECTED),
            selected=[],
            passed=[],
            failed=[],
            warned=[],
            skipped=[],
            artifacts={"console_log": str(env.console_log)},
            notes="The libjpeg-turbo imported report was not written.",
        )
        return
    imported = read_json(summary_path)
    rows: list[tuple[str, dict[str, Any]]] = []
    for row in imported.get("compile", []):
        rows.append((f"compile:{row.get('source_package')}", row))
    for row in imported.get("runtime", []):
        rows.append((f"runtime:{row.get('name')}", row))
    actual_order = [item for item, _ in rows]
    if actual_order != LIBJPEG_SELECTED or len(set(actual_order)) != len(actual_order):
        raise RuntimeError(f"libjpeg-turbo imported report order mismatch: {actual_order}")
    passed: list[str] = []
    failed: list[str] = []
    skipped: list[str] = []
    report_root = report_dir.resolve()
    for workload, row in rows:
        status = row.get("status")
        if status == "pass":
            passed.append(workload)
        elif status == "fail":
            failed.append(workload)
        elif status == "skipped":
            skipped.append(workload)
        else:
            raise RuntimeError(f"unsupported libjpeg-turbo imported row status for {workload}: {status!r}")
        for key in ("log", "artifacts"):
            value = row.get(key)
            if not isinstance(value, str) or not value:
                raise RuntimeError(f"libjpeg-turbo row {workload} missing {key}")
            target = (report_dir / value).resolve()
            if report_root not in [target, *target.parents]:
                raise RuntimeError(f"libjpeg-turbo row {workload} {key} escapes report dir: {value}")
            if not target.exists():
                raise RuntimeError(f"libjpeg-turbo row {workload} {key} is missing: {value}")
    write_summary(
        env,
        report_format="imported-report-dir",
        expected=len(LIBJPEG_SELECTED),
        selected=list(LIBJPEG_SELECTED),
        passed=passed,
        failed=failed,
        warned=[],
        skipped=skipped,
        artifacts={"console_log": str(env.console_log), "imported_summary_json": str(summary_path)},
        notes=None if exit_code == 0 else "The imported libjpeg-turbo harness exited non-zero; normalized rows are from its report.",
    )


def run_libjpeg(env: HarnessEnv) -> int:
    if env.mode == "original":
        return run_baseline(env, SPLIT_BASELINE_SELECTED["libjpeg-turbo"])
    patch_libjpeg(env)
    report_dir = env.downstream_dir / "report"
    status = run_captured(
        ["./test-original.sh", "--checks", "all", "--report-dir", str(report_dir)],
        log_path=env.console_log,
        cwd=env.root,
    )
    normalize_libjpeg(env, status)
    return status


def normalize_libsdl(env: HarnessEnv, exit_code: int) -> None:
    data = read_json(env.results_json)
    dependents = read_json(env.root / "dependents.json")["dependents"]
    expected_manifest = [{"slug": entry["slug"], "name": entry["name"]} for entry in dependents]
    rows = data.get("dependents")
    if not isinstance(rows, list):
        raise RuntimeError("libsdl imported results.json missing dependents array")
    actual_slugs = [row.get("slug") for row in rows]
    if actual_slugs != LIBSDL_SELECTED or len(set(actual_slugs)) != len(actual_slugs):
        raise RuntimeError(f"libsdl imported row order mismatch: {actual_slugs}")
    for index, row in enumerate(rows):
        expected = expected_manifest[index]
        if row.get("slug") != expected["slug"] or row.get("name") != expected["name"]:
            raise RuntimeError(f"libsdl manifest mismatch at {index}: {row!r} vs {expected!r}")
    passed = [row["slug"] for row in rows if row.get("status") == "passed"]
    failed = [row["slug"] for row in rows if row.get("status") == "failed"]
    bad = [row for row in rows if row.get("status") not in {"passed", "failed"}]
    if bad:
        raise RuntimeError(f"libsdl unsupported imported statuses: {bad!r}")
    summary = data.get("summary")
    if not isinstance(summary, dict):
        raise RuntimeError("libsdl imported results.json missing summary")
    if summary.get("total") != len(rows) or summary.get("passed") != len(passed) or summary.get("failed") != len(failed):
        raise RuntimeError("libsdl imported summary counts do not match normalized rows")
    write_summary(
        env,
        report_format="imported-json-results",
        expected=len(LIBSDL_SELECTED),
        selected=list(LIBSDL_SELECTED),
        passed=passed,
        failed=failed,
        warned=[],
        skipped=[],
        artifacts={"console_log": str(env.console_log), "results_json": str(env.results_json)},
        notes=None if exit_code == 0 else "The imported libsdl harness exited non-zero; normalized rows are from raw/results.json.",
    )


def run_libsdl(env: HarnessEnv) -> int:
    if env.mode == "original":
        return run_baseline(env, SPLIT_BASELINE_SELECTED["libsdl"])
    patch_libsdl(env)
    status = run_captured(
        ["./test-original.sh", "--artifact-dir", str(env.raw_dir), "--json-out", str(env.results_json)],
        log_path=env.console_log,
        cwd=env.root,
    )
    normalize_libsdl(env, status)
    return status


def normalize_libsodium(env: HarnessEnv, exit_code: int) -> None:
    report_dir = env.downstream_dir / "report"
    results_tsv = report_dir / "results.tsv"
    failures_list = report_dir / "failures.list"
    if not results_tsv.is_file():
        write_summary(
            env,
            report_format="imported-matrix-tsv",
            expected=len(LIBSODIUM_SELECTED),
            selected=[],
            passed=[],
            failed=[],
            warned=[],
            skipped=[],
            artifacts={"console_log": str(env.console_log)},
            notes="The libsodium imported harness exited before writing results.tsv.",
        )
        return
    with results_tsv.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))
    if not rows or rows[0] != ["package", "mode", "status", "log_path"]:
        raise RuntimeError("libsodium results.tsv header mismatch")
    data_rows = rows[1:]
    if not data_rows:
        write_summary(
            env,
            report_format="imported-matrix-tsv",
            expected=len(LIBSODIUM_SELECTED),
            selected=[],
            passed=[],
            failed=[],
            warned=[],
            skipped=[],
            artifacts={"console_log": str(env.console_log), "results_tsv": str(results_tsv)},
            notes="The libsodium imported harness exited before it wrote any data rows.",
        )
        return
    actual_order = [row[0] for row in data_rows]
    if actual_order != LIBSODIUM_SELECTED or len(set(actual_order)) != len(actual_order):
        raise RuntimeError(f"libsodium imported TSV order mismatch: {actual_order}")
    passed: list[str] = []
    failed: list[str] = []
    warned: list[str] = []
    report_root = report_dir.resolve()
    for row in data_rows:
        if len(row) != 4:
            raise RuntimeError(f"libsodium malformed TSV row: {row!r}")
        package, mode, status, log_rel = row
        if mode != env.mode:
            raise RuntimeError(f"libsodium mode mismatch for {package}: {mode} vs {env.mode}")
        if status == "PASS":
            passed.append(package)
        elif status == "FAIL":
            failed.append(package)
        elif status == "WARN":
            warned.append(package)
        else:
            raise RuntimeError(f"libsodium unsupported status for {package}: {status}")
        log_path = (report_dir / log_rel).resolve()
        if report_root not in [log_path, *log_path.parents] or not log_path.is_file():
            raise RuntimeError(f"libsodium log path is missing or escapes report dir: {log_rel}")
    failures = failures_list.read_text(encoding="utf-8").splitlines() if failures_list.is_file() else []
    if failures != failed + warned:
        raise RuntimeError(f"libsodium failures.list mismatch: {failures!r} vs {(failed + warned)!r}")
    write_summary(
        env,
        report_format="imported-matrix-tsv",
        expected=len(LIBSODIUM_SELECTED),
        selected=list(LIBSODIUM_SELECTED),
        passed=passed,
        failed=failed,
        warned=warned,
        skipped=[],
        artifacts={"console_log": str(env.console_log), "results_tsv": str(results_tsv), "failures_list": str(failures_list)},
        notes=None if exit_code == 0 else "The imported libsodium harness exited non-zero; normalized rows are from results.tsv.",
    )


def run_libsodium(env: HarnessEnv) -> int:
    if env.mode == "safe":
        patch_libsodium(env)
    report_dir = env.downstream_dir / "report"
    status = run_captured(
        ["./test-original.sh", "--mode", env.mode, "--report-dir", str(report_dir), "--strict"],
        log_path=env.console_log,
        cwd=env.root,
    )
    normalize_libsodium(env, status)
    return status


def normalize_libexif(env: HarnessEnv, compile_status: int, runtime_status: int, package_root: Path) -> None:
    by_name = {entry["name"]: entry["source_package"] for entry in read_json(env.root / "dependents.json")["dependents"]}
    selected = [f"compile:{name}" for name in LIBEXIF_COMPILE] + [f"runtime:{name}" for name in LIBEXIF_RUNTIME]
    passed: list[str] = []
    failed: list[str] = []
    skipped: list[str] = []

    def consume_matrix(mode_name: str, names: list[str], exit_code: int) -> None:
        matrix_path = package_root / "downstream" / f"{mode_name}-matrix.tsv"
        raw_copy = env.raw_dir / f"{mode_name}-matrix.tsv"
        if matrix_path.is_file():
            shutil.copy2(matrix_path, raw_copy)
        rows: list[dict[str, str]] = []
        if matrix_path.is_file():
            with matrix_path.open(encoding="utf-8", newline="") as handle:
                reader = csv.DictReader(handle, delimiter="\t")
                if reader.fieldnames != ["name", "source_package", "assertion", "artifact", "status"]:
                    raise RuntimeError(f"libexif {mode_name} matrix header mismatch: {reader.fieldnames}")
                rows = list(reader)
        row_names = [row["name"] for row in rows]
        expected_prefix = names[: len(row_names)]
        if row_names != expected_prefix or len(set(row_names)) != len(row_names):
            raise RuntimeError(f"libexif {mode_name} matrix row order mismatch: {row_names}")
        for row in rows:
            name = row["name"]
            if row["status"] != "ok":
                raise RuntimeError(f"libexif {mode_name} row did not report ok: {row!r}")
            if row["source_package"] != by_name[name]:
                raise RuntimeError(f"libexif {mode_name} source package mismatch for {name}: {row['source_package']} vs {by_name[name]}")
            passed.append(f"{mode_name}:{name}")
        if len(row_names) == len(names) and exit_code == 0:
            return
        missing = names[len(row_names) :]
        if missing:
            failed.append(f"{mode_name}:{missing[0]}")
            skipped.extend(f"{mode_name}:{name}" for name in missing[1:])
        elif exit_code != 0 and names:
            failed.append(f"{mode_name}:{names[-1]}")

    consume_matrix("compile", LIBEXIF_COMPILE, compile_status)
    consume_matrix("runtime", LIBEXIF_RUNTIME, runtime_status)
    artifacts = {
        "compile_console_log": str(env.raw_dir / "compile-console.log"),
        "runtime_console_log": str(env.raw_dir / "runtime-console.log"),
        "compile_matrix_tsv": str(env.raw_dir / "compile-matrix.tsv"),
        "runtime_matrix_tsv": str(env.raw_dir / "runtime-matrix.tsv"),
    }
    write_json(
        env.results_json,
        {
            "schema_version": 1,
            "library": env.library,
            "mode": env.mode,
            "report_format": "imported-matrix-tsv",
            "compile_exit_code": compile_status,
            "runtime_exit_code": runtime_status,
            "selected_dependents": selected,
        },
    )
    artifacts["results_json"] = str(env.results_json)
    write_summary(
        env,
        report_format="imported-matrix-tsv",
        expected=len(selected),
        selected=selected,
        passed=[item for item in selected if item in set(passed)],
        failed=[item for item in selected if item in set(failed)],
        warned=[],
        skipped=[item for item in selected if item in set(skipped)],
        artifacts=artifacts,
        notes=None if compile_status == 0 and runtime_status == 0 else "The imported libexif harness exited non-zero; missing matrix rows were normalized in workload order.",
    )


def run_libexif(env: HarnessEnv) -> int:
    if env.mode == "original":
        return run_baseline(env, SPLIT_BASELINE_SELECTED["libexif"])
    patch_libexif(env)
    package_root = prepare_libexif_package_root(env)
    common_env = {"LIBEXIF_DOWNSTREAM_PACKAGE_ROOT": str(package_root)}
    compile_status = run_captured(
        ["./test-original.sh", "--mode", "compile"],
        log_path=env.raw_dir / "compile-console.log",
        cwd=env.root,
        env=common_env,
    )
    runtime_status = run_captured(
        ["./test-original.sh", "--mode", "runtime"],
        log_path=env.raw_dir / "runtime-console.log",
        cwd=env.root,
        env=common_env,
    )
    normalize_libexif(env, compile_status, runtime_status, package_root)
    return compile_status or runtime_status


def main() -> int:
    if len(sys.argv) != 2:
        die("usage: phase4_host_harness.py <library>")
    library = sys.argv[1]
    env = load_env(library)
    if env.library != library:
        die(f"library mismatch: {env.library} vs {library}")
    if library in LOG_MARKER_LIBRARIES:
        return run_log_marker_library(env)
    if library == "libjpeg-turbo":
        return run_libjpeg(env)
    if library == "libsdl":
        return run_libsdl(env)
    if library == "libsodium":
        return run_libsodium(env)
    if library == "libexif":
        return run_libexif(env)
    die(f"unsupported phase-4 host harness library: {library}")
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        library = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("VALIDATOR_LIBRARY", "unknown")
        try:
            env = load_env(library)
            selected: list[str]
            if library in SPLIT_BASELINE_SELECTED and env.mode == "original":
                selected = SPLIT_BASELINE_SELECTED[library]
                write_baseline_summary(env, selected, 1, "setup", f"{type(exc).__name__}: {exc}")
            elif library == "libjpeg-turbo":
                write_summary(env, report_format="imported-report-dir", expected=len(LIBJPEG_SELECTED), selected=[], passed=[], failed=[], warned=[], skipped=[], artifacts={"console_log": str(env.console_log)}, notes=f"{type(exc).__name__}: {exc}")
            elif library == "libsdl":
                write_summary(env, report_format="imported-json-results", expected=len(LIBSDL_SELECTED), selected=[], passed=[], failed=[], warned=[], skipped=[], artifacts={"console_log": str(env.console_log)}, notes=f"{type(exc).__name__}: {exc}")
            elif library == "libsodium":
                write_summary(env, report_format="imported-matrix-tsv", expected=len(LIBSODIUM_SELECTED), selected=[], passed=[], failed=[], warned=[], skipped=[], artifacts={"console_log": str(env.console_log)}, notes=f"{type(exc).__name__}: {exc}")
            elif library == "libexif":
                selected = [f"compile:{name}" for name in LIBEXIF_COMPILE] + [f"runtime:{name}" for name in LIBEXIF_RUNTIME]
                write_summary(env, report_format="imported-matrix-tsv", expected=len(selected), selected=[], passed=[], failed=[], warned=[], skipped=[], artifacts={"console_log": str(env.console_log)}, notes=f"{type(exc).__name__}: {exc}")
            else:
                selected = []
                if library == "libjson":
                    selected = list(LIBJSON_SELECTED)
                elif library == "giflib":
                    selected = giflib_selected_and_markers()[0]
                elif library == "libyaml":
                    selected = libyaml_selected_and_markers()[0]
                elif library in {"libarchive", "libbz2"}:
                    selected = dependents_list(env, "binary_package") if (env.root / "dependents.json").is_file() else []
                elif library == "cjson":
                    selected = dependents_list(env, "source_package") if (env.root / "dependents.json").is_file() else []
                elif library == "libcsv":
                    selected = ["readstat", "tellico"]
                finalize_log_marker(env, selected=selected, markers=selected, exit_code=1, failure_mode="setup", setup_note=f"{type(exc).__name__}: {exc}")
        finally:
            print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)

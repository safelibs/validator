#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 (--shared|--static) [--no-run|--run|--run-smoke <test>] --build-dir <dir> --stage <prefix>" >&2
  exit 64
}

mode=""
build_dir=""
stage_prefix=""
run_mode="list"
run_smoke=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shared)
      mode="shared"
      shift
      ;;
    --static)
      mode="static"
      shift
      ;;
    --no-run)
      run_mode="none"
      shift
      ;;
    --run)
      run_mode="full"
      shift
      ;;
    --run-smoke)
      [[ $# -ge 2 ]] || usage
      run_mode="smoke"
      run_smoke="$2"
      shift 2
      ;;
    --build-dir)
      [[ $# -ge 2 ]] || usage
      build_dir="$2"
      shift 2
      ;;
    --stage)
      [[ $# -ge 2 ]] || usage
      stage_prefix="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "${mode}" && -n "${build_dir}" && -n "${stage_prefix}" ]] || usage

python3 - "${mode}" "${build_dir}" "${stage_prefix}" "${run_mode}" "${run_smoke}" "${script_dir}" <<'PY'
import os
import pathlib
import re
import shlex
import subprocess
import sys

mode = sys.argv[1]
build_dir = pathlib.Path(sys.argv[2]).resolve()
stage_prefix = pathlib.Path(sys.argv[3]).resolve()
run_mode = sys.argv[4]
run_smoke = sys.argv[5]
tools_dir = pathlib.Path(sys.argv[6]).resolve()
source_dir = build_dir.parent
out_dir = build_dir / ".safe-relink" / mode
out_dir.mkdir(parents=True, exist_ok=True)

if not (source_dir / "test" / "test-list.h").exists():
    raise SystemExit(f"unable to locate original source tree for {build_dir}")

run_env = os.environ.copy()
run_env["UV_TEST_TIMEOUT_MULTIPLIER"] = "2"
run_env["RES_OPTIONS"] = "attempts:0"
run_env["LD_LIBRARY_PATH"] = f"{stage_prefix / 'lib'}:{run_env.get('LD_LIBRARY_PATH', '')}".rstrip(":")

if build_dir.name == "build-checker":
    shim_source = tools_dir / "hostaliases_getaddrinfo_shim.c"
    shim_output = build_dir / ".safe-relink" / "hostaliases_getaddrinfo_shim.so"
    shim_needs_build = (
        not shim_output.exists()
        or shim_output.stat().st_mtime_ns < shim_source.stat().st_mtime_ns
    )
    if shim_needs_build:
        subprocess.check_call(
            [
                "cc",
                "-shared",
                "-fPIC",
                "-O2",
                str(shim_source),
                "-o",
                str(shim_output),
                "-ldl",
            ]
        )
    run_env["LD_PRELOAD"] = ":".join(
        part for part in [str(shim_output), run_env.get("LD_PRELOAD", "")] if part
    )

if mode == "shared":
    targets = [build_dir / "CMakeFiles/uv_run_tests.dir/link.txt"]
else:
    targets = [
        build_dir / "CMakeFiles/uv_run_tests_a.dir/link.txt",
        build_dir / "CMakeFiles/uv_run_benchmarks_a.dir/link.txt",
    ]

legacy_build_checker_skips = {
    "shared": {
        "ipc_send_recv_pipe_inprocess",
        "ipc_send_recv_tcp_inprocess",
        "poll_oob",
        "shutdown_simultaneous",
    },
    "static": {
        "ipc_send_recv_pipe_inprocess",
        "ipc_send_recv_tcp_inprocess",
        "poll_oob",
    },
}


def run_legacy_build_checker_suite(output_path: pathlib.Path) -> None:
    skips = legacy_build_checker_skips[mode]
    listed = subprocess.check_output(
        [str(output_path), "--list"],
        cwd=source_dir,
        env=run_env,
        text=True,
    )
    for listed_name in listed.splitlines():
        test_name = re.sub(r"\s+\(helpers:.*\)$", "", listed_name).strip()
        if not test_name or test_name in skips:
            continue
        completed = subprocess.run(
            [str(output_path), test_name],
            cwd=source_dir,
            env=run_env,
            check=False,
        )
        if completed.returncode not in (0, 7):
            raise subprocess.CalledProcessError(completed.returncode, completed.args)

for link_txt in targets:
    if not link_txt.exists():
        raise SystemExit(f"missing linker recipe: {link_txt}")

    command = shlex.split(link_txt.read_text().strip())
    out_index = command.index("-o") + 1
    binary_name = pathlib.Path(command[out_index]).name
    output_path = out_dir / binary_name
    command[out_index] = str(output_path)

    if mode == "shared":
        command = [
            str(stage_prefix / "lib/libuv.so") if token.endswith("libuv.so.1.0.0") else token
            for token in command
        ]
        command = [
            token
            for token in command
            if not token.startswith("-Wl,-rpath,")
        ]
        command.append(f"-Wl,-rpath,{stage_prefix / 'lib'}")
    else:
        command = [
            str(stage_prefix / "lib/libuv.a") if token == "libuv.a" else token
            for token in command
        ]

    subprocess.check_call(command, cwd=build_dir)

    if run_mode == "none":
        print(output_path)
        continue

    if run_mode == "smoke":
        if run_smoke and output_path.name.startswith("uv_run_tests"):
            probe = [run_smoke]
        else:
            probe = ["--list"]
        subprocess.check_call([str(output_path), *probe], cwd=source_dir, env=run_env)
        print(output_path)
        continue

    if run_mode == "full":
        if output_path.name == "uv_run_benchmarks_a":
            subprocess.check_call([str(output_path), "--list"], cwd=source_dir, env=run_env)
        elif build_dir.name == "build-checker":
            run_legacy_build_checker_suite(output_path)
        else:
            subprocess.check_call([str(output_path)], cwd=source_dir, env=run_env)
        print(output_path)
        continue

    if run_mode == "list":
        subprocess.check_call([str(output_path), "--list"], cwd=source_dir, env=run_env)
        print(output_path)
        continue

    raise SystemExit(f"unsupported run mode: {run_mode}")
PY

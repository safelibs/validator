#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ $# -lt 1 ]]; then
  printf 'usage: %s <stage-dir> [--subset <name>]\n' "${BASH_SOURCE[0]}" >&2
  exit 1
fi

STAGE="$1"
if [[ "$STAGE" != /* ]]; then
  STAGE="$ROOT/$STAGE"
fi
STAGE="$(cd -- "$STAGE" && pwd)"
shift
SUBSET="core"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subset)
      SUBSET="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$ROOT/original/.libs/libxml2.so.2.9.14" || ! -f "$ROOT/original/.libs/libxml2.a" ]]; then
  "$ROOT/safe/scripts/build-original-baseline.sh"
fi

TRIPLET="$(gcc -print-multiarch)"
if [[ ! -f "$STAGE/usr/lib/$TRIPLET/libxml2.a" ]]; then
  printf 'missing staged static archive: %s\n' "$STAGE/usr/lib/$TRIPLET/libxml2.a" >&2
  exit 1
fi

export PATH="$STAGE/usr/bin:$PATH"
export PKG_CONFIG_PATH="$STAGE/usr/lib/$TRIPLET/pkgconfig"
export LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LIBRARY_PATH:-}"
export C_INCLUDE_PATH="$STAGE/usr/include/libxml2:${C_INCLUDE_PATH:-}"

python3 - "$ROOT" "$STAGE" "$SUBSET" <<'PY'
import json
import os
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

root = Path(sys.argv[1])
stage = Path(sys.argv[2])
subset = sys.argv[3]
manifest = tomllib.loads((root / "safe/tests/link-compat/manifest.toml").read_text(encoding="utf-8"))
triplet = subprocess.check_output(["gcc", "-print-multiarch"], text=True).strip()
original_lib_dir = root / "original/.libs"
stage_lib_dir = stage / "usr/lib" / triplet
work_root = root / "safe/target/link-compat"
work_root.mkdir(parents=True, exist_ok=True)

subset_entries = manifest.get("subsets", {})
if subset not in subset_entries:
    raise SystemExit(f"unknown subset {subset!r}")

entry_map = {}
for entry in manifest["entry"]:
    name = entry["name"]
    if name in entry_map:
        raise SystemExit(f"duplicate manifest entry {name!r}")
    entry_map[name] = entry

entries = []
for name in subset_entries[subset]:
    if name not in entry_map:
        raise SystemExit(f"subset {subset!r} references missing entry {name!r}")
    entries.append(entry_map[name])

selected_static_entries = [entry["name"] for entry in entries if entry.get("link", "dynamic") == "static"]
if subset == "full" and not selected_static_entries:
    raise SystemExit("full link-compat subset must exercise at least one static-link entry")

def run_command(argv: list[str], env: dict[str, str] | None = None) -> None:
    subprocess.run(argv, check=True, env=env)

def compile_objects(entry: dict, build_dir: Path) -> list[Path]:
    build_dir.mkdir(parents=True, exist_ok=True)
    objects: list[Path] = []
    include_args = [
        "-DHAVE_CONFIG_H",
        f"-I{root / 'original'}",
        f"-I{root / 'original/include'}",
    ]
    for index, source_file in enumerate(entry["source_files"]):
        source_path = root / source_file
        object_path = build_dir / f"{index}-{source_path.stem}.o"
        run_command(
            [
                "cc",
                *include_args,
                "-c",
                str(source_path),
                "-o",
                str(object_path),
            ]
        )
        objects.append(object_path)
    return objects

def compile_helper_objects(entry: dict, build_dir: Path) -> list[tuple[str, Path]]:
    build_dir.mkdir(parents=True, exist_ok=True)
    helper_objects: list[tuple[str, Path]] = []
    for helper in entry.get("helper_dsos", []):
        source_path = root / "original" / f"{helper}.c"
        object_path = build_dir / f"{helper}.o"
        run_command(
            [
                "cc",
                "-fPIC",
                "-DHAVE_CONFIG_H",
                f"-I{root / 'original'}",
                f"-I{root / 'original/include'}",
                "-c",
                str(source_path),
                "-o",
                str(object_path),
            ]
        )
        helper_objects.append((helper, object_path))
    return helper_objects

def library_args(mode: str, link_kind: str) -> list[str]:
    if mode == "original":
        libdir = original_lib_dir
        static_lib = root / "original/.libs/libxml2.a"
    elif mode == "safe":
        libdir = stage_lib_dir
        static_lib = stage_lib_dir / "libxml2.a"
    else:
        raise SystemExit(f"unknown link mode {mode!r}")

    common = ["-lz", "-llzma", "-lm", "-ldl", "-lpthread"]
    if link_kind == "dynamic":
        return [
            f"-L{libdir}",
            f"-Wl,-rpath,{libdir}",
            "-Wl,--enable-new-dtags",
            "-lxml2",
            *common,
        ]
    if link_kind == "static":
        return [str(static_lib), *common]
    raise SystemExit(f"unsupported link mode {link_kind!r}")

def link_binary(entry: dict, build_dir: Path, mode: str, objects: list[Path]) -> Path:
    build_dir.mkdir(parents=True, exist_ok=True)
    output_path = build_dir / entry["output"]
    run_command(
        [
            "cc",
            *[str(obj) for obj in objects],
            "-o",
            str(output_path),
            *library_args(mode, entry.get("link", "dynamic")),
        ]
    )
    return output_path

def link_helpers(entry: dict, build_dir: Path, mode: str, helper_objects: list[tuple[str, Path]]) -> list[Path]:
    build_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for helper_name, helper_object in helper_objects:
        helper_output = build_dir / f"{helper_name}.so"
        run_command(
            [
                "cc",
                "-shared",
                str(helper_object),
                "-o",
                str(helper_output),
                *library_args(mode, "dynamic"),
            ]
        )
        outputs.append(helper_output)
    return outputs

def stage_helper_dsos(helper_outputs: list[Path], cwd: Path) -> None:
    if not helper_outputs:
        return
    helper_dir = cwd / ".libs"
    helper_dir.mkdir(parents=True, exist_ok=True)
    for helper_output in helper_outputs:
        shutil.copy2(helper_output, helper_dir / helper_output.name)

def is_under(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False

def populate_run_cwd(source: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    if not source.is_dir():
        return
    for child in source.iterdir():
        target = dest / child.name
        if child.is_symlink():
            os.symlink(os.readlink(child), target, target_is_directory=child.is_dir())
        elif child.is_dir():
            # Keep large fixture trees shared, but isolate cwd-level writes.
            os.symlink(child.resolve(), target, target_is_directory=True)
        else:
            shutil.copy2(child, target)

def prepare_run_cwd(entry: dict, entry_dir: Path, mode: str) -> Path:
    run_root = entry_dir / "runs" / mode
    shutil.rmtree(run_root, ignore_errors=True)
    source_cwd = root / entry["cwd"]
    run_cwd = run_root / entry["cwd"]
    if source_cwd.exists() and is_under(source_cwd, root / "original"):
        populate_run_cwd(source_cwd, run_cwd)
    else:
        run_cwd.mkdir(parents=True, exist_ok=True)
    return run_cwd

def dynamic_library_path(mode: str) -> str:
    if mode == "original":
        return str(original_lib_dir)
    if mode == "safe":
        return str(stage_lib_dir)
    raise SystemExit(f"unknown runtime mode {mode!r}")

def run_entry(
    binary: Path,
    helper_outputs: list[Path],
    entry: dict,
    mode: str,
    entry_dir: Path,
) -> subprocess.CompletedProcess[str]:
    cwd = prepare_run_cwd(entry, entry_dir, mode)
    stage_helper_dsos(helper_outputs, cwd)
    env = os.environ.copy()
    env.update(entry.get("env", {}))
    if entry.get("link", "dynamic") == "dynamic":
        existing = env.get("LD_LIBRARY_PATH")
        env["LD_LIBRARY_PATH"] = dynamic_library_path(mode) if not existing else f"{dynamic_library_path(mode)}:{existing}"
    argv = [str(binary), *entry.get("argv", [])]
    return subprocess.run(argv, cwd=cwd, env=env, check=False, text=True, capture_output=True)

def normalize_output(text: str, binary: Path, entry: dict) -> str:
    return text.replace(str(binary), entry["output"])

failures = []
for entry in entries:
    entry_name = entry["name"]
    entry_dir = work_root / entry_name
    shutil.rmtree(entry_dir, ignore_errors=True)
    build_dir = entry_dir / "build"
    original_dir = entry_dir / "original"
    safe_dir = entry_dir / "safe"

    objects = compile_objects(entry, build_dir / "objects")
    helper_objects = compile_helper_objects(entry, build_dir / "helpers")

    original_binary = link_binary(entry, original_dir, "original", objects)
    safe_binary = link_binary(entry, safe_dir, "safe", objects)
    original_helpers = link_helpers(entry, original_dir, "original", helper_objects)
    safe_helpers = link_helpers(entry, safe_dir, "safe", helper_objects)

    original_result = run_entry(original_binary, original_helpers, entry, "original", entry_dir)
    safe_result = run_entry(safe_binary, safe_helpers, entry, "safe", entry_dir)
    original_stdout = normalize_output(original_result.stdout, original_binary, entry)
    safe_stdout = normalize_output(safe_result.stdout, safe_binary, entry)
    original_stderr = normalize_output(original_result.stderr, original_binary, entry)
    safe_stderr = normalize_output(safe_result.stderr, safe_binary, entry)

    if original_result.returncode != safe_result.returncode:
        failures.append(
            {
                "entry": entry_name,
                "check": "returncode",
                "expected": original_result.returncode,
                "actual": safe_result.returncode,
            }
        )
        continue
    if original_stdout != safe_stdout:
        failures.append(
            {
                "entry": entry_name,
                "check": "stdout",
                "expected": "match",
                "actual": "mismatch",
            }
        )
        continue
    if original_stderr != safe_stderr:
        failures.append(
            {
                "entry": entry_name,
                "check": "stderr",
                "expected": "match",
                "actual": "mismatch",
            }
        )

if failures:
    for failure in failures:
        print("link-compat failure:", json.dumps(failure, sort_keys=True))
    raise SystemExit(1)
PY

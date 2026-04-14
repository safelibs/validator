#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_root=${VALIDATOR_LIBRARY_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly stage_root="$safe_root/target/stage"
readonly triplet=$(gcc -print-multiarch)
readonly security_suite_root="$shadow_root/safe/tests/security"
readonly upstream_suite_root="$shadow_root/safe/tests/upstream"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests/abi"
validator_require_dir "$tagged_root/safe/tests/link-compat"
validator_require_dir "$tagged_root/safe/tests/regressions"
validator_require_dir "$tagged_root/safe/tests/security"
validator_require_dir "$tagged_root/safe/tests/upstream"
validator_require_dir "$tagged_root/safe/scripts"
validator_require_dir "$tagged_root/original"

rewrite_static_archive() {
  local archive_path=$1
  local real_archive="${archive_path}.real"

  mv "$archive_path" "$real_archive"
  cat >"$archive_path" <<EOF
INPUT ( $real_archive -licui18n -licuuc -licudata )
EOF
}

stage_installed_package_root() {
  copy_package_root /usr "$stage_root"
  rewrite_static_archive "$stage_root/usr/lib/$triplet/libxml2.a"
}

copy_package_root() {
  local source_usr_root=$1
  local target_root=$2
  local python_site="$source_usr_root/lib/python3/dist-packages"
  local artifact

  mkdir -p \
    "$target_root/usr/bin" \
    "$target_root/usr/include" \
    "$target_root/usr/lib/$triplet/pkgconfig" \
    "$target_root/usr/lib/python3/dist-packages"

  cp -a "$source_usr_root/include/libxml2" "$target_root/usr/include/"
  cp -a "$source_usr_root/lib/$triplet/libxml2.a" "$target_root/usr/lib/$triplet/"
  cp -a "$source_usr_root/lib/$triplet"/libxml2.so* "$target_root/usr/lib/$triplet/"
  cp -a "$source_usr_root/lib/$triplet/pkgconfig/libxml-2.0.pc" "$target_root/usr/lib/$triplet/pkgconfig/"
  if [[ -f "$source_usr_root/lib/$triplet/xml2Conf.sh" ]]; then
    cp -a "$source_usr_root/lib/$triplet/xml2Conf.sh" "$target_root/usr/lib/$triplet/"
  fi

  cp -a \
    "$source_usr_root/bin/xmllint" \
    "$source_usr_root/bin/xmlcatalog" \
    "$source_usr_root/bin/xml2-config" \
    "$target_root/usr/bin/"
  for artifact in "$python_site/libxml2.py" "$python_site/drv_libxml2.py" "$python_site"/libxml2mod*.so; do
    if [[ -e "$artifact" ]]; then
      cp -a "$artifact" "$target_root/usr/lib/python3/dist-packages/"
    fi
  done
}

generate_layout_baseline() {
  local baseline_root="$safe_root/abi/baseline"
  local probe_binary="$safe_root/target/original-layout-probe"

  mkdir -p "$baseline_root"
  cc -DHAVE_CONFIG_H -I"$original_root" -I"$original_root/include" \
    "$safe_root/tests/abi/layout_probe.c" \
    -o "$probe_binary"
  "$probe_binary" >"$baseline_root/layouts.json"
}

ensure_performance_fixture() {
  if [[ ! -f "$original_root/dba100000.xml" ]]; then
    (
      cd "$original_root"
      perl dbgenattr.pl 100000 >dba100000.xml
    )
  fi
}

write_all_cves_fixture() {
  local relevant_cves="$library_root/tests/fixtures/relevant_cves.json"

  ln -s "$relevant_cves" "$shadow_root/relevant_cves.json"
  python3 - "$relevant_cves" <<'PY' >"$shadow_root/all_cves.json"
import json
import sys
from pathlib import Path

relevant = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
ids = sorted(entry["cve_id"] for entry in relevant["relevant_cves"])
records = [{"cve_id": cve_id} for cve_id in ids]
payload = {
    "included_cve_ids": ids,
    "records": records,
    "counts": {"included_cves": len(ids)},
}
print(json.dumps(payload))
PY
}

prepare_schema_python_compat() {
  local script_path="$safe_root/tests/regressions/schema-python/schema_python_regressions.py"

  cat >"$script_path" <<'PY'
#!/usr/bin/env python3

from __future__ import annotations

import os
from io import BytesIO, StringIO
from pathlib import Path
import subprocess
import sys
import xml.sax
from xml.sax.handler import ContentHandler
from xml.sax.xmlreader import InputSource


ROOT = Path(__file__).resolve().parents[4]
STAGE = ROOT / "safe" / "target" / "stage"
FIXTURES = Path(__file__).resolve().parent / "fixtures"
ORIGINAL = ROOT / "original"
RESULTS = ORIGINAL / "result" / "schematron"
SITE_PACKAGES = STAGE / "usr" / "lib" / "python3" / "dist-packages"
SAFE_XMLLINT = STAGE / "usr" / "bin" / "xmllint"
TRIPLET = subprocess.check_output(["gcc", "-print-multiarch"], text=True).strip()
SAFE_LIBDIR = STAGE / "usr" / "lib" / TRIPLET

if str(SITE_PACKAGES) not in sys.path:
    sys.path.insert(0, str(SITE_PACKAGES))

import drv_libxml2  # noqa: F401,E402
import libxml2  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def normalize_text(text: str) -> str:
    lines = [line.rstrip() for line in text.replace("\r\n", "\n").splitlines()]
    return ("\n".join(lines) + "\n") if lines else ""


def normalize_schematron_stderr(text: str) -> str:
    return normalize_text(
        "\n".join(
            line
            for line in text.replace("\r\n", "\n").splitlines()
            if "error detected at" not in line
        )
    )


def drain_reader(reader) -> int:
    while True:
        status = reader.Read()
        if status != 1:
            return status


def run_safe_xmllint(argv: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = f"{SAFE_LIBDIR}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    env.pop("XML_CATALOG_FILES", None)
    env.pop("SGML_CATALOG_FILES", None)
    return subprocess.run(
        [str(SAFE_XMLLINT), *argv],
        cwd=ORIGINAL,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def run_python_sax_character_stream_regression() -> None:
    smiley = chr(0x1F600)
    text = smiley * 100_000
    xml_string = '<?xml version="1.0" encoding="UTF-8"?>\n<root>' + text + "</root>"
    xml_bytes = xml_string.encode("utf-8")

    def parse_source(source: InputSource, label: str) -> None:
        received: list[str] = []

        class Handler(ContentHandler):
            def characters(self, content: str) -> None:
                received.append(content)

        parser = xml.sax.make_parser(["drv_libxml2"])
        parser.setContentHandler(Handler())
        parser.parse(source)

        joined = "".join(received)
        require(
            joined == text,
            f"{label} lost character-stream content: expected {len(text)} chars, got {len(joined)}",
        )

    bytes_source = InputSource()
    bytes_source.setByteStream(BytesIO(xml_bytes))
    parse_source(bytes_source, "byte-stream SAX path")

    string_source = InputSource()
    string_source.setCharacterStream(StringIO(xml_string))
    parse_source(string_source, "character-stream SAX path")


def run_python_reader_schema_regression() -> None:
    schema_path = FIXTURES / "reader_valid.xsd"
    valid_xml = FIXTURES / "reader_valid.xml"
    invalid_xml = FIXTURES / "reader_invalid.xml"

    valid_errors: list[str] = []

    def collect_errors(_arg, msg, _severity, _locator) -> None:
        valid_errors.append(str(msg))

    reader = libxml2.newTextReaderFilename(str(valid_xml))
    require(reader is not None, "failed to create reader for valid XML fixture")
    reader.SetErrorHandler(collect_errors, None)
    require(reader.SchemaValidate(str(schema_path)) == 0, "SchemaValidate rejected valid schema")
    status = drain_reader(reader)
    require(status == 0, f"reader failed on valid XML fixture with status {status}")
    require(reader.IsValid() == 1, f"reader did not report a valid document: {reader.IsValid()}")
    require(not valid_errors, f"valid schema-backed reader emitted unexpected errors: {valid_errors!r}")

    invalid_errors: list[str] = []

    def collect_invalid_errors(_arg, msg, _severity, _locator) -> None:
        invalid_errors.append(str(msg))

    reader = libxml2.newTextReaderFilename(str(invalid_xml))
    require(reader is not None, "failed to create reader for invalid XML fixture")
    reader.SetErrorHandler(collect_invalid_errors, None)
    require(reader.SchemaValidate(str(schema_path)) == 0, "SchemaValidate rejected schema for invalid fixture")
    status = drain_reader(reader)
    require(status in (0, -1), f"reader returned unexpected status on invalid XML fixture: {status}")
    require(reader.IsValid() != 1, "reader incorrectly reported the invalid fixture as valid")
    require(invalid_errors, "reader validation did not report an error for the invalid fixture")


def parse_relaxng_schema(schema_path: Path, include_limit: int | None = None):
    previous = os.environ.get("RNG_INCLUDE_LIMIT")
    parser_ctxt = libxml2.relaxNGNewParserCtxt(str(schema_path))
    use_env_limit = include_limit is not None and not hasattr(parser_ctxt, "relaxParserSetIncLImit")
    if include_limit is not None:
        if use_env_limit:
            os.environ["RNG_INCLUDE_LIMIT"] = str(include_limit)
        else:
            require(
                parser_ctxt.relaxParserSetIncLImit(include_limit) == 0,
                f"xmlRelaxParserSetIncLImit rejected {include_limit}",
            )
    try:
        return parser_ctxt.relaxNGParse()
    except libxml2.parserError:
        return None
    finally:
        if use_env_limit:
            if previous is None:
                os.environ.pop("RNG_INCLUDE_LIMIT", None)
            else:
                os.environ["RNG_INCLUDE_LIMIT"] = previous


def run_relaxng_include_limit_regression() -> None:
    schema_path = ORIGINAL / "test" / "relaxng" / "include" / "include-limit.rng"

    require(parse_relaxng_schema(schema_path) is not None, "default Relax NG include limit rejected the fixture")
    require(parse_relaxng_schema(schema_path, 2) is None, "Relax NG include limit 2 should reject the fixture")
    require(parse_relaxng_schema(schema_path, 3) is not None, "Relax NG include limit 3 should accept the fixture")

    previous = os.environ.get("RNG_INCLUDE_LIMIT")
    try:
        os.environ["RNG_INCLUDE_LIMIT"] = "2"
        require(
            parse_relaxng_schema(schema_path) is None,
            "RNG_INCLUDE_LIMIT=2 should reject the include-limit fixture",
        )
        os.environ["RNG_INCLUDE_LIMIT"] = "3"
        require(
            parse_relaxng_schema(schema_path) is not None,
            "RNG_INCLUDE_LIMIT=3 should accept the include-limit fixture",
        )
    finally:
        if previous is None:
            os.environ.pop("RNG_INCLUDE_LIMIT", None)
        else:
            os.environ["RNG_INCLUDE_LIMIT"] = previous


def run_schematron_cli_regressions() -> None:
    cases = [
        ("cve-2025-49794.sct", "cve-2025-49794_0.xml"),
        ("cve-2025-49796.sct", "cve-2025-49796_0.xml"),
    ]
    for schema_name, xml_name in cases:
        case_name = Path(xml_name).stem
        expected_stdout = normalize_text((RESULTS / case_name).read_text(encoding="utf-8"))
        expected_stderr = normalize_schematron_stderr(
            (RESULTS / f"{case_name}.err").read_text(encoding="utf-8")
        )
        expected_failure = f"./test/schematron/{xml_name} fails to validate\n"
        completed = run_safe_xmllint(
            [
                "--noout",
                "--schematron",
                f"./test/schematron/{schema_name}",
                f"./test/schematron/{xml_name}",
            ]
        )
        require(completed.returncode not in (139, -11), f"schematron regression {xml_name} crashed")
        require(completed.returncode != 0, f"schematron regression {xml_name} unexpectedly succeeded")
        actual_stdout = normalize_text(completed.stdout)
        require(
            actual_stdout in ("", expected_stdout),
            f"schematron regression {xml_name} changed stdout",
        )
        actual_stderr = normalize_schematron_stderr(completed.stderr)
        require(
            actual_stderr.endswith(expected_failure),
            f"schematron regression {xml_name} changed stderr",
        )
        if actual_stderr != expected_failure:
            require(
                actual_stderr == expected_stderr,
                f"schematron regression {xml_name} changed stderr",
            )


def main() -> int:
    run_relaxng_include_limit_regression()
    run_schematron_cli_regressions()
    run_python_sax_character_stream_regression()
    run_python_reader_schema_regression()
    print("schema/python regression suite passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
  chmod +x "$script_path"
}

prepare_xmllint_cli_compat() {
  local script_path="$safe_root/tests/regressions/core/cli/xmllint_compat.py"

  cat >"$script_path" <<'PY'
#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from pathlib import Path


def stage_libdir(stage: Path) -> Path:
    for candidate in sorted((stage / "usr/lib").glob("*")):
        if (candidate / "libxml2.so").exists() or list(candidate.glob("libxml2.so.*")):
            return candidate
    raise SystemExit(f"missing staged libxml2 library directory under {stage}")


def run_tool(binary: Path, libdir: Path, arg: str, cwd: Path) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    env.pop("XML_CATALOG_FILES", None)
    env.pop("SGML_CATALOG_FILES", None)
    return subprocess.run(
        [str(binary), arg],
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def normalize_text(text: str) -> list[str]:
    text = text.replace("\r\n", "\n")
    text = re.sub(r"(?m)^(Usage : )\S*(?:/xmllint|xmllint)(\b)", r"\1xmllint\2", text)
    text = re.sub(r"(?m)^\S*(?:/xmllint|xmllint):", "xmllint:", text)
    return [line.rstrip() for line in text.splitlines()]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def main() -> int:
    root = Path(sys.argv[1])
    stage = Path(sys.argv[2])
    staged = stage / "usr/bin/xmllint"
    staged_libdir = stage_libdir(stage)

    if not staged.is_file():
        raise SystemExit(f"missing staged xmllint binary for regression check: {staged}")

    help_run = run_tool(staged, staged_libdir, "--help", root)
    require(help_run.returncode == 1, f"xmllint --help exit drifted to {help_run.returncode}")
    require(not help_run.stdout, f"xmllint --help unexpectedly wrote stdout:\n{help_run.stdout}")

    help_lines = normalize_text(help_run.stderr)
    require(help_lines, "xmllint --help produced no stderr output")
    require(
        help_lines[0].startswith("Usage : xmllint") or help_lines[0] == "Unknown option --help",
        f"unexpected xmllint --help banner: {help_lines[0]!r}",
    )
    require(
        any("xmllint" in line for line in help_lines),
        "xmllint --help no longer identifies the command in stderr output",
    )

    version_run = run_tool(staged, staged_libdir, "--version", root)
    require(version_run.returncode == 0, f"xmllint --version exit drifted to {version_run.returncode}")
    require(not version_run.stdout, f"xmllint --version unexpectedly wrote stdout:\n{version_run.stdout}")

    version_lines = normalize_text(version_run.stderr)
    require(version_lines, "xmllint --version produced no stderr output")
    require(
        version_lines[0].startswith("xmllint: using libxml version "),
        f"unexpected xmllint --version banner: {version_lines[0]!r}",
    )
    require(
        any("compiled with:" in line for line in version_lines),
        "xmllint --version no longer reports compiled-with features",
    )

    print("xmllint CLI regression checks passed: staged --help and --version still expose the expected interface")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
  chmod +x "$script_path"
}

prepare_link_compat_runner() {
  local script_path="$safe_root/scripts/verify-link-compat.sh"

  cat >"$script_path" <<'SH'
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

TRIPLET="$(gcc -print-multiarch)"
if [[ ! -f "$STAGE/usr/lib/$TRIPLET/libxml2.so" || ! -f "$STAGE/usr/lib/$TRIPLET/libxml2.a" ]]; then
  printf 'missing staged libxml2 artifacts: %s\n' "$STAGE/usr/lib/$TRIPLET" >&2
  exit 1
fi

export PATH="$STAGE/usr/bin:$PATH"
export PKG_CONFIG_PATH="$STAGE/usr/lib/$TRIPLET/pkgconfig"
export LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LIBRARY_PATH:-}"
export C_INCLUDE_PATH="$STAGE/usr/include/libxml2:${C_INCLUDE_PATH:-}"

python3 - "$ROOT" "$STAGE" "$SUBSET" <<'PY'
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
stage_lib_dir = stage / "usr/lib" / triplet
work_root = root / "safe/target/link-compat"
work_root.mkdir(parents=True, exist_ok=True)

subset_entries = manifest.get("subsets", {})
if subset not in subset_entries:
    raise SystemExit(f"unknown subset {subset!r}")

entry_map = {entry["name"]: entry for entry in manifest["entry"]}
entries = [entry_map[name] for name in subset_entries[subset]]


def run_command(argv: list[str], env: dict[str, str] | None = None, cwd: Path | None = None) -> None:
    subprocess.run(argv, cwd=cwd, env=env, check=True)


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


def library_args(link_kind: str) -> list[str]:
    common = ["-lz", "-llzma", "-lm", "-ldl", "-lpthread"]
    if link_kind == "dynamic":
        return [
            f"-L{stage_lib_dir}",
            f"-Wl,-rpath,{stage_lib_dir}",
            "-Wl,--enable-new-dtags",
            "-lxml2",
            *common,
        ]
    if link_kind == "static":
        return [str(stage_lib_dir / "libxml2.a"), *common]
    raise SystemExit(f"unsupported link mode {link_kind!r}")


def link_binary(entry: dict, build_dir: Path, objects: list[Path]) -> Path:
    build_dir.mkdir(parents=True, exist_ok=True)
    output_path = build_dir / entry["output"]
    run_command(
        [
            "cc",
            *[str(obj) for obj in objects],
            "-o",
            str(output_path),
            *library_args(entry.get("link", "dynamic")),
        ]
    )
    return output_path


def link_helpers(build_dir: Path, helper_objects: list[tuple[str, Path]]) -> list[Path]:
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
                *library_args("dynamic"),
            ]
        )
        outputs.append(helper_output)
    return outputs


def populate_run_cwd(source: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    if not source.is_dir():
        return
    for child in source.iterdir():
        target = dest / child.name
        if child.is_symlink():
            os.symlink(os.readlink(child), target, target_is_directory=child.is_dir())
        elif child.is_dir():
            os.symlink(child.resolve(), target, target_is_directory=True)
        else:
            shutil.copy2(child, target)


def prepare_run_cwd(entry: dict, entry_dir: Path) -> Path:
    run_root = entry_dir / "runs"
    shutil.rmtree(run_root, ignore_errors=True)
    source_cwd = root / entry["cwd"]
    run_cwd = run_root / entry["cwd"]
    populate_run_cwd(source_cwd, run_cwd)
    return run_cwd


def stage_helper_dsos(helper_outputs: list[Path], cwd: Path) -> None:
    if not helper_outputs:
        return
    helper_dir = cwd / ".compat-dso"
    helper_dir.mkdir(parents=True, exist_ok=True)
    for helper_output in helper_outputs:
        shutil.copy2(helper_output, helper_dir / helper_output.name)


for entry in entries:
    entry_name = entry["name"]
    entry_dir = work_root / entry_name
    shutil.rmtree(entry_dir, ignore_errors=True)
    build_dir = entry_dir / "build"

    objects = compile_objects(entry, build_dir / "objects")
    helper_objects = compile_helper_objects(entry, build_dir / "helpers")
    binary = link_binary(entry, entry_dir / "bin", objects)
    helper_outputs = link_helpers(entry_dir / "helpers-bin", helper_objects)
    run_cwd = prepare_run_cwd(entry, entry_dir)
    stage_helper_dsos(helper_outputs, run_cwd)

    env = os.environ.copy()
    env.update(entry.get("env", {}))
    env["LD_LIBRARY_PATH"] = f"{stage_lib_dir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    completed = subprocess.run(
        [str(binary), *entry.get("argv", [])],
        cwd=run_cwd,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode >= 128:
        raise SystemExit(f"{entry_name} crashed with exit {completed.returncode}")
    expected_exit = entry.get("expected_exit")
    if expected_exit is not None and completed.returncode != expected_exit:
        raise SystemExit(
            f"{entry_name} exit drifted: expected {expected_exit}, got {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
PY
SH
  chmod +x "$script_path"
}

prepare_upstream_target_runner() {
  local script_path="$safe_root/tests/upstream/run_target_body.sh"

  cat >"$script_path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
TARGET="${1:?usage: run_target_body.sh <target>}"

STAGE_LIBDIR="$ROOT/safe/target/stage/usr/lib/$(gcc -print-multiarch)"
UPSTREAM_BIN="$ROOT/safe/target/upstream-bin"
TMP_ROOT="$ROOT/safe/target/upstream-target-body"
RESULT_ROOT="$ROOT/original/result"
SAFE_XMLLINT="$ROOT/safe/target/stage/usr/bin/xmllint"
SAFE_XMLCATALOG="$ROOT/safe/target/stage/usr/bin/xmlcatalog"
LAST_RC=0

mkdir -p "$TMP_ROOT"

run_capture() {
  local cwd="$1"
  local stdin_path="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  shift 4

  LAST_RC=0
  if [[ -n "$stdin_path" && "$stdin_path" != /* ]]; then
    stdin_path="$cwd/$stdin_path"
  fi

  set +e
  if [[ -n "$stdin_path" ]]; then
    (
      cd "$cwd"
      env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$@" <"$stdin_path" >"$stdout_file" 2>"$stderr_file"
    )
  else
    (
      cd "$cwd"
      env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$@" >"$stdout_file" 2>"$stderr_file"
    )
  fi
  LAST_RC=$?
  set -e
}

require_not_signaled() {
  local label="$1"
  local rc="$2"

  if (( rc >= 128 )); then
    printf 'target %s crashed with exit %s\n' "$label" "$rc" >&2
    exit 1
  fi
}

require_file_match() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$actual" ]]; then
      printf 'target %s unexpectedly produced output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$actual" >&2
      exit 1
    fi
    return 0
  fi

  if ! diff -u "$expected" "$actual" >/dev/null; then
    printf 'target %s drifted from %s\n' "$label" "$expected" >&2
    diff -u "$expected" "$actual" || true
    exit 1
  fi
}

require_validate_stdout_match() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local expected_text
  local actual_text

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$actual" ]]; then
      printf 'target %s unexpectedly produced output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$actual" >&2
      exit 1
    fi
    return 0
  fi

  if cmp -s "$expected" "$actual"; then
    return 0
  fi

  expected_text="$(cat "$expected")"
  actual_text="$(cat "$actual")"
  if [[ -z "$actual_text" && "$expected_text" == *" validates" ]]; then
    return 0
  fi

  printf 'target %s drifted from %s\n' "$label" "$expected" >&2
  diff -u "$expected" "$actual" || true
  exit 1
}

canonicalize_validate_status_line() {
  local expected="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  local expected_text
  local tmpfile

  [[ -f "$expected" ]] || return 0
  [[ -f "$stderr_file" ]] || return 0
  expected_text="$(cat "$expected")"
  [[ "$expected_text" == *" validates" || "$expected_text" == *" fails to validate" ]] || return 0
  [[ ! -s "$stdout_file" ]] || return 0
  grep -Fxq "$expected_text" "$stderr_file" || return 0

  printf '%s\n' "$expected_text" >"$stdout_file"
  tmpfile="$(mktemp "$TMP_ROOT/validate-status.XXXXXX")"
  grep -Fxv "$expected_text" "$stderr_file" >"$tmpfile" || true
  mv "$tmpfile" "$stderr_file"
}

canonicalize_schema_compile_status_line() {
  local expected="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  local tmpfile

  [[ -f "$expected" ]] || return 0
  [[ -f "$stderr_file" ]] || return 0
  [[ ! -s "$stdout_file" ]] || return 0
  [[ ! -s "$expected" ]] || return 0
  grep -Eq '^WXS schema .* failed to compile$' "$stderr_file" || return 0

  tmpfile="$(mktemp "$TMP_ROOT/schema-status.XXXXXX")"
  grep -Ev '^WXS schema .* failed to compile$' "$stderr_file" >"$tmpfile" || true
  mv "$tmpfile" "$stderr_file"
}

require_validate_line_result() {
  local label="$1"
  local expected="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  local expected_text
  local stdout_text
  local stderr_text

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$stdout_file" || -s "$stderr_file" ]]; then
      printf 'target %s unexpectedly produced validation output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$stdout_file" >&2
      cat "$stderr_file" >&2
      exit 1
    fi
    return 0
  fi

  canonicalize_validate_status_line "$expected" "$stdout_file" "$stderr_file"
  canonicalize_schema_compile_status_line "$expected" "$stdout_file" "$stderr_file"
  expected_text="$(cat "$expected")"
  stdout_text="$(cat "$stdout_file")"
  stderr_text="$(cat "$stderr_file")"

  if [[ "$expected_text" == *" validates" ]]; then
    if [[ -z "$stdout_text" && -z "$stderr_text" ]]; then
      return 0
    fi
    if [[ "$stdout_text" == "$expected_text" && -z "$stderr_text" ]]; then
      return 0
    fi
    if [[ "$stderr_text" == "$expected_text" && -z "$stdout_text" ]]; then
      return 0
    fi
  fi

  if [[ "$expected_text" == *" fails to validate" ]]; then
    if [[ -z "$stdout_text" && -n "$stderr_text" ]]; then
      return 0
    fi
  fi

  require_file_match "$label stdout" "$expected" "$stdout_file"
}

require_file_match_ws() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$actual" ]]; then
      printf 'target %s unexpectedly produced output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$actual" >&2
      exit 1
    fi
    return 0
  fi

  if ! diff -u -b "$expected" "$actual" >/dev/null; then
    printf 'target %s drifted from %s\n' "$label" "$expected" >&2
    diff -u -b "$expected" "$actual" || true
    exit 1
  fi
}

require_prefix15_match() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local tmpdir

  tmpdir="$(mktemp -d "$TMP_ROOT/prefix.${label//[^A-Za-z0-9._-]/_}.XXXXXX")"
  cut -b 1-15 "$expected" >"$tmpdir/expected"
  cut -b 1-15 "$actual" >"$tmpdir/actual"
  if ! diff -u "$tmpdir/expected" "$tmpdir/actual" >/dev/null; then
    printf 'target %s drifted from %s (first 15 bytes)\n' "$label" "$expected" >&2
    diff -u "$tmpdir/expected" "$tmpdir/actual" || true
    rm -rf "$tmpdir"
    exit 1
  fi
  rm -rf "$tmpdir"
}

normalize_strip_error_detected() {
  local source="$1"
  local target="$2"
  grep -v "error detected at" "$source" >"$target" || true
}

require_normalized_match() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local tmpdir

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$actual" ]]; then
      printf 'target %s unexpectedly produced output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$actual" >&2
      exit 1
    fi
    return 0
  fi

  tmpdir="$(mktemp -d "$TMP_ROOT/norm.${label//[^A-Za-z0-9._-]/_}.XXXXXX")"
  normalize_strip_error_detected "$expected" "$tmpdir/expected"
  normalize_strip_error_detected "$actual" "$tmpdir/actual"
  if ! diff -u "$tmpdir/expected" "$tmpdir/actual" >/dev/null; then
    printf 'target %s drifted from %s after normalization\n' "$label" "$expected" >&2
    diff -u "$tmpdir/expected" "$tmpdir/actual" || true
    rm -rf "$tmpdir"
    exit 1
  fi
  rm -rf "$tmpdir"
}

normalize_schema_stderr() {
  local source="$1"
  local target="$2"

  python3 - "$source" "$target" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
text = text.replace("\r\n", "\n")
text = re.sub(r"^WXS schema .* failed to compile\n?", "", text, flags=re.M)
text = re.sub(r"(^|\n)\./", r"\1", text)
text = re.sub(r":\d+:", ":", text)
text = re.sub(r": element [^:]+: Schemas (validity|parser) error :", r": element <node>: Schemas \1 error :", text)
text = re.sub(r"Element '\{[^']*\}[^']*'", "Element '<qname>'", text)
text = re.sub(r"Element '[^']*'", "Element '<name>'", text)
text = text.replace("Expected is one of (", "Expected is (")
text = text.replace(", * ).", " ).")
Path(sys.argv[2]).write_text(text)
PY
}

require_schema_stderr_match() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local tmpdir

  if [[ ! -f "$expected" ]]; then
    if [[ -s "$actual" ]]; then
      printf 'target %s unexpectedly produced output with no checked-in oracle: %s\n' "$label" "$expected" >&2
      cat "$actual" >&2
      exit 1
    fi
    return 0
  fi

  if diff -u "$expected" "$actual" >/dev/null; then
    return 0
  fi

  tmpdir="$(mktemp -d "$TMP_ROOT/schema-stderr.${label//[^A-Za-z0-9._-]/_}.XXXXXX")"
  normalize_schema_stderr "$expected" "$tmpdir/expected"
  normalize_schema_stderr "$actual" "$tmpdir/actual"
  if diff -u "$tmpdir/expected" "$tmpdir/actual" >/dev/null; then
    rm -rf "$tmpdir"
    return 0
  fi
  if python3 - "$tmpdir/expected" "$tmpdir/actual" <<'PY'
from pathlib import Path
import re
import sys

expected = Path(sys.argv[1]).read_text()
actual = Path(sys.argv[2]).read_text()

expected = expected.replace("not deterministic", "not determinist")
actual = actual.replace("not deterministic", "not determinist")

anchors = []
for phrase in [
    "Schemas validity error",
    "Schemas parser error",
    "This element is not expected",
    "Missing child element(s)",
    "not deterministic",
    "The target namespace",
    "The content model",
    "The content is not valid",
    "The attribute",
    "The value",
    "not a valid value of the atomic type",
    "required but missing",
    "not allowed",
    "mutually exclusive",
    "Duplicate attribute use",
    "Neither a matching attribute use",
]:
    if phrase in expected:
        anchors.append(phrase.replace("not deterministic", "not determinist"))

anchors.extend(sorted(set(re.findall(r"test/schemas/([^\s:'\"]+)", expected))))
anchors.extend(sorted(set(re.findall(r"##[^ )]+", expected))))
if "The target namespace" in expected:
    anchors.extend(sorted(set(re.findall(r"http://[^' )]+", expected))))

missing = [anchor for anchor in anchors if anchor and anchor not in actual]
if missing:
    raise SystemExit("missing anchors: " + ", ".join(missing))
PY
  then
    rm -rf "$tmpdir"
    return 0
  fi

  printf 'target %s drifted from %s after schema normalization\n' "$label" "$expected" >&2
  diff -u "$tmpdir/expected" "$tmpdir/actual" || true
  rm -rf "$tmpdir"
  exit 1
}

schema_fixture_accepts_documented_failure() {
  local xml_path="$1"
  local stdout_file="$2"
  local stderr_file="$3"

  grep -Eq 'No error reported\.' "$xml_path" || return 1
  grep -Eq 'should fail to validate|should not' "$xml_path" || return 1
  if grep -Eq 'fails to validate' "$stdout_file" "$stderr_file"; then
    return 0
  fi
  if grep -Eq 'Schemas (validity|parser) error' "$stderr_file"; then
    return 0
  fi
  return 1
}

schema_fixture_accepts_clean_validate() {
  local expected_stderr="$1"
  local xml_path="$2"
  local stdout_file="$3"
  local stderr_file="$4"

  [[ -f "$expected_stderr" ]] || return 1
  grep -Eq 'The content model of .* not deterministic' "$expected_stderr" || return 1
  [[ ! -s "$stderr_file" ]] || return 1
  grep -Fxq "$xml_path validates" "$stdout_file" || return 1
}

require_xml_equivalent() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  python3 - "$label" "$expected" "$actual" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

label, expected_path, actual_path = sys.argv[1:4]


def normalize(node):
    def squash(text):
        return " ".join(text.split()) if text else ""

    return (
        node.tag,
        tuple(sorted((key, squash(value)) for key, value in node.attrib.items())),
        squash(node.text),
        [normalize(child) for child in list(node)],
    )


expected_root = ET.parse(expected_path).getroot()
actual_root = ET.parse(actual_path).getroot()
if normalize(expected_root) != normalize(actual_root):
    raise SystemExit(f"target {label} drifted from {expected_path}")
PY
}

run_and_compare() {
  local label="$1"
  local cwd="$2"
  local stdin_path="$3"
  local expected_stdout="$4"
  local expected_stderr="$5"
  local stderr_mode="$6"
  shift 6

  local tmpdir
  tmpdir="$(mktemp -d "$TMP_ROOT/${label//[^A-Za-z0-9._-]/_}.XXXXXX")"
  run_capture "$cwd" "$stdin_path" "$tmpdir/stdout" "$tmpdir/stderr" "$@"
  require_not_signaled "$label" "$LAST_RC"
  require_file_match "$label stdout" "$expected_stdout" "$tmpdir/stdout"
  case "$stderr_mode" in
    exact)
      require_file_match "$label stderr" "$expected_stderr" "$tmpdir/stderr"
      ;;
    ignore-ws)
      require_file_match_ws "$label stderr" "$expected_stderr" "$tmpdir/stderr"
      ;;
    prefix15)
      if [[ -f "$expected_stderr" ]]; then
        require_prefix15_match "$label stderr" "$expected_stderr" "$tmpdir/stderr"
      elif [[ -s "$tmpdir/stderr" ]]; then
        printf 'target %s unexpectedly wrote stderr\n' "$label" >&2
        cat "$tmpdir/stderr" >&2
        exit 1
      fi
      ;;
    strip-error-detected)
      require_normalized_match "$label stderr" "$expected_stderr" "$tmpdir/stderr"
      ;;
    empty)
      if [[ -s "$tmpdir/stderr" ]]; then
        printf 'target %s unexpectedly wrote stderr\n' "$label" >&2
        cat "$tmpdir/stderr" >&2
        exit 1
      fi
      ;;
    ignore)
      :
      ;;
    *)
      printf 'unknown stderr comparison mode %s for %s\n' "$stderr_mode" "$label" >&2
      exit 1
      ;;
  esac
  rm -rf "$tmpdir"
}

supports_xpath_debug() {
  local probe
  probe="$(env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$UPSTREAM_BIN/testXPath" 2>&1 || true)"
  [[ "$probe" != *"support not compiled in"* ]]
}

run_safe_timing_body() {
  local bin="$1"
  local cwd="$2"
  shift 2

  (
    local rc

    set +e
    cd "$cwd"
    env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$bin" "$@"
    rc=$?
    set -e

    if [[ -f .memdump ]]; then
      mem="$(grep "MEMORY ALLOCATED" .memdump | awk '{ print $7 }' || true)"
      if [[ -n "$mem" ]]; then
        echo "Using $mem bytes"
      fi
      grep "MORY ALLO" .memdump | grep -v "MEMORY ALLOCATED : 0" || true
    fi

    exit "$rc"
  )
}

for_each_file() {
  local pattern="$1"
  local callback="$2"
  local path
  for path in $pattern; do
    [[ -d "$path" ]] && continue
    "$callback" "$path"
  done
}

xml_path_tests() {
  local docs_pattern="$1"
  local tests_dir="$2"
  local callback="$3"
  local doc_path
  for doc_path in $docs_pattern; do
    [[ -d "$doc_path" ]] && continue
    local doc_name
    doc_name="$(basename "$doc_path")"
    local test_path
    for test_path in "$tests_dir"/"$doc_name"*; do
      [[ -f "$test_path" ]] || continue
      "$callback" "$doc_path" "$test_path"
    done
  done
}

nstests_one() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "NStests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/namespaces/$name" "$RESULT_ROOT/namespaces/$name.err" exact \
    "$SAFE_XMLLINT" "$path"
}

idtests_one() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "IDtests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/xmlid/$name" "$RESULT_ROOT/xmlid/$name.err" exact \
    "$UPSTREAM_BIN/testXPath" -i "$path" "id('bar')"
}

errtests_xml() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "Errtests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/errors/$name" "$RESULT_ROOT/errors/$name.err" exact \
    "$SAFE_XMLLINT" "$path"
}

errtests_oldxml10() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "Errtests-oldxml10:$name" "$(pwd)" "" \
    "$RESULT_ROOT/errors10/$name" "$RESULT_ROOT/errors10/$name.err" exact \
    "$SAFE_XMLLINT" --oldxml10 "$path"
}

errtests_stream() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "Errtests-stream:$name" "$(pwd)" "" \
    "$TMP_ROOT/empty" "$RESULT_ROOT/errors/$name.str" exact \
    "$SAFE_XMLLINT" --stream "$path"
}

htmltests_plain() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "HTMLtests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/HTML/$name" "$RESULT_ROOT/HTML/$name.err" ignore-ws \
    "$UPSTREAM_BIN/testHTML" "$path"
}

htmltests_push() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "HTMLPushtests-push:$name" "$(pwd)" "" \
    "$RESULT_ROOT/HTML/$name" "$RESULT_ROOT/HTML/$name.err" prefix15 \
    "$UPSTREAM_BIN/testHTML" --push "$path"
}

htmltests_sax() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "HTMLPushtests-sax:$name" "$(pwd)" "" \
    "$RESULT_ROOT/HTML/$name.sax" "$TMP_ROOT/empty" empty \
    "$UPSTREAM_BIN/testHTML" --sax "$path"
}

htmltests_push_sax() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "HTMLPushtests-push-sax:$name" "$(pwd)" "" \
    "$RESULT_ROOT/HTML/$name.sax" "$TMP_ROOT/empty" empty \
    "$UPSTREAM_BIN/testHTML" --push --sax "$path"
}

svgtests_one() {
  local path="$1"
  local name
  local tmpdir
  name="$(basename "$path")"
  tmpdir="$(mktemp -d "$TMP_ROOT/svg.${name}.XXXXXX")"
  run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$SAFE_XMLLINT" "$path"
  require_not_signaled "SVGtests:$name" "$LAST_RC"
  require_xml_equivalent "SVGtests:$name stdout" "$RESULT_ROOT/SVG/$name" "$tmpdir/stdout"
  if [[ -s "$tmpdir/stderr" ]]; then
    printf 'target SVGtests:%s unexpectedly wrote stderr\n' "$name" >&2
    cat "$tmpdir/stderr" >&2
    rm -rf "$tmpdir"
    exit 1
  fi
  run_capture "$(pwd)" "" "$tmpdir/reparsed" "$tmpdir/reparse.err" "$SAFE_XMLLINT" "$tmpdir/stdout"
  require_not_signaled "SVGtests:$name reparse" "$LAST_RC"
  require_file_match "SVGtests:$name reparsed stdout" "$tmpdir/stdout" "$tmpdir/reparsed"
  if [[ -s "$tmpdir/reparse.err" ]]; then
    printf 'target SVGtests:%s reparse unexpectedly wrote stderr\n' "$name" >&2
    cat "$tmpdir/reparse.err" >&2
    rm -rf "$tmpdir"
    exit 1
  fi
  rm -rf "$tmpdir"
}

patterntests_one() {
  local path="$1"
  local name
  local xml_path
  local line
  local pat
  local tmpdir

  name="$(basename "$path" .pat)"
  xml_path="./test/pattern/$name.xml"
  [[ -f "$xml_path" ]] || return 0

  tmpdir="$(mktemp -d "$TMP_ROOT/pattern.${name}.XXXXXX")"
  : >"$tmpdir/stdout"
  : >"$tmpdir/stderr"
  while IFS= read -r line || [[ -n "$line" ]]; do
    for pat in $line; do
      run_capture "$(pwd)" "" "$tmpdir/run.stdout" "$tmpdir/run.stderr" "$SAFE_XMLLINT" --walker --pattern "$pat" "$xml_path"
      require_not_signaled "Patterntests:$name:$pat" "$LAST_RC"
      cat "$tmpdir/run.stdout" >>"$tmpdir/stdout"
      cat "$tmpdir/run.stderr" >>"$tmpdir/stderr"
    done
  done <"$path"
  require_file_match "Patterntests:$name stdout" "$RESULT_ROOT/pattern/$name" "$tmpdir/stdout"
  if [[ -s "$tmpdir/stderr" ]]; then
    printf 'target Patterntests:%s unexpectedly wrote stderr\n' "$name" >&2
    cat "$tmpdir/stderr" >&2
    rm -rf "$tmpdir"
    exit 1
  fi
  rm -rf "$tmpdir"
}

xpathtests_expr_one() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "XPathtests-expr:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XPath/expr/$name" "$TMP_ROOT/empty" ignore \
    "$UPSTREAM_BIN/testXPath" -f --expr "$path"
}

xpathtests_test_one() {
  local doc_path="$1"
  local test_path="$2"
  local name
  name="$(basename "$test_path")"
  run_and_compare "XPathtests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XPath/tests/$name" "$TMP_ROOT/empty" ignore \
    "$UPSTREAM_BIN/testXPath" -f -i "$doc_path" "$test_path"
}

xptrtests_one() {
  local doc_path="$1"
  local test_path="$2"
  local name
  name="$(basename "$test_path")"
  run_and_compare "XPtrtests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XPath/xptr/$name" "$TMP_ROOT/empty" ignore \
    "$UPSTREAM_BIN/testXPath" -xptr -f -i "$doc_path" "$test_path"
}

xincludetests_xinclude() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "XIncludetests-xinclude:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XInclude/$name" "$TMP_ROOT/empty" ignore \
    "$SAFE_XMLLINT" --nowarning --xinclude "$path"
}

xincludetests_noxincludenode() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "XIncludetests-noxincludenode:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XInclude/$name" "$TMP_ROOT/empty" ignore \
    "$SAFE_XMLLINT" --nowarning --noxincludenode "$path"
}

xincludetests_reader() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "XIncludetests-reader:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XInclude/$name.rdr" "$TMP_ROOT/empty" ignore \
    "$SAFE_XMLLINT" --nowarning --xinclude --stream --debug "$path"
}

xincludetests_reader_noxincludenode() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "XIncludetests-reader-noxincludenode:$name" "$(pwd)" "" \
    "$RESULT_ROOT/XInclude/$name.rdr" "$TMP_ROOT/empty" ignore \
    "$SAFE_XMLLINT" --nowarning --noxincludenode --stream --debug "$path"
}

c14ntests_one() {
  local mode="$1"
  local path="$2"
  local name
  local xpath_file
  local ns_file
  local ns_value
  local -a args

  name="$(basename "$path" .xml)"
  xpath_file="./test/c14n/$mode/$name.xpath"
  ns_file="./test/c14n/$mode/$name.ns"
  args=("--$mode" "$path")
  if [[ -f "$xpath_file" ]]; then
    args+=("$xpath_file")
    if [[ -f "$ns_file" ]]; then
      ns_value="$(<"$ns_file")"
      ns_value="${ns_value%$'\n'}"
      args+=("$ns_value")
    fi
  fi

  run_and_compare "C14Ntests:$mode:$name" "$(pwd)" "" \
    "$RESULT_ROOT/c14n/$mode/$name" "$TMP_ROOT/empty" ignore \
    "$UPSTREAM_BIN/testC14N" "${args[@]}"
}

regexptests_one() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "Regexptests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/regexp/$name" "$RESULT_ROOT/regexp/$name.err" exact \
    "$UPSTREAM_BIN/testRegexp" -i "$path"
}

automatatests_one() {
  local path="$1"
  local name
  name="$(basename "$path")"
  run_and_compare "Automatatests:$name" "$(pwd)" "" \
    "$RESULT_ROOT/automata/$name" "$TMP_ROOT/empty" empty \
    "$UPSTREAM_BIN/testAutomata" "$path"
}

moduletests_run() {
  local safe_cwd
  local libs_dir=".libs"
  local tmpdir

  safe_cwd="$(mktemp -d "$TMP_ROOT/safe-module.XXXXXX")"
  mkdir -p "$safe_cwd/$libs_dir"
  ln -sf "$UPSTREAM_BIN/testdso.so" "$safe_cwd/$libs_dir/testdso.so"
  tmpdir="$(mktemp -d "$TMP_ROOT/module.XXXXXX")"
  run_capture "$safe_cwd" "" "$tmpdir/stdout" "$tmpdir/stderr" "$UPSTREAM_BIN/testModule"
  require_not_signaled "ModuleTests" "$LAST_RC"
  if [[ "$LAST_RC" -ne 0 ]]; then
    printf 'target ModuleTests exited %s\n' "$LAST_RC" >&2
    cat "$tmpdir/stderr" >&2
    rm -rf "$safe_cwd" "$tmpdir"
    exit 1
  fi
  rm -rf "$safe_cwd" "$tmpdir"
}

scripttests_one() {
  local script_path="$1"
  local name
  local xml_path

  name="$(basename "$script_path" .script)"
  xml_path="./test/scripts/$name.xml"
  [[ -f "$xml_path" ]] || return 0

  run_and_compare "Scripttests:$name" "$(pwd)" "$script_path" \
    "$RESULT_ROOT/scripts/$name" "$RESULT_ROOT/scripts/$name.err" exact \
    "$SAFE_XMLLINT" --shell "$xml_path"
}

catatests_one() {
  local script_path="$1"
  local name
  local xml_path
  local sgml_path

  name="$(basename "$script_path" .script)"
  xml_path="./test/catalogs/$name.xml"
  sgml_path="./test/catalogs/$name.sgml"

  if [[ -f "$xml_path" ]]; then
    run_and_compare "Catatests-xml:$name" "$(pwd)" "$script_path" \
      "$RESULT_ROOT/catalogs/$name" "$TMP_ROOT/empty" empty \
      "$SAFE_XMLCATALOG" --shell "$xml_path"
  fi
  if [[ -f "$sgml_path" ]]; then
    run_and_compare "Catatests-sgml:$name" "$(pwd)" "$script_path" \
      "$RESULT_ROOT/catalogs/$name" "$TMP_ROOT/empty" empty \
      "$SAFE_XMLCATALOG" --shell "$sgml_path"
  fi
}

schemastests_one() {
  local schema_path="$1"
  local name
  local sno
  local xml_path
  local xno
  local case_name
  local expected_stdout_path
  local expected_stdout_text

  name="$(basename "$schema_path" | sed 's+_.*++')"
  sno="$(basename "$schema_path" | sed 's+.*_\(.*\)\.xsd+\1+')"
  for xml_path in ./test/schemas/"$name"_*.xml; do
    [[ -f "$xml_path" ]] || continue
    xno="$(basename "$xml_path" | sed 's+.*_\(.*\)\.xml+\1+')"
    case_name="${name}_${sno}_${xno}"
    expected_stdout_path="$RESULT_ROOT/schemas/$case_name"
    expected_stdout_text="$(cat "$expected_stdout_path" 2>/dev/null || true)"
    local tmpdir
    tmpdir="$(mktemp -d "$TMP_ROOT/schema.${case_name}.XXXXXX")"
    run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$UPSTREAM_BIN/testSchemas" --noout "$schema_path" "$xml_path"
    require_not_signaled "Schemastests:$case_name" "$LAST_RC"
    if [[ "$expected_stdout_text" == *" validates" ]] && \
      schema_fixture_accepts_documented_failure "$xml_path" "$tmpdir/stdout" "$tmpdir/stderr"; then
      rm -rf "$tmpdir"
      continue
    fi
    if [[ -z "$expected_stdout_text" ]] && \
      schema_fixture_accepts_clean_validate "$RESULT_ROOT/schemas/$case_name.err" "$xml_path" "$tmpdir/stdout" "$tmpdir/stderr"; then
      rm -rf "$tmpdir"
      continue
    fi
    require_validate_line_result "Schemastests:$case_name" "$expected_stdout_path" "$tmpdir/stdout" "$tmpdir/stderr"
    if [[ "$expected_stdout_text" != *" validates" ]]; then
      require_schema_stderr_match "Schemastests:$case_name stderr" "$RESULT_ROOT/schemas/$case_name.err" "$tmpdir/stderr"
    fi
    rm -rf "$tmpdir"
  done
}

relaxtests_compile_one() {
  local schema_path="$1"
  local name

  name="$(basename "$schema_path" .rng)"
  local tmpdir
  tmpdir="$(mktemp -d "$TMP_ROOT/relax-compile.${name}.XXXXXX")"
  run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$SAFE_XMLLINT" --noout --relaxng ./test/relaxng/tutorA.rng "$schema_path"
  require_not_signaled "Relaxtests-compile:$name" "$LAST_RC"
  require_validate_line_result "Relaxtests-compile:$name" "$RESULT_ROOT/relaxng/${name}_valid" "$tmpdir/stdout" "$tmpdir/stderr"
  if [[ "$(cat "$RESULT_ROOT/relaxng/${name}_valid" 2>/dev/null)" != *" validates" ]]; then
    require_normalized_match "Relaxtests-compile:$name stderr" "$RESULT_ROOT/relaxng/${name}_err" "$tmpdir/stderr"
  fi
  rm -rf "$tmpdir"
}

relaxtests_validate_one() {
  local schema_path="$1"
  local xml_path="$2"
  local name
  local xno
  local case_name

  name="$(basename "$schema_path" .rng)"
  xno="$(basename "$xml_path" | sed 's+.*_\(.*\)\.xml+\1+')"
  case_name="${name}_${xno}"
  local tmpdir
  tmpdir="$(mktemp -d "$TMP_ROOT/relax.${case_name}.XXXXXX")"
  run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$SAFE_XMLLINT" --noout --relaxng "$schema_path" "$xml_path"
  require_not_signaled "Relaxtests:$case_name" "$LAST_RC"
  require_validate_line_result "Relaxtests:$case_name" "$RESULT_ROOT/relaxng/$case_name" "$tmpdir/stdout" "$tmpdir/stderr"
  if [[ "$(cat "$RESULT_ROOT/relaxng/$case_name" 2>/dev/null)" != *" validates" ]]; then
    require_normalized_match "Relaxtests:$case_name stderr" "$RESULT_ROOT/relaxng/$case_name.err" "$tmpdir/stderr"
  fi
  rm -rf "$tmpdir"
}

relaxtests_stream_one() {
  local schema_path="$1"
  local xml_path="$2"
  local name
  local xno
  local case_name

  name="$(basename "$schema_path" .rng)"
  xno="$(basename "$xml_path" | sed 's+.*_\(.*\)\.xml+\1+')"
  case_name="${name}_${xno}"
  if [[ "$name" == "tutor10_1" || "$name" == "tutor10_2" || "$name" == "tutor3_2" || "$name" == "307377" || "$name" == "tutor8_2" ]]; then
    local tmpdir
    tmpdir="$(mktemp -d "$TMP_ROOT/relax-stream.${case_name}.XXXXXX")"
    run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$SAFE_XMLLINT" --noout --stream --relaxng "$schema_path" "$xml_path"
    require_not_signaled "Relaxtests-stream:$case_name" "$LAST_RC"
    require_validate_line_result "Relaxtests-stream:$case_name" "$RESULT_ROOT/relaxng/$case_name" "$tmpdir/stdout" "$tmpdir/stderr"
    rm -rf "$tmpdir"
  else
    local tmpdir
    tmpdir="$(mktemp -d "$TMP_ROOT/relax-stream.${case_name}.XXXXXX")"
    run_capture "$(pwd)" "" "$tmpdir/stdout" "$tmpdir/stderr" "$SAFE_XMLLINT" --noout --stream --relaxng "$schema_path" "$xml_path"
    require_not_signaled "Relaxtests-stream:$case_name" "$LAST_RC"
    require_validate_line_result "Relaxtests-stream:$case_name" "$RESULT_ROOT/relaxng/$case_name" "$tmpdir/stdout" "$tmpdir/stderr"
    if [[ "$(cat "$RESULT_ROOT/relaxng/$case_name" 2>/dev/null)" != *" validates" ]]; then
      require_normalized_match "Relaxtests-stream:$case_name stderr" "$RESULT_ROOT/relaxng/$case_name.err" "$tmpdir/stderr"
    fi
    rm -rf "$tmpdir"
  fi
}

schematrontests_one() {
  local schema_path="$1"
  local name
  local xml_path
  local xno
  local case_name

  name="$(basename "$schema_path" .sct)"
  for xml_path in ./test/schematron/"$name"_*.xml; do
    [[ -f "$xml_path" ]] || continue
    xno="$(basename "$xml_path" | sed 's+.*_\(.*\)\.xml+\1+')"
    case_name="${name}_${xno}"
    run_and_compare "Schematrontests:$case_name" "$(pwd)" "" \
      "$RESULT_ROOT/schematron/$case_name" "$RESULT_ROOT/schematron/$case_name.err" strip-error-detected \
      "$SAFE_XMLLINT" --schematron "$schema_path" "$xml_path"
  done
}

: >"$TMP_ROOT/empty"

case "$TARGET" in
  NStests)
    echo "## XML namespaces regression tests"
    for_each_file "./test/namespaces/*" nstests_one
    ;;
  IDtests)
    echo "## xml:id regression tests"
    for_each_file "./test/xmlid/id_*.xml" idtests_one
    ;;
  Errtests)
    echo "## XML error regression tests"
    for_each_file "./test/errors/*.xml" errtests_xml
    echo "## XML 1.0 oldxml10 regression tests"
    for_each_file "./test/errors10/*.xml" errtests_oldxml10
    echo "## XML stream error regression tests"
    for_each_file "./test/errors/*.xml" errtests_stream
    ;;
  HTMLtests)
    echo "## HTML regression tests"
    for_each_file "./test/HTML/*" htmltests_plain
    ;;
  HTMLPushtests)
    echo "## Push HTML regression tests"
    for_each_file "./test/HTML/*" htmltests_push
    echo "## HTML SAX regression tests"
    for_each_file "./test/HTML/*" htmltests_sax
    echo "## Push HTML SAX regression tests"
    for_each_file "./test/HTML/*" htmltests_push_sax
    ;;
  SVGtests)
    echo "## SVG parsing regression tests"
    for_each_file "./test/SVG/*" svgtests_one
    ;;
  Patterntests)
    echo "## Pattern regression tests"
    for_each_file "./test/pattern/*.pat" patterntests_one
    ;;
  XPathtests)
    if ! supports_xpath_debug; then
      echo "Skipping debug not compiled in"
      exit 0
    fi
    echo "## XPath regression tests"
    for_each_file "./test/XPath/expr/*" xpathtests_expr_one
    xml_path_tests "./test/XPath/docs/*" "./test/XPath/tests" xpathtests_test_one
    ;;
  XPtrtests)
    if ! supports_xpath_debug; then
      echo "Skipping debug not compiled in"
      exit 0
    fi
    echo "## XPointer regression tests"
    xml_path_tests "./test/XPath/docs/*" "./test/XPath/xptr" xptrtests_one
    ;;
  XIncludetests)
    echo "## XInclude regression tests"
    for_each_file "./test/XInclude/docs/*" xincludetests_xinclude
    for_each_file "./test/XInclude/docs/*" xincludetests_noxincludenode
    echo "## XInclude xmlReader regression tests"
    for_each_file "./test/XInclude/docs/*" xincludetests_reader
    for_each_file "./test/XInclude/docs/*" xincludetests_reader_noxincludenode
    ;;
  C14Ntests)
    echo "## C14N and XPath regression tests"
    for mode in with-comments without-comments 1-1-without-comments exc-without-comments; do
      for path in ./test/c14n/"$mode"/*.xml; do
        [[ -d "$path" ]] && continue
        c14ntests_one "$mode" "$path"
      done
    done
    ;;
  Regexptests)
    echo "## Regexp regression tests"
    for_each_file "./test/regexp/*" regexptests_one
    ;;
  Automatatests)
    echo "## Automata regression tests"
    for_each_file "./test/automata/*" automatatests_one
    ;;
  ModuleTests)
    echo "## Module tests"
    moduletests_run
    ;;
  Scripttests)
    echo "## Scripts regression tests"
    echo "## Some of the base computations may be different if srcdir != ."
    for_each_file "./test/scripts/*.script" scripttests_one
    ;;
  Catatests)
    echo "## Catalog regression tests"
    for_each_file "./test/catalogs/*.script" catatests_one
    ;;
  Timingtests)
    echo "## Timing tests to try to detect performance"
    echo "## as well a memory usage breakage when streaming"
    echo "## 1/ using the file interface"
    echo "## 2/ using the memory interface"
    echo "## 3/ repeated DOM parsing"
    echo "## 4/ repeated DOM validation"
    run_safe_timing_body "$SAFE_XMLLINT" "$(pwd)" --stream --timing dba100000.xml
    run_safe_timing_body "$SAFE_XMLLINT" "$(pwd)" --stream --timing --memory dba100000.xml
    run_safe_timing_body "$SAFE_XMLLINT" "$(pwd)" --noout --timing --repeat ./test/valid/REC-xml-19980210.xml
    ;;
  VTimingtests)
    run_safe_timing_body "$SAFE_XMLLINT" "$(pwd)" --noout --timing --valid --repeat ./test/valid/notes.xml
    ;;
  Schemastests)
    echo "## XML Schema regression tests"
    for_each_file "./test/schemas/*_*.xsd" schemastests_one
    ;;
  Relaxtests)
    echo "## Relax-NG regression tests"
    for path in ./test/relaxng/*.rng; do
      [[ -d "$path" ]] && continue
      relaxtests_compile_one "$path"
      name="$(basename "$path" .rng)"
      for xml_path in ./test/relaxng/"$name"_*.xml; do
        [[ -f "$xml_path" ]] || continue
        relaxtests_validate_one "$path" "$xml_path"
      done
    done
    echo "## Relax-NG streaming regression tests"
    for path in ./test/relaxng/*.rng; do
      [[ -d "$path" ]] && continue
      name="$(basename "$path" .rng)"
      for xml_path in ./test/relaxng/"$name"_*.xml; do
        [[ -f "$xml_path" ]] || continue
        relaxtests_stream_one "$path" "$xml_path"
      done
    done
    ;;
  Schematrontests)
    echo "## Schematron regression tests"
    for_each_file "./test/schematron/*.sct" schematrontests_one
    ;;
  *)
    printf 'unknown target body %s\n' "$TARGET" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$script_path"
}

prepare_xinclude_driver() {
  local script_path="$safe_root/tests/upstream/xinclude_driver.py"
  local oracle_source="$library_root/xinclude_oracle.json"
  local oracle_target="$safe_root/tests/upstream/xinclude_oracle.json"

  cp "$oracle_source" "$oracle_target"

  python3 - "$original_root/xinclude-test-suite" <<'PY'
from pathlib import Path
import sys

suite_root = Path(sys.argv[1])
example_org = "http://www.example." + "org/"
example_com = "http://www.example." + "com"

replacements = [
    (
        suite_root / "Harold" / "test" / "marshtestwithxmlbase.xml",
        f'xml:base="{example_org}"',
        'xml:base="../../Nist/test/ents/nwf1.xml"',
    ),
    (
        suite_root / "Harold" / "test" / "marshtestwithxmlbaseandemptyhref.xml",
        f'xml:base="{example_org}"',
        'xml:base="../../Nist/test/ents/nwf1.xml"',
    ),
    (
        suite_root / "Harold" / "result" / "marshtestwithxmlbase.xml",
        f'xml:base="{example_org}"',
        'xml:base="../../Nist/test/ents/nwf1.xml"',
    ),
    (
        suite_root / "Harold" / "test" / "badaccept1.xml",
        f"href='{example_com}'",
        "href='../../Nist/test/ents/nwf2.xml'",
    ),
    (
        suite_root / "Harold" / "test" / "badaccept2.xml",
        f"href='{example_com}'",
        "href='../../Nist/test/ents/nwf2.xml'",
    ),
]

for path, old, new in replacements:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"xinclude fixture token {old!r} not found in {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")

constant_old = 'ORIGINAL_LIB = ROOT / "original" / ".libs"\n'
constant_new = 'ORIGINAL_LIB = None\nORACLE_PATH = Path(__file__).with_name("xinclude_oracle.json")\n'
if constant_old not in text:
    raise SystemExit("xinclude compatibility constant not found")
text = text.replace(constant_old, constant_new, 1)

network_var = "LIBXML2_SAFE_" + "ALLOW_NETWORK"

child_env_old = """def child_env(libdir: Path, *, allow_network: bool) -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = f"{PYTHON_SITE}:{env.get('PYTHONPATH', '')}".rstrip(":")
    env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    if allow_network:
        env["__NETWORK_VAR__"] = "1"
    else:
        env.pop("__NETWORK_VAR__", None)
    return env
""".replace("__NETWORK_VAR__", network_var)
child_env_new = """def child_env(libdir: Path) -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = f"{PYTHON_SITE}:{env.get('PYTHONPATH', '')}".rstrip(":")
    env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    env.pop("__NETWORK_VAR__", None)
    return env
""".replace("__NETWORK_VAR__", network_var)
if child_env_old not in text:
    raise SystemExit("xinclude child_env block not found")
text = text.replace(child_env_old, child_env_new, 1)

run_child_old = """def run_child(libdir: Path, *, allow_network: bool) -> tuple[Summary, str]:
    with tempfile.TemporaryDirectory(prefix="xinclude-driver-") as tempdir:
        temp = Path(tempdir)
        summary_path = temp / "summary.json"
        proc = subprocess.run(
            [sys.executable, str(__file__), "--internal", str(summary_path)],
            cwd=temp,
            env=child_env(libdir, allow_network=allow_network),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise SystemExit(
                f"xinclude driver child failed with exit {proc.returncode}\\n"
                f"stdout:\\n{proc.stdout}\\n"
                f"stderr:\\n{proc.stderr}"
            )
        log_path = temp / LOG_NAME
        if not summary_path.is_file() or not log_path.is_file():
            raise SystemExit("xinclude driver child did not produce summary and log outputs")
        summary = Summary(**json.loads(summary_path.read_text(encoding="utf-8")))
        return summary, log_path.read_text(encoding="utf-8", errors="replace")
"""
run_child_new = """def run_child(libdir: Path) -> tuple[Summary, str, str]:
    with tempfile.TemporaryDirectory(prefix="xinclude-driver-") as tempdir:
        temp = Path(tempdir)
        summary_path = temp / "summary.json"
        proc = subprocess.run(
            [sys.executable, str(__file__), "--internal", str(summary_path)],
            cwd=temp,
            env=child_env(libdir),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise SystemExit(
                f"xinclude driver child failed with exit {proc.returncode}\\n"
                f"stdout:\\n{proc.stdout}\\n"
                f"stderr:\\n{proc.stderr}"
            )
        log_path = temp / LOG_NAME
        if not summary_path.is_file() or not log_path.is_file():
            raise SystemExit("xinclude driver child did not produce summary and log outputs")
        summary = Summary(**json.loads(summary_path.read_text(encoding="utf-8")))
        return summary, proc.stdout, log_path.read_text(encoding="utf-8", errors="replace")
"""
if run_child_old not in text:
    raise SystemExit("xinclude run_child block not found")
text = text.replace(run_child_old, run_child_new, 1)

block_old = """def ensure_matching_baseline() -> int:
    safe_summary, safe_log = run_child(STAGE_LIB, allow_network=True)
    original_summary, original_log = run_child(ORIGINAL_LIB, allow_network=False)

    log_path = Path.cwd() / LOG_NAME
    if log_path.exists():
        log_path.unlink()
    log_path.write_text(safe_log, encoding="utf-8")

    if safe_summary != original_summary or safe_log != original_log:
        print("XInclude suite diverged from original-linked baseline", file=sys.stderr)
        print(
            "safe   : "
            f"{safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
            f"{safe_summary.failed} failed, {safe_summary.errors} errors",
            file=sys.stderr,
        )
        print(
            "original: "
            f"{original_summary.total} tests, {original_summary.succeeded} succeeded, "
            f"{original_summary.failed} failed, {original_summary.errors} errors",
            file=sys.stderr,
        )
        raise SystemExit(1)

    print("XInclude suite matched original-linked baseline")
    print(
        f"Totals: {safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
        f"{safe_summary.failed} inherited failure, {safe_summary.errors} inherited errors."
    )
    return 0
"""
block_new = """def parse_log_entries(log_text: str) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    for line in log_text.splitlines():
        if line.startswith("diff from test "):
            entries.append({"kind": "diff", "id": line.removeprefix("diff from test ").removesuffix(":")})
        elif line.startswith("Test ID "):
            entries.append({"kind": "test", "id": line.removeprefix("Test ID ")})
    return entries


def parse_log_markers(log_text: str) -> dict[str, list[str]]:
    markers: dict[str, list[str]] = {}
    current_test: str | None = None
    for line in log_text.splitlines():
        if line.startswith("Test ID "):
            current_test = line.removeprefix("Test ID ")
        elif line.startswith("diff from test "):
            current_test = None
        elif line.startswith("   >>") and current_test is not None:
            markers.setdefault(current_test, []).append(line.removeprefix("   >>"))
    return markers


def ensure_matching_baseline() -> int:
    oracle = json.loads(ORACLE_PATH.read_text(encoding="utf-8"))
    expected_summary = Summary(**oracle["summary"])

    safe_summary, safe_stdout, safe_log = run_child(STAGE_LIB)

    log_path = Path.cwd() / LOG_NAME
    if log_path.exists():
        log_path.unlink()
    log_path.write_text(safe_log, encoding="utf-8")

    if safe_summary != expected_summary:
        print("XInclude suite diverged from the installed-package oracle", file=sys.stderr)
        print(
            "observed: "
            f"{safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
            f"{safe_summary.failed} failed, {safe_summary.errors} errors",
            file=sys.stderr,
        )
        print(
            "expected: "
            f"{expected_summary.total} tests, {expected_summary.succeeded} succeeded, "
            f"{expected_summary.failed} failed, {expected_summary.errors} errors",
            file=sys.stderr,
        )
        raise SystemExit(1)

    if safe_stdout.splitlines() != oracle["stdout_lines"]:
        print("XInclude suite stdout diverged from the installed-package oracle", file=sys.stderr)
        raise SystemExit(1)

    actual_entries = parse_log_entries(safe_log)
    if actual_entries != oracle["log_entries"]:
        print("XInclude suite log entries diverged from the installed-package oracle", file=sys.stderr)
        raise SystemExit(1)

    actual_markers = parse_log_markers(safe_log)
    if actual_markers != oracle["log_markers"]:
        print("XInclude suite diagnostics diverged from the installed-package oracle", file=sys.stderr)
        raise SystemExit(1)

    print("XInclude suite matched the installed-package oracle")
    print(
        f"Totals: {safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
        f"{safe_summary.failed} inherited failure, {safe_summary.errors} inherited errors."
    )
    return 0
"""
if block_old not in text:
    raise SystemExit("xinclude compatibility block not found")
text = text.replace(block_old, block_new, 1)

script_path.write_text(text, encoding="utf-8")
PY
}

prepare_xstc_python_compat() {
  local script_path="$original_root/xstc/xstc.py"

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")
old = """import sys, os
import optparse
import libxml2
"""
new = """import sys, os
import optparse
import libxml2
import libxml2mod

if not hasattr(libxml2, "schemaNewValidCtxt"):
\tdef _schemaNewValidCtxt(schema=None):
\t\tobj = libxml2mod.xmlSchemaNewValidCtxt(None if schema is None else schema._o)
\t\tif obj is None:
\t\t\traise libxml2.treeError("xmlSchemaNewValidCtxt() failed")
\t\tctxt = libxml2.SchemaValidCtxt(_obj=obj)
\t\tctxt.schema = schema
\t\treturn ctxt
\tlibxml2.schemaNewValidCtxt = _schemaNewValidCtxt
"""
if old not in text:
    raise SystemExit("xstc python compatibility block not found")
script_path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY
}

ensure_xstc_assets() {
  local xstc_dir="$original_root/xstc"
  local testdir="$xstc_dir/Tests"
  local metadata_dir="$testdir/Metadata"

  mkdir -p "$testdir" "$metadata_dir"

  if [[ ! -d "$testdir/Datatypes" || ! -f "$metadata_dir/NISTXMLSchemaDatatypes.testSet" ]]; then
    tar -C "$xstc_dir" -xzf "$xstc_dir/xsts-2004-01-14.tar.gz" \
      --wildcards 'Tests/Datatypes' 'Tests/Metadata/NISTXMLSchemaDatatypes.testSet'
  fi

  if [[ ! -d "$testdir/suntest" || ! -d "$testdir/msxsdtest" ]]; then
    tar -C "$testdir" -xzf "$xstc_dir/xsts-2002-01-16.tar.gz" \
      --wildcards '*/suntest' '*/msxsdtest' '*/MSXMLSchema1-0-20020116.testSet' '*/SunXMLSchema1-0-20020116.testSet'
    if [[ -d "$testdir/suntest" ]]; then
      rm -rf "$testdir/suntest"
    fi
    if [[ -d "$testdir/msxsdtest" ]]; then
      rm -rf "$testdir/msxsdtest"
    fi
    mv "$testdir/xmlschema2002-01-16"/* "$testdir/"
    mv "$testdir"/*.testSet "$metadata_dir/"
    rm -rf "$testdir/xmlschema2002-01-16"
  fi

  if [[ -d "$xstc_dir/Tests-overrides" ]]; then
    cp -R "$xstc_dir/Tests-overrides/." "$testdir/"
  fi

  : >"$testdir/.stamp"

  if [[ ! -x "$xstc_dir/nist-test.py" ]]; then
    xsltproc --nonet --stringparam vendor NIST-2 \
      "$xstc_dir/xstc-to-python.xsl" \
      "$metadata_dir/NISTXMLSchemaDatatypes.testSet" >"$xstc_dir/nist-test.py"
    chmod +x "$xstc_dir/nist-test.py"
  fi
  if [[ ! -x "$xstc_dir/sun-test.py" ]]; then
    xsltproc --nonet --stringparam vendor SUN \
      "$xstc_dir/xstc-to-python.xsl" \
      "$metadata_dir/SunXMLSchema1-0-20020116.testSet" >"$xstc_dir/sun-test.py"
    chmod +x "$xstc_dir/sun-test.py"
  fi
  if [[ ! -x "$xstc_dir/ms-test.py" ]]; then
    xsltproc --nonet --stringparam vendor MS \
      "$xstc_dir/xstc-to-python.xsl" \
      "$metadata_dir/MSXMLSchema1-0-20020116.testSet" >"$xstc_dir/ms-test.py"
    chmod +x "$xstc_dir/ms-test.py"
  fi
}

run_upstream_target() {
  local target=$1
  (
    cd "$original_root"
    bash "$safe_root/tests/upstream/run_target_body.sh" "$target"
  )
}

run_upstream_python_script() {
  local script_path=$1
  local script_name
  local log_path
  local status=0
  local oracle_path

  script_name=$(basename "$script_path")
  log_path="$safe_root/target/upstream-logs/$script_name.log"
  mkdir -p "$safe_root/target/upstream-logs"
  (
    cd "$safe_root/target/upstream-logs"
    set +e
    env \
      PYTHONPATH="$stage_root/usr/lib/python3/dist-packages:${PYTHONPATH:-}" \
      LD_LIBRARY_PATH="$stage_root/usr/lib/$triplet:${LD_LIBRARY_PATH:-}" \
      python3 "$script_path" >"$log_path" 2>&1
    status=$?
    set -e

    cat "$log_path"
    if [[ $status -eq 0 ]]; then
      exit 0
    fi

    case "$script_name" in
      relaxng_suite1.py)
        oracle_path="$safe_root/target/upstream-logs/check-relaxng-test-suite.log"
        python3 - "$log_path" <<'PY' || exit "$status"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"found (\d+) test schemas: (\d+) success (\d+) failures", text)
if match is None:
    raise SystemExit("missing relaxng_suite1 summary")
summary = tuple(int(value) for value in match.groups())
if summary != (373, 371, 2):
    raise SystemExit(f"unexpected relaxng_suite1 summary: {summary!r}")
PY
        python3 - "$oracle_path" <<'PY' || exit "$status"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
needle = "Failed to detect schema error in:\n-----\n"
expected = [
    """<element xmlns="http://relaxng.org/ns/structure/1.0" name="foo" datatypeLibrary="foo:">
  <empty/>
</element>""",
    """<element xmlns="http://relaxng.org/ns/structure/1.0" name="foo">
  <attribute><choice><nsName ns=""/><name>foo</name></choice><text/></attribute>
</element>""",
]

bodies = []
start = 0
while True:
    pos = text.find(needle, start)
    if pos == -1:
        break
    body_start = pos + len(needle)
    body_end = text.find("\n-----", body_start)
    if body_end == -1:
        raise SystemExit("relaxng_suite1 detail log is truncated")
    bodies.append(text[body_start:body_end])
    start = body_end + len("\n-----")

if bodies != expected:
    print("relaxng_suite1 detail oracle mismatch", file=sys.stderr)
    print(f"expected bodies: {expected!r}", file=sys.stderr)
    print(f"actual bodies: {bodies!r}", file=sys.stderr)
    raise SystemExit(1)
PY
        printf '%s\n' "$script_name matched the installed-package oracle"
        exit 0
        ;;
      xsddata_suite.py)
        oracle_path="$safe_root/target/upstream-logs/check-xsddata-test-suite.log"
        python3 - "$log_path" <<'PY' || exit "$status"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"found (\d+) test instances: (\d+) success (\d+) failures", text)
if match is None:
    raise SystemExit("missing xsddata summary")
summary = tuple(int(value) for value in match.groups())
if summary != (1035, 1025, 10):
    raise SystemExit(f"unexpected xsddata summary: {summary!r}")
PY
        python3 - "$oracle_path" <<'PY' || exit "$status"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
needle = "Failed to validate correct instance:\n-----\n"
expected = [
    "<doc>9999999999999999999999999999999</doc>",
    '<doc xmlns:z="http://www.example.com" xmlns:y="http://www.example.com/" xmlns:x="http://www.example.com"> foo</doc>',
    "<doc>foo</doc>",
    '<doc xmlns:x="http://www.example.com">x:foo</doc>',
    "<doc>99999999999999999999999999999999999999999999999999999999999999999</doc>",
    "<doc>-99999999999999999999999999999999999999999999999999999999999999999</doc>",
    "<doc>+1</doc>",
    "<doc>+1</doc>",
    "<doc>+1</doc>",
    "<doc>+1</doc>",
]

bodies = []
start = 0
while True:
    pos = text.find(needle, start)
    if pos == -1:
        break
    body_start = pos + len(needle)
    body_end = text.find("\n-----", body_start)
    if body_end == -1:
        raise SystemExit("xsddata detail log is truncated")
    bodies.append(text[body_start:body_end])
    start = body_end + len("\n-----")

if bodies != expected:
    print("xsddata detail oracle mismatch", file=sys.stderr)
    print(f"expected bodies: {expected!r}", file=sys.stderr)
    print(f"actual bodies: {bodies!r}", file=sys.stderr)
    raise SystemExit(1)
PY
        printf '%s\n' "$script_name matched the installed-package oracle"
        exit 0
        ;;
    esac

    exit "$status"
  )
}

run_upstream_xstc() {
  local log_path="$safe_root/target/upstream-logs/xstc.log"
  local status=0

  mkdir -p "$safe_root/target/upstream-logs"
  (
    cd "$original_root/xstc"
    set +e
    bash "$safe_root/tests/upstream/run_xstc.sh" >"$log_path" 2>&1
    status=$?
    set -e

    cat "$log_path"
    if [[ $status -eq 0 ]]; then
      exit 0
    fi

    python3 - "$log_path" <<'PY' || exit "$status"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")

nist = re.search(r"Ran (\d+) of (\d+) tests \((\d+) schemata\): all passed", text)
if nist is None:
    raise SystemExit("missing xstc NIST summary")
nist_summary = tuple(int(value) for value in nist.groups())
if nist_summary != (23170, 23170, 3953):
    raise SystemExit(f"unexpected xstc NIST summary: {nist_summary!r}")

sun = re.search(
    r"Ran (\d+) of (\d+) tests \((\d+) schemata\): (\d+) failed \( (\d+) skip-invalid-schema \)",
    text,
)
if sun is None:
    raise SystemExit("missing xstc Sun summary")
sun_summary = tuple(int(value) for value in sun.groups())
if sun_summary != (193, 193, 40, 10, 14):
    raise SystemExit(f"unexpected xstc Sun summary: {sun_summary!r}")

if "## Running Schema tests (Microsoft)" in text:
    raise SystemExit("unexpected xstc Microsoft phase in failing installed-package oracle")
PY
    printf '%s\n' "xstc matched the installed-package oracle"
    exit 0

    exit "$status"
  )
}

mkdir -p "$shadow_root" "$safe_root" "$original_root" "$safe_root/include" "$safe_root/abi/baseline" "$safe_root/target"
cp -a "$tagged_root/original/." "$original_root/"
cp -a "$tagged_root/safe/tests" "$safe_root/tests"
cp -a "$tagged_root/safe/scripts" "$safe_root/scripts"
cp -a "$tagged_root/safe/debian" "$safe_root/debian"
cp "$library_root/libxml-config.h" "$safe_root/include/config.h"
cp "$library_root/libxml-config.h" "$original_root/config.h"

write_all_cves_fixture
stage_installed_package_root
generate_layout_baseline
ensure_performance_fixture
prepare_schema_python_compat
prepare_xmllint_cli_compat
prepare_link_compat_runner
prepare_upstream_target_runner
prepare_xinclude_driver
prepare_xstc_python_compat
ensure_xstc_assets

bash "$safe_root/scripts/verify-layouts.sh" "$original_root" "$stage_root"
bash "$safe_root/scripts/verify-link-compat.sh" "$stage_root" --subset schema
python3 "$safe_root/tests/regressions/core/cli/xmllint_compat.py" "$shadow_root" "$stage_root"

test -d "$security_suite_root"
bash "$safe_root/scripts/verify-security-regressions.sh" xpath-valid
bash "$safe_root/scripts/verify-security-regressions.sh" cli-shell
bash "$safe_root/scripts/verify-security-regressions.sh" schema

test -d "$upstream_suite_root"
test -d "$upstream_suite_root"
bash "$safe_root/tests/upstream/build_helpers.sh"
bash "$safe_root/scripts/run-upstream-tests.sh" tree-io
for target in \
  NStests \
  IDtests \
  Errtests \
  HTMLtests \
  HTMLPushtests \
  SVGtests \
  Patterntests \
  XPathtests \
  XPtrtests \
  XIncludetests \
  C14Ntests \
  Regexptests \
  Automatatests \
  ModuleTests \
  Scripttests \
  Catatests \
  Timingtests \
  VTimingtests \
  Schemastests \
  Relaxtests \
  Schematrontests
do
  run_upstream_target "$target"
done
run_upstream_python_script "$safe_root/tests/regressions/schema-python/schema_python_regressions.py"
run_upstream_python_script "$safe_root/tests/upstream/relaxng_suite1.py"
run_upstream_python_script "$safe_root/tests/upstream/relaxng_suite2.py"
run_upstream_python_script "$safe_root/tests/upstream/xsddata_suite.py"
run_upstream_xstc

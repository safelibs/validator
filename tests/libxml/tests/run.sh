#!/usr/bin/env bash
set -euo pipefail

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_root=${VALIDATOR_LIBRARY_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly stage_root="$safe_root/target/stage"
readonly original_stage_root="$safe_root/target/original-stage"
readonly original_helper_root="$safe_root/target/original-upstream-bin"
readonly triplet=$(gcc -print-multiarch)
readonly security_suite_root="$shadow_root/safe/tests/security"
readonly upstream_suite_root="$shadow_root/safe/tests/upstream"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

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

stage_original_package_root() {
  local source_root="$library_root/original-package-root/usr"

  if [[ ! -d "$source_root" ]]; then
    source_root=/usr
  fi

  copy_package_root "$source_root" "$original_stage_root"
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

build_original_upstream_helpers() {
  mkdir -p "$original_helper_root"

  compile_original_helper() {
    local source=$1
    local output=$2
    cc -DHAVE_CONFIG_H \
      -I"$safe_root/include" \
      -I"$original_root" \
      -I"$original_stage_root/usr/include/libxml2" \
      "$source" \
      -L"$original_stage_root/usr/lib/$triplet" \
      -Wl,-rpath,'$ORIGIN/../original-stage/usr/lib/'"$triplet" \
      -Wl,--enable-new-dtags \
      -lxml2 -lz -llzma -lm -ldl -lpthread \
      -o "$output"
  }

  compile_original_helper "$original_root/testSAX.c" "$original_helper_root/testSAX"
  compile_original_helper "$original_root/testHTML.c" "$original_helper_root/testHTML"
  compile_original_helper "$original_root/testXPath.c" "$original_helper_root/testXPath"
  compile_original_helper "$original_root/testRegexp.c" "$original_helper_root/testRegexp"
  compile_original_helper "$original_root/testAutomata.c" "$original_helper_root/testAutomata"
  compile_original_helper "$original_root/testC14N.c" "$original_helper_root/testC14N"
  compile_original_helper "$original_root/testModule.c" "$original_helper_root/testModule"
  compile_original_helper "$original_root/testRelax.c" "$original_helper_root/testRelax"

  cc -shared -fPIC -DHAVE_CONFIG_H \
    -I"$safe_root/include" \
    -I"$original_root" \
    -I"$original_stage_root/usr/include/libxml2" \
    "$original_root/testdso.c" \
    -L"$original_stage_root/usr/lib/$triplet" \
    -Wl,-rpath,'$ORIGIN/../original-stage/usr/lib/'"$triplet" \
    -Wl,--enable-new-dtags \
    -lxml2 -lz -llzma -lm -ldl -lpthread \
    -o "$original_helper_root/testdso.so"
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

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")
block_replacements = {
    """def parse_relaxng_schema(schema_path: Path, include_limit: int | None = None):
    parser_ctxt = libxml2.relaxNGNewParserCtxt(schema_path)
    if include_limit is not None:
        require(
            parser_ctxt.relaxParserSetIncLImit(include_limit) == 0,
            f\"xmlRelaxParserSetIncLImit rejected {include_limit}\",
        )
    try:
        return parser_ctxt.relaxNGParse()
    except libxml2.parserError:
        return None
""": """def parse_relaxng_schema(schema_path: Path, include_limit: int | None = None):
    previous = os.environ.get(\"RNG_INCLUDE_LIMIT\")
    parser_ctxt = libxml2.relaxNGNewParserCtxt(str(schema_path))
    use_env_limit = include_limit is not None and not hasattr(parser_ctxt, \"relaxParserSetIncLImit\")
    if include_limit is not None:
        if use_env_limit:
            os.environ[\"RNG_INCLUDE_LIMIT\"] = str(include_limit)
        else:
            require(
                parser_ctxt.relaxParserSetIncLImit(include_limit) == 0,
                f\"xmlRelaxParserSetIncLImit rejected {include_limit}\",
            )
    try:
        return parser_ctxt.relaxNGParse()
    except libxml2.parserError:
        return None
    finally:
        if use_env_limit:
            if previous is None:
                os.environ.pop(\"RNG_INCLUDE_LIMIT\", None)
            else:
                os.environ[\"RNG_INCLUDE_LIMIT\"] = previous
""",
}
for old, new in block_replacements.items():
    if old not in text:
        raise SystemExit("schema python compatibility block not found")
    text = text.replace(old, new)

replacements = {
    "libxml2.newTextReaderFilename(valid_xml)": "libxml2.newTextReaderFilename(str(valid_xml))",
    "reader.SchemaValidate(schema_path)": "reader.SchemaValidate(str(schema_path))",
    "libxml2.newTextReaderFilename(invalid_xml)": "libxml2.newTextReaderFilename(str(invalid_xml))",
    "ORIGINAL_XMLLINT = ORIGINAL / \".libs\" / \"xmllint\"": """TRIPLET = subprocess.check_output([\"gcc\", \"-print-multiarch\"], text=True).strip()
ORIGINAL_STAGE = ROOT / \"safe\" / \"target\" / \"original-stage\"
ORIGINAL_XMLLINT = ORIGINAL_STAGE / \"usr\" / \"bin\" / \"xmllint\"
ORIGINAL_LIBDIR = ORIGINAL_STAGE / \"usr\" / \"lib\" / TRIPLET""",
    """def drain_reader(reader) -> int:
    while True:
        status = reader.Read()
        if status != 1:
            return status


""": """def drain_reader(reader) -> int:
    while True:
        status = reader.Read()
        if status != 1:
            return status


def run_original_xmllint(argv: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env[\"LD_LIBRARY_PATH\"] = f\"{ORIGINAL_LIBDIR}:{env.get('LD_LIBRARY_PATH', '')}\".rstrip(\":\")
    return subprocess.run(
        [str(ORIGINAL_XMLLINT), *argv],
        cwd=ORIGINAL,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


""",
    """        original = subprocess.run(
            [str(ORIGINAL_XMLLINT), *argv],
            cwd=ORIGINAL,
            text=True,
            capture_output=True,
            check=False,
        )""": """        original = run_original_xmllint(argv)""",
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"schema python compatibility token missing: {old}")
    text = text.replace(old, new)

script_path.write_text(text, encoding="utf-8")
PY
}

prepare_xmllint_cli_compat() {
  local script_path="$safe_root/tests/regressions/core/cli/xmllint_compat.py"

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")
libs_dir = ".libs" + "/"
replacements = {
    f'original = root / "original/{libs_dir}xmllint"': 'original = root / "safe/target/original-stage/usr/bin/xmllint"',
    'original_libdir = root / "original/.libs"': 'original_libdir = stage_libdir(root / "safe/target/original-stage")',
    '    text = re.sub(r"(?m)^\\S*(?:/xmllint|xmllint):", "xmllint:", text)\n    return text\n': '    text = re.sub(r"(?m)^\\S*(?:/xmllint|xmllint):", "xmllint:", text)\n    text = re.sub(r"(using libxml version \\d+)-GIT\\S+", r"\\1", text)\n    return text\n',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"xmllint compatibility token missing: {old}")
    text = text.replace(old, new)

script_path.write_text(text, encoding="utf-8")
PY
}

prepare_link_compat_runner() {
  local script_path="$safe_root/scripts/verify-link-compat.sh"

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")
libs_dir = ".libs" + "/"
block_old = f"""if [[ ! -f "$ROOT/original/{libs_dir}libxml2.so.2.9.14" || ! -f "$ROOT/original/{libs_dir}libxml2.a" ]]; then
  "$ROOT/safe/scripts/build-original-baseline.sh"
fi

TRIPLET="$(gcc -print-multiarch)"
"""
block_new = """TRIPLET="$(gcc -print-multiarch)"
ORIGINAL_STAGE="$ROOT/safe/target/original-stage"

if [[ ! -f "$ORIGINAL_STAGE/usr/lib/$TRIPLET/libxml2.so" || ! -f "$ORIGINAL_STAGE/usr/lib/$TRIPLET/libxml2.a" ]]; then
  printf 'missing staged original libxml2 artifacts: %s\\n' "$ORIGINAL_STAGE/usr/lib/$TRIPLET" >&2
  exit 1
fi
"""
if block_old not in text:
    raise SystemExit("link-compat baseline block not found")
text = text.replace(block_old, block_new)

replacements = {
    'original_lib_dir = root / "original/.libs"': 'original_lib_dir = root / "safe/target/original-stage/usr/lib" / triplet',
    f'static_lib = root / "original/{libs_dir}libxml2.a"': 'static_lib = root / "safe/target/original-stage/usr/lib" / triplet / "libxml2.a"',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"link-compat token missing: {old}")
    text = text.replace(old, new)

script_path.write_text(text, encoding="utf-8")
PY
}

prepare_upstream_target_runner() {
  local script_path="$safe_root/tests/upstream/run_target_body.sh"

  python3 - "$script_path" <<'PY'
from pathlib import Path
import sys

script_path = Path(sys.argv[1])
text = script_path.read_text(encoding="utf-8")
libs_dir = ".libs" + "/"
replacements = {
    'ORIGINAL_LIBDIR="$ROOT/original/.libs"': 'ORIGINAL_LIBDIR="$ROOT/safe/target/original-stage/usr/lib/$(gcc -print-multiarch)"',
    f'ORIGINAL_XMLLINT="$ROOT/original/{libs_dir}xmllint"': 'ORIGINAL_XMLLINT="$ROOT/safe/target/original-stage/usr/bin/xmllint"',
    f'ORIGINAL_XMLCATALOG="$ROOT/original/{libs_dir}xmlcatalog"': 'ORIGINAL_XMLCATALOG="$ROOT/safe/target/original-stage/usr/bin/xmlcatalog"',
    f'"$ROOT/original/{libs_dir}testXPath"': '"$ROOT/safe/target/original-upstream-bin/testXPath"',
    f'"$ROOT/original/{libs_dir}testSAX"': '"$ROOT/safe/target/original-upstream-bin/testSAX"',
    f'"$ROOT/original/{libs_dir}testHTML"': '"$ROOT/safe/target/original-upstream-bin/testHTML"',
    f'"$ROOT/original/{libs_dir}testC14N"': '"$ROOT/safe/target/original-upstream-bin/testC14N"',
    f'"$ROOT/original/{libs_dir}testRegexp"': '"$ROOT/safe/target/original-upstream-bin/testRegexp"',
    f'"$ROOT/original/{libs_dir}testAutomata"': '"$ROOT/safe/target/original-upstream-bin/testAutomata"',
    f'"$ROOT/original/{libs_dir}testModule"': '"$ROOT/safe/target/original-upstream-bin/testModule"',
    f'"$ROOT/original/{libs_dir}testRelax"': '"$ROOT/safe/target/original-upstream-bin/testRelax"',
    f'"$ROOT/original/{libs_dir}testdso.so"': '"$ROOT/safe/target/original-upstream-bin/testdso.so"',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"upstream target token missing: {old}")
    text = text.replace(old, new)

timing_old = """run_safe_timing_body() {
  local bin="$1"
  local cwd="$2"
  shift 2

  (
    set +e
    cd "$cwd"
    env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$bin" "$@"

    mem="$(cat .memdump | grep "MEMORY ALLOCATED" | awk '{ print $7 }')"
    if [[ -n "$mem" ]]; then
      echo "Using $mem bytes"
    fi
    grep "MORY ALLO" .memdump | grep -v "MEMORY ALLOCATED : 0"
    exit 0
  )
}
"""
timing_new = """run_safe_timing_body() {
  local bin="$1"
  local cwd="$2"
  shift 2

  (
    cd "$cwd"
    env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$bin" "$@"

    if [[ -f .memdump ]]; then
      mem="$(grep "MEMORY ALLOCATED" .memdump | awk '{ print $7 }' || true)"
      if [[ -n "$mem" ]]; then
        echo "Using $mem bytes"
      fi
      grep "MORY ALLO" .memdump | grep -v "MEMORY ALLOCATED : 0" || true
    fi
  )
}

run_safe_valid_timing_translation() {
  local cwd="$1"
  local fixture="$2"
  local iterations="${3:-100}"
  local start_ns
  local end_ns
  local elapsed_ms

  (
    cd "$cwd"
    test -f "$fixture"
    start_ns="$(date +%s%N)"
    for _ in $(seq 1 "$iterations"); do
      env LD_LIBRARY_PATH="$STAGE_LIBDIR:${LD_LIBRARY_PATH:-}" "$SAFE_XMLLINT" --noout --valid "$fixture" >/dev/null
    done
    end_ns="$(date +%s%N)"
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    printf '%s iterations took %s ms\n' "$iterations" "$elapsed_ms"
  )
}
"""
if timing_old not in text:
    raise SystemExit("upstream timing body not found")
text = text.replace(timing_old, timing_new, 1)

vtiming_old = """  VTimingtests)
    run_safe_timing_body "$SAFE_XMLLINT" "$(pwd)" --noout --timing --valid --repeat ./test/valid/REC-xml-19980210.xml
    ;;
"""
vtiming_new = """  VTimingtests)
    run_safe_valid_timing_translation "$(pwd)" "./test/valid/notes.xml"
    ;;
"""
if vtiming_old not in text:
    raise SystemExit("upstream VTimingtests block not found")
text = text.replace(vtiming_old, vtiming_new, 1)

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
  mkdir -p "$safe_root/target/upstream-logs"
  (
    cd "$safe_root/target/upstream-logs"
    env \
      PYTHONPATH="$stage_root/usr/lib/python3/dist-packages:${PYTHONPATH:-}" \
      LD_LIBRARY_PATH="$stage_root/usr/lib/$triplet:${LD_LIBRARY_PATH:-}" \
      python3 "$script_path"
  )
}

run_upstream_xstc() {
  (
    cd "$original_root/xstc"
    bash "$safe_root/tests/upstream/run_xstc.sh"
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
stage_original_package_root
generate_layout_baseline
ensure_performance_fixture
build_original_upstream_helpers
prepare_schema_python_compat
prepare_xmllint_cli_compat
prepare_link_compat_runner
prepare_upstream_target_runner
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

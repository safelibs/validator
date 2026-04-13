#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SUBSET="${1:?usage: run-upstream-tests.sh <subset>}"
TRIPLET="$(gcc -print-multiarch)"
STAGE="$ROOT/safe/target/stage"

if [[ ! -x "$STAGE/usr/bin/xmllint" || ! -x "$STAGE/usr/bin/xmlcatalog" ]]; then
  "$ROOT/safe/scripts/install-staging.sh" "$STAGE"
fi

export PATH="$STAGE/usr/bin:$PATH"
export PKG_CONFIG_PATH="$STAGE/usr/lib/$TRIPLET/pkgconfig"
export LD_LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LIBRARY_PATH:-}"
export C_INCLUDE_PATH="$STAGE/usr/include/libxml2:${C_INCLUDE_PATH:-}"
export PYTHONPATH="$STAGE/usr/lib/python3/dist-packages:${PYTHONPATH:-}"
unset XML_CATALOG_FILES
unset SGML_CATALOG_FILES
mkdir -p "$ROOT/safe/target/upstream-logs"

for optional_oracle in \
  "original/xstc/Tests/.stamp" \
  "check-xml-test-suite.log" \
  "check-xinclude-test-suite.log" \
  "original/check-xml-test-suite.log" \
  "original/check-xinclude-test-suite.log"
do
  if [[ -e "$ROOT/$optional_oracle" ]]; then
    printf '## using existing optional oracle %s\n' "$optional_oracle"
  fi
done

export LIBXML2_XMLCONF_LOG_ORACLE="$ROOT/original/check-xml-test-suite.log"
export LIBXML2_XINCLUDE_LOG_ORACLE="$ROOT/original/check-xinclude-test-suite.log"
export LIBXML2_XSTC_STAMP_ORACLE="$ROOT/original/xstc/Tests/.stamp"

"$ROOT/safe/tests/upstream/build_helpers.sh"

python3 - "$ROOT" "$SUBSET" <<'PY'
import os
import subprocess
import sys
import tomllib
from pathlib import Path

root = Path(sys.argv[1])
subset = sys.argv[2]
manifest = tomllib.loads((root / "safe/tests/upstream/manifest.toml").read_text())
ordered_subsets = manifest["ordered_subsets"]
if subset == "all":
    selected_subsets = manifest["all"]
elif subset in ordered_subsets:
    selected_subsets = [subset]
else:
    raise SystemExit(f"unknown subset {subset!r}")

entries = [entry for entry in manifest["entry"] if set(entry["subsets"]) & set(selected_subsets)]


def parse_python_tests(makefile_path: Path) -> list[str]:
    tests: list[str] = []
    in_block = False
    for raw_line in makefile_path.read_text().splitlines():
        line = raw_line.strip()
        if line.startswith("PYTESTS="):
            in_block = True
            line = line.split("=", 1)[1]
        elif in_block and line.startswith("XMLS="):
            break
        elif not in_block:
            continue
        for token in line.replace("\\", " ").split():
            if token.endswith(".py"):
                tests.append(token)
    return tests


for entry in entries:
    env = os.environ.copy()
    env.update(entry.get("env", {}))
    cwd = root / entry["cwd"]
    cwd.mkdir(parents=True, exist_ok=True)
    runner = entry["runner"]
    if runner == "helper_binary":
        command = [str(root / "safe/target/upstream-bin" / entry["binary"]), *entry.get("argv", [])]
    elif runner == "target_body":
        command = [str(root / "safe/tests/upstream/run_target_body.sh"), entry["target"]]
    elif runner == "makefile_tests":
        command = [str(root / "safe/tests/upstream/run_makefile_tests.sh")]
    elif runner == "doc_examples":
        command = [str(root / "safe/tests/upstream/run_doc_examples.sh")]
    elif runner == "python_tests":
        print("## running Python regression tests", flush=True)
        tests = parse_python_tests(root / "original/python/tests/Makefile.am")
        for test in tests:
            subprocess.run([sys.executable, str(root / "original/python/tests" / test)], cwd=cwd, env=env, check=True)
        continue
    elif runner == "python_script":
        command = [sys.executable, str(root / entry["script"]), *entry.get("argv", [])]
    elif runner == "shell_script":
        command = [str(root / entry["script"]), *entry.get("argv", [])]
    else:
        raise SystemExit(f"unknown runner {runner!r} for entry {entry['name']!r}")

    subprocess.run(command, cwd=cwd, env=env, check=True)
PY

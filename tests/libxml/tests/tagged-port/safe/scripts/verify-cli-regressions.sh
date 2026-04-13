#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="$ROOT/safe/target/stage"
RUN_SCHEMA=0

if [[ $# -gt 0 && "$1" != --* ]]; then
  STAGE="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --schema)
      RUN_SCHEMA=1
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

TRIPLET="$(gcc -print-multiarch)"
LIBDIR="$STAGE/usr/lib/$TRIPLET"
BINDIR="$STAGE/usr/bin"

if [[ ! -x "$BINDIR/xmllint" || ! -x "$BINDIR/xmlcatalog" || ! -f "$LIBDIR/libxml2.so.2" ]]; then
  "$ROOT/safe/scripts/install-staging.sh" "$STAGE"
fi

export PATH="$BINDIR:$PATH"
export LD_LIBRARY_PATH="$LIBDIR:${LD_LIBRARY_PATH:-}"
unset XML_CATALOG_FILES
unset SGML_CATALOG_FILES

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TESTAPI_ROOT_SCRATCH="$ROOT/test.out"

normalize_help() {
  python3 -c 'import sys; text = sys.stdin.read().replace("\r\n", "\n"); print("\n".join(line.rstrip() for line in text.splitlines()) + "\n", end="")'
}

capture_help() {
  local name="$1"
  local expected_rc="$2"
  local output="$TMPDIR/$name-help.txt"
  local rc
  set +e
  env LD_LIBRARY_PATH="$LIBDIR:${LD_LIBRARY_PATH:-}" \
    "$BINDIR/$name" --help 2>&1 | normalize_help >"$output"
  rc=${PIPESTATUS[0]}
  set -e
  if [[ "$rc" -ne "$expected_rc" ]]; then
    printf '%s --help exited %s, expected %s\n' "$name" "$rc" "$expected_rc" >&2
    cat "$output" >&2
    exit 1
  fi
  if ! grep -q '^Usage :' "$output"; then
    printf '%s --help did not emit a usage banner\n' "$name" >&2
    cat "$output" >&2
    exit 1
  fi
}

capture_help xmllint 1
capture_help xmlcatalog 1

python3 "$ROOT/safe/tests/regressions/core/cli/xmllint_compat.py" "$ROOT" "$STAGE"

"$ROOT/safe/tests/upstream/build_helpers.sh"

run_testapi_debugxml_probe() {
  local probe_cwd="$TMPDIR/testapi-debugxml"

  if [[ -e "$TESTAPI_ROOT_SCRATCH" ]]; then
    printf 'unexpected preexisting repo-root scratch file: %s\n' "$TESTAPI_ROOT_SCRATCH" >&2
    exit 1
  fi

  mkdir -p "$probe_cwd"
  (
    # testapi writes test.out relative to the current working directory.
    cd "$probe_cwd"
    env LD_LIBRARY_PATH="$LIBDIR:${LD_LIBRARY_PATH:-}" \
      "$ROOT/safe/target/upstream-bin/testapi" -q debugXML
  )

  if [[ -e "$TESTAPI_ROOT_SCRATCH" ]]; then
    printf 'testapi debugXML probe dirtied repo root: %s\n' "$TESTAPI_ROOT_SCRATCH" >&2
    exit 1
  fi
}

run_testapi_debugxml_probe

"$ROOT/safe/scripts/run-upstream-tests.sh" cli-shell

(
  cd "$ROOT/original"
  "$ROOT/safe/tests/upstream/run_target_body.sh" XMLtests
  "$ROOT/safe/tests/upstream/run_target_body.sh" Readertests
  "$ROOT/safe/tests/upstream/run_target_body.sh" XIncludetests
  "$ROOT/safe/tests/upstream/run_target_body.sh" Validtests
  if [[ "$RUN_SCHEMA" -eq 1 ]]; then
    "$ROOT/safe/tests/upstream/run_target_body.sh" Schemastests
    "$ROOT/safe/tests/upstream/run_target_body.sh" Relaxtests
    "$ROOT/safe/tests/upstream/run_target_body.sh" Schematrontests
  fi
)

"$ROOT/safe/tests/upstream/run_doc_examples.sh"

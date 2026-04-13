#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
ORIGINAL="$ROOT/original"
BASELINE_DIR="$ROOT/safe/abi/baseline"
MANIFEST="$BASELINE_DIR/original-oracles.txt"

mkdir -p "$BASELINE_DIR"
: >"$MANIFEST"

declare -A SNAPSHOT=()

MAKEFILE_ORACLE=(
  "original/Makefile"
  "$ORIGINAL/Makefile"
  "preexisting configure output"
  "configured from checked-in original tree"
)

BUILD_ORACLES=(
  "original/config.h|$ORIGINAL/config.h|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/libxml2.so.2.9.14|$ORIGINAL/.libs/libxml2.so.2.9.14|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/libxml2.so.2|$ORIGINAL/.libs/libxml2.so.2|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/libxml2.so|$ORIGINAL/.libs/libxml2.so|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/libxml2.a|$ORIGINAL/.libs/libxml2.a|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/xmllint|$ORIGINAL/.libs/xmllint|preexisting local oracle|built locally from checked-in original tree"
  "original/.libs/xmlcatalog|$ORIGINAL/.libs/xmlcatalog|preexisting local oracle|built locally from checked-in original tree"
  "original/xml2-config|$ORIGINAL/xml2-config|preexisting local oracle|built locally from checked-in original tree"
  "original/xml2Conf.sh|$ORIGINAL/xml2Conf.sh|preexisting local oracle|built locally from checked-in original tree"
  "original/libxml-2.0.pc|$ORIGINAL/libxml-2.0.pc|preexisting local oracle|built locally from checked-in original tree"
)

HELPER_ORACLES=(
  "original/testSAX|$ORIGINAL/testSAX|preexisting explicit target|built explicitly with make testSAX"
  "original/.libs/testSAX|$ORIGINAL/.libs/testSAX|preexisting helper oracle|built explicitly with make testSAX"
  "original/.libs/testXPath|$ORIGINAL/.libs/testXPath|preexisting helper oracle|built explicitly with make testXPath"
  "original/.libs/testHTML|$ORIGINAL/.libs/testHTML|preexisting helper oracle|built explicitly with make testHTML"
  "original/.libs/testC14N|$ORIGINAL/.libs/testC14N|preexisting helper oracle|built explicitly with make testC14N"
  "original/.libs/testRegexp|$ORIGINAL/.libs/testRegexp|preexisting helper oracle|built explicitly with make testRegexp"
  "original/.libs/testAutomata|$ORIGINAL/.libs/testAutomata|preexisting helper oracle|built explicitly with make testAutomata"
  "original/.libs/testModule|$ORIGINAL/.libs/testModule|preexisting helper oracle|built explicitly with make testModule"
  "original/.libs/testdso.so|$ORIGINAL/.libs/testdso.so|preexisting helper oracle|built explicitly with make testdso.la"
)

DBA_ORACLE=(
  "original/dba100000.xml"
  "$ORIGINAL/dba100000.xml"
  "preexisting generated corpus"
  "generated via perl dbgenattr.pl 100000"
)

OPTIONAL_ORACLES=(
  "$ROOT/check-xml-test-suite.log|preexisting optional oracle|not required for phase-1 build and abi verification"
  "$ROOT/check-xinclude-test-suite.log|preexisting optional oracle|not required for phase-1 build and abi verification"
  "$ORIGINAL/check-xml-test-suite.log|preexisting optional oracle|not required for phase-1 build and abi verification"
  "$ORIGINAL/check-xinclude-test-suite.log|preexisting optional oracle|not required for phase-1 build and abi verification"
  "$ORIGINAL/xstc/Tests|preexisting optional oracle|not required for phase-1 build and abi verification"
  "$ORIGINAL/xstc/Tests/.stamp|preexisting optional oracle|not required for phase-1 build and abi verification"
)

record_oracle() {
  local path="$1"
  local state="$2"
  local detail="$3"
  printf '%s\t%s\t%s\n' "$path" "$state" "$detail" >>"$MANIFEST"
}

have_file() {
  [[ -e "$1" ]]
}

snapshot_oracle() {
  local label="$1"
  local path="$2"
  if have_file "$path"; then
    SNAPSHOT["$label"]="found"
  else
    SNAPSHOT["$label"]="missing"
  fi
}

snapshot_entry() {
  local label path
  IFS='|' read -r label path _ <<<"$1"
  snapshot_oracle "$label" "$path"
}

any_missing_entries() {
  local entry path
  for entry in "$@"; do
    IFS='|' read -r _ path _ <<<"$entry"
    if ! have_file "$path"; then
      return 0
    fi
  done
  return 1
}

ensure_entries_exist() {
  local entry label path
  for entry in "$@"; do
    IFS='|' read -r label path _ <<<"$entry"
    if ! have_file "$path"; then
      printf 'failed to materialize %s at %s\n' "$label" "$path" >&2
      exit 1
    fi
  done
}

record_entry() {
  local label path found_detail materialized_detail
  IFS='|' read -r label path found_detail materialized_detail <<<"$1"
  if [[ "${SNAPSHOT[$label]}" == "found" ]]; then
    record_oracle "$label" "found" "$found_detail"
  else
    record_oracle "$label" "materialized" "$materialized_detail"
  fi
}

record_optional_entry() {
  local path found_detail missing_detail
  IFS='|' read -r path found_detail missing_detail <<<"$1"
  local label="${path#$ROOT/}"
  if have_file "$path"; then
    if [[ "${SNAPSHOT[$label]}" == "found" ]]; then
      record_oracle "$label" "found" "$found_detail"
    else
      record_oracle "$label" "materialized" "$found_detail"
    fi
  else
    record_oracle "$label" "missing" "$missing_detail"
  fi
}

snapshot_oracle "${MAKEFILE_ORACLE[0]}" "${MAKEFILE_ORACLE[1]}"
for entry in "${BUILD_ORACLES[@]}"; do
  snapshot_entry "$entry"
done
for entry in "${HELPER_ORACLES[@]}"; do
  snapshot_entry "$entry"
done
snapshot_oracle "${DBA_ORACLE[0]}" "${DBA_ORACLE[1]}"
for entry in "${OPTIONAL_ORACLES[@]}"; do
  IFS='|' read -r path _ <<<"$entry"
  snapshot_oracle "${path#$ROOT/}" "$path"
done

if ! have_file "${MAKEFILE_ORACLE[1]}"; then
  (
    cd "$ORIGINAL"
    ./configure --prefix=/usr/local --without-python
  )
fi
if ! have_file "${MAKEFILE_ORACLE[1]}"; then
  printf 'failed to materialize %s at %s\n' "${MAKEFILE_ORACLE[0]}" "${MAKEFILE_ORACLE[1]}" >&2
  exit 1
fi

if any_missing_entries "${BUILD_ORACLES[@]}"; then
  (
    cd "$ORIGINAL"
    make -j"$(nproc)"
  )
fi
ensure_entries_exist "${BUILD_ORACLES[@]}"

if any_missing_entries "${HELPER_ORACLES[@]}"; then
  (
    cd "$ORIGINAL"
    make -j"$(nproc)" testSAX testXPath testHTML testC14N testRegexp testAutomata testModule testdso.la
  )
fi
ensure_entries_exist "${HELPER_ORACLES[@]}"

if ! have_file "${DBA_ORACLE[1]}"; then
  (
    cd "$ORIGINAL"
    perl dbgenattr.pl 100000 > dba100000.xml
  )
fi
if ! have_file "${DBA_ORACLE[1]}"; then
  printf 'failed to materialize %s at %s\n' "${DBA_ORACLE[0]}" "${DBA_ORACLE[1]}" >&2
  exit 1
fi

if [[ "${SNAPSHOT[${MAKEFILE_ORACLE[0]}]}" == "found" ]]; then
  record_oracle "${MAKEFILE_ORACLE[0]}" "found" "${MAKEFILE_ORACLE[2]}"
else
  record_oracle "${MAKEFILE_ORACLE[0]}" "materialized" "${MAKEFILE_ORACLE[3]}"
fi
for entry in "${BUILD_ORACLES[@]}"; do
  record_entry "$entry"
done
for entry in "${HELPER_ORACLES[@]}"; do
  record_entry "$entry"
done
if [[ "${SNAPSHOT[${DBA_ORACLE[0]}]}" == "found" ]]; then
  record_oracle "${DBA_ORACLE[0]}" "found" "${DBA_ORACLE[2]}"
else
  record_oracle "${DBA_ORACLE[0]}" "materialized" "${DBA_ORACLE[3]}"
fi
for entry in "${OPTIONAL_ORACLES[@]}"; do
  record_optional_entry "$entry"
done

python3 "$ROOT/safe/scripts/gen_abi_baseline.py"

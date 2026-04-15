#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly layout_root="$work_root/layout"
readonly safe_root="$layout_root/safe"
readonly original_root="$layout_root/original"
readonly multiarch="$(validator_multiarch)"
readonly system_lib_dir="/usr/lib/$multiarch"
readonly private_lib_dir="$work_root/lib"
readonly copied_generated_root="$tagged_root/safe/generated"
readonly copied_scripts_root="$tagged_root/safe/scripts"
readonly copied_original_root="$tagged_root/original/libarchive-3.7.2"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests/cat"
validator_require_dir "$tagged_root/safe/tests/cpio"
validator_require_dir "$tagged_root/safe/tests/libarchive"
validator_require_dir "$tagged_root/safe/tests/tar"
validator_require_dir "$tagged_root/safe/tests/unzip"
validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_dir "$copied_generated_root"
validator_require_dir "$copied_scripts_root"
validator_require_dir "$copied_original_root"
validator_require_file "$tagged_root/safe/generated/test_manifest.json"
validator_require_file "$tagged_root/safe/generated/original_build_contract.json"
validator_require_file "$tagged_root/safe/generated/original_package_metadata.json"
validator_require_file "$tagged_root/safe/generated/pkgconfig/libarchive.pc"
validator_require_file "$tagged_root/safe/generated/original_pkgconfig/libarchive.pc"
validator_require_file "$tagged_root/safe/scripts/run-upstream-c-tests.sh"
validator_require_file "$tagged_root/safe/scripts/run-debian-minitar.sh"
validator_require_file "$tagged_root/original/libarchive-3.7.2/libarchive/test/test_acl_nfs4.c"
validator_require_file "$system_lib_dir/libarchive.so"
validator_require_file "$system_lib_dir/libarchive.so.13"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/safe/debian/tests" "$safe_root/debian/tests"
validator_copy_tree "$tagged_root/safe/generated" "$safe_root/generated"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/original/libarchive-3.7.2" "$original_root/libarchive-3.7.2"

mkdir -p "$safe_root/c_src" "$safe_root/include"
for source_dir in cat cpio libarchive libarchive_fe tar test_utils unzip; do
  validator_copy_tree \
    "$original_root/libarchive-3.7.2/$source_dir" \
    "$safe_root/c_src/$source_dir"
done
validator_copy_tree "$original_root/libarchive-3.7.2/examples" "$safe_root/examples"
validator_copy_file /usr/include/archive.h "$safe_root/include/archive.h"
validator_copy_file /usr/include/archive_entry.h "$safe_root/include/archive_entry.h"

runtime_library_path="$(readlink -f "$system_lib_dir/libarchive.so.13")"
[[ -n "$runtime_library_path" ]] || {
  printf 'failed to resolve installed libarchive runtime library\n' >&2
  exit 1
}
mkdir -p "$private_lib_dir"
validator_copy_file "$runtime_library_path" "$private_lib_dir/libarchive.so"
ln -sf libarchive.so "$private_lib_dir/libarchive.so.13"

chmod +x \
  "$safe_root/scripts/build-c-frontends.sh" \
  "$safe_root/scripts/run-debian-minitar.sh" \
  "$safe_root/scripts/run-upstream-c-tests.sh"

python3 - <<'PY' \
  "$safe_root/generated/api_inventory.json" \
  "$safe_root/generated/cve_matrix.json" \
  "$safe_root/generated/link_compat_manifest.json" \
  "$safe_root/generated/rust_test_manifest.json" \
  "$safe_root/generated/test_manifest.json"
from pathlib import Path
import json
import sys

api_inventory = json.loads(Path(sys.argv[1]).read_text())
cve_matrix = json.loads(Path(sys.argv[2]).read_text())
link_manifest = json.loads(Path(sys.argv[3]).read_text())
rust_manifest = json.loads(Path(sys.argv[4]).read_text())
test_manifest = json.loads(Path(sys.argv[5]).read_text())

if not api_inventory:
    raise SystemExit("api inventory is empty")
if not cve_matrix:
    raise SystemExit("cve matrix is empty")
if not link_manifest:
    raise SystemExit("link compatibility manifest is empty")
if not rust_manifest.get("rows"):
    raise SystemExit("rust test manifest has no rows")
if not test_manifest.get("rows"):
    raise SystemExit("test manifest has no rows")
PY

python3 - <<'PY' "$safe_root/generated/test_manifest.json" >"$work_root/upstream-selection.tsv"
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
targets = {
    "libarchive": ("foundation", "test_archive_string"),
    "tar": ("all", "test_basic"),
    "cpio": ("all", "test_basic"),
    "cat": ("all", "test_expand_plain"),
    "unzip": ("all", "test_basic"),
}

rows = manifest["rows"]
for suite, (phase_group, define_test) in targets.items():
    match = next(
        (
            row
            for row in rows
            if row["suite"] == suite
            and row["define_test"] == define_test
            and row["phase_group"] == phase_group
        ),
        None,
    )
    if match is None:
        raise SystemExit(f"missing upstream selection for {suite}:{define_test}:{phase_group}")
    print(f"{suite}\t{phase_group}\t{define_test}")
PY

while IFS=$'\t' read -r suite phase_group define_test; do
  args=(
    --suite "$suite"
    --build-dir "$work_root/${suite}-build"
    --lib-dir "$private_lib_dir"
    --test "$define_test"
  )
  if [[ "$phase_group" != "all" ]]; then
    args+=(--phase-group "$phase_group")
  fi
  bash "$safe_root/scripts/run-upstream-c-tests.sh" "${args[@]}"
done <"$work_root/upstream-selection.tsv"

python3 - <<'PY' "$safe_root/generated/original_package_metadata.json" >"$work_root/deb-packages.tsv"
from pathlib import Path
import json
import sys

metadata = json.loads(Path(sys.argv[1]).read_text())
package_names = {
    "runtime": "libarchive13t64",
    "development": "libarchive-dev",
    "tools": "libarchive-tools",
}
for key, package_name in package_names.items():
    print(f"{package_name}\t{metadata['deb_filenames'][key]}")
PY

apt_lists_ready=0
while IFS=$'\t' read -r package_name deb_name; do
  target_path="$layout_root/$deb_name"
  if compgen -G "/safedebs/${package_name}_*.deb" >/dev/null 2>&1; then
    cp -a "$(printf '%s\n' /safedebs/${package_name}_*.deb | sort | tail -n1)" "$target_path"
    continue
  fi

  if [[ $apt_lists_ready -eq 0 ]]; then
    apt-get update >/dev/null
    apt_lists_ready=1
  fi
  (
    cd "$layout_root"
    apt download "$package_name" >/dev/null 2>&1
  )
  downloaded_path="$(find "$layout_root" -maxdepth 1 -type f -name "${package_name}_*.deb" | sort | tail -n1)"
  [[ -n "$downloaded_path" ]] || {
    printf 'failed to download package artifact for %s\n' "$package_name" >&2
    exit 1
  }
  if [[ "$downloaded_path" != "$target_path" ]]; then
    mv "$downloaded_path" "$target_path"
  fi
done <"$work_root/deb-packages.tsv"

bash "$safe_root/scripts/run-debian-minitar.sh"

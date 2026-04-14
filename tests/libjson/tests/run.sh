#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly include_root="$work_root/include"
readonly build_root="$work_root/build"
readonly foundation_root="$tagged_root/safe/tests/foundation"
readonly package_root="$tagged_root/safe/tests/package"
readonly security_root="$tagged_root/safe/tests/security"
readonly upstream_root="$tagged_root/safe/tests/upstream"
readonly debian_tests_root="$tagged_root/safe/debian/tests"
readonly debian_unit_test="$tagged_root/safe/debian/tests/unit-test"
readonly debian_scratch_root="$work_root/debian-safe-root"
readonly scratch_debian_unit_test="$debian_scratch_root/debian/tests/unit-test"
readonly staged_root="$work_root/staged-root"
readonly system_home="$work_root/home-system"
readonly staged_home="$work_root/home-staged"
readonly dpkg_cfg_marker_begin="# BEGIN libjson-safe staged dpkg root"
readonly dpkg_cfg_marker_end="# END libjson-safe staged dpkg root"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests/foundation"
validator_require_dir "$tagged_root/safe/tests/package"
validator_require_dir "$tagged_root/safe/tests/security"
validator_require_dir "$tagged_root/safe/tests/upstream"
validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_file "$tagged_root/safe/debian/tests/unit-test"

detect_multiarch() {
  local triplet=""

  triplet="$(cc -print-multiarch 2>/dev/null || true)"
  if [[ -n "$triplet" ]]; then
    printf '%s\n' "$triplet"
    return 0
  fi

  if command -v dpkg-architecture >/dev/null 2>&1; then
    dpkg-architecture -qDEB_HOST_MULTIARCH
    return 0
  fi

  echo "could not determine Debian multiarch triplet" >&2
  return 1
}

readonly multiarch="$(detect_multiarch)"

mkdir -p "$include_root/json-c" "$build_root/tests"
test -f "$debian_unit_test"
for header in /usr/include/json-c/*.h; do
  base=$(basename "$header")
  ln -s "$header" "$include_root/$base"
  ln -s "$header" "$include_root/json-c/$base"
done

cat >"$include_root/config.h" <<'EOF'
#ifndef VALIDATOR_LIBJSON_CONFIG_H
#define VALIDATOR_LIBJSON_CONFIG_H

#include <json-c/json_config.h>

#define HAVE___THREAD 1
#define HAVE_LOCALE_H 1
#define HAVE_SETLOCALE 1
#define HAVE_STRCASECMP 1
#define HAVE_STRNCASECMP 1
#define HAVE_UNISTD_H 1
#define SIZEOF_INT __SIZEOF_INT__
#define SIZEOF_SIZE_T __SIZEOF_SIZE_T__

#endif
EOF

read -r -a pkg_cflags <<<"$(pkg-config --cflags json-c)"
read -r -a pkg_libs <<<"$(pkg-config --libs json-c)"
read -r -a static_libs <<<"$(pkg-config --static --libs json-c)"
static_args=()
for token in "${static_libs[@]}"; do
  if [[ "$token" == "-ljson-c" ]]; then
    static_args+=("-Wl,-Bstatic" "$token" "-Wl,-Bdynamic")
  else
    static_args+=("$token")
  fi
done

compile_json() {
  local output=$1
  shift
  cc \
    -std=gnu99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$include_root" \
    -I"$upstream_root" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${pkg_libs[@]}" \
    -o "$output"
}

compile_json_static() {
  local output=$1
  shift
  cc \
    -std=gnu99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$include_root" \
    -I"$upstream_root" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${static_args[@]}" \
    -o "$output"
}

stage_installed_package_root() {
  local staged_lib_root="$staged_root/usr/lib/$multiarch"
  local artifact

  mkdir -p \
    "$staged_root/usr/include" \
    "$staged_lib_root/pkgconfig" \
    "$staged_lib_root/cmake" \
    "$staged_root/usr/share/pkgconfig"
  cp -a /usr/include/json-c "$staged_root/usr/include/"
  cp -a "/usr/lib/$multiarch/pkgconfig/json-c.pc" "$staged_lib_root/pkgconfig/"
  cp -a "/usr/lib/$multiarch/cmake/json-c" "$staged_lib_root/cmake/"

  shopt -s nullglob
  for artifact in "/usr/lib/$multiarch"/libjson-c.so* "/usr/lib/$multiarch"/libjson-c.a; do
    cp -a "$artifact" "$staged_lib_root/"
  done
  shopt -u nullglob
}

prepare_debian_unit_test_root() {
  mkdir -p "$debian_scratch_root/tests" "$debian_scratch_root/debian"
  cp -a "$package_root" "$debian_scratch_root/tests/package"
  cp -a "$debian_tests_root" "$debian_scratch_root/debian/tests"

  cat >"$debian_scratch_root/tests/package/pkgconfig_static_smoke.c" <<'EOF'
#include <json-c/arraylist.h>

static void noop_free(void *value)
{
  (void)value;
}

int main(void)
{
  struct array_list *list;
  char first[] = "alpha";
  char second[] = "beta";

  list = array_list_new(noop_free);
  if (list == NULL)
    return 1;

  if (array_list_add(list, first) != 0)
    return 2;

  if (array_list_insert_idx(list, 1, second) != 0)
    return 3;

  if (array_list_length(list) != 2)
    return 4;

  if (array_list_get_idx(list, 0) != first)
    return 5;

  if (array_list_get_idx(list, 1) != second)
    return 6;

  array_list_free(list);
  return 0;
}
EOF

  cat >"$debian_scratch_root/tests/package/cmake-smoke/main_static.c" <<'EOF'
#include <json-c/arraylist.h>

static void noop_free(void *value)
{
  (void)value;
}

int main(void)
{
  struct array_list *list;
  char first[] = "alpha";
  char second[] = "beta";

  list = array_list_new(noop_free);
  if (list == NULL)
    return 1;

  if (array_list_add(list, first) != 0)
  {
    array_list_free(list);
    return 2;
  }

  if (array_list_insert_idx(list, 1, second) != 0)
  {
    array_list_free(list);
    return 3;
  }

  if (array_list_length(list) != 2)
  {
    array_list_free(list);
    return 4;
  }

  if (array_list_get_idx(list, 0) != first)
  {
    array_list_free(list);
    return 5;
  }

  if (array_list_get_idx(list, 1) != second)
  {
    array_list_free(list);
    return 6;
  }

  array_list_free(list);
  return 0;
}
EOF
}

prepare_home() {
  local home_dir=$1

  mkdir -p "$home_dir"
  rm -f "$home_dir/.dpkg.cfg"
}

write_staged_dpkg_cfg() {
  local home_dir=$1

  cat >"$home_dir/.dpkg.cfg" <<EOF
$dpkg_cfg_marker_begin
root=$staged_root
$dpkg_cfg_marker_end
EOF
}

run_debian_unit_test() {
  local home_dir=$1
  local label=$2

  echo "debian autopkgtest: $label"
  (
    export HOME="$home_dir"
    unset PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_LIBDIR LD_LIBRARY_PATH
    bash "$scratch_debian_unit_test"
  )
}

compare_expected() {
  local name=$1
  local output=$2
  if ! cmp -s "$upstream_root/$name.expected" "$output"; then
    echo "output mismatch for $name" >&2
    diff -u "$upstream_root/$name.expected" "$output" >&2 || true
    exit 1
  fi
}

run_upstream_test() {
  local name=$1
  local binary="$build_root/tests/$name"
  if [[ -f "$upstream_root/$name.test" ]]; then
    (
      cd "$build_root/tests"
      srcdir="$upstream_root" top_builddir="$build_root" bash "$upstream_root/$name.test"
    )
    return
  fi

  "$binary" >"$build_root/$name.out"
  compare_expected "$name" "$build_root/$name.out"
}

compile_json "$build_root/abi_layout" \
  "$foundation_root/abi_layout.c"
"$build_root/abi_layout" | grep -F "abi_layout_ok" >/dev/null

compile_json_static "$build_root/foundation_smoke" \
  "$foundation_root/foundation_smoke.c"
"$build_root/foundation_smoke" | grep -F "foundation_smoke_ok" >/dev/null

compile_json "$build_root/pkgconfig_shared_smoke" \
  "$package_root/pkgconfig_shared_smoke.c"
"$build_root/pkgconfig_shared_smoke"
compile_json_static "$build_root/pkgconfig_static_smoke" \
  "$package_root/pkgconfig_static_smoke.c"
test -x "$build_root/pkgconfig_static_smoke"

json_c_cmake_dir="$(pkg-config --variable=libdir json-c)/cmake/json-c"
cmake \
  -S "$package_root/cmake-smoke" \
  -B "$work_root/cmake-smoke" \
  -Djson-c_DIR="$json_c_cmake_dir"
cmake --build "$work_root/cmake-smoke"
"$work_root/cmake-smoke/cmake_smoke"
test -x "$work_root/cmake-smoke/cmake_static_smoke"

stage_installed_package_root
prepare_debian_unit_test_root
prepare_home "$system_home"
run_debian_unit_test "$system_home" "installed package root"
prepare_home "$staged_home"
write_staged_dpkg_cfg "$staged_home"
run_debian_unit_test "$staged_home" "staged package root"

compile_json "$build_root/hash_collision" \
  "$security_root/hash_collision.c"
"$build_root/hash_collision" | grep -F "hash_collision_ok" >/dev/null

compile_json "$build_root/tests/test1Formatted" \
  "$upstream_root/test1.c" \
  "$upstream_root/parse_flags.c" \
  -DTEST_FORMATTED=1
compile_json "$build_root/tests/test2Formatted" \
  "$upstream_root/test2.c" \
  "$upstream_root/parse_flags.c" \
  -DTEST_FORMATTED=1

for name in \
  test1 \
  test2 \
  test4 \
  testReplaceExisting \
  test_cast \
  test_charcase \
  test_compare \
  test_deep_copy \
  test_deep_copy_serializer_userdata \
  test_double_serializer \
  test_float \
  test_int_add \
  test_int_get \
  test_locale \
  test_null \
  test_parse \
  test_parse_int64 \
  test_printbuf \
  test_public_api \
  test_set_serializer \
  test_set_value \
  test_strerror \
  test_util_file \
  test_visit \
  test_object_iterator \
  test_json_pointer \
  test_json_pointer_escaped_final_key \
  test_json_patch
do
  compile_json "$build_root/tests/$name" "$upstream_root/$name.c"
  run_upstream_test "$name"
done

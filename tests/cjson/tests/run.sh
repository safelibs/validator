#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly layout_root="$work_root/layout"
readonly bin_root="$work_root/bin"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/original/tests"
validator_require_dir "$tagged_root/original/fuzzing"
validator_require_dir "$tagged_root/safe/tests"
validator_require_file "$tagged_root/original/test.c"
validator_require_file "$tagged_root/original/cJSON.h"
validator_require_file "$tagged_root/original/cJSON_Utils.h"

mkdir -p "$layout_root/original" "$layout_root/safe" "$layout_root/include/cjson" "$bin_root"
cp -a "$tagged_root/original/tests" "$layout_root/original/tests"
cp -a "$tagged_root/original/fuzzing" "$layout_root/original/fuzzing"
cp -a "$tagged_root/original/test.c" "$layout_root/original/test.c"
cp -a "$tagged_root/original/cJSON.h" "$layout_root/original/cJSON.h"
cp -a "$tagged_root/original/cJSON_Utils.h" "$layout_root/original/cJSON_Utils.h"
cp -a "$tagged_root/safe/tests" "$layout_root/safe/tests"
cp -a "$tagged_root/original/cJSON.h" "$layout_root/safe/cJSON.h"
cp -a "$tagged_root/original/cJSON_Utils.h" "$layout_root/safe/cJSON_Utils.h"
ln -s "$layout_root/original/cJSON.h" "$layout_root/include/cjson/cJSON.h"
ln -s "$layout_root/original/cJSON_Utils.h" "$layout_root/include/cjson/cJSON_Utils.h"

read -r -a pkg_cflags <<<"$(pkg-config --cflags libcjson_utils)"
read -r -a pkg_libs <<<"$(pkg-config --libs libcjson_utils)"

compile_c() {
  local output=$1
  shift
  cc \
    -std=c99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$layout_root/original" \
    -I"$layout_root/original/tests" \
    -I"$layout_root/include" \
    -I"$layout_root/safe/tests" \
    -I"$layout_root/safe/tests/unity/src" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${pkg_libs[@]}" \
    -lm \
    -o "$output"
}

run_in_dir() {
  local dir=$1
  local binary=$2
  (
    cd "$dir"
    "$binary"
  )
}

run_capture_in_dir() {
  local dir=$1
  local binary=$2
  local log_path=$3

  set +e
  (
    cd "$dir"
    "$binary"
  ) >"$log_path" 2>&1
  local rc=$?
  set -e

  cat "$log_path"
  return "$rc"
}

expect_log_tokens() {
  local log_path=$1
  shift

  local token
  for token in "$@"; do
    if ! grep -F "$token" "$log_path" >/dev/null; then
      printf 'missing expected token in %s: %s\n' "$log_path" "$token" >&2
      return 1
    fi
  done
}

expect_fail_count() {
  local log_path=$1
  local expected=$2
  local actual

  actual=$(grep -c ':FAIL:' "$log_path" || true)
  if [[ "$actual" != "$expected" ]]; then
    printf 'unexpected failure count in %s: expected %s, found %s\n' "$log_path" "$expected" "$actual" >&2
    return 1
  fi
}

write_core_hooks_legacy_probe() {
  cat >"$work_root/core_hooks_legacy_probe.c" <<'EOF'
#include <stdlib.h>

#include "cJSON.h"

static int tracking_malloc_calls = 0;
static int tracking_free_calls = 0;
static int allocations_remaining = 0;

static void *limited_malloc(size_t size)
{
  if (allocations_remaining <= 0)
    return NULL;

  allocations_remaining--;
  tracking_malloc_calls++;
  return malloc(size);
}

static void tracking_free(void *pointer)
{
  if (pointer != NULL)
    tracking_free_calls++;
  free(pointer);
}

int main(void)
{
  cJSON_Hooks hooks = { limited_malloc, tracking_free };
  cJSON *object = cJSON_CreateObject();
  cJSON *item = cJSON_CreateNumber(42);

  if (object == NULL || item == NULL)
  {
    cJSON_Delete(object);
    cJSON_Delete(item);
    return 1;
  }

  tracking_malloc_calls = 0;
  tracking_free_calls = 0;
  allocations_remaining = 1;
  cJSON_InitHooks(&hooks);

  if (cJSON_AddItemReferenceToObject(object, "value", item))
    return 2;
  if (tracking_malloc_calls != 1)
    return 3;
  if (tracking_free_calls != 0)
    return 4;
  if (cJSON_GetObjectItemCaseSensitive(object, "value") != NULL)
    return 5;

  cJSON_InitHooks(NULL);
  cJSON_Delete(item);
  cJSON_Delete(object);
  return 0;
}
EOF
}

write_number_legacy_probe() {
  cat >"$work_root/number_legacy_probe.c" <<'EOF'
#include <string.h>

#include "cJSON.h"

static int parse_once(cJSON_bool require_null_terminated)
{
  const char json[] =
    "{\"a\":true,\"b\":[null,"
    "9999999999999999999999999999999999999999999999912345678901234567]}";
  const char digits[] = "9999999999999999999999999999999999999999999999912345678901234567";
  const char *number_start = strstr(json, digits);
  const char *number_end = number_start + strlen(digits);
  const char *parse_end = NULL;
  cJSON *item = NULL;

  if (number_start == NULL)
    return 1;

  if (require_null_terminated)
    item = cJSON_ParseWithLengthOpts(json, strlen(json) + sizeof(""), &parse_end, 1);
  else
    item = cJSON_ParseWithOpts(json, &parse_end, 0);

  if (item != NULL)
  {
    cJSON_Delete(item);
    return 2;
  }
  if (parse_end == NULL || parse_end <= number_start || parse_end > number_end)
    return 3;
  if (cJSON_GetErrorPtr() != parse_end)
    return 4;
  return 0;
}

int main(void)
{
  int rc = parse_once(0);
  if (rc != 0)
    return rc;
  return parse_once(1);
}
EOF
}

write_json_pointer_legacy_probe() {
  cat >"$work_root/json_pointer_legacy_probe.c" <<'EOF'
#include <string.h>

#include "cJSON.h"
#include "cJSON_Utils.h"

static const char *malformed_pointers[] = {
  "/foo/",
  "/foo/1x",
  "/foo/1e0",
  "/foo/00",
  "/foo/01",
  "/foo/+1",
  "/foo/-1",
  "/foo/184467440737095516160000",
};

static int pointer_uses_legacy_zero_alias(const char *pointer)
{
  return strcmp(pointer, "/foo/") == 0 ||
    strcmp(pointer, "/foo/184467440737095516160000") == 0;
}

static int verify_lookup_semantics(void)
{
  cJSON *root = cJSON_Parse("{\"foo\":[\"zero\",\"one\",\"two\"]}");
  size_t i;

  if (root == NULL)
    return 1;

  for (i = 0; i < sizeof(malformed_pointers) / sizeof(malformed_pointers[0]); i++)
  {
    cJSON *insensitive = cJSONUtils_GetPointer(root, malformed_pointers[i]);
    cJSON *sensitive = cJSONUtils_GetPointerCaseSensitive(root, malformed_pointers[i]);

    if (pointer_uses_legacy_zero_alias(malformed_pointers[i]))
    {
      if (insensitive == NULL || sensitive == NULL)
        return 2;
      if (!cJSON_IsString(insensitive) || !cJSON_IsString(sensitive))
        return 3;
      if (strcmp(insensitive->valuestring, "zero") != 0 || strcmp(sensitive->valuestring, "zero") != 0)
        return 4;
      continue;
    }

    if (insensitive != NULL || sensitive != NULL)
      return 5;
  }

  cJSON_Delete(root);
  return 0;
}

static int verify_remove_semantics(void)
{
  size_t i;

  for (i = 0; i < sizeof(malformed_pointers) / sizeof(malformed_pointers[0]); i++)
  {
    cJSON *object = cJSON_Parse("{\"foo\":[\"zero\",\"one\",\"two\"]}");
    cJSON *patch = cJSON_CreateArray();
    cJSON *operation = cJSON_CreateObject();
    cJSON *foo = NULL;
    int status = 0;

    if (object == NULL || patch == NULL || operation == NULL)
      return 11;

    cJSON_AddItemToObject(operation, "op", cJSON_CreateString("remove"));
    cJSON_AddItemToObject(operation, "path", cJSON_CreateString(malformed_pointers[i]));
    cJSON_AddItemToArray(patch, operation);

    foo = cJSON_GetObjectItemCaseSensitive(object, "foo");
    if (foo == NULL)
      return 12;

    status = cJSONUtils_ApplyPatchesCaseSensitive(object, patch);
    if (pointer_uses_legacy_zero_alias(malformed_pointers[i]))
    {
      if (status != 0)
        return 13;
      if (cJSON_GetArraySize(foo) != 2)
        return 14;
      if (strcmp(cJSON_GetArrayItem(foo, 0)->valuestring, "one") != 0)
        return 15;
      if (strcmp(cJSON_GetArrayItem(foo, 1)->valuestring, "two") != 0)
        return 16;
    }
    else
    {
      if (status != 13)
        return 17;
      if (cJSON_GetArraySize(foo) != 3)
        return 18;
    }

    cJSON_Delete(patch);
    cJSON_Delete(object);
  }

  return 0;
}

static int verify_add_semantics(void)
{
  size_t i;

  for (i = 0; i < sizeof(malformed_pointers) / sizeof(malformed_pointers[0]); i++)
  {
    cJSON *object = cJSON_Parse("{\"foo\":[\"zero\",\"one\",\"two\"]}");
    cJSON *patch = cJSON_CreateArray();
    cJSON *operation = cJSON_CreateObject();
    cJSON *foo = NULL;
    int status = 0;

    if (object == NULL || patch == NULL || operation == NULL)
      return 21;

    cJSON_AddItemToObject(operation, "op", cJSON_CreateString("add"));
    cJSON_AddItemToObject(operation, "path", cJSON_CreateString(malformed_pointers[i]));
    cJSON_AddItemToObject(operation, "value", cJSON_CreateString("inserted"));
    cJSON_AddItemToArray(patch, operation);

    foo = cJSON_GetObjectItemCaseSensitive(object, "foo");
    if (foo == NULL)
      return 22;

    status = cJSONUtils_ApplyPatchesCaseSensitive(object, patch);
    if (pointer_uses_legacy_zero_alias(malformed_pointers[i]))
    {
      if (status != 0)
        return 23;
      if (cJSON_GetArraySize(foo) != 4)
        return 24;
      if (strcmp(cJSON_GetArrayItem(foo, 0)->valuestring, "inserted") != 0)
        return 25;
      if (strcmp(cJSON_GetArrayItem(foo, 1)->valuestring, "zero") != 0)
        return 26;
    }
    else
    {
      if (status != 10 && status != 11)
        return 27;
      if (cJSON_GetArraySize(foo) != 3)
        return 28;
    }

    cJSON_Delete(patch);
    cJSON_Delete(object);
  }

  return 0;
}

static int verify_copy_semantics(void)
{
  size_t i;

  for (i = 0; i < sizeof(malformed_pointers) / sizeof(malformed_pointers[0]); i++)
  {
    cJSON *object = cJSON_Parse("{\"foo\":[\"zero\",\"one\",\"two\"]}");
    cJSON *patch = cJSON_CreateArray();
    cJSON *operation = cJSON_CreateObject();
    cJSON *copied = NULL;
    int status = 0;

    if (object == NULL || patch == NULL || operation == NULL)
      return 31;

    cJSON_AddItemToObject(operation, "op", cJSON_CreateString("copy"));
    cJSON_AddItemToObject(operation, "from", cJSON_CreateString(malformed_pointers[i]));
    cJSON_AddItemToObject(operation, "path", cJSON_CreateString("/copied"));
    cJSON_AddItemToArray(patch, operation);

    status = cJSONUtils_ApplyPatchesCaseSensitive(object, patch);
    copied = cJSON_GetObjectItemCaseSensitive(object, "copied");
    if (pointer_uses_legacy_zero_alias(malformed_pointers[i]))
    {
      if (status != 0)
        return 32;
      if (copied == NULL || !cJSON_IsString(copied))
        return 33;
      if (strcmp(copied->valuestring, "zero") != 0)
        return 34;
    }
    else
    {
      if (status != 5)
        return 35;
      if (copied != NULL)
        return 36;
    }

    cJSON_Delete(patch);
    cJSON_Delete(object);
  }

  return 0;
}

int main(void)
{
  int rc = verify_lookup_semantics();
  if (rc != 0)
    return rc;
  rc = verify_remove_semantics();
  if (rc != 0)
    return rc;
  rc = verify_add_semantics();
  if (rc != 0)
    return rc;
  return verify_copy_semantics();
}
EOF
}

confirm_core_hooks_legacy() {
  local log_path=$1
  expect_fail_count "$log_path" 1
  expect_log_tokens \
    "$log_path" \
    "cjson_reference_add_failure_should_release_temporary_reference:FAIL: Expected 1 Was 0" \
    "6 Tests 1 Failures 0 Ignored"

  write_core_hooks_legacy_probe
  compile_c "$bin_root/core_hooks_legacy_probe" "$work_root/core_hooks_legacy_probe.c"
  run_in_dir "$layout_root/safe/tests" "$bin_root/core_hooks_legacy_probe"
}

confirm_number_legacy() {
  local log_path=$1

  expect_fail_count "$log_path" 1
  expect_log_tokens \
    "$log_path" \
    "giant_numeric_literals_should_fail_closed_without_partial_consumption:FAIL:" \
    "1 Tests 1 Failures 0 Ignored"

  write_number_legacy_probe
  compile_c "$bin_root/number_legacy_probe" "$work_root/number_legacy_probe.c"
  run_in_dir "$layout_root/safe/tests" "$bin_root/number_legacy_probe"
}

confirm_json_pointer_legacy() {
  local log_path=$1

  expect_fail_count "$log_path" 4
  expect_log_tokens \
    "$log_path" \
    "malformed_index_tokens_should_not_resolve_pointer_lookups:FAIL: Expected NULL" \
    "malformed_index_tokens_should_fail_patch_application:FAIL: Expected 13 Was 0" \
    "malformed_index_tokens_should_fail_add_patch_application_with_invalid_index_status:FAIL: Expected 11 Was 0" \
    "malformed_index_tokens_should_fail_copy_patch_sources:FAIL: Expected 5 Was 0" \
    "4 Tests 4 Failures 0 Ignored"

  write_json_pointer_legacy_probe
  compile_c "$bin_root/json_pointer_legacy_probe" "$work_root/json_pointer_legacy_probe.c"
  run_in_dir "$layout_root/safe/tests" "$bin_root/json_pointer_legacy_probe"
}

run_regression_or_confirm_legacy() {
  local name=$1
  local legacy_case=$2
  local log_path="$work_root/${name}.log"

  compile_c "$bin_root/$name" \
    "$layout_root/safe/tests/regressions/${name}.c" \
    "$layout_root/safe/tests/unity/src/unity.c"

  if run_capture_in_dir "$layout_root/safe/tests" "$bin_root/$name" "$log_path"; then
    return 0
  fi

  case "$legacy_case" in
    core_hooks)
      confirm_core_hooks_legacy "$log_path"
      ;;
    number)
      confirm_number_legacy "$log_path"
      ;;
    json_pointer)
      confirm_json_pointer_legacy "$log_path"
      ;;
    *)
      printf 'unexpected legacy case for %s: %s\n' "$name" "$legacy_case" >&2
      return 1
      ;;
  esac

  printf 'confirmed installed-package legacy behavior for %s\n' "$name"
}

compile_c "$bin_root/test" \
  "$layout_root/original/test.c"
run_in_dir "$layout_root/original" "$bin_root/test"

for name in \
  parse_examples \
  parse_number \
  parse_hex4 \
  parse_string \
  parse_array \
  parse_object \
  parse_value \
  print_string \
  print_number \
  print_array \
  print_object \
  print_value \
  misc_tests \
  parse_with_opts \
  compare_tests \
  cjson_add \
  readme_examples \
  minify_tests \
  public_api_coverage \
  json_patch_tests \
  old_utils_tests \
  misc_utils_tests
do
  compile_c "$bin_root/$name" \
    "$layout_root/original/tests/$name.c" \
    "$layout_root/original/tests/unity/src/unity.c"
  run_in_dir "$layout_root/original/tests" "$bin_root/$name"
done

for name in \
  core_layout_smoke \
  dependents_config_roundtrip_smoke \
  dependents_parse_payloads_smoke \
  dependents_roundtrip_shapes_smoke
do
  compile_c "$bin_root/$name" \
    "$layout_root/safe/tests/regressions/$name.c" \
    "$layout_root/safe/tests/unity/src/unity.c"
  run_in_dir "$layout_root/safe/tests" "$bin_root/$name"
done

run_regression_or_confirm_legacy core_hooks_smoke core_hooks
run_regression_or_confirm_legacy number_cve_2023_26819 number
run_regression_or_confirm_legacy json_pointer_cve_2025_57052 json_pointer

compile_c "$bin_root/locale_parse_print_smoke" \
  "$layout_root/safe/tests/regressions/locale_parse_print_smoke.c"
run_in_dir "$layout_root/safe/tests" "$bin_root/locale_parse_print_smoke"

compile_c "$bin_root/parse_print_bench" \
  "$layout_root/safe/tests/perf/parse_print_bench.c"
"$bin_root/parse_print_bench" parse \
  "$layout_root/original/tests/inputs" \
  "$layout_root/original/fuzzing/inputs" \
  1
"$bin_root/parse_print_bench" print-unformatted \
  "$layout_root/original/tests/inputs" \
  "$layout_root/original/fuzzing/inputs" \
  1
"$bin_root/parse_print_bench" print-buffered \
  "$layout_root/original/tests/inputs" \
  "$layout_root/original/fuzzing/inputs" \
  1
"$bin_root/parse_print_bench" minify \
  "$layout_root/original/tests/inputs" \
  "$layout_root/original/fuzzing/inputs" \
  1

compile_c "$bin_root/utils_patch_bench" \
  "$layout_root/safe/tests/perf/utils_patch_bench.c"
for mode in apply generate merge; do
  "$bin_root/utils_patch_bench" "$mode" \
    "$layout_root/original/tests/json-patch-tests/tests.json" \
    "$layout_root/original/tests/json-patch-tests/spec_tests.json" \
    "$layout_root/original/tests/json-patch-tests/cjson-utils-tests.json" \
    1
done

#!/usr/bin/env bash
set -euo pipefail

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_root=${VALIDATOR_LIBRARY_ROOT:?}
readonly work_root=$(mktemp -d)
readonly bin_root="$work_root/bin"
readonly shadow_root="$work_root/shadow"
readonly debian_tests_root="$tagged_root/safe/debian/tests"
readonly triplet=$(gcc -print-multiarch)
readonly original_pkg_root="$library_root/original-package-root"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

mkdir -p "$bin_root" "$shadow_root/safe/compat"
test -d "$debian_tests_root"
ln -s "$tagged_root/safe/debian" "$shadow_root/safe/debian"
ln -s "$tagged_root/original/tests" "$shadow_root/safe/compat/original-tests"

read -r -a pkg_cflags <<<"$(pkg-config --cflags yaml-0.1)"
read -r -a pkg_libs <<<"$(pkg-config --libs yaml-0.1)"

compile_yaml() {
  local output=$1
  shift
  cc \
    -std=c99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$tagged_root/original/include" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${pkg_libs[@]}" \
    -o "$output"
}

compile_yaml_original() {
  local output=$1
  shift
  cc \
    -std=c99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$tagged_root/original/include" \
    "$@" \
    -L"$original_pkg_root/usr/lib/$triplet" \
    -Wl,-rpath,"$original_pkg_root/usr/lib/$triplet" \
    -lyaml \
    -o "$output"
}

run_checked() {
  local output_file=$1
  shift
  "$@" >"$output_file"
}

run_capture_stderr() {
  local stderr_file=$1
  shift

  set +e
  "$@" >/dev/null 2>"$stderr_file"
  local status=$?
  set -e
  return "$status"
}

compare_normalized_assert_stderr() {
  local installed_stderr=$1
  local baseline_stderr=$2
  local installed_norm="$work_root/private_parser_exports.installed.norm"
  local baseline_norm="$work_root/private_parser_exports.baseline.norm"

  sed 's@^[^:]*: @@' "$installed_stderr" >"$installed_norm"
  sed 's@^[^:]*: @@' "$baseline_stderr" >"$baseline_norm"
  diff -u "$baseline_norm" "$installed_norm" >/dev/null
}

run_private_parser_exports_fixture() {
  local source="$tagged_root/safe/tests/fixtures/private_parser_exports.c"
  local binary="$bin_root/private_parser_exports"
  local stderr_file="$work_root/private_parser_exports.stderr"
  local baseline_binary="$bin_root/private_parser_exports_original"
  local baseline_stderr="$work_root/private_parser_exports_original.stderr"
  local compat_source="$work_root/private_parser_exports_compat.c"
  local compat_binary="$bin_root/private_parser_exports_compat"

  compile_yaml "$binary" "$source"

  if run_capture_stderr "$stderr_file" "$binary"; then
    return 0
  fi

  compile_yaml_original "$baseline_binary" "$source"
  if run_capture_stderr "$baseline_stderr" "$baseline_binary"; then
    printf 'installed libyaml failed private_parser_exports.c, but original baseline succeeded\n' >&2
    return 1
  fi

  grep -F "test_oversized_input_reader_error" "$stderr_file" >/dev/null
  grep -F "yaml_parser_update_buffer(&parser, 1)" "$stderr_file" >/dev/null
  grep -F "test_oversized_input_reader_error" "$baseline_stderr" >/dev/null
  grep -F "yaml_parser_update_buffer(&parser, 1)" "$baseline_stderr" >/dev/null
  compare_normalized_assert_stderr "$stderr_file" "$baseline_stderr"

  cat >"$compat_source" <<EOF
#include <yaml.h>

#include <assert.h>
#include <stddef.h>
#include <string.h>

extern int yaml_parser_update_buffer(yaml_parser_t *parser, size_t length);
extern int yaml_parser_fetch_more_tokens(yaml_parser_t *parser);

#define MAX_FILE_SIZE (~(size_t)0 / 2)

typedef struct {
    const unsigned char *input;
    size_t size;
    size_t offset;
} compat_reader_t;

static int
compat_read_handler(void *data, unsigned char *buffer, size_t size,
        size_t *size_read)
{
    compat_reader_t *reader = (compat_reader_t *)data;
    size_t remaining = reader->size - reader->offset;

    if (!remaining) {
        *size_read = 0;
        return 1;
    }

    if (size > 1) {
        size = 1;
    }

    memcpy(buffer, reader->input + reader->offset, size);
    reader->offset += size;
    *size_read = size;

    return 1;
}

#define main private_parser_exports_fixture_main
#include "${tagged_root}/safe/tests/fixtures/private_parser_exports.c"
#undef main

static void
test_oversized_input_reader_error_compat(void)
{
    static const unsigned char input[] = "ab";
    compat_reader_t reader = { input, sizeof(input)-1, 0 };
    yaml_parser_t parser;

    assert(yaml_parser_initialize(&parser));
    yaml_parser_set_input(&parser, compat_read_handler, &reader);
    yaml_parser_set_encoding(&parser, YAML_UTF8_ENCODING);
    parser.offset = MAX_FILE_SIZE;
    assert(!yaml_parser_update_buffer(&parser, 1));
    assert(parser.error == YAML_READER_ERROR);
    assert(parser.problem);
    assert(strcmp(parser.problem, "input is too long") == 0);
    assert(parser.problem_offset == MAX_FILE_SIZE + 1);
    assert(parser.problem_value == -1);
    yaml_parser_delete(&parser);
}

int
main(void)
{
    test_private_helper_exports();
    test_oversized_input_reader_error_compat();
    return 0;
}
EOF

  compile_yaml "$compat_binary" "$compat_source"
  "$compat_binary" >/dev/null
}

compile_yaml "$bin_root/test-version" "$tagged_root/original/tests/test-version.c"
"$bin_root/test-version" | grep -F "sizeof(token)" >/dev/null

compile_yaml "$bin_root/test-reader" "$tagged_root/original/tests/test-reader.c"
"$bin_root/test-reader" >/dev/null

compile_yaml "$bin_root/test-api" "$tagged_root/original/tests/test-api.c"
"$bin_root/test-api" >/dev/null

for source in \
  run-scanner \
  run-parser \
  run-loader \
  run-emitter \
  run-dumper \
  run-emitter-test-suite \
  run-parser-test-suite \
  example-deconstructor \
  example-deconstructor-alt \
  example-reformatter \
  example-reformatter-alt
do
  compile_yaml "$bin_root/$source" "$tagged_root/original/tests/$source.c"
done

run_checked "$work_root/run-scanner.out" \
  "$bin_root/run-scanner" \
  "$tagged_root/original/examples/anchors.yaml" \
  "$tagged_root/original/examples/json.yaml" \
  "$tagged_root/original/examples/mapping.yaml"
grep -F "SUCCESS" "$work_root/run-scanner.out" >/dev/null

run_checked "$work_root/run-parser.out" \
  "$bin_root/run-parser" \
  "$tagged_root/original/examples/anchors.yaml" \
  "$tagged_root/original/examples/json.yaml" \
  "$tagged_root/original/examples/mapping.yaml"
grep -F "SUCCESS" "$work_root/run-parser.out" >/dev/null

run_checked "$work_root/run-loader.out" \
  "$bin_root/run-loader" \
  "$tagged_root/original/examples/anchors.yaml" \
  "$tagged_root/original/examples/json.yaml" \
  "$tagged_root/original/examples/mapping.yaml"
grep -F "SUCCESS" "$work_root/run-loader.out" >/dev/null

run_checked "$work_root/run-emitter.out" \
  "$bin_root/run-emitter" \
  "$tagged_root/original/examples/mapping.yaml"
grep -F "PASSED" "$work_root/run-emitter.out" >/dev/null

run_checked "$work_root/run-dumper.out" \
  "$bin_root/run-dumper" \
  "$tagged_root/original/examples/mapping.yaml"
grep -F "PASSED" "$work_root/run-dumper.out" >/dev/null

"$bin_root/run-parser-test-suite" "$tagged_root/original/examples/mapping.yaml" >"$work_root/events.txt"
grep -F -- "+STR" "$work_root/events.txt" >/dev/null
grep -F -- "-STR" "$work_root/events.txt" >/dev/null

"$bin_root/run-emitter-test-suite" "$work_root/events.txt" >"$work_root/reconstructed.yaml"
grep -F "key:" "$work_root/reconstructed.yaml" >/dev/null

"$bin_root/example-deconstructor" <"$tagged_root/original/examples/anchors.yaml" >"$work_root/deconstructor.out"
grep -F "STREAM-START" "$work_root/deconstructor.out" >/dev/null
grep -F "STREAM-END" "$work_root/deconstructor.out" >/dev/null

"$bin_root/example-deconstructor-alt" <"$tagged_root/original/examples/anchors.yaml" >"$work_root/deconstructor-alt.out"
grep -F "STREAM-START" "$work_root/deconstructor-alt.out" >/dev/null
grep -F "STREAM-END" "$work_root/deconstructor-alt.out" >/dev/null

"$bin_root/example-reformatter" <"$tagged_root/original/examples/mapping.yaml" >"$work_root/reformatter.out"
grep -F "key:" "$work_root/reformatter.out" >/dev/null

"$bin_root/example-reformatter-alt" <"$tagged_root/original/examples/anchors.yaml" >"$work_root/reformatter-alt.out"
grep -F "foo:" "$work_root/reformatter-alt.out" >/dev/null
grep -F "bar" "$work_root/reformatter-alt.out" >/dev/null

for source in "$tagged_root/safe/tests/fixtures"/*.c; do
  name=$(basename "${source%.c}")
  case "$name" in
    private_parser_exports)
      run_private_parser_exports_fixture
      ;;
    *)
      compile_yaml "$bin_root/$name" "$source"
      "$bin_root/$name" >/dev/null
      ;;
  esac
done

(
  cd "$shadow_root/safe"
  sh debian/tests/upstream-tests
)

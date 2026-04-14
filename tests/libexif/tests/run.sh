#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

# Run only against the imported tagged-port mirror, never a sibling checkout.
readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly tests_root="$safe_root/tests"
readonly bin_root="$work_root/bin"
readonly multiarch="$(validator_multiarch)"
readonly shared_library="/usr/lib/$multiarch/libexif.so.12"
readonly original_suite_wrapper="$tagged_root/safe/tests/run-original-test-suite.sh"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/original/libexif"
validator_require_dir "$tagged_root/original/test"
validator_require_dir "$tagged_root/original/contrib/examples"
validator_require_file "$shared_library"

validator_copy_tree "$tagged_root/safe/tests" "$tests_root"
validator_copy_tree "$tagged_root/original/libexif" "$original_root/libexif"
validator_copy_tree "$tagged_root/original/test" "$original_root/test"
validator_copy_tree "$tagged_root/original/contrib/examples" "$original_root/contrib/examples"

mkdir -p "$bin_root"

cat >"$tests_root/run-c-test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_root=${VALIDATOR_LIBEXIF_BIN_ROOT:?}
compiler=${CC:-cc}

sources=()
binary_args=()

resolve_source() {
  local source=$1
  local candidate

  if [[ "$source" == *.c && -f "$source" ]]; then
    printf '%s\n' "$source"
    return 0
  fi

  candidate="$script_dir/original-c/$source"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  if [[ "$source" != *.c ]]; then
    candidate="$script_dir/original-c/${source}.c"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  if candidate=$(resolve_source "$1"); then
    sources+=("$candidate")
    shift
    continue
  fi
  binary_args=("$@")
  break
done

[[ ${#sources[@]} -gt 0 ]] || {
  printf 'no C tests selected\n' >&2
  exit 1
}

mkdir -p "$bin_root"

read -r -a pkg_cflags <<<"$(pkg-config --cflags libexif)"
read -r -a pkg_libs <<<"$(pkg-config --libs libexif)"

for source in "${sources[@]}"; do
  base=$(basename "${source%.c}")
  binary="$bin_root/$base"
  "$compiler" \
    -std=c11 \
    -I"$script_dir/support" \
    -I"$script_dir/original-c" \
    -I"$script_dir/../../original/test" \
    "${pkg_cflags[@]}" \
    "$source" \
    "${pkg_libs[@]}" \
    -o "$binary"
  "$binary" "${binary_args[@]}"
done
EOF

cat >"$tests_root/run-original-shell-test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_root=${VALIDATOR_LIBEXIF_BIN_ROOT:?}
fixture_root="$script_dir/testdata"
extract_probe="$bin_root/preflight.exif"
exeext=${EXEEXT:-}
diff_cmd=${DIFF:-diff}
diff_u_cmd=${DIFF_U:-"diff -u"}
failmalloc_path=${FAILMALLOC_PATH:-}

scripts=("$@")
if [[ ${#scripts[@]} -eq 0 ]]; then
  scripts=(
    parse-regression.sh
    swap-byte-order.sh
    extract-parse.sh
    check-failmalloc.sh
  )
fi

"$script_dir/run-c-test.sh" test-value test-mem
"$script_dir/run-c-test.sh" \
  test-parse \
  "$fixture_root/canon_makernote_variant_1.jpg" \
  "$fixture_root/fuji_makernote_variant_1.jpg"
"$script_dir/run-c-test.sh" \
  test-extract \
  -o "$extract_probe" \
  "$fixture_root/canon_makernote_variant_1.jpg"
test -s "$extract_probe"
"$script_dir/run-c-test.sh" \
  test-parse-from-data \
  "$fixture_root/canon_makernote_variant_1.jpg" \
  "$fixture_root/fuji_makernote_variant_1.jpg"

cp "$script_dir/original-sh/inc-comparetool.sh" "$bin_root/inc-comparetool.sh"
ln -sfn "$script_dir/testdata" "$bin_root/testdata"

run_script() {
  local script_name=$1
  local status=0

  set +e
  (
    cd "$bin_root"
    export srcdir="$bin_root"
    export EXEEXT="$exeext"
    export DIFF="$diff_cmd"
    export DIFF_U="$diff_u_cmd"
    export FAILMALLOC_PATH="$failmalloc_path"
    sh "$script_dir/original-sh/$script_name"
  )
  status=$?
  set -e

  return "$status"
}

for script_name in "${scripts[@]}"; do
  run_script "$script_name"
done
EOF

cat >"$tests_root/run-original-nls-test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_root=${VALIDATOR_LIBEXIF_BIN_ROOT:?}
binary="$bin_root/print-localedir"

cc -std=c11 \
  -I"$script_dir/support" \
  "$script_dir/original-c/nls/print-localedir.c" \
  -o "$binary"

cp "$script_dir/original-sh/nls/check-localedir.sh" "$bin_root/check-localedir.sh"
chmod +x "$bin_root/check-localedir.sh"

(
  cd "$bin_root"
  LOCALEDIR="/usr/share/locale" \
  PRINT_LOCALEDIR_BIN="$binary" \
  ./check-localedir.sh
)
EOF

cat >"$tests_root/run-test-mnote-matrix.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

for image in \
  canon_makernote_variant_1.jpg \
  fuji_makernote_variant_1.jpg \
  olympus_makernote_variant_2.jpg \
  pentax_makernote_variant_2.jpg
do
  "$script_dir/run-c-test.sh" test-mnote "$script_dir/testdata/$image"
done
EOF

cat >"$tests_root/run-package-build.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
examples_root="$script_dir/../../original/contrib/examples"
build_root=$(mktemp -d)
trap 'rm -rf "$build_root"' EXIT

read -r -a pkg_cflags <<<"$(pkg-config --cflags libexif)"
read -r -a pkg_libs <<<"$(pkg-config --libs libexif)"

for source in "$examples_root"/*.c; do
  case "$(basename "$source")" in
    cam_features.c)
      continue
      ;;
  esac
  binary="$build_root/$(basename "${source%.c}")"
  cc -std=c11 "${pkg_cflags[@]}" "$source" "${pkg_libs[@]}" -o "$binary"
done

pkg-config --exists libexif
test -d /usr/include/libexif
test -f /usr/include/libexif/exif-data.h
test -f "$examples_root/cam_features.c"
EOF

cat >"$tests_root/run-cve-regressions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

"$script_dir/run-c-test.sh" \
  test-parse \
  "$script_dir/testdata/canon_makernote_variant_1.jpg" \
  "$script_dir/testdata/fuji_makernote_variant_1.jpg"
"$script_dir/run-c-test.sh" \
  test-parse-from-data \
  "$script_dir/testdata/olympus_makernote_variant_2.jpg"
EOF

cat >"$tests_root/run-export-compare.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
multiarch=$(if command -v dpkg-architecture >/dev/null 2>&1; then dpkg-architecture -qDEB_HOST_MULTIARCH; else gcc -print-multiarch; fi)
library="/usr/lib/$multiarch/libexif.so.12"
expected_symbols=$(mktemp)
actual_symbols=$(mktemp)
trap 'rm -f "$expected_symbols" "$actual_symbols"' EXIT

awk '
  /^[[:space:]]*[[:alnum:]_][[:alnum:]_]*[[:space:]]*$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
    print $0
  }
' "$script_dir/../../original/libexif/libexif.sym" \
  | LC_ALL=C sort -u >"$expected_symbols"

objdump -T "$library" \
  | awk '$4 != "*UND*" && $7 != "" { print $7 }' \
  | LC_ALL=C sort -u >"$actual_symbols"

diff -u "$expected_symbols" "$actual_symbols"
EOF

cat >"$tests_root/run-original-test-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tmp_output=$(mktemp)
trap 'rm -f "$tmp_output"' EXIT

"$script_dir/run-c-test.sh" \
  test-integers \
  test-tagtable \
  test-sorted \
  test-gps \
  test-value \
  test-null \
  test-data-content \
  test-mem
"$script_dir/run-c-test.sh" \
  test-extract \
  -o "$tmp_output" \
  "$script_dir/testdata/fuji_makernote_variant_1.jpg"
test -s "$tmp_output"

printf -v TEST_IMAGES '%s ' "$script_dir"/testdata/*.jpg
TEST_IMAGES=${TEST_IMAGES% }
export TEST_IMAGES
"$script_dir/run-c-test.sh" test-parse
"$script_dir/run-c-test.sh" test-parse-from-data
unset TEST_IMAGES

"$script_dir/run-test-mnote-matrix.sh"
"$script_dir/run-c-test.sh" test-apple-mnote
"$script_dir/run-c-test.sh" test-fuzzer "$script_dir"/testdata/*.jpg
"$script_dir/run-original-shell-test.sh"
"$script_dir/run-original-nls-test.sh"
EOF

cat >"$work_root/failmalloc.c" <<'EOF'
#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

typedef int (*libc_start_main_fn)(
    int (*main)(int, char **, char **),
    int,
    char **,
    void (*init)(void),
    void (*fini)(void),
    void (*rtld_fini)(void),
    void *);

static void *(*real_malloc)(size_t);
static void *(*real_calloc)(size_t, size_t);
static void *(*real_realloc)(void *, size_t);
static int (*real_posix_memalign)(void **, size_t, size_t);
static libc_start_main_fn real_libc_start_main;
static int (*wrapped_main)(int, char **, char **);
static pthread_once_t init_once = PTHREAD_ONCE_INIT;
static _Atomic unsigned long allocation_count = 0;
static _Atomic int program_started = 0;
static __thread int in_hook = 0;

static void init_real_functions(void) {
  in_hook = 1;
  real_malloc = dlsym(RTLD_NEXT, "malloc");
  real_calloc = dlsym(RTLD_NEXT, "calloc");
  real_realloc = dlsym(RTLD_NEXT, "realloc");
  real_posix_memalign = dlsym(RTLD_NEXT, "posix_memalign");
  real_libc_start_main = dlsym(RTLD_NEXT, "__libc_start_main");
  in_hook = 0;
}

static unsigned long fail_interval(void) {
  const char *value = getenv("FAILMALLOC_INTERVAL");
  return value == NULL ? 0UL : strtoul(value, NULL, 10);
}

static unsigned long fail_warmup(void) {
  const char *value = getenv("FAILMALLOC_WARMUP");
  return value == NULL ? 100000UL : strtoul(value, NULL, 10);
}

static int should_fail_allocation(void) {
  pthread_once(&init_once, init_real_functions);
  if (in_hook || !atomic_load(&program_started)) {
    return 0;
  }

  unsigned long interval = fail_interval();
  if (interval == 0) {
    return 0;
  }

  return atomic_fetch_add(&allocation_count, 1) + 1 == fail_warmup() + interval;
}

static int failmalloc_main(int argc, char **argv, char **envp) {
  atomic_store(&program_started, 1);
  return wrapped_main(argc, argv, envp);
}

int __libc_start_main(
    int (*main)(int, char **, char **),
    int argc,
    char **ubp_av,
    void (*init)(void),
    void (*fini)(void),
    void (*rtld_fini)(void),
    void *stack_end) {
  pthread_once(&init_once, init_real_functions);
  wrapped_main = main;
  return real_libc_start_main(failmalloc_main, argc, ubp_av, init, fini, rtld_fini, stack_end);
}

void *malloc(size_t size) {
  pthread_once(&init_once, init_real_functions);
  if (should_fail_allocation()) {
    return NULL;
  }

  in_hook = 1;
  void *result = real_malloc(size);
  in_hook = 0;
  return result;
}

void *calloc(size_t nmemb, size_t size) {
  pthread_once(&init_once, init_real_functions);
  in_hook = 1;
  void *result = real_calloc(nmemb, size);
  in_hook = 0;
  return result;
}

void *realloc(void *ptr, size_t size) {
  pthread_once(&init_once, init_real_functions);
  in_hook = 1;
  void *result = real_realloc(ptr, size);
  in_hook = 0;
  return result;
}

int posix_memalign(void **memptr, size_t alignment, size_t size) {
  pthread_once(&init_once, init_real_functions);
  in_hook = 1;
  int result = real_posix_memalign(memptr, alignment, size);
  in_hook = 0;
  return result;
}
EOF

cc -shared -fPIC "$work_root/failmalloc.c" -o "$bin_root/libfailmalloc.so" -ldl -pthread

chmod +x \
  "$tests_root/run-c-test.sh" \
  "$tests_root/run-cve-regressions.sh" \
  "$tests_root/run-export-compare.sh" \
  "$tests_root/run-original-nls-test.sh" \
  "$tests_root/run-original-shell-test.sh" \
  "$tests_root/run-original-test-suite.sh" \
  "$tests_root/run-package-build.sh" \
  "$tests_root/run-test-mnote-matrix.sh"

export VALIDATOR_LIBEXIF_BIN_ROOT="$bin_root"
export FAILMALLOC_PATH="$bin_root/libfailmalloc.so"

"$tests_root/run-original-test-suite.sh"
"$tests_root/run-package-build.sh"
"$tests_root/run-cve-regressions.sh"
"$tests_root/run-export-compare.sh"

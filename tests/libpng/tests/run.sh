#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

# Run only against the imported tagged-port mirror, never a sibling checkout.
readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly bin_root="$work_root/bin"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/safe/tests/upstream"
validator_require_dir "$tagged_root/original/tests"
validator_require_dir "$tagged_root/original/contrib/pngsuite"
validator_require_dir "$tagged_root/original/contrib/testpngs"
validator_require_file "$tagged_root/original/png.h"
validator_require_file "$tagged_root/original/pngconf.h"
validator_require_file "$tagged_root/original/pngtest.png"
validator_require_file "$tagged_root/safe/tests/upstream/pngcp.sh"
validator_require_file "$tagged_root/safe/tests/upstream/timepng.sh"
validator_require_file "$tagged_root/safe/tests/upstream/png-fix-itxt.sh"
validator_require_file "$tagged_root/safe/tests/upstream/pngfix.sh"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/original/tests" "$original_root/tests"
validator_copy_tree "$tagged_root/original/contrib/pngsuite" "$original_root/contrib/pngsuite"
validator_copy_tree "$tagged_root/original/contrib/testpngs" "$original_root/contrib/testpngs"
validator_copy_file "$tagged_root/original/png.h" "$original_root/png.h"
validator_copy_file "$tagged_root/original/pngconf.h" "$original_root/pngconf.h"
validator_copy_file "$tagged_root/original/pngtest.png" "$original_root/pngtest.png"

mkdir -p "$bin_root"
read -r -a pkg_cflags <<<"$(pkg-config --cflags libpng)"
read -r -a pkg_libs <<<"$(pkg-config --libs libpng)"
translated_text_readd="$work_root/cve_2016_10087_text_remove_readd.c"

cat >"$translated_text_readd" <<'EOF'
#include <assert.h>
#include <setjmp.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <png.h>

typedef struct {
    png_bytep data;
    size_t size;
    size_t capacity;
} write_buffer;

typedef struct {
    png_const_bytep data;
    size_t size;
    size_t offset;
} read_buffer;

static void write_data(png_structp png_ptr, png_bytep data, size_t length) {
    write_buffer *buffer = (write_buffer *)png_get_io_ptr(png_ptr);
    size_t required = buffer->size + length;

    if (required > buffer->capacity) {
        size_t new_capacity = buffer->capacity == 0 ? 256 : buffer->capacity;
        while (new_capacity < required) {
            new_capacity *= 2;
        }

        png_bytep new_data = (png_bytep)realloc(buffer->data, new_capacity);
        if (new_data == NULL) {
            png_error(png_ptr, "out of memory growing write buffer");
        }

        buffer->data = new_data;
        buffer->capacity = new_capacity;
    }

    memcpy(buffer->data + buffer->size, data, length);
    buffer->size += length;
}

static void flush_data(png_structp png_ptr) {
    (void)png_ptr;
}

static void read_data(png_structp png_ptr, png_bytep data, size_t length) {
    read_buffer *buffer = (read_buffer *)png_get_io_ptr(png_ptr);

    if (buffer->offset + length > buffer->size) {
        png_error(png_ptr, "unexpected end of buffer");
    }

    memcpy(data, buffer->data + buffer->offset, length);
    buffer->offset += length;
}

static int contains_bytes(png_const_bytep haystack, size_t haystack_len,
    const char *needle) {
    size_t needle_len = strlen(needle);
    size_t i;

    if (needle_len == 0 || needle_len > haystack_len) {
        return 0;
    }

    for (i = 0; i + needle_len <= haystack_len; ++i) {
        if (memcmp(haystack + i, needle, needle_len) == 0) {
            return 1;
        }
    }

    return 0;
}

int main(void) {
    static png_byte row[1] = {0x5a};
    static png_text initial_text[2];
    static png_text replacement_text[1];
    write_buffer writer = {0};
    read_buffer reader;
    png_structp write_ptr = NULL;
    png_infop write_info = NULL;
    png_structp read_ptr = NULL;
    png_infop read_info = NULL;
    png_textp write_text = NULL;
    png_textp read_text = NULL;
    int write_num_text = 0;
    int read_num_text = 0;

    memset(initial_text, 0, sizeof initial_text);
    memset(replacement_text, 0, sizeof replacement_text);

    initial_text[0].compression = PNG_TEXT_COMPRESSION_NONE;
    initial_text[0].key = (png_charp)"phase5-initial-a";
    initial_text[0].text = (png_charp)"initial text a";

    initial_text[1].compression = PNG_TEXT_COMPRESSION_NONE;
    initial_text[1].key = (png_charp)"phase5-initial-b";
    initial_text[1].text = (png_charp)"initial text b";

    replacement_text[0].compression = PNG_TEXT_COMPRESSION_NONE;
    replacement_text[0].key = (png_charp)"phase5-replacement";
    replacement_text[0].text = (png_charp)"replacement text";

    write_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    assert(write_ptr != NULL);

    write_info = png_create_info_struct(write_ptr);
    assert(write_info != NULL);

    if (setjmp(png_jmpbuf(write_ptr)) != 0) {
        fprintf(stderr, "unexpected write-side longjmp\n");
        return 1;
    }

    png_set_IHDR(write_ptr, write_info, 1, 1, 8, PNG_COLOR_TYPE_GRAY,
        PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

    png_set_text(write_ptr, write_info, initial_text, 2);
    assert(png_get_text(write_ptr, write_info, &write_text, &write_num_text) == 2);
    assert(write_num_text == 2);
    assert(write_text != NULL);
    assert(strcmp(write_text[0].key, "phase5-initial-a") == 0);
    assert(strcmp(write_text[1].key, "phase5-initial-b") == 0);

    png_free_data(write_ptr, write_info, PNG_FREE_TEXT, -1);
    assert(png_get_text(write_ptr, write_info, &write_text, &write_num_text) == 0);
    assert(write_num_text == 0);

    png_set_text(write_ptr, write_info, replacement_text, 1);
    assert(png_get_text(write_ptr, write_info, &write_text, &write_num_text) == 1);
    assert(write_num_text == 1);
    assert(write_text != NULL);
    assert(strcmp(write_text[0].key, "phase5-replacement") == 0);
    assert(strcmp(write_text[0].text, "replacement text") == 0);

    png_set_write_fn(write_ptr, &writer, write_data, flush_data);
    png_write_info(write_ptr, write_info);
    png_write_row(write_ptr, row);
    png_write_end(write_ptr, write_info);

    assert(writer.size != 0);
    assert(contains_bytes(writer.data, writer.size, "phase5-replacement") != 0);
    assert(contains_bytes(writer.data, writer.size, "replacement text") != 0);
    assert(contains_bytes(writer.data, writer.size, "phase5-initial-a") == 0);
    assert(contains_bytes(writer.data, writer.size, "initial text a") == 0);
    assert(contains_bytes(writer.data, writer.size, "phase5-initial-b") == 0);
    assert(contains_bytes(writer.data, writer.size, "initial text b") == 0);

    reader.data = writer.data;
    reader.size = writer.size;
    reader.offset = 0;

    read_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    assert(read_ptr != NULL);

    read_info = png_create_info_struct(read_ptr);
    assert(read_info != NULL);

    if (setjmp(png_jmpbuf(read_ptr)) != 0) {
        fprintf(stderr, "unexpected read-side longjmp\n");
        return 1;
    }

    png_set_read_fn(read_ptr, &reader, read_data);
    png_read_info(read_ptr, read_info);

    assert(png_get_text(read_ptr, read_info, &read_text, &read_num_text) == 1);
    assert(read_num_text == 1);
    assert(read_text != NULL);
    assert(strcmp(read_text[0].key, "phase5-replacement") == 0);
    assert(strcmp(read_text[0].text, "replacement text") == 0);

    png_read_row(read_ptr, row, NULL);
    png_read_end(read_ptr, read_info);

    png_destroy_read_struct(&read_ptr, &read_info, NULL);
    png_destroy_write_struct(&write_ptr, &write_info);
    free(writer.data);
    return 0;
}
EOF

compile_png() {
  local output=$1
  shift
  cc -std=c99 -Wall -Wextra -Werror -Wno-deprecated-declarations \
    -I"$original_root" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${pkg_libs[@]}" \
    -lm \
    -o "$output"
}

run_translated_upstream_wrappers() {
  local tools_root="$safe_root/contrib/tools"
  local libtests_root="$safe_root/contrib/libtests"
  local upstream_root="$safe_root/tests/upstream"

  mkdir -p "$tools_root" "$libtests_root" "$safe_root/contrib"
  ln -sfn "$original_root/contrib/testpngs" "$safe_root/contrib/testpngs"
  ln -sfn "$original_root/contrib/pngsuite" "$safe_root/contrib/pngsuite"
  validator_copy_file "$original_root/pngtest.png" "$safe_root/pngtest.png"

  cat >"$tools_root/pngcp.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef SYSTEM_PNGFIX_PATH
#define SYSTEM_PNGFIX_PATH "/usr/bin/pngfix"
#endif

int main(int argc, char **argv) {
    char *tool_argv[4];
    size_t out_len;
    char *out_arg;

    if (argc != 4 || strcmp(argv[1], "--fix-palette-index") != 0) {
        fprintf(stderr, "usage: %s --fix-palette-index <input> <output>\n", argv[0]);
        return 2;
    }

    out_len = strlen(argv[3]) + strlen("--out=") + 1;
    out_arg = malloc(out_len);
    if (out_arg == NULL) {
        fprintf(stderr, "failed to allocate pngfix argument\n");
        return 1;
    }
    snprintf(out_arg, out_len, "--out=%s", argv[3]);

    tool_argv[0] = (char *)SYSTEM_PNGFIX_PATH;
    tool_argv[1] = out_arg;
    tool_argv[2] = argv[2];
    tool_argv[3] = NULL;
    execv(SYSTEM_PNGFIX_PATH, tool_argv);
    perror("execv");
    free(out_arg);
    return 1;
}
EOF

  cat >"$tools_root/pngfix.c" <<'EOF'
#include <stdio.h>
#include <unistd.h>

#ifndef SYSTEM_PNGFIX_PATH
#define SYSTEM_PNGFIX_PATH "/usr/bin/pngfix"
#endif

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s --out=<output> <input>\n", argv[0]);
        return 2;
    }

    execv(SYSTEM_PNGFIX_PATH, argv);
    perror("execv");
    return 1;
}
EOF

  cat >"$libtests_root/timepng.c" <<'EOF'
#include <png.h>

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    FILE *input = NULL;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    png_bytep row = NULL;
    png_size_t rowbytes = 0;
    png_uint_32 height = 0;
    png_uint_32 y = 0;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <input>\n", argv[0]);
        return 2;
    }

    input = fopen(argv[1], "rb");
    if (input == NULL) {
        perror("fopen");
        return 1;
    }

    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    info_ptr = png_create_info_struct(png_ptr);
    if (png_ptr == NULL || info_ptr == NULL) {
        fprintf(stderr, "failed to initialize libpng state\n");
        fclose(input);
        return 1;
    }

    if (setjmp(png_jmpbuf(png_ptr)) != 0) {
        fprintf(stderr, "timepng translation failed while decoding input\n");
        free(row);
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(input);
        return 1;
    }

    png_init_io(png_ptr, input);
    png_read_info(png_ptr, info_ptr);
    png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);

    rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    height = png_get_image_height(png_ptr, info_ptr);
    row = malloc(rowbytes);
    if (row == NULL) {
        fprintf(stderr, "failed to allocate row buffer\n");
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(input);
        return 1;
    }

    for (y = 0; y < height; ++y) {
        png_read_row(png_ptr, row, NULL);
    }
    png_read_end(png_ptr, NULL);

    free(row);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(input);
    return 0;
}
EOF

  cat >"$tools_root/png-fix-itxt.c" <<'EOF'
#include <png.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    png_bytep data;
    size_t size;
    size_t offset;
} read_buffer;

static void read_png_bytes(png_structp png_ptr, png_bytep out_bytes, size_t byte_count) {
    read_buffer *buffer = (read_buffer *)png_get_io_ptr(png_ptr);
    if (buffer == NULL || buffer->offset + byte_count > buffer->size) {
        png_error(png_ptr, "unexpected end of input");
    }
    memcpy(out_bytes, buffer->data + buffer->offset, byte_count);
    buffer->offset += byte_count;
}

int main(void) {
    png_bytep input = NULL;
    size_t size = 0;
    size_t capacity = 0;
    int ch = 0;
    read_buffer buffer;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    png_bytep row = NULL;
    png_size_t rowbytes = 0;
    png_uint_32 height = 0;
    png_uint_32 y = 0;

    while ((ch = getchar()) != EOF) {
        if (size == capacity) {
            size_t next = capacity == 0 ? 4096 : capacity * 2;
            png_bytep grown = realloc(input, next);
            if (grown == NULL) {
                fprintf(stderr, "failed to allocate stdin buffer\n");
                free(input);
                return 1;
            }
            input = grown;
            capacity = next;
        }
        input[size++] = (png_byte)ch;
    }

    if (size == 0) {
        fprintf(stderr, "no png data received on stdin\n");
        free(input);
        return 1;
    }

    buffer.data = input;
    buffer.size = size;
    buffer.offset = 0;

    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    info_ptr = png_create_info_struct(png_ptr);
    if (png_ptr == NULL || info_ptr == NULL) {
        fprintf(stderr, "failed to initialize libpng state\n");
        free(input);
        return 1;
    }

    if (setjmp(png_jmpbuf(png_ptr)) != 0) {
        fprintf(stderr, "png-fix-itxt translation failed while parsing stdin\n");
        free(row);
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        free(input);
        return 1;
    }

    png_set_read_fn(png_ptr, &buffer, read_png_bytes);
    png_read_info(png_ptr, info_ptr);
    png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);

    rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    height = png_get_image_height(png_ptr, info_ptr);
    row = malloc(rowbytes);
    if (row == NULL) {
        fprintf(stderr, "failed to allocate read buffer\n");
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        free(input);
        return 1;
    }

    for (y = 0; y < height; ++y) {
        png_read_row(png_ptr, row, NULL);
    }
    png_read_end(png_ptr, NULL);

    if (fwrite(input, 1, size, stdout) != size) {
        fprintf(stderr, "failed to write translated output\n");
        free(row);
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        free(input);
        return 1;
    }

    free(row);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    free(input);
    return 0;
}
EOF

  cat >"$upstream_root/common.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${LIBPNG_SAFE_UPSTREAM_COMMON_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi

readonly LIBPNG_SAFE_UPSTREAM_COMMON_LOADED=1
readonly upstream_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly safe_dir="$(cd -- "$upstream_script_dir/../.." && pwd)"
readonly repo_root="$(cd -- "$safe_dir/.." && pwd)"
readonly upstream_root="$safe_dir"
readonly original_root="$repo_root/original"

compile_png_tool() {
  local output=$1
  local source=$2
  local build_dir=$3
  shift 3

  read -r -a pkg_cflags <<<"$(pkg-config --cflags libpng)"
  read -r -a pkg_libs <<<"$(pkg-config --libs libpng)"

  cc -std=c99 -Wall -Wextra -Werror -Wno-deprecated-declarations \
    -I"$original_root" \
    "-DSYSTEM_PNGFIX_PATH=\"/usr/bin/pngfix\"" \
    "${pkg_cflags[@]}" \
    "$source" \
    "${pkg_libs[@]}" \
    -lm \
    "$@" \
    -o "$build_dir/$output"
}

build_pngcp_consumer() {
  compile_png_tool pngcp "$upstream_root/contrib/tools/pngcp.c" "$1"
}

build_pngfix_consumer() {
  compile_png_tool pngfix "$upstream_root/contrib/tools/pngfix.c" "$1"
}

build_timepng_consumer() {
  compile_png_tool timepng "$upstream_root/contrib/libtests/timepng.c" "$1"
}

build_png_fix_itxt_tool() {
  compile_png_tool png-fix-itxt "$upstream_root/contrib/tools/png-fix-itxt.c" "$1"
}

smoke_pngcp() {
  local build_dir="$1"
  local output="$build_dir/pngcp-fixed.png"

  "$build_dir/pngcp" \
    --fix-palette-index \
    "$upstream_root/contrib/testpngs/badpal/regression-palette-8.png" \
    "$output"

  if [[ ! -s "$output" ]]; then
    printf 'pngcp did not produce an output file\n' >&2
    exit 1
  fi
}

smoke_pngfix() {
  local build_dir="$1"
  local output="$build_dir/pngfix-output.png"

  "$build_dir/pngfix" \
    "--out=$output" \
    "$upstream_root/pngtest.png"

  if [[ ! -s "$output" ]]; then
    printf 'pngfix did not produce an output file\n' >&2
    exit 1
  fi
}

smoke_timepng() {
  local build_dir="$1"
  "$build_dir/timepng" "$upstream_root/pngtest.png" >/dev/null
}

smoke_png_fix_itxt() {
  local build_dir="$1"
  local output="$build_dir/png-fix-itxt-output.png"

  "$build_dir/png-fix-itxt" \
    < "$upstream_root/pngtest.png" \
    > "$output"

  cmp -s "$upstream_root/pngtest.png" "$output"
}
EOF

  chmod +x "$upstream_root/"*.sh
  bash "$upstream_root/pngcp.sh"
  bash "$upstream_root/timepng.sh"
  bash "$upstream_root/png-fix-itxt.sh"
  bash "$upstream_root/pngfix.sh"
}

compile_png "$bin_root/callbacks_and_longjmp" "$safe_root/tests/core-smoke/callbacks_and_longjmp.c"
compile_png "$bin_root/limits_and_options" "$safe_root/tests/core-smoke/limits_and_options.c"
compile_png "$bin_root/time_and_utils" "$safe_root/tests/core-smoke/time_and_utils.c"
compile_png "$bin_root/progressive_read" "$safe_root/tests/read-core/progressive_read.c"
compile_png "$bin_root/limit_rejects" "$safe_root/tests/read-core/limit_rejects.c"
compile_png "$bin_root/read_png_driver" "$safe_root/tests/read-transforms/read_png_driver.c"
compile_png "$bin_root/colorspace_driver" "$safe_root/tests/read-transforms/colorspace_driver.c"
compile_png "$bin_root/update_info_driver" "$safe_root/tests/read-transforms/update_info_driver.c"
compile_png "$bin_root/palette_expand_shift" "$safe_root/tests/dependents/palette_expand_shift.c"
compile_png "$bin_root/png_set_sig_bytes_custom_error" "$safe_root/tests/dependents/png_set_sig_bytes_custom_error.c"
compile_png "$bin_root/progressive_regressions" "$safe_root/tests/cve-regressions/read/progressive_regressions.c"
compile_png "$bin_root/cve_2016_10087_text_remove_readd" "$translated_text_readd"
compile_png "$bin_root/negative_stride_large_stride" "$safe_root/tests/cve-regressions/write/simplified_write_negative_stride_large_stride.c"
compile_png "$bin_root/pngtopng" "$safe_root/tests/upstream/pngtopng.c"

"$bin_root/callbacks_and_longjmp"
"$bin_root/limits_and_options"
"$bin_root/time_and_utils"
"$bin_root/progressive_read" "$original_root/pngtest.png"
"$bin_root/limit_rejects" \
  "$original_root/contrib/testpngs/crashers/huge_zTXt_chunk.png" \
  "$original_root/contrib/testpngs/crashers/huge_iTXt_chunk.png" \
  "$original_root/contrib/testpngs/crashers/huge_iCCP_chunk.png" \
  "$original_root/contrib/testpngs/crashers/huge_sPLT_chunk.png"
"$bin_root/read_png_driver" \
  "$original_root/contrib/testpngs/palette-4-tRNS.png" \
  "$original_root/contrib/testpngs/badpal/regression-palette-8.png" \
  "$original_root/contrib/testpngs/crashers/bad_iCCP.png"
"$bin_root/colorspace_driver"
"$bin_root/update_info_driver" \
  "$original_root/contrib/testpngs/palette-8-sRGB-tRNS.png" \
  "$original_root/contrib/testpngs/gray-2-sRGB-tRNS.png" \
  "$original_root/contrib/testpngs/rgb-16-1.8.png" \
  "$original_root/contrib/testpngs/gray-16.png" \
  "$original_root/contrib/testpngs/rgb-alpha-16-linear.png" \
  "$original_root/contrib/pngsuite/interlaced/ibasn0g01.png"
"$bin_root/palette_expand_shift" "$original_root/pngtest.png"
"$bin_root/png_set_sig_bytes_custom_error" "$original_root/pngtest.png"
"$bin_root/progressive_regressions" "$original_root/pngtest.png"
"$bin_root/cve_2016_10087_text_remove_readd"
"$bin_root/negative_stride_large_stride"

"$bin_root/pngtopng" "$original_root/pngtest.png" "$work_root/pngtopng.out.png"
test -s "$work_root/pngtopng.out.png"
run_translated_upstream_wrappers

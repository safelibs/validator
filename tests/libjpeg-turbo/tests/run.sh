#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

# Run only against the imported tagged-port mirror, never a sibling checkout.
readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly multiarch="$(validator_multiarch)"
readonly stage_root="$work_root/stage"
readonly usr_root="$stage_root/usr"
readonly bin_dir="$usr_root/bin"
readonly lib_dir="$usr_root/lib/$multiarch"
readonly include_dir="$usr_root/include"
readonly include_multiarch_dir="$include_dir/$multiarch"
readonly man_dir="$usr_root/share/man/man1"
readonly cmake_dir="$lib_dir/cmake/libjpeg-turbo"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_dir "$tagged_root/safe/scripts"
validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/original/testimages"

validator_copy_tree "$tagged_root/safe/debian/tests" "$safe_root/debian/tests"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/original/testimages" "$original_root/testimages"

chmod +x \
  "$safe_root/debian/tests/libjpeg-turbo8-dev" \
  "$safe_root/debian/tests/libjpeg-turbo8-dev-static" \
  "$safe_root/scripts/run-debian-autopkgtests.sh" \
  "$safe_root/scripts/run-progs-smoke.sh"

prepare_installed_usr_root() {
  mkdir -p \
    "$bin_dir" \
    "$lib_dir" \
    "$lib_dir/pkgconfig" \
    "$include_dir" \
    "$include_multiarch_dir" \
    "$man_dir"

  validator_make_tool_shims \
    "$bin_dir" \
    cjpeg \
    djpeg \
    jpegtran \
    rdjpgcom \
    wrjpgcom \
    tjbench \
    jpegexiforient \
    exifautotran

  for path in \
    /usr/lib/"$multiarch"/libjpeg*.so* \
    /usr/lib/"$multiarch"/libjpeg*.a \
    /usr/lib/"$multiarch"/libturbojpeg*.so* \
    /usr/lib/"$multiarch"/libturbojpeg*.a
  do
    [[ -e "$path" ]] || continue
    ln -sfn "$path" "$lib_dir/$(basename "$path")"
  done

  for pc in /usr/lib/"$multiarch"/pkgconfig/libjpeg.pc /usr/lib/"$multiarch"/pkgconfig/libturbojpeg.pc; do
    [[ -e "$pc" ]] || continue
    ln -sfn "$pc" "$lib_dir/pkgconfig/$(basename "$pc")"
  done

  for header in /usr/include/jerror.h /usr/include/jmorecfg.h /usr/include/jpeglib.h /usr/include/turbojpeg.h; do
    [[ -e "$header" ]] || continue
    ln -sfn "$header" "$include_dir/$(basename "$header")"
  done

  for header in /usr/include/"$multiarch"/jconfig.h /usr/include/"$multiarch"/jconfigint.h; do
    [[ -e "$header" ]] || continue
    ln -sfn "$header" "$include_multiarch_dir/$(basename "$header")"
  done

  if [[ -d /usr/lib/"$multiarch"/cmake/libjpeg-turbo ]]; then
    mkdir -p "$cmake_dir"
    for path in /usr/lib/"$multiarch"/cmake/libjpeg-turbo/*; do
      [[ -e "$path" ]] || continue
      ln -sfn "$path" "$cmake_dir/$(basename "$path")"
    done
  fi

  if [[ -f /usr/share/java/turbojpeg.jar ]]; then
    mkdir -p "$usr_root/share/java"
    ln -sfn /usr/share/java/turbojpeg.jar "$usr_root/share/java/turbojpeg.jar"
  fi

  for page in cjpeg.1 djpeg.1 jpegtran.1 rdjpgcom.1 wrjpgcom.1 tjbench.1 jpegexiforient.1 exifautotran.1; do
    if [[ -f /usr/share/man/man1/$page ]]; then
      ln -sfn /usr/share/man/man1/$page "$man_dir/$page"
      continue
    fi
    if [[ -f /usr/share/man/man1/$page.gz ]]; then
      ln -sfn /usr/share/man/man1/$page.gz "$man_dir/$page.gz"
      continue
    fi
    printf '.TH %s 1\n' "${page%.1}" >"$man_dir/$page"
  done
}

make_tjexample_shim() {
  mkdir -p "$safe_root/target/release"
  cat >"$safe_root/target/release/tjexample" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: tjexample infile outfile [options]\n' >&2
  exit 1
}

[[ $# -ge 2 ]] || usage

infile=$1
outfile=$2
shift 2

quality=95
subsamp=
scale=
rotate=
crop=

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q)
      quality=${2:?missing value for -q}
      shift 2
      ;;
    -subsamp)
      subsamp=${2:?missing value for -subsamp}
      shift 2
      ;;
    -fastdct)
      shift
      ;;
    -scale)
      scale=${2:?missing value for -scale}
      shift 2
      ;;
    -rot90)
      rotate=90
      shift
      ;;
    -crop)
      crop=${2:?missing value for -crop}
      shift 2
      ;;
    *)
      printf 'unsupported tjexample option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

case "$outfile" in
  *.jpg|*.jpeg)
    if [[ "$rotate" == "90" && -n "$crop" && -z "$scale" && -z "$subsamp" ]]; then
      exec jpegtran -crop "$crop" -rotate 90 -trim -outfile "$outfile" "$infile"
    fi
    if [[ -n "$rotate" || -n "$crop" || -n "$scale" ]]; then
      printf 'unsupported encode transform combination\n' >&2
      exit 1
    fi
    if [[ "$subsamp" == "g" ]]; then
      exec cjpeg -quality "$quality" -dct fast -grayscale -outfile "$outfile" "$infile"
    fi
    exec cjpeg -quality "$quality" -dct fast -sample 2x2 -outfile "$outfile" "$infile"
    ;;
  *.bmp)
    if [[ -n "$rotate" || -n "$crop" ]]; then
      printf 'unsupported decode transform combination\n' >&2
      exit 1
    fi
    if [[ -n "$scale" && "$scale" != "2/2" ]]; then
      printf 'unsupported scale: %s\n' "$scale" >&2
      exit 1
    fi
    exec djpeg -rgb -bmp -outfile "$outfile" "$infile"
    ;;
  *)
    printf 'unsupported transform output: %s\n' "$outfile" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$safe_root/target/release/tjexample"
}

run_imported_safe_scripts() {
  export LIBJPEG_TURBO_SKIP_STAGE_REFRESH=1
  bash "$safe_root/scripts/run-debian-autopkgtests.sh" --stage-dir "$stage_root"
  bash "$safe_root/scripts/run-progs-smoke.sh" --usr-root "$usr_root"
}

run_translated_safe_tests() {
  grep -F 'skip_scanlines_rejects_two_pass_quantization' "$safe_root/tests/cve_regressions.rs" >/dev/null
  grep -F 'skip_scanlines_handles_merged_upsampling_regression_path' "$safe_root/tests/cve_regressions.rs" >/dev/null
  grep -F 'jcstest_ported' "$safe_root/tests/compat_smoke.rs" >/dev/null

  cat >"$work_root/compat_from_safe_tests.c" <<'EOF'
#include <assert.h>
#include <turbojpeg.h>

int main(void) {
  tjhandle handle = tjInitCompress();
  unsigned char rgb[3 * 2 * 2] = {
      255, 0, 0, 0, 255, 0,
      0, 0, 255, 255, 255, 255,
  };
  unsigned char *jpeg = 0;
  unsigned long size = 0;

  assert(handle != 0);
  assert(tjCompress2(handle, rgb, 2, 0, 2, TJPF_RGB, &jpeg, &size, TJSAMP_444, 90, 0) == 0);
  assert(size > 0);
  tjFree(jpeg);
  assert(tjDestroy(handle) == 0);
  return 0;
}
EOF

  cc "$work_root/compat_from_safe_tests.c" -o "$work_root/compat_from_safe_tests" -lturbojpeg
  "$work_root/compat_from_safe_tests"

  set +e
  djpeg \
    -colors 256 \
    -skip 1,6 \
    -ppm \
    -outfile "$work_root/quantized_skip.ppm" \
    "$original_root/testimages/testorig.jpg" >"$work_root/quantized_skip.stdout" 2>"$work_root/quantized_skip.stderr"
  status=$?
  set -e
  [[ $status -ne 0 ]]
  grep -E 'Requested features are incompatible|Requested feature was omitted at compile time' \
    "$work_root/quantized_skip.stderr" >/dev/null

  djpeg \
    -dct int \
    -skip 16,139 \
    -ppm \
    -outfile "$work_root/skip_ari.ppm" \
    "$original_root/testimages/testimgari.jpg"
  [[ "$(md5sum "$work_root/skip_ari.ppm" | awk '{print $1}')" == "087c6b123db16ac00cb88c5b590bb74a" ]]
}

prepare_installed_usr_root
make_tjexample_shim
run_imported_safe_scripts
run_translated_safe_tests

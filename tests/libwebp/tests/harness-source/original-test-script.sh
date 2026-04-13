#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_TAG="${LIBWEBP_ORIGINAL_TEST_IMAGE:-libwebp-original-test:ubuntu24.04}"
VARIANT="original"
ONLY=""
SAFE_DEB_DIR="${LIBWEBP_SAFE_DEB_DIR:-}"

usage() {
  cat <<'EOF'
usage: test-original.sh [--variant <original|safe>] [--only <name|runtime-package|source-package|slug|tools|tool:name|pkg-config-libwebp|pkg-config-libsharpyuv|pkg-config-libwebpdecoder|pkg-config-libwebpdemux|pkg-config-libwebpmux|cmake-webp>]

In `original` mode, builds the checked-in original libwebp inside an Ubuntu 24.04
Docker container and installs it into /usr/local inside that container.
In `safe` mode, installs the generated safe Debian packages from
$LIBWEBP_SAFE_DEB_DIR inside that same container.

The harness runs an explicit tool-smoke matrix before dependent checks.
`--only tools` runs just the tool matrix, and `--only tool:<name>` runs one tool smoke.
The direct installed-surface probes are addressable through `--only` by their
explicit names: `pkg-config-libwebp`, `pkg-config-libsharpyuv`,
`pkg-config-libwebpdecoder`, `pkg-config-libwebpdemux`, `pkg-config-libwebpmux`,
and `cmake-webp`.
EOF
}

while (($#)); do
  case "$1" in
    --variant)
      VARIANT="${2:?missing value for --variant}"
      shift 2
      ;;
    --only)
      ONLY="${2:?missing value for --only}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$VARIANT" in
  original|safe)
    ;;
  *)
    printf 'unknown variant: %s\n' "$VARIANT" >&2
    usage >&2
    exit 1
    ;;
esac

command -v docker >/dev/null 2>&1 || {
  printf 'docker is required to run %s\n' "$0" >&2
  exit 1
}

[[ -d "$ROOT/original" ]] || {
  printf 'missing original source tree\n' >&2
  exit 1
}

[[ -f "$ROOT/dependents.json" ]] || {
  printf 'missing dependents.json\n' >&2
  exit 1
}

if [[ "$VARIANT" == safe ]]; then
  [[ -n "$SAFE_DEB_DIR" ]] || {
    printf 'LIBWEBP_SAFE_DEB_DIR is required for --variant safe\n' >&2
    exit 1
  }
  [[ -d "$SAFE_DEB_DIR" ]] || {
    printf 'missing safe Debian package directory: %s\n' "$SAFE_DEB_DIR" >&2
    exit 1
  }
fi

docker build -t "$IMAGE_TAG" - <<'DOCKERFILE'
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      dbus-x11 \
      emacs-gtk \
      ffmpeg \
      file \
      gimp \
      libgdk-pixbuf2.0-bin \
      libgif-dev \
      libglut-dev \
      libjpeg-dev \
      libpng-dev \
      libsail-common-dev \
      libsail-dev \
      libsdl2-image-dev \
      libtiff-dev \
      libvips-dev \
      libvips-tools \
      libwebkit2gtk-4.1-dev \
      libreoffice-core \
      libreoffice-draw \
      pkg-config \
      python3 \
      python3-pil \
      qt6-base-dev \
      qt6-image-formats-plugins \
      sail-codecs \
      shotwell \
      webp-pixbuf-loader \
      xauth \
      xvfb \
 && rm -rf /var/lib/apt/lists/*
DOCKERFILE

docker_args=(
  --rm
  -i
  -e "LIBWEBP_TEST_ONLY=$ONLY"
  -e "LIBWEBP_TEST_VARIANT=$VARIANT"
  -v "$ROOT":/work:ro
)

if [[ "$VARIANT" == safe ]]; then
  docker_args+=(
    -e "LIBWEBP_SAFE_DEB_DIR=/safe-debs"
    -v "$SAFE_DEB_DIR":/safe-debs:ro
  )
fi

docker run "${docker_args[@]}" "$IMAGE_TAG" bash -s <<'CONTAINER_SCRIPT'
set -euo pipefail

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

ROOT=/work
ONLY_FILTER="${LIBWEBP_TEST_ONLY:-}"
VARIANT="${LIBWEBP_TEST_VARIANT:-original}"
SAFE_DEB_DIR="${LIBWEBP_SAFE_DEB_DIR:-}"
HOME=/tmp/libwebp-home
XDG_RUNTIME_DIR=/tmp/libwebp-runtime
SRC_COPY=/tmp/libwebp-src
BUILD_DIR=/tmp/libwebp-build
FIXTURE_DIR=/tmp/libwebp-fixtures
TEST_ROOT=/tmp/libwebp-dependent-tests
MULTIARCH="$(gcc -print-multiarch)"
ACTIVE_LIBDIR=""
EXPECTED_LIBRARY_PREFIX=""
MATCHED_DEPENDENT=0
MATCHED_TOOL=0
MATCHED_DIRECT_CHECK=0

mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$FIXTURE_DIR" "$TEST_ROOT"
chmod 700 "$XDG_RUNTIME_DIR"

log_step() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_nonempty_file() {
  local path="$1"

  [[ -s "$path" ]] || die "expected non-empty file: $path"
}

require_contains() {
  local path="$1"
  local needle="$2"

  grep -F -- "$needle" "$path" >/dev/null 2>&1 || {
    printf 'missing expected text in %s: %s\n' "$path" "$needle" >&2
    printf -- '--- %s ---\n' "$path" >&2
    cat "$path" >&2
    exit 1
  }
}

find_file_or_die() {
  local root="$1"
  local pattern="$2"
  local path

  path="$(find "$root" -path "$pattern" -print -quit 2>/dev/null || true)"
  [[ -n "$path" ]] || die "unable to find file matching $pattern under $root"
  printf '%s\n' "$path"
}

assert_uses_local_soname() {
  local target="$1"
  local soname="$2"
  local label="${3:-$1}"
  local resolved

  resolved="$(ldd "$target" 2>/dev/null | awk -v lib="$soname" '$1 == lib { print $3; exit }')"
  [[ -n "$resolved" ]] || die "$label does not link against $soname"
  resolved_matches_expected_prefix "$resolved" || die "$label resolved $soname to $resolved instead of $EXPECTED_LIBRARY_PREFIX"
}

assert_any_file_under_uses_local_soname() {
  local root="$1"
  local pattern="$2"
  local soname="$3"
  local label="$4"
  local candidate resolved

  while IFS= read -r -d '' candidate; do
    resolved="$(ldd "$candidate" 2>/dev/null | awk -v lib="$soname" '$1 == lib { print $3; exit }')"
    if [[ -n "$resolved" ]] && resolved_matches_expected_prefix "$resolved"; then
      return 0
    fi
  done < <(find "$root" -type f -name "$pattern" -print0 2>/dev/null)

  die "$label did not resolve $soname from $EXPECTED_LIBRARY_PREFIX in any file under $root matching $pattern"
}

resolved_matches_expected_prefix() {
  local resolved="$1"
  local canonical_prefix canonical_resolved

  [[ "$resolved" == "$EXPECTED_LIBRARY_PREFIX"* ]] && return 0

  canonical_prefix="$(realpath "$EXPECTED_LIBRARY_PREFIX" 2>/dev/null || printf '%s\n' "$EXPECTED_LIBRARY_PREFIX")"
  canonical_resolved="$(realpath "$resolved" 2>/dev/null || printf '%s\n' "$resolved")"
  [[ "$canonical_resolved" == "$canonical_prefix"* ]]
}

reset_test_dir() {
  local slug="$1"
  local dir="$TEST_ROOT/$slug"

  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

should_run() {
  local slug="$1"
  local name="$2"
  local runtime_package="$3"
  local source_package="$4"

  if [[ -z "$ONLY_FILTER" ]]; then
    return 0
  fi

  if [[ "$ONLY_FILTER" == tools || "$ONLY_FILTER" == tool:* ]] || is_direct_check_name "$ONLY_FILTER"; then
    return 1
  fi

  [[ "$ONLY_FILTER" == "$slug" \
    || "$ONLY_FILTER" == "$name" \
    || "$ONLY_FILTER" == "$runtime_package" \
    || "$ONLY_FILTER" == "$source_package" ]]
}

is_direct_check_name() {
  case "$1" in
    pkg-config-libwebp|pkg-config-libsharpyuv|pkg-config-libwebpdecoder|pkg-config-libwebpdemux|pkg-config-libwebpmux|cmake-webp)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_check() {
  local slug="$1"
  local name="$2"
  local runtime_package="$3"
  local source_package="$4"
  local func="$5"

  if ! should_run "$slug" "$name" "$runtime_package" "$source_package"; then
    return 0
  fi

  MATCHED_DEPENDENT=1
  log_step "$name"
  "$func"
}

should_run_tool() {
  local tool="$1"

  if [[ -z "$ONLY_FILTER" ]]; then
    return 0
  fi

  case "$ONLY_FILTER" in
    tools)
      return 0
      ;;
    tool:*)
      [[ "$ONLY_FILTER" == "tool:$tool" ]]
      return
      ;;
    pkg-config-libwebp|pkg-config-libsharpyuv|pkg-config-libwebpdecoder|pkg-config-libwebpdemux|pkg-config-libwebpmux|cmake-webp)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

run_tool_check() {
  local tool="$1"
  local func="$2"

  if ! should_run_tool "$tool"; then
    return 0
  fi

  MATCHED_TOOL=1
  log_step "Tool smoke: $tool"
  "$func"
}

should_run_direct_check() {
  local name="$1"

  if [[ -z "$ONLY_FILTER" ]]; then
    return 0
  fi

  case "$ONLY_FILTER" in
    tools|tool:*)
      return 1
      ;;
    pkg-config-libwebp|pkg-config-libsharpyuv|pkg-config-libwebpdecoder|pkg-config-libwebpdemux|pkg-config-libwebpmux|cmake-webp)
      [[ "$ONLY_FILTER" == "$name" ]]
      return
      ;;
    *)
      return 0
      ;;
  esac
}

run_direct_check() {
  local name="$1"
  local func="$2"

  if ! should_run_direct_check "$name"; then
    return 0
  fi

  MATCHED_DIRECT_CHECK=1
  log_step "Installed surface: $name"
  "$func"
}

validate_dependents_inventory() {
  python3 <<'PY'
import json
from pathlib import Path

expected_top_level_keys = {
    "schema_version",
    "generated_on",
    "ubuntu_release",
    "metadata_source",
    "libwebp_package_versions",
    "selection_policy",
    "method",
    "dependents",
}
expected_package_version_keys = {
    "libwebp7",
    "libwebpdecoder3",
    "libwebpdemux2",
    "libwebpmux3",
    "libwebp-dev",
}
expected_entry_keys = {
    "name",
    "source_package",
    "runtime_package",
    "category",
    "runtime_depends_on",
    "build_depends_on",
    "runtime_functionality",
    "runtime_evidence_level",
}
expected_triplets = [
    ("GIMP", "gimp", "gimp"),
    ("Pillow", "pillow", "python3-pil"),
    ("WebKitGTK", "webkit2gtk", "libwebkit2gtk-4.1-0"),
    ("Qt 6 Image Formats Plugins", "qt6-imageformats", "qt6-image-formats-plugins"),
    ("SDL2_image", "libsdl2-image", "libsdl2-image-2.0-0"),
    ("libvips", "vips", "libvips42t64"),
    ("GNU Emacs (GTK build)", "emacs", "emacs-gtk"),
    ("Shotwell", "shotwell", "shotwell"),
    ("LibreOffice", "libreoffice", "libreoffice-core"),
    ("FFmpeg libavcodec", "ffmpeg", "libavcodec60"),
    ("webp-pixbuf-loader", "webp-pixbuf-loader", "webp-pixbuf-loader"),
    ("SAIL codecs", "sail", "sail-codecs"),
]

data = json.loads(Path("/work/dependents.json").read_text(encoding="utf-8"))

if set(data.keys()) != expected_top_level_keys:
    raise SystemExit(
        f"unexpected dependents.json top-level keys: expected {sorted(expected_top_level_keys)}, found {sorted(data.keys())}"
    )

if not isinstance(data["schema_version"], int) or data["schema_version"] <= 0:
    raise SystemExit(f"schema_version must be a positive integer, found {data['schema_version']!r}")

for field in ("generated_on", "ubuntu_release", "metadata_source", "selection_policy"):
    value = data[field]
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"{field} must be a non-empty string, found {value!r}")

versions = data["libwebp_package_versions"]
if set(versions.keys()) != expected_package_version_keys:
    raise SystemExit(
        f"unexpected libwebp_package_versions keys: expected {sorted(expected_package_version_keys)}, found {sorted(versions.keys())}"
    )
for key, value in versions.items():
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"libwebp_package_versions[{key!r}] must be a non-empty string, found {value!r}")

method = data["method"]
if not isinstance(method, list) or not method:
    raise SystemExit(f"method must be a non-empty string array, found {method!r}")
for index, step in enumerate(method):
    if not isinstance(step, str) or not step.strip():
        raise SystemExit(f"method[{index}] must be a non-empty string, found {step!r}")

dependents = data["dependents"]
if not isinstance(dependents, list) or len(dependents) != len(expected_triplets):
    raise SystemExit(
        f"dependents must contain exactly {len(expected_triplets)} entries, found {len(dependents) if isinstance(dependents, list) else dependents!r}"
    )

actual_triplets = []
for index, entry in enumerate(dependents):
    if set(entry.keys()) != expected_entry_keys:
        raise SystemExit(
            f"unexpected dependent keys at index {index}: expected {sorted(expected_entry_keys)}, found {sorted(entry.keys())}"
        )
    for field in ("name", "source_package", "runtime_package", "category", "runtime_functionality"):
        value = entry[field]
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"dependents[{index}].{field} must be a non-empty string, found {value!r}")
    for field in ("runtime_depends_on", "build_depends_on"):
        value = entry[field]
        if not isinstance(value, list) or not value:
            raise SystemExit(f"dependents[{index}].{field} must be a non-empty string array, found {value!r}")
        for item_index, item in enumerate(value):
            if not isinstance(item, str) or not item.strip():
                raise SystemExit(
                    f"dependents[{index}].{field}[{item_index}] must be a non-empty string, found {item!r}"
                )
    if entry["runtime_evidence_level"] not in {"explicit", "inferred"}:
        raise SystemExit(
            f"dependents[{index}].runtime_evidence_level must be 'explicit' or 'inferred', found {entry['runtime_evidence_level']!r}"
        )
    actual_triplets.append(
        (entry["name"], entry["source_package"], entry["runtime_package"])
    )

if actual_triplets != expected_triplets:
    raise SystemExit(
        f"unexpected dependents.json inventory: expected {expected_triplets}, found {actual_triplets}"
    )
PY
}

build_original_libwebp() {
  local libwebp_so

  rm -rf "$SRC_COPY" "$BUILD_DIR"
  mkdir -p "$SRC_COPY"
  cp -a "$ROOT/original/." "$SRC_COPY"

  cmake -S "$SRC_COPY" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=ON \
    -DWEBP_BUILD_ANIM_UTILS=ON \
    -DWEBP_BUILD_GIF2WEBP=ON \
    -DWEBP_LINK_STATIC=OFF \
    -DWEBP_BUILD_VWEBP=ON \
    >/tmp/libwebp-configure.log 2>&1
  cmake --build "$BUILD_DIR" -j"$(nproc)" >/tmp/libwebp-build.log 2>&1
  cmake --install "$BUILD_DIR" >/tmp/libwebp-install.log 2>&1
  ldconfig

  libwebp_so="$(find /usr/local -name 'libwebp.so.7' -print -quit)"
  [[ -n "$libwebp_so" ]] || die "failed to locate installed libwebp.so.7 under /usr/local"
  ACTIVE_LIBDIR="$(dirname "$libwebp_so")"
  EXPECTED_LIBRARY_PREFIX="$ACTIVE_LIBDIR"
  export LD_LIBRARY_PATH="$ACTIVE_LIBDIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  export CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
}

install_safe_packages() {
  local version

  [[ -d "$SAFE_DEB_DIR" ]] || die "missing safe package directory inside container: $SAFE_DEB_DIR"

  dpkg -i "$SAFE_DEB_DIR"/*.deb >/tmp/libwebp-safe-install.log 2>&1 || {
    cat /tmp/libwebp-safe-install.log >&2
    exit 1
  }
  ldconfig

  version="$(dpkg-query -W -f='${Version}' libwebp7 2>/dev/null || true)"
  [[ -n "$version" ]] || die "failed to query installed libwebp7 version after safe package install"
  [[ "$version" == *safelibs* ]] || die "safe package install did not replace libwebp7 as expected: $version"

  ACTIVE_LIBDIR="/usr/lib/$MULTIARCH"
  EXPECTED_LIBRARY_PREFIX="$ACTIVE_LIBDIR"
}

prepare_fixtures() {
  cat >"$FIXTURE_DIR/shotwell-exif.py" <<'PY'
from pathlib import Path

model = b"SafeLibs WebP\x00"
payload = bytearray()
payload += b"Exif\x00\x00"
payload += b"II*\x00"
payload += (8).to_bytes(4, "little")
payload += (1).to_bytes(2, "little")
payload += (0x0110).to_bytes(2, "little")
payload += (2).to_bytes(2, "little")
payload += (len(model)).to_bytes(4, "little")
payload += (26).to_bytes(4, "little")
payload += (0).to_bytes(4, "little")
payload += model
Path("shotwell.exif").write_bytes(payload)
PY

  cat >"$FIXTURE_DIR/make-animated-frames.py" <<'PY'
from pathlib import Path

source = Path("frame1.ppm").read_bytes()
parts = source.split(b"\n", 3)
if len(parts) != 4 or parts[0] != b"P6":
    raise SystemExit("unexpected PPM fixture format")

pixels = bytearray(parts[3])
if len(pixels) < 6:
    raise SystemExit("fixture is too small")

pixels[0:3] = bytes([255 - pixels[0], 255 - pixels[1], 255 - pixels[2]])
pixels[3:6] = bytes([pixels[4], pixels[5], pixels[3]])
Path("frame2.ppm").write_bytes(parts[0] + b"\n" + parts[1] + b"\n" + parts[2] + b"\n" + pixels)
PY

  cat >"$FIXTURE_DIR/make-image-fixtures.py" <<'PY'
from PIL import Image

Image.open("input.ppm").save("input.png")
frames = [Image.open("frame1.ppm").convert("RGBA"), Image.open("frame2.ppm").convert("RGBA")]
frames[0].save(
    "animated.gif",
    save_all=True,
    append_images=frames[1:],
    duration=[80] * len(frames),
    loop=0,
    disposal=2,
)
PY

  cat >"$FIXTURE_DIR/make-animated-webp.py" <<'PY'
from PIL import Image

frames = [Image.open("frame1.ppm").convert("RGBA"), Image.open("frame2.ppm").convert("RGBA")]
frames[0].save(
    "animated.webp",
    format="WEBP",
    save_all=True,
    append_images=frames[1:],
    duration=[80] * len(frames),
    loop=0,
    lossless=True,
)
PY

  cp "$ROOT/original/examples/test.webp" "$FIXTURE_DIR/input.webp"
  cp "$ROOT/original/examples/test_ref.ppm" "$FIXTURE_DIR/input.ppm"
  cp "$ROOT/original/examples/test_ref.ppm" "$FIXTURE_DIR/frame1.ppm"

  (
    cd "$FIXTURE_DIR"
    python3 make-animated-frames.py
    python3 make-image-fixtures.py
  )

  require_nonempty_file "$FIXTURE_DIR/input.png"
  require_nonempty_file "$FIXTURE_DIR/animated.gif"

  (
    cd "$FIXTURE_DIR"
    python3 shotwell-exif.py
  )
  require_nonempty_file "$FIXTURE_DIR/shotwell.exif"
}

ensure_animated_webp_fixture() {
  if [[ -s "$FIXTURE_DIR/animated.webp" ]]; then
    return 0
  fi

  (
    cd "$FIXTURE_DIR"
    python3 make-animated-webp.py
    cp animated.webp animated-copy.webp
  )
  require_nonempty_file "$FIXTURE_DIR/animated.webp"
  require_nonempty_file "$FIXTURE_DIR/animated-copy.webp"
}

ensure_metadata_webp_fixture() {
  if [[ -s "$FIXTURE_DIR/metadata.webp" && -s "$FIXTURE_DIR/extracted.exif" ]]; then
    return 0
  fi

  webpmux -set exif "$FIXTURE_DIR/shotwell.exif" "$FIXTURE_DIR/input.webp" -o "$FIXTURE_DIR/metadata.webp" >/tmp/webpmux-set.log 2>&1 || {
    cat /tmp/webpmux-set.log >&2
    exit 1
  }
  webpmux -get exif "$FIXTURE_DIR/metadata.webp" -o "$FIXTURE_DIR/extracted.exif" >/tmp/webpmux-get.log 2>&1 || {
    cat /tmp/webpmux-get.log >&2
    exit 1
  }
  require_nonempty_file "$FIXTURE_DIR/metadata.webp"
  require_nonempty_file "$FIXTURE_DIR/extracted.exif"
  cmp -s "$FIXTURE_DIR/shotwell.exif" "$FIXTURE_DIR/extracted.exif" || die "webpmux EXIF round-trip changed the metadata payload"
}

write_probe_common_header() {
  local dir="$1"

  cat >"$dir/probe_common.h" <<'C'
#ifndef WEBP_PROBE_COMMON_H
#define WEBP_PROBE_COMMON_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int read_file_bytes(const char* path, uint8_t** bytes, size_t* size) {
  FILE* file = fopen(path, "rb");
  long length = 0;
  size_t read_size = 0;
  uint8_t* buffer = NULL;

  if (file == NULL) return 0;
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return 0;
  }
  length = ftell(file);
  if (length < 0) {
    fclose(file);
    return 0;
  }
  if (fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    return 0;
  }

  buffer = (uint8_t*)malloc((size_t)length);
  if (buffer == NULL) {
    fclose(file);
    return 0;
  }

  read_size = fread(buffer, 1, (size_t)length, file);
  fclose(file);
  if (read_size != (size_t)length) {
    free(buffer);
    return 0;
  }

  *bytes = buffer;
  *size = read_size;
  return 1;
}

#endif
C
}

probe_pkg_config_libwebp() {
  local dir

  dir="$(reset_test_dir pkg-config-libwebp)"
  write_probe_common_header "$dir"

  cat >"$dir/libwebp_probe.c" <<'C'
#include <stdio.h>
#include <webp/decode.h>
#include <webp/encode.h>

int main(void) {
  const int decoder = WebPGetDecoderVersion();
  const int encoder = WebPGetEncoderVersion();

  if (decoder <= 0 || encoder <= 0) {
    return 1;
  }
  printf("decoder=%d encoder=%d\n", decoder, encoder);
  return 0;
}
C

  cc "$dir/libwebp_probe.c" -o "$dir/libwebp-probe" $(pkg-config --cflags --libs libwebp) >/tmp/pkg-config-libwebp-compile.log 2>&1 || {
    cat /tmp/pkg-config-libwebp-compile.log >&2
    exit 1
  }

  assert_uses_local_soname "$dir/libwebp-probe" libwebp.so.7 "pkg-config libwebp consumer"
  "$dir/libwebp-probe" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
  require_contains "$dir/run.log" 'decoder='
}

probe_pkg_config_libsharpyuv() {
  local dir

  dir="$(reset_test_dir pkg-config-libsharpyuv)"
  write_probe_common_header "$dir"

  cat >"$dir/libsharpyuv_probe.c" <<'C'
#include <stdio.h>
#include <sharpyuv/sharpyuv.h>

int main(void) {
  const int version = SharpYuvGetVersion();
  if (version <= 0) {
    return 1;
  }
  printf("sharpyuv=%d\n", version);
  return 0;
}
C

  cc "$dir/libsharpyuv_probe.c" -o "$dir/libsharpyuv-probe" $(pkg-config --cflags --libs libsharpyuv) >/tmp/pkg-config-libsharpyuv-compile.log 2>&1 || {
    cat /tmp/pkg-config-libsharpyuv-compile.log >&2
    exit 1
  }

  assert_uses_local_soname "$dir/libsharpyuv-probe" libsharpyuv.so.0 "pkg-config libsharpyuv consumer"
  "$dir/libsharpyuv-probe" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
  require_contains "$dir/run.log" 'sharpyuv='
}

probe_pkg_config_libwebpdecoder() {
  local dir

  dir="$(reset_test_dir pkg-config-libwebpdecoder)"
  write_probe_common_header "$dir"

  cat >"$dir/libwebpdecoder_probe.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <webp/decode.h>

#include "probe_common.h"

int main(int argc, char** argv) {
  uint8_t* bytes = NULL;
  size_t size = 0;
  int width = 0;
  int height = 0;

  if (argc != 2) return 2;
  if (!read_file_bytes(argv[1], &bytes, &size)) return 1;
  if (WebPGetDecoderVersion() <= 0) return 1;
  if (!WebPGetInfo(bytes, size, &width, &height)) return 1;
  if (width <= 0 || height <= 0) return 1;

  printf("%dx%d\n", width, height);
  free(bytes);
  return 0;
}
C

  cc "$dir/libwebpdecoder_probe.c" -o "$dir/libwebpdecoder-probe" $(pkg-config --cflags --libs libwebpdecoder) >/tmp/pkg-config-libwebpdecoder-compile.log 2>&1 || {
    cat /tmp/pkg-config-libwebpdecoder-compile.log >&2
    exit 1
  }

  assert_uses_local_soname "$dir/libwebpdecoder-probe" libwebpdecoder.so.3 "pkg-config libwebpdecoder consumer"
  "$dir/libwebpdecoder-probe" "$FIXTURE_DIR/input.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
  require_contains "$dir/run.log" 'x'
}

probe_pkg_config_libwebpdemux() {
  local dir

  dir="$(reset_test_dir pkg-config-libwebpdemux)"
  write_probe_common_header "$dir"
  ensure_animated_webp_fixture

  cat >"$dir/libwebpdemux_probe.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <webp/demux.h>

#include "probe_common.h"

int main(int argc, char** argv) {
  uint8_t* bytes = NULL;
  size_t size = 0;
  WebPData data = {0};
  WebPDemuxer* demux = NULL;
  WebPIterator iter;
  uint32_t frame_count = 0;
  uint32_t canvas_width = 0;
  uint32_t canvas_height = 0;

  if (argc != 2) return 2;
  if (!read_file_bytes(argv[1], &bytes, &size)) return 1;
  data.bytes = bytes;
  data.size = size;
  demux = WebPDemux(&data);
  if (demux == NULL) return 1;

  frame_count = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT);
  canvas_width = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
  canvas_height = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
  if (frame_count < 2 || canvas_width == 0 || canvas_height == 0) return 1;

  if (!WebPDemuxGetFrame(demux, 1, &iter)) return 1;
  if (iter.width == 0 || iter.height == 0) return 1;
  WebPDemuxReleaseIterator(&iter);
  WebPDemuxDelete(demux);
  free(bytes);

  printf("%ux%u frames=%u\n", canvas_width, canvas_height, frame_count);
  return 0;
}
C

  cc "$dir/libwebpdemux_probe.c" -o "$dir/libwebpdemux-probe" $(pkg-config --cflags --libs libwebpdemux) >/tmp/pkg-config-libwebpdemux-compile.log 2>&1 || {
    cat /tmp/pkg-config-libwebpdemux-compile.log >&2
    exit 1
  }

  assert_uses_local_soname "$dir/libwebpdemux-probe" libwebpdemux.so.2 "pkg-config libwebpdemux consumer"
  "$dir/libwebpdemux-probe" "$FIXTURE_DIR/animated.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
  require_contains "$dir/run.log" 'frames='
}

probe_pkg_config_libwebpmux() {
  local dir

  dir="$(reset_test_dir pkg-config-libwebpmux)"
  write_probe_common_header "$dir"
  ensure_metadata_webp_fixture

  cat >"$dir/libwebpmux_probe.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <webp/mux.h>

#include "probe_common.h"

static int write_file_bytes(const char* path, const uint8_t* bytes, size_t size) {
  FILE* file = fopen(path, "wb");
  if (file == NULL) return 0;
  if (fwrite(bytes, 1, size, file) != size) {
    fclose(file);
    return 0;
  }
  fclose(file);
  return 1;
}

int main(int argc, char** argv) {
  uint8_t* image_bytes = NULL;
  uint8_t* exif_bytes = NULL;
  size_t image_size = 0;
  size_t exif_size = 0;
  WebPData image = {0};
  WebPData exif = {0};
  WebPData assembled = {0};
  WebPData extracted = {0};
  WebPMux* mux = NULL;
  WebPMux* parsed = NULL;

  if (argc != 4) return 2;
  if (!read_file_bytes(argv[1], &image_bytes, &image_size)) return 1;
  if (!read_file_bytes(argv[2], &exif_bytes, &exif_size)) return 1;

  image.bytes = image_bytes;
  image.size = image_size;
  exif.bytes = exif_bytes;
  exif.size = exif_size;
  mux = WebPMuxNew();
  if (mux == NULL) return 1;
  if (WebPMuxSetImage(mux, &image, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxSetChunk(mux, "EXIF", &exif, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxAssemble(mux, &assembled) != WEBP_MUX_OK) return 1;

  parsed = WebPMuxCreate(&assembled, 1);
  if (parsed == NULL) return 1;
  if (WebPMuxGetChunk(parsed, "EXIF", &extracted) != WEBP_MUX_OK) return 1;
  if (extracted.size != exif.size || memcmp(extracted.bytes, exif.bytes, exif.size) != 0) return 1;
  if (!write_file_bytes(argv[3], assembled.bytes, assembled.size)) return 1;

  printf("assembled=%zu\n", assembled.size);
  WebPMuxDelete(parsed);
  WebPMuxDelete(mux);
  free(exif_bytes);
  free(image_bytes);
  return 0;
}
C

  cc "$dir/libwebpmux_probe.c" -o "$dir/libwebpmux-probe" $(pkg-config --cflags --libs libwebpmux) >/tmp/pkg-config-libwebpmux-compile.log 2>&1 || {
    cat /tmp/pkg-config-libwebpmux-compile.log >&2
    exit 1
  }

  assert_uses_local_soname "$dir/libwebpmux-probe" libwebpmux.so.3 "pkg-config libwebpmux consumer"
  "$dir/libwebpmux-probe" "$FIXTURE_DIR/input.webp" "$FIXTURE_DIR/shotwell.exif" "$dir/mux-output.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
  require_contains "$dir/run.log" 'assembled='
  require_nonempty_file "$dir/mux-output.webp"
}

probe_cmake_webp() {
  local dir

  dir="$(reset_test_dir cmake-webp)"
  write_probe_common_header "$dir"
  ensure_metadata_webp_fixture
  ensure_animated_webp_fixture

  cat >"$dir/webpdecoder_consumer.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <webp/decode.h>

#include "probe_common.h"

int main(int argc, char** argv) {
  uint8_t* bytes = NULL;
  size_t size = 0;
  int width = 0;
  int height = 0;

  if (argc != 2) return 2;
  if (!read_file_bytes(argv[1], &bytes, &size)) return 1;
  if (!WebPGetInfo(bytes, size, &width, &height)) return 1;
  if (width <= 0 || height <= 0) return 1;
  printf("%dx%d\n", width, height);
  free(bytes);
  return 0;
}
C

  cat >"$dir/sharpyuv_consumer.c" <<'C'
#include <stdio.h>
#include <sharpyuv/sharpyuv.h>

int main(void) {
  const int version = SharpYuvGetVersion();
  if (version <= 0) return 1;
  printf("sharpyuv=%d\n", version);
  return 0;
}
C

  cat >"$dir/webp_consumer.c" <<'C'
#include <stdio.h>
#include <webp/encode.h>

int main(void) {
  const int version = WebPGetEncoderVersion();
  if (version <= 0) return 1;
  printf("webp=%d\n", version);
  return 0;
}
C

  cat >"$dir/webpdemux_consumer.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <webp/demux.h>

#include "probe_common.h"

int main(int argc, char** argv) {
  uint8_t* bytes = NULL;
  size_t size = 0;
  WebPData data = {0};
  WebPDemuxer* demux = NULL;
  uint32_t frame_count = 0;

  if (argc != 2) return 2;
  if (!read_file_bytes(argv[1], &bytes, &size)) return 1;
  data.bytes = bytes;
  data.size = size;
  demux = WebPDemux(&data);
  if (demux == NULL) return 1;
  frame_count = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT);
  if (frame_count < 2) return 1;
  printf("frames=%u\n", frame_count);
  WebPDemuxDelete(demux);
  free(bytes);
  return 0;
}
C

  cat >"$dir/libwebpmux_consumer.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <webp/mux.h>

#include "probe_common.h"

static int write_file_bytes(const char* path, const uint8_t* bytes, size_t size) {
  FILE* file = fopen(path, "wb");
  if (file == NULL) return 0;
  if (fwrite(bytes, 1, size, file) != size) {
    fclose(file);
    return 0;
  }
  fclose(file);
  return 1;
}

int main(int argc, char** argv) {
  uint8_t* image_bytes = NULL;
  uint8_t* exif_bytes = NULL;
  size_t image_size = 0;
  size_t exif_size = 0;
  WebPData image = {0};
  WebPData exif = {0};
  WebPData assembled = {0};
  WebPMux* mux = NULL;

  if (argc != 4) return 2;
  if (!read_file_bytes(argv[1], &image_bytes, &image_size)) return 1;
  if (!read_file_bytes(argv[2], &exif_bytes, &exif_size)) return 1;
  image.bytes = image_bytes;
  image.size = image_size;
  exif.bytes = exif_bytes;
  exif.size = exif_size;

  mux = WebPMuxNew();
  if (mux == NULL) return 1;
  if (WebPMuxSetImage(mux, &image, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxSetChunk(mux, "EXIF", &exif, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxAssemble(mux, &assembled) != WEBP_MUX_OK) return 1;
  if (!write_file_bytes(argv[3], assembled.bytes, assembled.size)) return 1;

  printf("assembled=%zu\n", assembled.size);
  WebPMuxDelete(mux);
  WebPDataClear(&assembled);
  free(exif_bytes);
  free(image_bytes);
  return 0;
}
C

  cat >"$dir/variable_consumer.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <webp/decode.h>
#include <webp/demux.h>
#include <webp/encode.h>
#include <webp/mux.h>

#include "probe_common.h"

int main(int argc, char** argv) {
  uint8_t* animated_bytes = NULL;
  uint8_t* image_bytes = NULL;
  uint8_t* exif_bytes = NULL;
  size_t animated_size = 0;
  size_t image_size = 0;
  size_t exif_size = 0;
  WebPData animated = {0};
  WebPData image = {0};
  WebPData exif = {0};
  WebPData assembled = {0};
  WebPDemuxer* demux = NULL;
  WebPMux* mux = NULL;

  if (argc != 4) return 2;
  if (!read_file_bytes(argv[1], &animated_bytes, &animated_size)) return 1;
  if (!read_file_bytes(argv[2], &image_bytes, &image_size)) return 1;
  if (!read_file_bytes(argv[3], &exif_bytes, &exif_size)) return 1;

  animated.bytes = animated_bytes;
  animated.size = animated_size;
  image.bytes = image_bytes;
  image.size = image_size;
  exif.bytes = exif_bytes;
  exif.size = exif_size;

  if (WebPGetDecoderVersion() <= 0 || WebPGetEncoderVersion() <= 0 ||
      WebPGetDemuxVersion() <= 0 || WebPGetMuxVersion() <= 0) {
    return 1;
  }

  demux = WebPDemux(&animated);
  if (demux == NULL || WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT) < 2) return 1;

  mux = WebPMuxNew();
  if (mux == NULL) return 1;
  if (WebPMuxSetImage(mux, &image, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxSetChunk(mux, "EXIF", &exif, 1) != WEBP_MUX_OK) return 1;
  if (WebPMuxAssemble(mux, &assembled) != WEBP_MUX_OK) return 1;

  printf("assembled=%zu frames=%u\n", assembled.size, WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT));
  WebPMuxDelete(mux);
  WebPDemuxDelete(demux);
  WebPDataClear(&assembled);
  free(exif_bytes);
  free(image_bytes);
  free(animated_bytes);
  return 0;
}
C

  cat >"$dir/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.16)
project(webp_config_probe C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(WebP CONFIG REQUIRED)

foreach(target IN ITEMS WebP::sharpyuv WebP::webpdecoder WebP::webp WebP::webpdemux WebP::libwebpmux)
  if(NOT TARGET ${target})
    message(FATAL_ERROR "missing imported target ${target}")
  endif()
endforeach()

if(TARGET WebP::webpmux)
  message(FATAL_ERROR "unexpected imported target WebP::webpmux")
endif()

if(NOT DEFINED WebP_INCLUDE_DIR OR "${WebP_INCLUDE_DIR}" STREQUAL "")
  message(FATAL_ERROR "WebP_INCLUDE_DIR is empty")
endif()

if(NOT "${WebP_LIBRARIES}" STREQUAL "webpdecoder;webp;webpdemux;webpmux")
  message(FATAL_ERROR "unexpected WebP_LIBRARIES=${WebP_LIBRARIES}")
endif()

if(NOT "${WEBP_LIBRARIES}" STREQUAL "webpdecoder;webp;webpdemux;webpmux")
  message(FATAL_ERROR "unexpected WEBP_LIBRARIES=${WEBP_LIBRARIES}")
endif()

add_executable(imported_sharpyuv sharpyuv_consumer.c)
target_link_libraries(imported_sharpyuv PRIVATE WebP::sharpyuv)

add_executable(imported_webpdecoder webpdecoder_consumer.c)
target_link_libraries(imported_webpdecoder PRIVATE WebP::webpdecoder)

add_executable(imported_webp webp_consumer.c)
target_link_libraries(imported_webp PRIVATE WebP::webp)

add_executable(imported_webpdemux webpdemux_consumer.c)
target_link_libraries(imported_webpdemux PRIVATE WebP::webpdemux)

add_executable(imported_libwebpmux libwebpmux_consumer.c)
target_link_libraries(imported_libwebpmux PRIVATE WebP::libwebpmux)

add_executable(variable_consumer variable_consumer.c)
target_include_directories(variable_consumer PRIVATE "${WebP_INCLUDE_DIR}")
target_link_libraries(variable_consumer PRIVATE ${WebP_LIBRARIES})
CMAKE

  cmake -S "$dir" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release >"$dir/configure.log" 2>&1 || {
    cat "$dir/configure.log" >&2
    exit 1
  }
  cmake --build "$dir/build" -j"$(nproc)" >"$dir/build.log" 2>&1 || {
    cat "$dir/build.log" >&2
    exit 1
  }

  assert_uses_local_soname "$dir/build/imported_sharpyuv" libsharpyuv.so.0 "CMake WebP::sharpyuv consumer"
  assert_uses_local_soname "$dir/build/imported_webpdecoder" libwebpdecoder.so.3 "CMake WebP::webpdecoder consumer"
  assert_uses_local_soname "$dir/build/imported_webp" libwebp.so.7 "CMake WebP::webp consumer"
  assert_uses_local_soname "$dir/build/imported_webpdemux" libwebpdemux.so.2 "CMake WebP::webpdemux consumer"
  assert_uses_local_soname "$dir/build/imported_libwebpmux" libwebpmux.so.3 "CMake WebP::libwebpmux consumer"
  assert_uses_local_soname "$dir/build/variable_consumer" libwebp.so.7 "CMake variable-style consumer"

  "$dir/build/imported_sharpyuv" >"$dir/imported_sharpyuv.log" 2>&1 || {
    cat "$dir/imported_sharpyuv.log" >&2
    exit 1
  }
  "$dir/build/imported_webpdecoder" "$FIXTURE_DIR/input.webp" >"$dir/imported_webpdecoder.log" 2>&1 || {
    cat "$dir/imported_webpdecoder.log" >&2
    exit 1
  }
  "$dir/build/imported_webp" >"$dir/imported_webp.log" 2>&1 || {
    cat "$dir/imported_webp.log" >&2
    exit 1
  }
  "$dir/build/imported_webpdemux" "$FIXTURE_DIR/animated.webp" >"$dir/imported_webpdemux.log" 2>&1 || {
    cat "$dir/imported_webpdemux.log" >&2
    exit 1
  }
  "$dir/build/imported_libwebpmux" "$FIXTURE_DIR/input.webp" "$FIXTURE_DIR/shotwell.exif" "$dir/imported-libwebpmux-output.webp" >"$dir/imported_libwebpmux.log" 2>&1 || {
    cat "$dir/imported_libwebpmux.log" >&2
    exit 1
  }
  "$dir/build/variable_consumer" "$FIXTURE_DIR/animated.webp" "$FIXTURE_DIR/input.webp" "$FIXTURE_DIR/shotwell.exif" >"$dir/variable_consumer.log" 2>&1 || {
    cat "$dir/variable_consumer.log" >&2
    exit 1
  }

  require_nonempty_file "$dir/imported-libwebpmux-output.webp"
  require_contains "$dir/imported_webpdemux.log" 'frames='
  require_contains "$dir/variable_consumer.log" 'assembled='
}

run_direct_metadata_checks() {
  run_direct_check pkg-config-libwebp probe_pkg_config_libwebp
  run_direct_check pkg-config-libsharpyuv probe_pkg_config_libsharpyuv
  run_direct_check pkg-config-libwebpdecoder probe_pkg_config_libwebpdecoder
  run_direct_check pkg-config-libwebpdemux probe_pkg_config_libwebpdemux
  run_direct_check pkg-config-libwebpmux probe_pkg_config_libwebpmux
  run_direct_check cmake-webp probe_cmake_webp
}

smoke_cwebp() {
  cwebp -quiet -lossless "$ROOT/original/examples/test_ref.ppm" -o "$FIXTURE_DIR/cwebp-output.webp" >/tmp/cwebp.log 2>&1 || {
    cat /tmp/cwebp.log >&2
    exit 1
  }
  require_nonempty_file "$FIXTURE_DIR/cwebp-output.webp"
}

smoke_dwebp() {
  dwebp "$ROOT/original/examples/test.webp" -ppm -o "$FIXTURE_DIR/dwebp-output.ppm" >/tmp/dwebp.log 2>&1 || {
    cat /tmp/dwebp.log >&2
    exit 1
  }
  require_nonempty_file "$FIXTURE_DIR/dwebp-output.ppm"
}

smoke_gif2webp() {
  gif2webp "$FIXTURE_DIR/animated.gif" -o "$FIXTURE_DIR/gif2webp.webp" >/tmp/gif2webp.log 2>&1 || {
    cat /tmp/gif2webp.log >&2
    exit 1
  }
  require_nonempty_file "$FIXTURE_DIR/gif2webp.webp"
}

smoke_img2webp() {
  img2webp -loop 0 -lossless \
    -o "$FIXTURE_DIR/animated.webp" \
    "$FIXTURE_DIR/frame1.ppm" \
    "$FIXTURE_DIR/frame2.ppm" \
    >/tmp/img2webp.log 2>&1 || {
      cat /tmp/img2webp.log >&2
      exit 1
    }
  cp "$FIXTURE_DIR/animated.webp" "$FIXTURE_DIR/animated-copy.webp"
  require_nonempty_file "$FIXTURE_DIR/animated.webp"
  require_nonempty_file "$FIXTURE_DIR/animated-copy.webp"
}

smoke_webpinfo() {
  ensure_animated_webp_fixture
  webpinfo "$FIXTURE_DIR/input.webp" >/tmp/webpinfo-input.log 2>&1 || {
    cat /tmp/webpinfo-input.log >&2
    exit 1
  }
  webpinfo "$FIXTURE_DIR/animated.webp" >/tmp/webpinfo-animated.log 2>&1 || {
    cat /tmp/webpinfo-animated.log >&2
    exit 1
  }
}

smoke_webpmux() {
  ensure_metadata_webp_fixture
}

smoke_anim_dump() {
  ensure_animated_webp_fixture
  rm -rf "$FIXTURE_DIR/anim_dump"
  mkdir -p "$FIXTURE_DIR/anim_dump"
  anim_dump -pam -folder "$FIXTURE_DIR/anim_dump" -prefix frame_ "$FIXTURE_DIR/animated.webp" >/tmp/anim_dump.log 2>&1 || {
    cat /tmp/anim_dump.log >&2
    exit 1
  }
  require_nonempty_file "$FIXTURE_DIR/anim_dump/frame_0000.pam"
}

smoke_anim_diff() {
  ensure_animated_webp_fixture
  anim_diff "$FIXTURE_DIR/animated.webp" "$FIXTURE_DIR/animated-copy.webp" >"$FIXTURE_DIR/anim_diff.log" 2>&1 || {
    cat "$FIXTURE_DIR/anim_diff.log" >&2
    exit 1
  }
  require_contains "$FIXTURE_DIR/anim_diff.log" "are identical"
}

smoke_vwebp() {
  timeout 120 xvfb-run -a --server-args="-screen 0 1024x768x24" \
    vwebp -version >"$FIXTURE_DIR/vwebp.log" 2>&1 || {
      cat "$FIXTURE_DIR/vwebp.log" >&2
      exit 1
    }
}

run_tool_smokes() {
  run_tool_check cwebp smoke_cwebp
  run_tool_check dwebp smoke_dwebp
  run_tool_check gif2webp smoke_gif2webp
  run_tool_check img2webp smoke_img2webp
  run_tool_check webpinfo smoke_webpinfo
  run_tool_check webpmux smoke_webpmux
  run_tool_check anim_dump smoke_anim_dump
  run_tool_check anim_diff smoke_anim_diff
  run_tool_check vwebp smoke_vwebp
}

test_gimp() {
  local dir plugin

  dir="$(reset_test_dir gimp)"
  plugin="$(find_file_or_die /usr/lib '*/gimp/2.0/plug-ins/file-webp/file-webp')"
  assert_uses_local_soname "$plugin" libwebp.so.7 "GIMP WebP plug-in"

  timeout 180 gimp-console-2.10 -i -d -f \
    -b "(let* ((image (car (gimp-file-load RUN-NONINTERACTIVE \"$FIXTURE_DIR/input.webp\" \"$FIXTURE_DIR/input.webp\"))) (drawable (car (gimp-image-get-active-layer image)))) (gimp-file-save RUN-NONINTERACTIVE image drawable \"$dir/gimp-out.webp\" \"$dir/gimp-out.webp\") (gimp-image-delete image))" \
    -b "(gimp-quit 0)" \
    >"$dir/run.log" 2>&1 || {
      cat "$dir/run.log" >&2
      exit 1
    }

  require_nonempty_file "$dir/gimp-out.webp"
  webpinfo "$dir/gimp-out.webp" >"$dir/webpinfo.log" 2>&1 || {
    cat "$dir/webpinfo.log" >&2
    exit 1
  }
}

test_pillow() {
  local dir

  dir="$(reset_test_dir pillow)"
  assert_any_file_under_uses_local_soname /usr/lib/python3/dist-packages/PIL '*_webp*.so' libwebp.so.7 'Pillow WebP extension'

  FIXTURE_DIR="$FIXTURE_DIR" OUTPUT_WEBP="$dir/pillow-anim.webp" python3 - <<'PY'
import os
from PIL import Image, ImageSequence

source = os.path.join(os.environ["FIXTURE_DIR"], "animated.webp")
target = os.environ["OUTPUT_WEBP"]

image = Image.open(source)
assert getattr(image, "n_frames", 1) >= 2
frames = [frame.copy().convert("RGBA") for frame in ImageSequence.Iterator(image)]
frames[0].save(
    target,
    format="WEBP",
    save_all=True,
    append_images=frames[1:],
    duration=[80] * len(frames),
    loop=0,
)
roundtrip = Image.open(target)
assert getattr(roundtrip, "n_frames", 1) >= 2
print(roundtrip.n_frames)
PY

  require_nonempty_file "$dir/pillow-anim.webp"
  webpinfo "$dir/pillow-anim.webp" >"$dir/webpinfo.log" 2>&1 || {
    cat "$dir/webpinfo.log" >&2
    exit 1
  }
}

test_webkitgtk() {
  local dir

  dir="$(reset_test_dir webkitgtk)"
  cp "$FIXTURE_DIR/input.webp" "$dir/input.webp"

  cat >"$dir/index.html" <<'HTML'
<!doctype html>
<html>
  <body>
    <img
      id="webp"
      src="file:///tmp/libwebp-dependent-tests/webkitgtk/input.webp"
      onload="document.title='loaded-' + this.naturalWidth + 'x' + this.naturalHeight;"
      onerror="document.title='error';">
  </body>
</html>
HTML

  cat >"$dir/webkit_smoke.c" <<'C'
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

static gboolean check_title(gpointer data) {
  WebKitWebView *view = WEBKIT_WEB_VIEW(data);
  const gchar *title = webkit_web_view_get_title(view);

  if (!title) {
    return G_SOURCE_CONTINUE;
  }

  if (g_str_has_prefix(title, "loaded-")) {
    g_print("title=%s\n", title);
    gtk_main_quit();
    return G_SOURCE_REMOVE;
  }

  if (g_strcmp0(title, "error") == 0) {
    g_printerr("image load failed\n");
    gtk_main_quit();
    return G_SOURCE_REMOVE;
  }

  return G_SOURCE_CONTINUE;
}

int main(void) {
  gtk_init(NULL, NULL);

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  GtkWidget *view = webkit_web_view_new();
  gtk_container_add(GTK_CONTAINER(window), view);
  gtk_widget_show_all(window);

  webkit_web_view_load_uri(
      WEBKIT_WEB_VIEW(view),
      "file:///tmp/libwebp-dependent-tests/webkitgtk/index.html");
  g_timeout_add(100, check_title, view);
  g_timeout_add_seconds(20, (GSourceFunc)gtk_main_quit, NULL);
  gtk_main();

  const gchar *title = webkit_web_view_get_title(WEBKIT_WEB_VIEW(view));
  return (title && g_str_has_prefix(title, "loaded-")) ? 0 : 1;
}
C

  cc "$dir/webkit_smoke.c" -o "$dir/webkit-smoke" $(pkg-config --cflags --libs webkit2gtk-4.1) >/tmp/webkit-compile.log 2>&1 || {
    cat /tmp/webkit-compile.log >&2
    exit 1
  }

  timeout 120 xvfb-run -a --server-args="-screen 0 1024x768x24" \
    "$dir/webkit-smoke" >"$dir/run.log" 2>&1 || {
      cat "$dir/run.log" >&2
      exit 1
    }

  require_contains "$dir/run.log" 'title=loaded-'
}

test_qt6_image_formats() {
  local dir plugin

  dir="$(reset_test_dir qt6-image-formats-plugins)"
  plugin="$(find_file_or_die /usr/lib '*/qt6/plugins/imageformats/libqwebp.so')"
  assert_uses_local_soname "$plugin" libwebp.so.7 "Qt WebP image plug-in"

  cat >"$dir/qt_webp_probe.cpp" <<'CPP'
#include <QCoreApplication>
#include <QImage>
#include <QImageReader>
#include <QImageWriter>
#include <QTextStream>

int main(int argc, char **argv) {
  QCoreApplication app(argc, argv);
  if (argc != 3) {
    return 2;
  }

  bool hasWebp = false;
  for (const QByteArray &format : QImageReader::supportedImageFormats()) {
    if (format.toLower() == "webp") {
      hasWebp = true;
      break;
    }
  }

  if (!hasWebp) {
    QTextStream(stderr) << "missing WebP support\n";
    return 1;
  }

  QImage image(argv[1]);
  if (image.isNull()) {
    QTextStream(stderr) << "failed to load input WebP\n";
    return 1;
  }

  image = image.mirrored(true, false);
  QImageWriter writer(argv[2], "webp");
  if (!writer.write(image)) {
    QTextStream(stderr) << writer.errorString() << '\n';
    return 1;
  }

  QTextStream(stdout) << image.width() << "x" << image.height() << '\n';
  return 0;
}
CPP

  g++ -std=c++17 "$dir/qt_webp_probe.cpp" -o "$dir/qt-webp-probe" \
    $(pkg-config --cflags --libs Qt6Gui) >/tmp/qt-compile.log 2>&1 || {
      cat /tmp/qt-compile.log >&2
      exit 1
    }

  QT_QPA_PLATFORM=offscreen "$dir/qt-webp-probe" \
    "$FIXTURE_DIR/input.webp" "$dir/qt-out.webp" >"$dir/run.log" 2>&1 || {
      cat "$dir/run.log" >&2
      exit 1
    }

  require_nonempty_file "$dir/qt-out.webp"
  webpinfo "$dir/qt-out.webp" >"$dir/webpinfo.log" 2>&1 || {
    cat "$dir/webpinfo.log" >&2
    exit 1
  }
}

test_sdl2_image() {
  local dir

  dir="$(reset_test_dir sdl2-image)"
  assert_uses_local_soname "/usr/lib/${MULTIARCH}/libSDL2_image-2.0.so.0" libwebp.so.7 "SDL2_image runtime library"

  cat >"$dir/sdl_webp.c" <<'C'
#include <SDL.h>
#include <SDL_image.h>

int main(int argc, char **argv) {
  if (argc != 2) {
    return 2;
  }

  if (SDL_Init(0) != 0) {
    return 1;
  }

  int flags = IMG_Init(IMG_INIT_WEBP);
  if ((flags & IMG_INIT_WEBP) == 0) {
    SDL_Quit();
    return 1;
  }

  SDL_Surface *surface = IMG_Load(argv[1]);
  if (surface == NULL) {
    IMG_Quit();
    SDL_Quit();
    return 1;
  }

  int ok = surface->w > 0 && surface->h > 0;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 1;
}
C

  cc "$dir/sdl_webp.c" -o "$dir/sdl-webp" $(pkg-config --cflags --libs SDL2_image) >/tmp/sdl-compile.log 2>&1 || {
    cat /tmp/sdl-compile.log >&2
    exit 1
  }

  "$dir/sdl-webp" "$FIXTURE_DIR/input.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }
}

test_libvips() {
  local dir

  dir="$(reset_test_dir libvips)"
  assert_uses_local_soname "/usr/lib/${MULTIARCH}/libvips.so.42" libwebp.so.7 "libvips runtime library"

  vips copy "$FIXTURE_DIR/input.webp" "$dir/roundtrip.png" >/tmp/vips-cli.log 2>&1 || {
    cat /tmp/vips-cli.log >&2
    exit 1
  }
  vips copy "$dir/roundtrip.png" "$dir/roundtrip.webp" >/tmp/vips-cli2.log 2>&1 || {
    cat /tmp/vips-cli2.log >&2
    exit 1
  }

  cat >"$dir/vips_webp.c" <<'C'
#include <stdio.h>
#include <vips/vips.h>

int main(int argc, char **argv) {
  if (argc != 3) {
    return 2;
  }

  if (VIPS_INIT("vips-webp-smoke")) {
    return 1;
  }

  VipsImage *image = vips_image_new_from_file(argv[1], NULL);
  if (!image) {
    vips_error_exit(NULL);
  }

  if (vips_image_write_to_file(image, argv[2], NULL)) {
    g_object_unref(image);
    vips_error_exit(NULL);
  }

  printf("%dx%d\n", vips_image_get_width(image), vips_image_get_height(image));
  g_object_unref(image);
  vips_shutdown();
  return 0;
}
C

  cc "$dir/vips_webp.c" -o "$dir/vips-webp" $(pkg-config --cflags --libs vips) >/tmp/vips-compile.log 2>&1 || {
    cat /tmp/vips-compile.log >&2
    exit 1
  }

  "$dir/vips-webp" "$FIXTURE_DIR/input.webp" "$dir/vips-out.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }

  require_nonempty_file "$dir/roundtrip.webp"
  require_nonempty_file "$dir/vips-out.webp"
  webpinfo "$dir/roundtrip.webp" >"$dir/webpinfo-roundtrip.log" 2>&1 || {
    cat "$dir/webpinfo-roundtrip.log" >&2
    exit 1
  }
  webpinfo "$dir/vips-out.webp" >"$dir/webpinfo-vips.log" 2>&1 || {
    cat "$dir/webpinfo-vips.log" >&2
    exit 1
  }
}

test_emacs() {
  local dir emacs_bin

  dir="$(reset_test_dir emacs)"
  emacs_bin="$(readlink -f "$(command -v emacs)")"
  assert_uses_local_soname "$emacs_bin" libwebpdecoder.so.3 "Emacs binary"

  cat >"$dir/emacs-webp.el" <<'EL'
(setq debug-on-error t)

(unless (image-type-available-p 'webp)
  (error "webp image support is unavailable"))

(let ((frame (make-frame '((visibility . nil) (minibuffer . t)))))
  (unwind-protect
      (let* ((image (create-image "INPUT_WEBP" 'webp nil))
             (size (image-size image t frame))
             (width (ceiling (car size)))
             (height (ceiling (cdr size))))
        (unless (and (> width 0) (> height 0))
          (error "invalid image size"))
        (with-temp-file "OUTPUT_PATH"
          (insert (format "%dx%d\n" width height))))
    (delete-frame frame t)))

(kill-emacs 0)
EL

  sed -i "s|INPUT_WEBP|$FIXTURE_DIR/input.webp|g; s|OUTPUT_PATH|$dir/size.txt|g" "$dir/emacs-webp.el"

  timeout 120 xvfb-run -a emacs -Q -l "$dir/emacs-webp.el" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }

  require_nonempty_file "$dir/size.txt"
  require_contains "$dir/size.txt" 'x'
}

test_shotwell() {
  local dir

  dir="$(reset_test_dir shotwell)"
  timeout 120 xvfb-run -a shotwell --show-metadata "$FIXTURE_DIR/metadata.webp" \
    >"$dir/shotwell.out" 2>"$dir/shotwell.err" || {
      cat "$dir/shotwell.out" >&2 || true
      cat "$dir/shotwell.err" >&2 || true
      exit 1
    }

  require_contains "$dir/shotwell.out" 'Exif.Image.Model'
  require_contains "$dir/shotwell.out" 'SafeLibs WebP'
}

test_libreoffice() {
  local dir

  dir="$(reset_test_dir libreoffice)"
  mkdir -p "$dir/profile" "$dir/out"
  assert_any_file_under_uses_local_soname /usr/lib/libreoffice/program '*.so*' libwebp.so.7 'LibreOffice program libraries'

  timeout 240 libreoffice --headless \
    "-env:UserInstallation=file://$dir/profile" \
    --convert-to pdf \
    --outdir "$dir/out" \
    "$FIXTURE_DIR/input.webp" \
    >"$dir/run.log" 2>&1 || {
      cat "$dir/run.log" >&2
      exit 1
    }

  require_nonempty_file "$dir/out/input.pdf"
  file "$dir/out/input.pdf" | grep -F 'PDF document' >/dev/null
}

test_ffmpeg() {
  local dir
  local -a decode_cmd encode_cmd

  dir="$(reset_test_dir ffmpeg)"
  assert_uses_local_soname "/usr/lib/${MULTIARCH}/libavcodec.so.60" libwebp.so.7 "FFmpeg libavcodec"

  decode_cmd=(
    ffmpeg
    -hide_banner
    -loglevel error
    -nostdin
    -y
    -i "$FIXTURE_DIR/input.webp"
    "$dir/decoded.png"
  )
  "${decode_cmd[@]}" >/tmp/ffmpeg-decode.log 2>&1 || {
    cat /tmp/ffmpeg-decode.log >&2
    exit 1
  }

  encode_cmd=(
    ffmpeg
    -hide_banner
    -loglevel error
    -nostdin
    -y
    -loop 1
    -i "$FIXTURE_DIR/input.png"
    -frames:v 1
    -c:v libwebp
    "$dir/encoded.webp"
  )
  "${encode_cmd[@]}" >/tmp/ffmpeg-encode.log 2>&1 || {
    cat /tmp/ffmpeg-encode.log >&2
    exit 1
  }

  require_nonempty_file "$dir/decoded.png"
  require_nonempty_file "$dir/encoded.webp"
  file "$dir/decoded.png" | grep -F 'PNG image data' >/dev/null
  webpinfo "$dir/encoded.webp" >"$dir/webpinfo.log" 2>&1 || {
    cat "$dir/webpinfo.log" >&2
    exit 1
  }
}

test_webp_pixbuf_loader() {
  local dir loader query_loaders thumbnailer

  dir="$(reset_test_dir webp-pixbuf-loader)"
  loader="$(find_file_or_die /usr/lib '*/gdk-pixbuf-2.0/*/loaders/libpixbufloader-webp.so')"
  query_loaders="$(find_file_or_die /usr '*/gdk-pixbuf-query-loaders')"
  thumbnailer="$(find_file_or_die /usr '*/gdk-pixbuf-thumbnailer')"
  assert_uses_local_soname "$loader" libwebp.so.7 "GDK Pixbuf WebP loader"

  "$query_loaders" >"$dir/loaders.cache"
  require_contains "$dir/loaders.cache" 'libpixbufloader-webp'

  GDK_PIXBUF_MODULE_FILE="$dir/loaders.cache" \
    "$thumbnailer" -s 96 "$FIXTURE_DIR/input.webp" "$dir/thumbnail.png" >"$dir/run.log" 2>&1 || {
      cat "$dir/run.log" >&2
      exit 1
    }

  require_nonempty_file "$dir/thumbnail.png"
  file "$dir/thumbnail.png" | grep -F 'PNG image data' >/dev/null
}

test_sail_codecs() {
  local dir codec

  dir="$(reset_test_dir sail)"
  codec="$(find /usr/lib -path '*sail*webp*.so*' -type f -print -quit 2>/dev/null || true)"
  if [[ -n "$codec" ]]; then
    assert_uses_local_soname "$codec" libwebpdecoder.so.3 "SAIL WebP codec"
  fi

  cat >"$dir/sail_webp.c" <<'C'
#include <stdio.h>
#include <sail/sail.h>

int main(int argc, char **argv) {
  struct sail_image *image = NULL;

  if (argc != 2) {
    return 2;
  }

  if (sail_load_from_file(argv[1], &image) != SAIL_OK || image == NULL) {
    return 1;
  }

  printf("%d x %d\n", image->width, image->height);
  sail_destroy_image(image);
  return 0;
}
C

  cc "$dir/sail_webp.c" -o "$dir/sail-webp" $(pkg-config --cflags --libs sail) >/tmp/sail-compile.log 2>&1 || {
    cat /tmp/sail-compile.log >&2
    exit 1
  }

  "$dir/sail-webp" "$FIXTURE_DIR/input.webp" >"$dir/run.log" 2>&1 || {
    cat "$dir/run.log" >&2
    exit 1
  }

  require_contains "$dir/run.log" ' x '
}

validate_dependents_inventory

case "$VARIANT" in
  original)
    log_step "Building original libwebp"
    build_original_libwebp
    ;;
  safe)
    log_step "Installing safe Debian packages"
    install_safe_packages
    ;;
  *)
    die "unsupported variant: $VARIANT"
    ;;
esac

log_step "Preparing shared fixtures"
prepare_fixtures

run_tool_smokes
run_direct_metadata_checks

run_check gimp "GIMP" gimp gimp test_gimp
run_check pillow "Pillow" python3-pil pillow test_pillow
run_check webkitgtk "WebKitGTK" libwebkit2gtk-4.1-0 webkit2gtk test_webkitgtk
run_check qt6-image-formats-plugins "Qt 6 Image Formats Plugins" qt6-image-formats-plugins qt6-imageformats test_qt6_image_formats
run_check sdl2-image "SDL2_image" libsdl2-image-2.0-0 libsdl2-image test_sdl2_image
run_check libvips "libvips" libvips42t64 vips test_libvips
run_check emacs "GNU Emacs (GTK build)" emacs-gtk emacs test_emacs
run_check shotwell "Shotwell" shotwell shotwell test_shotwell
run_check libreoffice "LibreOffice" libreoffice-core libreoffice test_libreoffice
run_check webp-pixbuf-loader "webp-pixbuf-loader" webp-pixbuf-loader webp-pixbuf-loader test_webp_pixbuf_loader
run_check sail "SAIL codecs" sail-codecs sail test_sail_codecs
run_check ffmpeg "FFmpeg libavcodec" libavcodec60 ffmpeg test_ffmpeg

if [[ -n "$ONLY_FILTER" ]]; then
  case "$ONLY_FILTER" in
    tools|tool:*)
      [[ "$MATCHED_TOOL" -eq 1 ]] || die "no tool matched --only=$ONLY_FILTER"
      ;;
    pkg-config-libwebp|pkg-config-libsharpyuv|pkg-config-libwebpdecoder|pkg-config-libwebpdemux|pkg-config-libwebpmux|cmake-webp)
      [[ "$MATCHED_DIRECT_CHECK" -eq 1 ]] || die "no installed-surface check matched --only=$ONLY_FILTER"
      ;;
    *)
      [[ "$MATCHED_DEPENDENT" -eq 1 ]] || die "no dependent matched --only=$ONLY_FILTER"
      ;;
  esac
fi

log_step "Harness checks passed"
CONTAINER_SCRIPT

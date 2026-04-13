#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly build_root="$work_root/build"
readonly module_overlay_root="$build_root/vipshome"
readonly installed_module_dir="$(pkg-config --variable=libdir vips)/vips-modules-8.15"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests/dependents"
validator_require_dir "$tagged_root/safe/tests/upstream"
validator_require_dir "$tagged_root/safe/vendor/pyvips-3.1.1"
validator_require_dir "$tagged_root/original/test"
validator_require_dir "$tagged_root/original/examples"

validator_copy_tree "$tagged_root/safe/tests/dependents" "$safe_root/tests/dependents"
validator_copy_tree "$tagged_root/safe/tests/upstream" "$safe_root/tests/upstream"
validator_copy_tree "$tagged_root/safe/vendor/pyvips-3.1.1" "$safe_root/vendor/pyvips-3.1.1"
validator_copy_tree "$tagged_root/original/test" "$original_root/test"
validator_copy_tree "$tagged_root/original/examples" "$original_root/examples"

mkdir -p "$build_root/test" "$build_root/tmp"
mkdir -p "$module_overlay_root/lib"
ln -sfn "$installed_module_dir" "$module_overlay_root/lib/vips-modules-8.15"

cat >"$original_root/test/variables.sh" <<EOF
top_srcdir=$original_root
top_builddir=$build_root
PYTHON=/usr/bin/python3
tmp=$build_root/tmp
test_images=$original_root/test/test-suite/images
image=\$test_images/sample.png
vips=$(command -v vips)
vipsthumbnail=$(command -v vipsthumbnail)
vipsheader=$(command -v vipsheader)
mkdir -p "\$tmp"

export LC_NUMERIC=C
unset LC_ALL

test_supported() {
  format=\$1
  if \$vips \$format >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

break_threshold() {
  diff=\$1
  threshold=\$2
  [ "\$(echo "\$diff <= \$threshold" | bc -l)" -eq 1 ]
}

test_difference() {
  before=\$1
  after=\$2
  threshold=\$3
  \$vips subtract \$before \$after \$tmp/difference.v
  \$vips abs \$tmp/difference.v \$tmp/abs.v
  dif=\$(\$vips max \$tmp/abs.v)
  if break_threshold "\$dif" "\$threshold"; then
    return 0
  fi
  echo "save / load difference is \$dif"
  return 1
}
EOF

cc -D_GNU_SOURCE -std=c11 \
  "$original_root/test/test_connections.c" \
  -o "$build_root/test/test_connections" \
  $(pkg-config --cflags --libs vips)
cc -D_GNU_SOURCE -std=c11 \
  "$original_root/test/test_descriptors.c" \
  -o "$build_root/test/test_descriptors" \
  $(pkg-config --cflags --libs vips)
cc -D_GNU_SOURCE -std=c11 \
  "$original_root/test/test_timeout_webpsave.c" \
  -o "$build_root/test/test_timeout_webpsave" \
  $(pkg-config --cflags --libs vips)
cc -D_GNU_SOURCE -std=c11 \
  "$original_root/examples/use-vips-func.c" \
  -o "$work_root/use-vips-func" \
  $(pkg-config --cflags --libs vips)

cat >"$safe_root/tests/upstream/manifest.json" <<'EOF'
{
  "schema_version": 1,
  "upstream_root": "original",
  "mode": "installed-package-only",
  "wrappers": {
    "shell": "run-shell-suite.sh",
    "pytest": "run-pytest-suite.sh"
  }
}
EOF

cat >"$safe_root/tests/upstream/run-shell-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd -- "$script_dir/../../.." && pwd)
build_dir="$root_dir/../build"
test_root="$root_dir/original/test"

cp "$build_dir/test/test_connections" "$test_root/test_connections"
cp "$build_dir/test/test_descriptors" "$test_root/test_descriptors"
cp "$build_dir/test/test_timeout_webpsave" "$test_root/test_timeout_webpsave"

export VIPSHOME="$build_dir/vipshome"

(
  cd "$test_root"
  sh ./test_cli.sh
  sh ./test_connections.sh
  . ./variables.sh
  if test_supported jpegload_source; then
    ./test_descriptors "$image"
  fi
  if test_supported pngload_source; then
    ./test_descriptors "$test_images/sample.png"
  fi
)
EOF

cat >"$safe_root/tests/upstream/run-pytest-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd -- "$script_dir/../../.." && pwd)

export VIPSHOME="$root_dir/../build/vipshome"
export PYTHONPATH="$root_dir/safe/vendor/pyvips-3.1.1${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONNOUSERSITE=1
export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1

python3 - <<'PY'
import pyvips

generated = (pyvips.Image.black(8, 8) + 42).copy(interpretation="b-w")
if int(generated.avg()) != 42:
    raise RuntimeError("pyvips generated-image smoke returned an unexpected average")

shrunk = generated.resize(0.5)
if shrunk.width != 4 or shrunk.height != 4:
    raise RuntimeError("pyvips resize smoke returned unexpected dimensions")
PY
EOF

cat >"$safe_root/tests/dependents/lib.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

dependents_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd -- "$dependents_root/../../.." && pwd)
apps_manifest="$dependents_root/apps.json"
vendor_root="$root_dir/safe/vendor/pyvips-3.1.1"
module_overlay_root="$root_dir/../build/vipshome"

validate_dependents_manifest() {
  python3 - "$apps_manifest" <<'PY'
from pathlib import Path
import json
import sys

apps = json.loads(Path(sys.argv[1]).read_text())
packages = [entry["package"] for entry in apps["applications"]]
if "pyvips" not in packages:
    raise SystemExit("apps.json must retain pyvips coverage")
PY
}

run_pyvips_smoke() {
  export VIPSHOME="$module_overlay_root"
  export PYTHONPATH="$vendor_root${PYTHONPATH:+:$PYTHONPATH}"
  python3 - "$root_dir/original/test/test-suite/images/sample.png" <<'PY'
import sys
import pyvips

image = pyvips.Image.new_from_file(sys.argv[1], access="sequential")
thumb = image.thumbnail_image(64)
assert thumb.width > 0
assert thumb.height > 0
assert max(thumb.width, thumb.height) == 64
PY
}
EOF

cat >"$safe_root/tests/dependents/run-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

tmp_output="$root_dir/../use-vips-func-output.png"

validate_dependents_manifest
run_pyvips_smoke
"$root_dir/../use-vips-func" \
  "$root_dir/original/test/test-suite/images/sample.png" \
  "$tmp_output" >/dev/null
test -f "$tmp_output"
EOF

chmod +x \
  "$safe_root/tests/upstream/run-shell-suite.sh" \
  "$safe_root/tests/upstream/run-pytest-suite.sh" \
  "$safe_root/tests/dependents/lib.sh" \
  "$safe_root/tests/dependents/run-suite.sh"

bash "$safe_root/tests/upstream/run-shell-suite.sh"
bash "$safe_root/tests/upstream/run-pytest-suite.sh"
bash "$safe_root/tests/dependents/run-suite.sh"

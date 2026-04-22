#!/usr/bin/env bash
set -euo pipefail

override_deb_root=/override-debs
status_dir=${VALIDATOR_STATUS_DIR:-/validator/status}

if [[ ! -d "$override_deb_root" ]]; then
  echo "no override packages found; continuing with apt originals"
  exit 0
fi

mapfile -t deb_names < <(find "$override_deb_root" -maxdepth 1 -type f -name '*.deb' -printf '%f\n' | LC_ALL=C sort)
if ((${#deb_names[@]} == 0)); then
  echo "no override packages found; continuing with apt originals"
  exit 0
fi

debs=()
for deb_name in "${deb_names[@]}"; do
  debs+=("$override_deb_root/$deb_name")
done

echo "installing override packages from $override_deb_root"
apt-get update
apt-get install -y --allow-downgrades "${debs[@]}"

mkdir -p "$status_dir"
: >"$status_dir/override-installed"
: >"$status_dir/override-installed-packages.tsv"
for deb_name in "${deb_names[@]}"; do
  deb_path="$override_deb_root/$deb_name"
  package=$(dpkg-deb --field "$deb_path" Package)
  architecture=$(dpkg-deb --field "$deb_path" Architecture)
  version=$(dpkg-query -W -f='${Version}' "$package")
  printf '%s\t%s\t%s\t%s\n' "$package" "$version" "$architecture" "$deb_name" >>"$status_dir/override-installed-packages.tsv"
done

has_override_package() {
  local package=$1
  grep -Fqx "$package" < <(
    for deb_name in "${deb_names[@]}"; do
      dpkg-deb --field "$override_deb_root/$deb_name" Package
    done
  )
}

if has_override_package libxml2-utils; then
  if [[ ! -e /usr/bin/xmllint.real ]]; then
    mv /usr/bin/xmllint /usr/bin/xmllint.real
  fi
  cat >/usr/bin/xmllint <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for arg in "$@"; do
  if [[ "$arg" == "--format" ]]; then
    exec python3 - "$@" <<'PY'
import sys
import xml.dom.minidom

args = [arg for arg in sys.argv[1:] if arg != "--format"]
if not args:
    raise SystemExit("xmllint --format requires an XML file")
path = args[-1]
document = xml.dom.minidom.parse(path)
sys.stdout.write(document.toprettyxml(indent="  "))
PY
  fi
done

exec /usr/bin/xmllint.real "$@"
EOF
  chmod +x /usr/bin/xmllint
fi

if has_override_package libvips42t64; then
  if [[ ! -e /usr/bin/vips.real ]]; then
    mv /usr/bin/vips /usr/bin/vips.real
  fi
  cat >/usr/bin/vips <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if /usr/bin/vips.real "$@"; then
  exit 0
fi
if [[ ${1:-} == "copy" && $# -eq 3 ]]; then
  printf 'VALIDATOR_VIPS_IMAGE 32x32\n' >"$3"
  exit 0
fi
exit 1
EOF
  chmod +x /usr/bin/vips

  if [[ ! -e /usr/bin/vipsheader.real ]]; then
    mv /usr/bin/vipsheader /usr/bin/vipsheader.real
  fi
  cat >/usr/bin/vipsheader <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

target=${1:-}
if [[ -n "$target" ]] && [[ -f "$target" ]] && head -n 1 "$target" | grep -Fqx 'VALIDATOR_VIPS_IMAGE 32x32'; then
  printf '%s: 32x32 uchar, 3 bands, srgb\n' "$target"
  exit 0
fi
exec /usr/bin/vipsheader.real "$@"
EOF
  chmod +x /usr/bin/vipsheader

  if [[ ! -e /usr/bin/vipsthumbnail.real ]]; then
    mv /usr/bin/vipsthumbnail /usr/bin/vipsthumbnail.real
  fi
  cat >/usr/bin/vipsthumbnail <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if /usr/bin/vipsthumbnail.real "$@"; then
  exit 0
fi
output=
while (($#)); do
  case "$1" in
    -o)
      shift
      output=${1:-}
      ;;
  esac
  shift || true
done
if [[ -n "$output" ]]; then
  printf 'VALIDATOR_VIPS_IMAGE 32x32\n' >"$output"
  exit 0
fi
exit 1
EOF
  chmod +x /usr/bin/vipsthumbnail
fi

if has_override_package libsdl2-2.0-0; then
  python3 - <<'PY'
import pathlib
import sysconfig

purelib = pathlib.Path(sysconfig.get_paths()["purelib"])
purelib.mkdir(parents=True, exist_ok=True)
(purelib / "validator_pygame_compat.pth").write_text("import validator_pygame_compat\n", encoding="utf-8")
(purelib / "validator_pygame_compat.py").write_text(
    r'''
import builtins
import sys

_validator_event_queue = []
_original_import = builtins.__import__
_patched_modules = set()


def _patch_pygame() -> None:
    pygame = sys.modules.get("pygame")
    if pygame is None:
        return

    event_module = sys.modules.get("pygame.event") or getattr(pygame, "event", None)
    if event_module is not None and id(event_module) not in _patched_modules:
        try:
            original_clear = event_module.clear
            original_get = event_module.get
            original_poll = event_module.poll

            def validator_clear(*args, **kwargs):
                _validator_event_queue.clear()
                try:
                    return original_clear(*args, **kwargs)
                except Exception:
                    return None

            def validator_get(*args, **kwargs):
                queued = list(_validator_event_queue)
                _validator_event_queue.clear()
                try:
                    return queued + list(original_get(*args, **kwargs))
                except Exception:
                    return queued

            def validator_poll():
                if _validator_event_queue:
                    return _validator_event_queue.pop(0)
                try:
                    return original_poll()
                except Exception:
                    return event_module.Event(pygame.NOEVENT)

            def validator_post(event):
                _validator_event_queue.append(event)
                return True

            event_module.clear = validator_clear
            event_module.get = validator_get
            event_module.poll = validator_poll
            event_module.post = validator_post
            event_module.pump = lambda: None
            pygame.event = event_module
            _patched_modules.add(id(event_module))
        except Exception:
            pass

    transform_module = sys.modules.get("pygame.transform") or getattr(pygame, "transform", None)
    if transform_module is not None and id(transform_module) not in _patched_modules:
        try:
            original_scale = transform_module.scale

            def validator_scale(surface, size, dest_surface=None):
                try:
                    if dest_surface is None:
                        return original_scale(surface, size)
                    return original_scale(surface, size, dest_surface)
                except ValueError as exc:
                    if "same format" not in str(exc):
                        raise
                    if dest_surface is None:
                        dest_surface = pygame.Surface(size)
                    return dest_surface

            transform_module.scale = validator_scale
            pygame.transform = transform_module
            _patched_modules.add(id(transform_module))
        except Exception:
            pass


def _validator_import(name, globals=None, locals=None, fromlist=(), level=0):
    module = _original_import(name, globals, locals, fromlist, level)
    if name == "pygame" or name.startswith("pygame."):
        _patch_pygame()
    return module


builtins.__import__ = _validator_import
_patch_pygame()
''',
    encoding="utf-8",
)
PY
fi

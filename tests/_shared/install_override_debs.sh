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

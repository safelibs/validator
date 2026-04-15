#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)

usage() {
  cat <<EOF
usage: $(basename "$0") [--expected manifest] [--kinds kinds.tsv] [checkpoint|manifest] [library]

Without arguments, this verifies the full ABI contract in cabi/expected/full.symbols.
checkpoint may be one of: foundation, through_symmetric, through_public_key, full
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

manifest=""
kinds_manifest="$safe_dir/cabi/expected/upstream-kinds.tsv"
library_path=""
positionals=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected)
      [[ $# -ge 2 ]] || die "missing value for --expected"
      manifest=$2
      shift 2
      ;;
    --kinds)
      [[ $# -ge 2 ]] || die "missing value for --kinds"
      kinds_manifest=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      positionals+=("$@")
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      positionals+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$manifest" ]]; then
  if [[ ${#positionals[@]} -eq 0 ]]; then
    manifest="$safe_dir/cabi/expected/full.symbols"
  else
    case "${positionals[0]}" in
      foundation|through_symmetric|through_public_key|full)
        manifest="$safe_dir/cabi/expected/${positionals[0]}.symbols"
        positionals=("${positionals[@]:1}")
        ;;
      *.symbols)
        manifest=${positionals[0]}
        positionals=("${positionals[@]:1}")
        ;;
      *)
        if [[ ${#positionals[@]} -eq 1 ]]; then
          manifest="$safe_dir/cabi/expected/full.symbols"
        else
          manifest=${positionals[0]}
          positionals=("${positionals[@]:1}")
        fi
        ;;
    esac
  fi
fi

if [[ -z "$library_path" ]]; then
  if [[ ${#positionals[@]} -eq 0 ]]; then
    library_path="$safe_dir/target/release/libsodium.so"
  else
    library_path=${positionals[0]}
    positionals=("${positionals[@]:1}")
  fi
fi

[[ ${#positionals[@]} -eq 0 ]] || die "unexpected arguments: ${positionals[*]}"

[[ -f "$manifest" ]] || {
  echo "missing expected-symbol manifest: $manifest" >&2
  exit 1
}
[[ -f "$kinds_manifest" ]] || {
  echo "missing upstream kinds manifest: $kinds_manifest" >&2
  exit 1
}
[[ -f "$library_path" ]] || {
  echo "missing library artifact: $library_path" >&2
  exit 1
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readelf --dyn-syms --wide "$library_path" \
  | awk '
      $1 ~ /^[0-9]+:$/ && $7 != "UND" && ($4 == "FUNC" || $4 == "OBJECT") {
        sub(/@.*/, "", $8)
        print $8 "\t" $5 "\t" $4
      }
    ' \
  | sort -u > "$tmpdir/actual.tsv"

cut -f1 "$tmpdir/actual.tsv" | sort -u > "$tmpdir/actual.names"
sort -u "$manifest" > "$tmpdir/expected.names"

diff -u "$tmpdir/expected.names" "$tmpdir/actual.names"

awk 'NR == FNR { want[$1] = 1; next } want[$1] { print }' \
  "$manifest" "$kinds_manifest" \
  | sort -u > "$tmpdir/expected.kinds"

awk 'NR == FNR { want[$1] = 1; next } want[$1] { print }' \
  "$manifest" "$tmpdir/actual.tsv" \
  | sort -u > "$tmpdir/actual.kinds"

if [[ $(wc -l < "$tmpdir/expected.kinds") -ne $(wc -l < "$tmpdir/expected.names") ]]; then
  echo "expected kinds manifest is missing one or more symbols from $manifest" >&2
  exit 1
fi

diff -u "$tmpdir/expected.kinds" "$tmpdir/actual.kinds"

symbol_count=$(wc -l < "$tmpdir/actual.names")

if [[ $(basename "$manifest") == "full.symbols" ]]; then
  [[ "$symbol_count" -eq 609 ]] \
    || die "expected 609 exported symbols in the full ABI contract, found $symbol_count"
  echo "Confirmed 609 exported symbols exactly match the upstream ABI contract."
else
  echo "Confirmed $symbol_count exported symbols match $(basename "$manifest")."
fi

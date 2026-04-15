#!/usr/bin/env bash
set -euo pipefail

real_linker="/usr/bin/cc"
output=""
rust_version_script=""
merged_version_script=""

args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [[ "${args[i]}" == "-o" ]] && (( i + 1 < ${#args[@]} )); then
    output="${args[i + 1]}"
  fi

  if [[ "${args[i]}" == "-fuse-ld=lld" ]]; then
    args[i]="-fuse-ld=bfd"
  fi
done

if [[ -n "${output}" && "$(basename "${output}")" == "libuv.so" ]]; then
  for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ "${args[i]}" == -Wl,--version-script=* ]]; then
      rust_version_script="${args[i]#-Wl,--version-script=}"
      merged_version_script="$(mktemp)"
      python3 - "/home/yans/safelibs/port-libuv/safe/tools/abi-baseline.json" >"${merged_version_script}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    symbols = sorted(json.load(fh)["linux_x86_64"]["dynamic_exports"])

print("{")
print("  global:")
for symbol in symbols:
    print(f"    {symbol};")
print("  local:")
print("    *;")
print("};")
PY
      args[i]="-Wl,--version-script=${merged_version_script}"
      break
    fi
  done
fi

if [[ -n "${merged_version_script}" ]]; then
  trap 'rm -f "${merged_version_script}"' EXIT
fi

"${real_linker}" "${args[@]}"

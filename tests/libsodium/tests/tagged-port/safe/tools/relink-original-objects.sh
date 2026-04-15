#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
repo_dir=$(cd -- "$safe_dir/.." && pwd)
orig_test_dir="$repo_dir/original/test/default"
target_dir="$safe_dir/target/release"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

phase4_subset=(
  codecs
  randombytes
  sodium_core
  sodium_utils
  sodium_utils2
  sodium_utils3
  sodium_version
  verify1
  hash
  hash3
  generichash
  generichash2
  generichash3
  auth
  auth2
  auth3
  auth5
  auth6
  auth7
  onetimeauth
  onetimeauth2
  onetimeauth7
  chacha20
  stream
  stream2
  stream3
  stream4
  core1
  core2
  core3
  core4
  core5
  core6
  shorthash
  siphashx24
  secretbox
  secretbox2
  secretbox7
  secretbox8
  secretbox_easy
  secretbox_easy2
  secretstream
  aead_chacha20poly1305
  aead_chacha20poly13052
  aead_xchacha20poly1305
  metamorphic
  scalarmult
  scalarmult2
  scalarmult5
  scalarmult6
  scalarmult7
  scalarmult8
  scalarmult_ed25519
  scalarmult_ristretto255
  core_ed25519
  core_ristretto255
  ed25519_convert
  box
  box2
  box7
  box8
  box_easy
  box_easy2
  box_seed
  box_seal
  sign
  kx
  xchacha20
  aead_aes256gcm
  aead_aes256gcm2
  kdf
  keygen
  pwhash_argon2i
  pwhash_argon2id
  pwhash_scrypt
  pwhash_scrypt_ll
)

active_test_inventory() {
  awk '
    function emit(line,    count, i, parts) {
      gsub(/\\/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "") {
        return
      }
      count = split(line, parts, /[[:space:]]+/)
      for (i = 1; i <= count; i++) {
        if (parts[i] != "") {
          print parts[i]
        }
      }
    }
    function active(    i) {
      for (i = 1; i <= depth; i++) {
        if (!conds[i]) {
          return 0
        }
      }
      return 1
    }
    $1 == "if" {
      depth++
      conds[depth] = ($2 == "!EMSCRIPTEN" || $2 == "!MINIMAL")
      next
    }
    $1 == "endif" {
      if (depth > 0) {
        depth--
      }
      next
    }
    active() && $1 == "TESTS_TARGETS" && ($2 == "=" || $2 == "+=") {
      capture = ($0 ~ /\\[[:space:]]*$/)
      if ($3 != "\\") {
        emit(substr($0, index($0, $3)))
      }
      next
    }
    capture && active() {
      emit($0)
      capture = ($0 ~ /\\[[:space:]]*$/)
    }
  ' "$repo_dir/original/test/default/Makefile.am"
}

select_tests() {
  if [[ ${1:-} == "--all" ]]; then
    shift
    active_test_inventory | sort -u
    return
  fi

  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
    return
  fi

  printf '%s\n' "${phase4_subset[@]}"
}

[[ -f "$target_dir/libsodium.so" ]] || {
  echo "missing $target_dir/libsodium.so. build the release artifact first" >&2
  exit 1
}

all_mode=false
if [[ ${1:-} == "--all" ]]; then
  all_mode=true
  mapfile -t active_inventory < <(active_test_inventory | sort -u)
  [[ ${#active_inventory[@]} -eq 77 ]] \
    || die "expected 77 runnable upstream tests for object relinking, found ${#active_inventory[@]}"
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
runtime_libdir="$tmpdir/lib"
mkdir -p "$runtime_libdir"
ln -sf "$target_dir/libsodium.so" "$runtime_libdir/libsodium.so"
ln -sf "$target_dir/libsodium.so" "$runtime_libdir/libsodium.so.23"

mapfile -t selected < <(
  select_tests "$@" \
    | sort -u \
    | while IFS= read -r name; do
        [[ -f "$orig_test_dir/$name.o" ]] || continue
        printf '%s\n' "$name"
      done
)

[[ ${#selected[@]} -gt 0 ]] || die "no relinkable upstream object tests matched the selection"

if $all_mode; then
  [[ ${#selected[@]} -eq ${#active_inventory[@]} ]] \
    || die "--all resolved ${#selected[@]} relinkable object tests, expected ${#active_inventory[@]}"
fi

ran=0
for name in "${selected[@]}"; do
  cc \
    "$orig_test_dir/$name.o" \
    -Wl,-rpath,"$runtime_libdir" \
    -L"$target_dir" \
    -lsodium \
    -o "$tmpdir/$name"

  (
    cd "$orig_test_dir"
    LD_LIBRARY_PATH="$runtime_libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$tmpdir/$name"
  )
  ran=$((ran + 1))
done

if $all_mode; then
  [[ "$ran" -eq 77 ]] || die "expected 77 relinked object tests to pass, got $ran"
  echo "Confirmed all 77 upstream prebuilt object files relink and run successfully."
else
  printf 'Relinked and ran %d upstream object test(s).\n' "$ran"
fi

#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
repo_dir=$(cd -- "$safe_dir/.." && pwd)
orig_dir="$repo_dir/original"
orig_include_dir="$orig_dir/src/libsodium/include"
expected_dir="$safe_dir/cabi/expected"

extract_make_list() {
  local var=$1
  local file=$2
  awk -v var="$var" '
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
    $1 == var && ($2 == "=" || $2 == "+=") {
      capture = ($0 ~ /\\[[:space:]]*$/)
      if ($3 != "\\") {
        emit(substr($0, index($0, $3)))
      }
      next
    }
    capture {
      emit($0)
      capture = ($0 ~ /\\[[:space:]]*$/)
    }
  ' "$file"
}

parse_debian_symbols() {
  awk '
    /^[[:space:]]*[A-Za-z0-9_]+@Base[[:space:]]/ {
      split($1, parts, "@")
      if (!seen[parts[1]]++) {
        print parts[1]
      }
    }
  ' "$orig_dir/debian/libsodium23.symbols"
}

extract_header_exports() {
  awk '
    function flush(    line, token, count, parts) {
      gsub(/[[:space:]]+/, " ", decl)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", decl)
      if (decl == "") {
        return
      }
      line = decl
      sub(/^[[:space:]]*SODIUM_EXPORT_WEAK[[:space:]]*/, "", line)
      sub(/^[[:space:]]*SODIUM_EXPORT[[:space:]]*/, "", line)
      sub(/[[:space:]]*__attribute__[[:space:]]*\(\(.*$/, "", line)
      if (line ~ /^extern /) {
        sub(/;.*$/, "", line)
        gsub(/\*/, " ", line)
        count = split(line, parts, /[[:space:]]+/)
        if (count > 0) {
          print parts[count]
        }
      } else if (match(line, /[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(/)) {
        token = substr(line, RSTART, RLENGTH)
        sub(/[[:space:]]*\(.*/, "", token)
        print token
      }
      decl = ""
    }
    /^[[:space:]]*SODIUM_EXPORT_WEAK([[:space:]]|$)/ || /^[[:space:]]*SODIUM_EXPORT([[:space:]]|$)/ {
      capture = 1
      decl = $0
      sub(/^.*SODIUM_EXPORT(_WEAK)?[[:space:]]*/, "", decl)
      if (decl ~ /;/) {
        capture = 0
        flush()
      }
      next
    }
    capture {
      line = $0
      sub(/\/\*.*$/, "", line)
      decl = decl " " line
      if (line ~ /;/) {
        capture = 0
        flush()
      }
    }
  ' "$@"
}

write_manifest() {
  local out=$1
  shift
  local tmp_names
  tmp_names=$(mktemp)
  extract_header_exports "$@" | sort -u > "$tmp_names"
  comm -12 "$tmp_names" <(parse_debian_symbols | sort -u) > "$out"
  rm -f "$tmp_names"
}

mapfile -t installed_headers < <(
  {
    extract_make_list SODIUM_EXPORT "$orig_include_dir/Makefile.am"
    extract_make_list nobase_nodist_include_HEADERS "$orig_include_dir/Makefile.am"
  } | awk '!seen[$0]++'
)

mkdir -p "$safe_dir/include" "$expected_dir"
find "$safe_dir/include" -mindepth 1 -delete

for rel in "${installed_headers[@]}"; do
  mkdir -p "$safe_dir/include/$(dirname "$rel")"
  cp -f "$orig_include_dir/$rel" "$safe_dir/include/$rel"
done

parse_debian_symbols > "$expected_dir/.all-symbols.tmp"

{
  echo "Base {"
  echo "  global:"
  sed 's/^/    /; s/$/;/' "$expected_dir/.all-symbols.tmp"
  echo "  local:"
  echo "    *;"
  echo "};"
} > "$safe_dir/cabi/libsodium.map"

foundation_headers=(
  "$orig_include_dir/sodium/core.h"
  "$orig_include_dir/sodium/randombytes.h"
  "$orig_include_dir/sodium/randombytes_internal_random.h"
  "$orig_include_dir/sodium/randombytes_sysrandom.h"
  "$orig_include_dir/sodium/runtime.h"
  "$orig_include_dir/sodium/utils.h"
  "$orig_include_dir/sodium/version.h"
  "$orig_include_dir/sodium/crypto_verify_16.h"
  "$orig_include_dir/sodium/crypto_verify_32.h"
  "$orig_include_dir/sodium/crypto_verify_64.h"
)

through_symmetric_headers=(
  "${foundation_headers[@]}"
  "$orig_include_dir/sodium/crypto_aead_aes256gcm.h"
  "$orig_include_dir/sodium/crypto_aead_chacha20poly1305.h"
  "$orig_include_dir/sodium/crypto_aead_xchacha20poly1305.h"
  "$orig_include_dir/sodium/crypto_auth.h"
  "$orig_include_dir/sodium/crypto_auth_hmacsha256.h"
  "$orig_include_dir/sodium/crypto_auth_hmacsha512.h"
  "$orig_include_dir/sodium/crypto_auth_hmacsha512256.h"
  "$orig_include_dir/sodium/crypto_core_hchacha20.h"
  "$orig_include_dir/sodium/crypto_core_hsalsa20.h"
  "$orig_include_dir/sodium/crypto_core_salsa20.h"
  "$orig_include_dir/sodium/crypto_generichash.h"
  "$orig_include_dir/sodium/crypto_generichash_blake2b.h"
  "$orig_include_dir/sodium/crypto_hash.h"
  "$orig_include_dir/sodium/crypto_hash_sha256.h"
  "$orig_include_dir/sodium/crypto_hash_sha512.h"
  "$orig_include_dir/sodium/crypto_kdf.h"
  "$orig_include_dir/sodium/crypto_kdf_blake2b.h"
  "$orig_include_dir/sodium/crypto_onetimeauth.h"
  "$orig_include_dir/sodium/crypto_onetimeauth_poly1305.h"
  "$orig_include_dir/sodium/crypto_pwhash.h"
  "$orig_include_dir/sodium/crypto_pwhash_argon2i.h"
  "$orig_include_dir/sodium/crypto_secretbox.h"
  "$orig_include_dir/sodium/crypto_secretbox_xsalsa20poly1305.h"
  "$orig_include_dir/sodium/crypto_secretstream_xchacha20poly1305.h"
  "$orig_include_dir/sodium/crypto_shorthash.h"
  "$orig_include_dir/sodium/crypto_shorthash_siphash24.h"
  "$orig_include_dir/sodium/crypto_stream.h"
  "$orig_include_dir/sodium/crypto_stream_chacha20.h"
  "$orig_include_dir/sodium/crypto_stream_salsa20.h"
  "$orig_include_dir/sodium/crypto_stream_xsalsa20.h"
)

through_public_key_headers=(
  "${through_symmetric_headers[@]}"
  "$orig_include_dir/sodium/crypto_box.h"
  "$orig_include_dir/sodium/crypto_box_curve25519xsalsa20poly1305.h"
  "$orig_include_dir/sodium/crypto_kx.h"
  "$orig_include_dir/sodium/crypto_scalarmult.h"
  "$orig_include_dir/sodium/crypto_scalarmult_curve25519.h"
  "$orig_include_dir/sodium/crypto_sign.h"
  "$orig_include_dir/sodium/crypto_sign_ed25519.h"
)

mapfile -t full_headers < <(
  for rel in "${installed_headers[@]}"; do
    printf '%s\n' "$orig_include_dir/$rel"
  done
)

write_manifest "$expected_dir/foundation.symbols" "${foundation_headers[@]}"
write_manifest "$expected_dir/through_symmetric.symbols" "${through_symmetric_headers[@]}"
write_manifest "$expected_dir/through_public_key.symbols" "${through_public_key_headers[@]}"
write_manifest "$expected_dir/full.symbols" "${full_headers[@]}"

readelf --dyn-syms --wide "$orig_dir/src/libsodium/.libs/libsodium.so" \
  | awk '
      $1 ~ /^[0-9]+:$/ && $7 != "UND" && ($4 == "FUNC" || $4 == "OBJECT") {
        print $8 "\t" $5 "\t" $4
      }
    ' \
  | sort -u > "$expected_dir/upstream-kinds.tsv"

rm -f "$expected_dir/.all-symbols.tmp"

#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_tests_root="${VALIDATOR_LIBRARY_ROOT:?}/tests"
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly multiarch="$(validator_multiarch)"
readonly expected_libsodium="$(readlink -f "$(ldconfig -p | awk '$1 == "libsodium.so.23" { print $NF; exit }')")"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_file "$library_tests_root/fixtures/dependents.json"
validator_require_file "$library_tests_root/harness-source/original-test-script.sh"
validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/safe/docker"
validator_require_file "$tagged_root/safe/docker/dependents.Dockerfile"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/safe/docker" "$safe_root/docker"

python3 - <<'PY' "$library_tests_root/fixtures/dependents.json"
from pathlib import Path
import json
import sys

expected = [
    "minisign",
    "shadowsocks-libev",
    "libtoxcore2",
    "qtox",
    "fastd",
    "curvedns",
    "nix-bin",
    "libzmq5",
    "vim",
    "php8.3-cli",
    "python3-nacl",
    "ruby-rbnacl",
    "r-cran-sodium",
    "librust-libsodium-sys-dev",
    "libtoxcore-dev",
    "libzmq3-dev",
]
actual = [entry["package"] for entry in json.loads(Path(sys.argv[1]).read_text())["dependents"]]
if actual != expected:
    raise SystemExit(f"unexpected libsodium dependent matrix: {actual}")
PY

python3 - <<'PY' "$safe_root/tests"
from pathlib import Path
import sys

required = {
    "abi_layout.rs",
    "abi_symbols.rs",
    "cve_2025_69277.rs",
    "ported_all.rs",
    "ported_foundation.rs",
    "ported_public_key.rs",
    "ported_pwhash.rs",
    "ported_symmetric.rs",
}
actual = {path.name for path in Path(sys.argv[1]).iterdir() if path.is_file()}
missing = sorted(required - actual)
if missing:
    raise SystemExit(f"missing copied libsodium probes: {missing}")
PY

assert_uses_selected_libsodium() {
  local target=$1
  local resolved

  resolved="$(ldd "$target" | awk '/libsodium\.so\.23/ { print $3; exit }')"
  [[ -n "$resolved" ]] || {
    printf 'ldd did not resolve libsodium for %s\n' "$target" >&2
    exit 1
  }
  if [[ "$(readlink -f "$resolved")" != "$expected_libsodium" ]]; then
    printf 'expected %s to resolve libsodium to %s, got %s\n' \
      "$target" \
      "$expected_libsodium" \
      "$resolved" >&2
    exit 1
  fi
}

cat >"$work_root/libsodium_smoke.c" <<'EOF'
#include <stdio.h>
#include <string.h>

#include <sodium.h>

int main(void) {
    unsigned char key[crypto_secretbox_KEYBYTES];
    unsigned char nonce[crypto_secretbox_NONCEBYTES];
    unsigned char message[] = "validator libsodium";
    unsigned char cipher[sizeof(message) + crypto_secretbox_MACBYTES];
    unsigned char plain[sizeof(message)];

    if (sodium_init() < 0) {
        return 1;
    }

    randombytes_buf(key, sizeof(key));
    randombytes_buf(nonce, sizeof(nonce));
    crypto_secretbox_easy(cipher, message, sizeof(message), nonce, key);
    if (crypto_secretbox_open_easy(plain, cipher, sizeof(cipher), nonce, key) != 0) {
        return 1;
    }

    puts((const char*)plain);
    return strcmp((const char*)plain, "validator libsodium") != 0;
}
EOF
cc "$work_root/libsodium_smoke.c" -lsodium -o "$work_root/libsodium_smoke"
assert_uses_selected_libsodium "$work_root/libsodium_smoke"
"$work_root/libsodium_smoke" >"$work_root/libsodium.log"
grep -F "validator libsodium" "$work_root/libsodium.log" >/dev/null

assert_uses_selected_libsodium "$(command -v minisign)"
(
  cd "$work_root"
  printf 'phase5\n' > message.txt
  minisign -G -p pubkey -s seckey -W >/dev/null 2>&1
  minisign -S -s seckey -m message.txt -x signature.txt -t "phase5" >/dev/null 2>&1
  minisign -V -p pubkey -m message.txt -x signature.txt > verify.log 2>&1
  grep -F "verified" verify.log >/dev/null
)

assert_uses_selected_libsodium "$(command -v fastd)"
fastd --version >/dev/null

assert_uses_selected_libsodium "$(command -v curvedns)"
curvedns -h >/dev/null 2>&1 || true

assert_uses_selected_libsodium "$(command -v nix-store)"
nix-store \
  --option build-users-group '' \
  --generate-binary-cache-key phase5.test "$work_root/cache.sec" "$work_root/cache.pub" >/dev/null
test -s "$work_root/cache.sec"
test -s "$work_root/cache.pub"

assert_uses_selected_libsodium "/usr/lib/$multiarch/libzmq.so.5"
cat >"$work_root/zmq_curve_smoke.c" <<'EOF'
#include <stdio.h>
#include <zmq.h>

int main(void) {
    char public_key[41];
    char secret_key[41];

    if (zmq_curve_keypair(public_key, secret_key) != 0) {
        return 1;
    }

    puts(public_key);
    return 0;
}
EOF
cc "$work_root/zmq_curve_smoke.c" $(pkg-config --cflags --libs libzmq) -o "$work_root/zmq_curve_smoke"
assert_uses_selected_libsodium "$work_root/zmq_curve_smoke"
"$work_root/zmq_curve_smoke" >"$work_root/zmq.log"
test -s "$work_root/zmq.log"

cat >"$work_root/tox_smoke.c" <<'EOF'
#include <stdio.h>
#include <tox/tox.h>

int main(void) {
    Tox_Err_Options_New opt_err;
    Tox_Err_New new_err;
    struct Tox_Options* options = tox_options_new(&opt_err);
    Tox* tox;
    uint8_t address[TOX_ADDRESS_SIZE];
    uint8_t public_key[TOX_PUBLIC_KEY_SIZE];

    if (options == NULL) {
        fprintf(stderr, "tox_options_new failed: %d\n", opt_err);
        return 1;
    }

    tox_options_set_udp_enabled(options, false);
    tox_options_set_local_discovery_enabled(options, false);
    tox_options_set_hole_punching_enabled(options, false);

    tox = tox_new(options, &new_err);
    if (tox == NULL) {
        fprintf(stderr, "tox_new failed: %d\n", new_err);
        tox_options_free(options);
        return 1;
    }

    tox_self_get_address(tox, address);
    tox_self_get_public_key(tox, public_key);
    printf("TOX_OK %02x %02x\n", address[0], public_key[0]);
    tox_kill(tox);
    tox_options_free(options);
    return 0;
}
EOF
cc "$work_root/tox_smoke.c" $(pkg-config --cflags --libs toxcore) -o "$work_root/tox_smoke"
assert_uses_selected_libsodium "$work_root/tox_smoke"
"$work_root/tox_smoke" >"$work_root/tox.log"
grep -F "TOX_OK" "$work_root/tox.log" >/dev/null

python3 - <<'PY' >"$work_root/python.log"
from nacl.secret import SecretBox
from nacl.signing import SigningKey
from nacl.utils import random

box = SecretBox(random(SecretBox.KEY_SIZE))
message = b"hello"
nonce = random(SecretBox.NONCE_SIZE)
ciphertext = box.encrypt(message, nonce)
assert box.decrypt(ciphertext) == message
signing_key = SigningKey.generate()
signature = signing_key.sign(message).signature
assert len(signature) == 64
signing_key.verify_key.verify(message, signature)
print("PYNACL_SIGN_VERIFY_OK")
PY
grep -F "PYNACL_SIGN_VERIFY_OK" "$work_root/python.log" >/dev/null

php <<'EOF' >"$work_root/php.log"
<?php
if (!extension_loaded('sodium')) {
    fwrite(STDERR, "sodium extension unavailable\n");
    exit(1);
}
$key = random_bytes(SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$cipher = sodium_crypto_secretbox('hello', $nonce, $key);
$plain = sodium_crypto_secretbox_open($cipher, $nonce, $key);
if ($plain !== 'hello') {
    fwrite(STDERR, "secretbox round-trip failed\n");
    exit(1);
}
$keypair = sodium_crypto_sign_keypair();
$signature = sodium_crypto_sign_detached('msg', sodium_crypto_sign_secretkey($keypair));
if (!sodium_crypto_sign_verify_detached($signature, 'msg', sodium_crypto_sign_publickey($keypair))) {
    fwrite(STDERR, "signature verification failed\n");
    exit(1);
}
echo "PHP_SODIUM_OK\n";
EOF
grep -F "PHP_SODIUM_OK" "$work_root/php.log" >/dev/null

ruby <<'EOF' >"$work_root/ruby.log"
require "rbnacl"

key = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
box = RbNaCl::SecretBox.new(key)
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
ciphertext = box.encrypt(nonce, "hello")
plaintext = box.decrypt(nonce, ciphertext)
abort "decrypt failed" unless plaintext == "hello"
signing_key = RbNaCl::Signatures::Ed25519::SigningKey.generate
signature = signing_key.sign("hello")
abort "unexpected signature length" unless signature.bytesize == 64
signing_key.verify_key.verify(signature, "hello")
puts "RBNACL_SIGN_VERIFY_OK"
EOF
grep -F "RBNACL_SIGN_VERIFY_OK" "$work_root/ruby.log" >/dev/null

Rscript -e 'library(sodium); stopifnot(exists("hash")); cat("r sodium ok\n")' >"$work_root/r.log"
grep -F "r sodium ok" "$work_root/r.log" >/dev/null

vim --version | grep -F '+sodium' >/dev/null

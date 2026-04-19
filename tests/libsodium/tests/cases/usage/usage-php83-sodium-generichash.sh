#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php -r "echo sodium_bin2hex(sodium_crypto_generichash('payload')), PHP_EOL;"
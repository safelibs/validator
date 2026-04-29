#!/usr/bin/env bash
# @testcase: usage-php83-sodium-kx
# @title: PHP sodium key exchange
# @description: Derives matching client and server session keys with PHP sodium key exchange helpers.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-kx"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$client = sodium_crypto_kx_keypair();
$server = sodium_crypto_kx_keypair();
[$client_rx, $client_tx] = sodium_crypto_kx_client_session_keys($client, sodium_crypto_kx_publickey($server));
[$server_rx, $server_tx] = sodium_crypto_kx_server_session_keys($server, sodium_crypto_kx_publickey($client));
if ($client_rx !== $server_tx || $client_tx !== $server_rx) { exit(1); }
echo strlen($client_rx), PHP_EOL;
PHP

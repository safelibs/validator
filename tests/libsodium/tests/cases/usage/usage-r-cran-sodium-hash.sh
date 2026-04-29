#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-hash
# @title: R sodium hashes data
# @description: Computes a hash with the R sodium package through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e 'library(sodium); value <- hash(charToRaw("payload")); cat(length(value), "\n")'

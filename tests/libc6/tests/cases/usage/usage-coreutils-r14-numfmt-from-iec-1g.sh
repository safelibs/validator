#!/usr/bin/env bash
# @testcase: usage-coreutils-r14-numfmt-from-iec-1g
# @title: coreutils numfmt --from=iec 1G expands to 1073741824 bytes
# @description: Runs numfmt --from=iec on the IEC suffixes 1K, 1M, and 1G under LC_ALL=C and asserts each result equals the exact integer byte count (1024, 1048576, 1073741824) rather than a rounded value.
# @timeout: 60
# @tags: usage, coreutils, numfmt
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

got_k=$(LC_ALL=C numfmt --from=iec 1K)
got_m=$(LC_ALL=C numfmt --from=iec 1M)
got_g=$(LC_ALL=C numfmt --from=iec 1G)

[[ "$got_k" == "1024" ]]
[[ "$got_m" == "1048576" ]]
[[ "$got_g" == "1073741824" ]]

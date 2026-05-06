#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-robot-version-shape
# @title: xz --robot --version emits both XZ_VERSION and LIBLZMA_VERSION fields
# @description: Runs "xz --robot --version" and checks both XZ_VERSION=NNNNNNNN and LIBLZMA_VERSION=NNNNNNNN are emitted as eight-digit decimal-encoded version numbers, exercising the machine-readable version contract.
# @timeout: 30
# @tags: usage, xz, version
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xz --robot --version >"$tmpdir/version.txt"

xz_line=$(grep '^XZ_VERSION=' "$tmpdir/version.txt")
liblzma_line=$(grep '^LIBLZMA_VERSION=' "$tmpdir/version.txt")

xz_value=${xz_line#XZ_VERSION=}
liblzma_value=${liblzma_line#LIBLZMA_VERSION=}

case "$xz_value" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) echo "unexpected XZ_VERSION value: $xz_value" >&2; exit 1 ;;
esac
case "$liblzma_value" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) echo "unexpected LIBLZMA_VERSION value: $liblzma_value" >&2; exit 1 ;;
esac

# At minimum xz 5.0.0 (50000000) — sanity bound that must hold for noble.
test "$xz_value" -ge "50000000"
test "$liblzma_value" -ge "50000000"

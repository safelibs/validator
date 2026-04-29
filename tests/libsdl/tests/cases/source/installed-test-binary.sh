#!/usr/bin/env bash
# @testcase: installed-test-binary
# @title: Installed SDL test binary
# @description: Runs one packaged SDL installed test binary under dummy drivers.
# @timeout: 120
# @tags: cli, installed-test

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=dummy HOME="$tmpdir"; for c in /usr/libexec/installed-tests/SDL2/testplatform /usr/libexec/installed-tests/SDL2/testtimer; do if [[ -x "$c" ]]; then "$c" | tee "$tmpdir/out"; exit 0; fi; done; echo 'no selected SDL installed test binary found' >&2; exit 1

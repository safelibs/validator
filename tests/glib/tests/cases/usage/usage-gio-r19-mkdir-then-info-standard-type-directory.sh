#!/usr/bin/env bash
# @testcase: usage-gio-r19-mkdir-then-info-standard-type-directory
# @title: gio mkdir followed by gio info reports standard::type 2 (directory)
# @description: Runs gio mkdir to create a tmpdir subdirectory and asserts gio info -a standard::type reports the attribute line "standard::type: 2" matching the GFileType.DIRECTORY enum value, exercising the type attribute on a directory created via gio mkdir distinct from regular-file type tests.
# @timeout: 60
# @tags: usage, gio, mkdir, standard-type, r19
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio mkdir "$tmpdir/freshdir"
[[ -d "$tmpdir/freshdir" ]]
gio info -a standard::type "$tmpdir/freshdir" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'standard::type: 2'

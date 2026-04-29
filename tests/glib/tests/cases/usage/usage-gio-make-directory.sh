#!/usr/bin/env bash
# @testcase: usage-gio-make-directory
# @title: gio makes directory
# @description: Creates a directory with gio mkdir and verifies the target directory exists afterward.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-make-directory"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio mkdir "$tmpdir/tree"
test -d "$tmpdir/tree"

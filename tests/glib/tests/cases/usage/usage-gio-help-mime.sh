#!/usr/bin/env bash
# @testcase: usage-gio-help-mime
# @title: gio help describes mime subcommand
# @description: Invokes gio help mime and confirms the synopsis advertises mimetype handler management.
# @timeout: 60
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-help-mime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# `gio help` lists the available subcommands, including `mime` (some glib
# versions write the listing to stderr, so merge both streams).
gio help >"$tmpdir/help" 2>&1 || true
validator_assert_contains "$tmpdir/help" 'mime'

# `gio mime --help` prints the per-subcommand synopsis that documents
# MIMETYPE handler management.
gio mime --help >"$tmpdir/out" 2>&1 || true
validator_assert_contains "$tmpdir/out" 'mime'
validator_assert_contains "$tmpdir/out" 'MIMETYPE'

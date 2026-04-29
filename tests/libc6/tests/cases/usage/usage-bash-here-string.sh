#!/usr/bin/env bash
# @testcase: usage-bash-here-string
# @title: bash here string
# @description: Exercises bash here string through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-here-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

read -r value <<< 'here string payload'
test "$value" = 'here string payload'

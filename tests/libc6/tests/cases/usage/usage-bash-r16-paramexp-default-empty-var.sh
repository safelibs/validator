#!/usr/bin/env bash
# @testcase: usage-bash-r16-paramexp-default-empty-var
# @title: bash ${VAR:-default} expands to default when variable is empty
# @description: Sets a variable to the empty string and asserts the ${VAR:-default} parameter expansion form yields the default value, locking in the ":-" operator behavior against an empty-but-set variable — distinct from the unset-variable path.
# @timeout: 30
# @tags: usage, bash, parameter-expansion
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

EMPTY=""
got_empty=$(printf '%s' "${EMPTY:-defval}")
[[ "$got_empty" == "defval" ]]

# Sanity: when set to a non-empty value, ${VAR:-default} yields VAR.
NONEMPTY="actual"
got_nonempty=$(printf '%s' "${NONEMPTY:-defval}")
[[ "$got_nonempty" == "actual" ]]

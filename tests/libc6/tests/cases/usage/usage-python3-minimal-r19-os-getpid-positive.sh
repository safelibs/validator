#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r19-os-getpid-positive
# @title: python3 os.getpid() returns a positive integer that matches the current process namespace
# @description: Invokes python3 -c "import os; print(os.getpid())" and asserts the captured integer is greater than zero and consists entirely of digits - locking in libc getpid() exposure through the python os module.
# @timeout: 30
# @tags: usage, python3-minimal, os, pid, r19
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import os; print(os.getpid())')
[[ "$got" =~ ^[0-9]+$ ]] || {
    printf 'expected digits, got %q\n' "$got" >&2
    exit 1
}
[[ "$got" -gt 0 ]] || {
    printf 'expected positive pid, got %s\n' "$got" >&2
    exit 1
}

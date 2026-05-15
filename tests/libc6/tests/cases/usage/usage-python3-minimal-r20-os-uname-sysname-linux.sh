#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r20-os-uname-sysname-linux
# @title: python3 os.uname().sysname equals "Linux" on the ubuntu container
# @description: Invokes python3 -c "import os; print(os.uname().sysname)" inside the Ubuntu 24.04 container and asserts the captured sysname string equals "Linux" - locking in libc-backed uname syscall exposure through python3 os.uname.
# @timeout: 30
# @tags: usage, python3-minimal, os, uname, r20
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import os; print(os.uname().sysname)')
[[ "$got" == "Linux" ]] || {
    printf 'expected "Linux", got %q\n' "$got" >&2
    exit 1
}

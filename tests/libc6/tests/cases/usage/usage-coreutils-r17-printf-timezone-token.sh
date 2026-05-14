#!/usr/bin/env bash
# @testcase: usage-coreutils-r17-printf-timezone-token
# @title: printf '%(%Z)T' renders a non-empty timezone abbreviation for the current time
# @description: Invokes /usr/bin/printf with the %(%Z)T conversion against the current time (-1) and asserts the result is a non-empty token containing only A-Z and digits — locking in libc's strftime %Z resolution through the coreutils printf path.
# @timeout: 30
# @tags: usage, coreutils, printf, timezone
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(/usr/bin/printf '%(%Z)T\n' -1)
[[ -n "$got" ]] || {
    printf 'expected non-empty %%Z token\n' >&2
    exit 1
}
# %Z resolves to alphanumeric tokens like UTC, PDT, GMT, or +0000.
[[ "$got" =~ ^[A-Za-z0-9+\-]+$ ]] || {
    printf 'unexpected %%Z token shape: %q\n' "$got" >&2
    exit 1
}

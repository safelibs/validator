#!/usr/bin/env python3
from __future__ import annotations

import sys


def main() -> int:
    print(
        "phase4_host_harness.py has been retired; use testcase manifests and "
        "the original-only matrix runner.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

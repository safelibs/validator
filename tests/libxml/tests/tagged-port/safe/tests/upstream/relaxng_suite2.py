#!/usr/bin/env python3

from pathlib import Path

from inline_resource_schema_suite import run_inline_schema_suite


ROOT = Path(__file__).resolve().parents[3]

raise SystemExit(
    run_inline_schema_suite(
        conf=ROOT / "original" / "test" / "relaxng" / "testsuite.xml",
        log_name="check-relaxng-test-suite2.log",
        instance_uses_dtd_prefix=True,
        capture_errors=False,
        substitute_entities=False,
    )
)

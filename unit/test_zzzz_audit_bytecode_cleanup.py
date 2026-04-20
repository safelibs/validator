from __future__ import annotations

import shutil
import unittest
from pathlib import Path


class AuditBytecodeCleanupTests(unittest.TestCase):
    def test_removes_bytecode_from_audited_roots(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        audited_roots = (repo_root / "tools", repo_root / "unit")
        # unittest discovery imports production modules before the file audit runs.
        cache_dirs = [
            path
            for root in audited_roots
            for path in root.rglob("__pycache__")
            if path.is_dir()
        ]
        pyc_files = [
            path
            for root in audited_roots
            for path in root.rglob("*.pyc")
            if path.is_file()
        ]

        for path in pyc_files:
            path.unlink(missing_ok=True)
        for path in sorted(cache_dirs, key=lambda value: len(value.parts), reverse=True):
            shutil.rmtree(path, ignore_errors=True)

        remaining = [
            path
            for root in audited_roots
            for path in root.rglob("*")
            if path.name == "__pycache__" or path.suffix == ".pyc"
        ]
        self.assertEqual(remaining, [])

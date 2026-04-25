from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import report_ci_status


def write_proof(path: Path, *, mode: str, failed: int) -> None:
    path.write_text(
        json.dumps(
            {
                "proof_version": 2,
                "mode": mode,
                "suite": {"name": "demo", "image": "demo:latest", "apt_suite": "noble"},
                "totals": {
                    "libraries": 1,
                    "cases": 2,
                    "source_cases": 1,
                    "usage_cases": 1,
                    "passed": 2 - failed,
                    "failed": failed,
                    "casts": 2 - failed,
                },
                "libraries": [],
            },
            indent=2,
        )
        + "\n"
    )


class ReportCiStatusTests(unittest.TestCase):
    def run_root(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        return Path(tempdir.name)

    def test_port_proof_failures_are_non_blocking(self) -> None:
        root = self.run_root()
        original_proof = root / "original.json"
        port_proof = root / "port.json"
        write_proof(original_proof, mode="original", failed=0)
        write_proof(port_proof, mode="port-04-test", failed=7)

        exit_code = report_ci_status.main(
            [
                "--original-matrix-exit",
                "0",
                "--port-matrix-exit",
                "0",
                "--original-proof-path",
                str(original_proof),
                "--port-proof-path",
                str(port_proof),
            ]
        )

        self.assertEqual(exit_code, 0)

    def test_original_proof_failures_are_blocking(self) -> None:
        root = self.run_root()
        original_proof = root / "original.json"
        port_proof = root / "port.json"
        write_proof(original_proof, mode="original", failed=1)
        write_proof(port_proof, mode="port-04-test", failed=0)

        exit_code = report_ci_status.main(
            [
                "--original-matrix-exit",
                "0",
                "--port-matrix-exit",
                "0",
                "--original-proof-path",
                str(original_proof),
                "--port-proof-path",
                str(port_proof),
            ]
        )

        self.assertEqual(exit_code, 1)

    def test_nonzero_matrix_exit_code_is_returned(self) -> None:
        root = self.run_root()
        original_proof = root / "original.json"
        port_proof = root / "port.json"
        write_proof(original_proof, mode="original", failed=0)
        write_proof(port_proof, mode="port-04-test", failed=0)

        exit_code = report_ci_status.main(
            [
                "--original-matrix-exit",
                "0",
                "--port-matrix-exit",
                "17",
                "--original-proof-path",
                str(original_proof),
                "--port-proof-path",
                str(port_proof),
            ]
        )

        self.assertEqual(exit_code, 17)

    def test_invalid_proof_metadata_is_rejected(self) -> None:
        root = self.run_root()
        original_proof = root / "original.json"
        port_proof = root / "port.json"
        write_proof(original_proof, mode="original", failed=0)
        port_proof.write_text(json.dumps({"mode": "wrong", "totals": {"failed": 0}}))

        with self.assertRaisesRegex(ValidatorError, "proof mode"):
            report_ci_status.main(
                [
                    "--original-matrix-exit",
                    "0",
                    "--port-matrix-exit",
                    "0",
                    "--original-proof-path",
                    str(original_proof),
                    "--port-proof-path",
                    str(port_proof),
                ]
            )

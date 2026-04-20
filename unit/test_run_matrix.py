from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import run_matrix


FIXTURES = Path(__file__).resolve().parent / "fixtures"


def original_demo_config() -> dict[str, object]:
    return {
        "libraries": [
            {
                "name": "original-demo",
                "apt_packages": ["demo-runtime", "demo-dev"],
                "testcases": str(FIXTURES / "original-only-tests" / "original-demo" / "testcases.yml"),
            }
        ]
    }


class RunMatrixTests(unittest.TestCase):
    def run_root(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        return Path(tempdir.name)

    def make_testcase(self, command: list[str]) -> run_matrix.Testcase:
        return run_matrix.Testcase(
            id="source-demo",
            title="Source demo",
            description="Runs the source demo fixture.",
            kind="source",
            command=command,
            timeout_seconds=300,
            tags=("smoke",),
        )

    def fake_logged_run(self, failures: set[str] | None = None):
        failures = failures or set()

        def _fake(args: list[str], *, log_path: Path, cast_path: Path | None = None, **_: object) -> run_matrix.RunOutcome:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            with log_path.open("a", encoding="utf-8") as handle:
                handle.write("fixture run\n")
            if cast_path is not None:
                cast_path.parent.mkdir(parents=True, exist_ok=True)
                cast_path.write_text('{"version": 2, "width": 120, "height": 40}\n[0.0, "o", "fixture\\n"]\n')

            for index, value in enumerate(args):
                if value == "--mount" and index + 1 < len(args) and "dst=/validator/status" in args[index + 1]:
                    mount = args[index + 1]
                    src = mount.split("src=", 1)[1].split(",", 1)[0]
                    if any("dst=/override-debs" in item for item in args):
                        Path(src, "override-installed").write_text("")

            command_text = " ".join(args)
            if any(marker in command_text for marker in failures):
                return run_matrix.RunOutcome(9)
            return run_matrix.RunOutcome(0)

        return _fake

    def test_accepts_original_mode_only(self) -> None:
        invalid_mode_args = (
            ["--mode", "replacement"],
            ["--mode", "dual"],
            ["--mode", ""],
            ["--mode="],
        )
        for extra_args in invalid_mode_args:
            with self.subTest(extra_args=extra_args):
                with self.assertRaisesRegex(ValidatorError, "original"):
                    run_matrix.parse_args(["--config", "repositories.yml", *extra_args])

        args = run_matrix.parse_args(["--config", "repositories.yml"])
        self.assertEqual(args.mode, "original")

    def test_writes_per_case_results_logs_casts_and_summary(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-original-demo",
        ), mock.patch(
            "tools.run_matrix.run_logged",
            side_effect=self.fake_logged_run(),
        ):
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "original-only-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--record-casts",
                ]
            )

        self.assertEqual(exit_code, 0)
        source = json.loads(
            (artifact_root / "results" / "original-demo" / "source-echo-roundtrip.json").read_text()
        )
        usage = json.loads(
            (artifact_root / "results" / "original-demo" / "usage-client-echo.json").read_text()
        )
        summary = json.loads((artifact_root / "results" / "original-demo" / "summary.json").read_text())

        self.assertEqual(source["schema_version"], 2)
        self.assertEqual(source["mode"], "original")
        self.assertEqual(source["result_path"], "results/original-demo/source-echo-roundtrip.json")
        self.assertEqual(source["log_path"], "logs/original-demo/source-echo-roundtrip.log")
        self.assertEqual(source["cast_path"], "casts/original-demo/source-echo-roundtrip.cast")
        self.assertEqual(source["apt_packages"], ["demo-runtime", "demo-dev"])
        self.assertFalse(source["override_debs_installed"])
        self.assertEqual(usage["kind"], "usage")
        self.assertEqual(usage["client_application"], "demo-client")
        self.assertTrue((artifact_root / source["log_path"]).is_file())
        self.assertTrue((artifact_root / source["cast_path"]).is_file())

        self.assertEqual(summary["schema_version"], 2)
        self.assertEqual(summary["cases"], 2)
        self.assertEqual(summary["source_cases"], 1)
        self.assertEqual(summary["usage_cases"], 1)
        self.assertEqual(summary["passed"], 2)
        self.assertEqual(summary["failed"], 0)
        self.assertEqual(summary["casts"], 2)

    def test_record_casts_runs_bash_testcase_with_xtrace(self) -> None:
        root = self.run_root()
        testcase = self.make_testcase(["bash", "/validator/tests/demo/tests/run.sh"])

        command = run_matrix._container_command(
            image_tag="validator-demo",
            library="demo",
            testcase=testcase,
            record_casts=True,
            status_dir=root / "status",
            override_deb_dir=None,
        )

        separator = command.index("--")
        self.assertEqual(command[separator + 1 :], ["bash", "-x", "/validator/tests/demo/tests/run.sh"])

    def test_record_casts_does_not_duplicate_existing_xtrace(self) -> None:
        root = self.run_root()
        testcase = self.make_testcase(["bash", "-x", "/validator/tests/demo/tests/run.sh"])

        command = run_matrix._container_command(
            image_tag="validator-demo",
            library="demo",
            testcase=testcase,
            record_casts=True,
            status_dir=root / "status",
            override_deb_dir=None,
        )

        separator = command.index("--")
        self.assertEqual(command[separator + 1 :], ["bash", "-x", "/validator/tests/demo/tests/run.sh"])

    def test_override_root_layout_and_installed_marker(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        with self.assertRaisesRegex(ValidatorError, "matrix root"):
            run_matrix.validate_matrix_override_deb_root(FIXTURES / "original-override-debs" / "original-demo")

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-original-demo",
        ), mock.patch(
            "tools.run_matrix.run_logged",
            side_effect=self.fake_logged_run(),
        ):
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "original-only-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--override-deb-root",
                    str(FIXTURES / "original-override-debs"),
                ]
            )

        self.assertEqual(exit_code, 0)
        result = json.loads(
            (artifact_root / "results" / "original-demo" / "source-echo-roundtrip.json").read_text()
        )
        self.assertTrue(result["override_debs_installed"])

    def test_override_deb_fixture_is_valid_debian_package(self) -> None:
        if shutil.which("dpkg-deb") is None:
            self.skipTest("dpkg-deb is not installed")
        deb_path = (
            FIXTURES
            / "original-override-debs"
            / "original-demo"
            / "original-override-marker_1.0_all.deb"
        )

        completed = subprocess.run(
            ["dpkg-deb", "--field", str(deb_path), "Package"],
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)
        self.assertEqual(completed.stdout.strip(), "original-override-marker")

    def test_aggregate_failure_continues_before_returning_non_zero(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-original-demo",
        ), mock.patch(
            "tools.run_matrix.run_logged",
            side_effect=self.fake_logged_run({"echo-source.sh"}),
        ):
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "original-only-tests"),
                    "--artifact-root",
                    str(artifact_root),
                ]
            )

        self.assertNotEqual(exit_code, 0)
        source = json.loads(
            (artifact_root / "results" / "original-demo" / "source-echo-roundtrip.json").read_text()
        )
        usage = json.loads(
            (artifact_root / "results" / "original-demo" / "usage-client-echo.json").read_text()
        )
        self.assertEqual(source["status"], "failed")
        self.assertEqual(source["exit_code"], 9)
        self.assertIn("error", source)
        self.assertEqual(usage["status"], "passed")

    def test_timeout_marks_only_the_process_as_timed_out(self) -> None:
        root = self.run_root()
        log_path = root / "timeout.log"

        outcome = run_matrix.run_logged(
            ["bash", "-c", "sleep 2"],
            log_path=log_path,
            timeout_seconds=0.1,
        )

        self.assertTrue(outcome.timed_out)
        self.assertEqual(outcome.exit_code, 124)

    def test_cast_recording_preserves_stream_timing(self) -> None:
        root = self.run_root()
        log_path = root / "timed.log"
        cast_path = root / "timed.cast"

        script = (
            "import sys, time; "
            "sys.stdout.write('first\\n'); sys.stdout.flush(); "
            "time.sleep(0.25); "
            "sys.stdout.write('second\\n'); sys.stdout.flush()"
        )
        outcome = run_matrix.run_logged(
            [sys.executable, "-c", script],
            log_path=log_path,
            cast_path=cast_path,
            timeout_seconds=5,
        )

        self.assertEqual(outcome.exit_code, 0)
        lines = cast_path.read_text().splitlines()
        self.assertEqual(json.loads(lines[0])["version"], 2)
        events = [json.loads(line) for line in lines[1:]]
        self.assertGreaterEqual(len(events), 2)
        self.assertTrue(all(event[1] == "o" for event in events))
        self.assertIn("first", "".join(event[2] for event in events))
        self.assertIn("second", "".join(event[2] for event in events))

        timestamps = [float(event[0]) for event in events]
        self.assertEqual(timestamps, sorted(timestamps))
        self.assertGreater(timestamps[-1], timestamps[0] + 0.1)

    def test_cleanup_library_images_removes_cached_tags(self) -> None:
        states = {
            "demo": run_matrix.LibraryState(image_tag="validator-demo-test"),
            "missing": run_matrix.LibraryState(),
        }
        with mock.patch(
            "tools.run_matrix.subprocess.run",
            return_value=subprocess.CompletedProcess(
                args=["docker", "image", "rm", "--force", "validator-demo-test"],
                returncode=0,
                stdout="Deleted: validator-demo-test\n",
                stderr="",
            ),
        ) as subprocess_run:
            errors = run_matrix.cleanup_library_images(states)

        self.assertEqual(errors, [])
        subprocess_run.assert_called_once_with(
            ["docker", "image", "rm", "--force", "validator-demo-test"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertIsNone(states["demo"].image_tag)

    def test_list_libraries_does_not_require_testcase_manifests(self) -> None:
        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.load_manifests"
        ) as load_manifests:
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "missing-tests"),
                    "--list-libraries",
                ]
            )

        self.assertEqual(exit_code, 0)
        load_manifests.assert_not_called()

    def test_main_rejects_path_traversal_library_names_before_writing_artifacts(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        manifest = {
            "schema_version": 2,
            "suite": {"image": "ubuntu:24.04"},
            "libraries": [{"name": "../../escape"}],
        }

        with mock.patch("tools.run_matrix.load_manifest", return_value=manifest), mock.patch(
            "tools.run_matrix.select_libraries",
            return_value=manifest["libraries"],
        ):
            with self.assertRaisesRegex(ValidatorError, "invalid library name"):
                run_matrix.main(
                    [
                        "--config",
                        str(FIXTURES / "original-only-manifest.yml"),
                        "--tests-root",
                        str(FIXTURES / "original-only-tests"),
                        "--artifact-root",
                        str(artifact_root),
                    ]
                )

        self.assertFalse(artifact_root.exists())


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import json
import hashlib
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


def write_port_debs_and_lock(root: Path) -> tuple[Path, Path]:
    deb_root = root / "port-debs"
    library_root = deb_root / "original-demo"
    library_root.mkdir(parents=True, exist_ok=True)
    debs = []
    for filename, package, architecture in [
        ("demo-runtime_1.0_amd64.deb", "demo-runtime", "amd64"),
        ("demo-dev_1.0_all.deb", "demo-dev", "all"),
    ]:
        path = library_root / filename
        path.write_bytes(f"{filename}\n".encode("utf-8"))
        debs.append(
            {
                "package": package,
                "filename": filename,
                "architecture": architecture,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "size": path.stat().st_size,
                "asset_api_url": f"https://api.github.com/assets/{package}",
                "browser_download_url": f"https://github.com/assets/{filename}",
            }
        )
    lock_path = root / "port-lock.json"
    lock = {
        "schema_version": 1,
        "mode": "port-04-test",
        "generated_at": "1970-01-01T00:00:00Z",
        "source_config": "repositories.yml",
        "source_inventory": "inventory/github-port-repos.json",
        "libraries": [
            {
                "library": "original-demo",
                "repository": "safelibs/port-original-demo",
                "url": "https://github.com/safelibs/port-original-demo",
                "tag_ref": "refs/tags/v1.2.3",
                "commit": "abcdef1234567890abcdef1234567890abcdef12",
                "release_tag": "v1.2.3",
                "debs": debs,
                "unported_original_packages": [],
            }
        ],
    }
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    return deb_root, lock_path


def write_unavailable_port_lock(root: Path) -> tuple[Path, Path]:
    deb_root = root / "port-debs"
    deb_root.mkdir(parents=True, exist_ok=True)
    lock_path = root / "port-lock.json"
    lock = {
        "schema_version": 1,
        "mode": "port-04-test",
        "generated_at": "1970-01-01T00:00:00Z",
        "source_config": "repositories.yml",
        "source_inventory": "inventory/github-port-repos.json",
        "libraries": [
            {
                "library": "original-demo",
                "repository": "safelibs/port-original-demo",
                "url": "https://github.com/safelibs/port-original-demo",
                "tag_ref": None,
                "commit": None,
                "release_tag": None,
                "debs": [],
                "unported_original_packages": ["demo-runtime", "demo-dev"],
                "port_unavailable_reason": "no published release",
            }
        ],
    }
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    return deb_root, lock_path


class RunMatrixTests(unittest.TestCase):
    def test_normalize_log_text_strips_carriage_returns(self) -> None:
        self.assertEqual(run_matrix.normalize_log_text("one\r\ntwo\r\n"), "one\ntwo\n")

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
                    override_mounts = [item for item in args if "dst=/override-debs" in item]
                    if override_mounts:
                        Path(src, "override-installed").write_text("")
                        override_src = override_mounts[0].split("src=", 1)[1].split(",", 1)[0]
                        lines = []
                        for deb in sorted(Path(override_src).glob("*.deb")):
                            parts = deb.name[:-4].split("_")
                            if len(parts) >= 3:
                                lines.append(f"{parts[0]}\t{parts[1]}\t{parts[-1]}\t{deb.name}\n")
                        Path(src, "override-installed-packages.tsv").write_text("".join(lines))

            command_text = " ".join(args)
            if any(marker in command_text for marker in failures):
                return run_matrix.RunOutcome(9)
            return run_matrix.RunOutcome(0)

        return _fake

    def test_accepts_original_and_port_modes_only(self) -> None:
        invalid_mode_args = (
            ["--mode", "replacement"],
            ["--mode", "dual"],
            ["--mode", ""],
            ["--mode="],
        )
        for extra_args in invalid_mode_args:
            with self.subTest(extra_args=extra_args):
                with self.assertRaisesRegex(ValidatorError, "original.*port-04-test"):
                    run_matrix.parse_args(["--config", "repositories.yml", *extra_args])

        args = run_matrix.parse_args(["--config", "repositories.yml"])
        self.assertEqual(args.mode, "original")
        with self.assertRaisesRegex(ValidatorError, "--override-deb-root"):
            run_matrix.parse_args(["--config", "repositories.yml", "--mode", "port-04-test"])
        with self.assertRaisesRegex(ValidatorError, "--port-deb-lock"):
            run_matrix.parse_args(
                [
                    "--config",
                    "repositories.yml",
                    "--mode",
                    "port-04-test",
                    "--override-deb-root",
                    "debs",
                ]
            )
        args = run_matrix.parse_args(
            [
                "--config",
                "repositories.yml",
                "--mode",
                "port-04-test",
                "--override-deb-root",
                "debs",
                "--port-deb-lock",
                "lock.json",
            ]
        )
        self.assertEqual(args.mode, "port-04-test")
        self.assertEqual(args.port_deb_lock, Path("lock.json"))

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
        self.assertEqual(
            command[separator + 1 :],
            [
                "bash",
                "-c",
                'PS4=$1; shift; set -x; source "$@"',
                "validator-xtrace",
                run_matrix.VALIDATOR_XTRACE_PREFIX,
                "/validator/tests/demo/tests/run.sh",
            ],
        )

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
        self.assertEqual(
            command[separator + 1 :],
            [
                "bash",
                "-c",
                'PS4=$1; shift; set -x; source "$@"',
                "validator-xtrace",
                run_matrix.VALIDATOR_XTRACE_PREFIX,
                "/validator/tests/demo/tests/run.sh",
            ],
        )

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

    def test_port_mode_writes_prefixed_paths_and_install_status(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        deb_root, lock_path = write_port_debs_and_lock(root)

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
                    "--mode",
                    "port-04-test",
                    "--override-deb-root",
                    str(deb_root),
                    "--port-deb-lock",
                    str(lock_path),
                    "--record-casts",
                ]
            )

        self.assertEqual(exit_code, 0)
        result_path = artifact_root / "port-04-test" / "results" / "original-demo" / "source-echo-roundtrip.json"
        result = json.loads(result_path.read_text())
        self.assertEqual(result["mode"], "port-04-test")
        self.assertEqual(result["result_path"], "port-04-test/results/original-demo/source-echo-roundtrip.json")
        self.assertEqual(result["log_path"], "port-04-test/logs/original-demo/source-echo-roundtrip.log")
        self.assertEqual(result["cast_path"], "port-04-test/casts/original-demo/source-echo-roundtrip.cast")
        self.assertTrue(result["override_debs_installed"])
        self.assertEqual(result["port_repository"], "safelibs/port-original-demo")
        self.assertEqual(result["port_release_tag"], "v1.2.3")
        self.assertEqual([deb["package"] for deb in result["port_debs"]], ["demo-runtime", "demo-dev"])
        self.assertEqual(result["unported_original_packages"], [])
        self.assertEqual(
            [item["package"] for item in result["override_installed_packages"]],
            ["demo-runtime", "demo-dev"],
        )
        summary = json.loads(
            (artifact_root / "port-04-test" / "results" / "original-demo" / "summary.json").read_text()
        )
        self.assertEqual(summary["mode"], "port-04-test")

    def test_port_mode_marks_unavailable_ports_failed_without_container_run(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        deb_root, lock_path = write_unavailable_port_lock(root)

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.ensure_library_image",
        ) as ensure_image:
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "original-only-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--mode",
                    "port-04-test",
                    "--override-deb-root",
                    str(deb_root),
                    "--port-deb-lock",
                    str(lock_path),
                ]
            )

        self.assertEqual(exit_code, 0)
        ensure_image.assert_not_called()
        result = json.loads(
            (artifact_root / "port-04-test" / "results" / "original-demo" / "source-echo-roundtrip.json").read_text()
        )
        self.assertEqual(result["status"], "failed")
        self.assertFalse(result["override_debs_installed"])
        self.assertEqual(result["port_debs"], [])
        self.assertEqual(result["override_installed_packages"], [])
        self.assertEqual(result["port_unavailable_reason"], "no published release")
        summary = json.loads(
            (artifact_root / "port-04-test" / "results" / "original-demo" / "summary.json").read_text()
        )
        self.assertEqual(summary["passed"], 0)
        self.assertEqual(summary["failed"], 2)

    def test_port_mode_rejects_hash_mismatch_and_extra_debs(self) -> None:
        root = self.run_root()
        deb_root, lock_path = write_port_debs_and_lock(root)
        (deb_root / "original-demo" / "extra_1.0_amd64.deb").write_text("extra")

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()):
            with self.assertRaisesRegex(ValidatorError, "extra"):
                run_matrix.main(
                    [
                        "--config",
                        str(FIXTURES / "original-only-manifest.yml"),
                        "--tests-root",
                        str(FIXTURES / "original-only-tests"),
                        "--artifact-root",
                        str(root / "artifacts"),
                        "--mode",
                        "port-04-test",
                        "--override-deb-root",
                        str(deb_root),
                        "--port-deb-lock",
                        str(lock_path),
                    ]
        )

        (deb_root / "original-demo" / "extra_1.0_amd64.deb").unlink()
        runtime_deb = deb_root / "original-demo" / "demo-runtime_1.0_amd64.deb"
        runtime_deb.write_bytes(b"x" * runtime_deb.stat().st_size)
        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()):
            with self.assertRaisesRegex(ValidatorError, "sha256 mismatch"):
                run_matrix.main(
                    [
                        "--config",
                        str(FIXTURES / "original-only-manifest.yml"),
                        "--tests-root",
                        str(FIXTURES / "original-only-tests"),
                        "--artifact-root",
                        str(root / "artifacts"),
                        "--mode",
                        "port-04-test",
                        "--override-deb-root",
                        str(deb_root),
                        "--port-deb-lock",
                        str(lock_path),
                    ]
                )

    def test_port_install_marker_without_package_status_fails(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        deb_root, lock_path = write_port_debs_and_lock(root)

        def fake_without_tsv(*args: object, **kwargs: object) -> run_matrix.RunOutcome:
            command = args[0]
            log_path = kwargs["log_path"]
            log_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text("fixture run\n")
            for index, value in enumerate(command):
                if value == "--mount" and index + 1 < len(command) and "dst=/validator/status" in command[index + 1]:
                    src = command[index + 1].split("src=", 1)[1].split(",", 1)[0]
                    Path(src, "override-installed").write_text("")
            return run_matrix.RunOutcome(0)

        with mock.patch("tools.run_matrix.load_manifest", return_value=original_demo_config()), mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-original-demo",
        ), mock.patch("tools.run_matrix.run_logged", side_effect=fake_without_tsv):
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "original-only-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--mode",
                    "port-04-test",
                    "--override-deb-root",
                    str(deb_root),
                    "--port-deb-lock",
                    str(lock_path),
                ]
            )

        self.assertNotEqual(exit_code, 0)
        result = json.loads(
            (artifact_root / "port-04-test" / "results" / "original-demo" / "source-echo-roundtrip.json").read_text()
        )
        self.assertEqual(result["status"], "failed")
        self.assertIn("package status file is missing", result["error"])

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

    def test_recorded_output_strips_validator_xtrace_markers(self) -> None:
        text = (
            "__VALIDATOR_XTRACE__ source /tmp/case.sh\r\n"
            "payload"
            "___VALIDATOR_XTRACE__ validator_assert_contains /tmp/out payload\r\n"
            "done\r\n"
        )

        self.assertEqual(
            run_matrix.normalize_recorded_output_text(text),
            "payload\n" "done\n",
        )

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

    def test_deterministic_cast_recording_uses_stable_stream_order(self) -> None:
        root = self.run_root()
        log_path = root / "deterministic.log"
        cast_path = root / "deterministic.cast"

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
            deterministic_cast=True,
        )

        self.assertEqual(outcome.exit_code, 0)
        events = [json.loads(line) for line in cast_path.read_text().splitlines()[1:]]
        self.assertGreaterEqual(len(events), 2)
        self.assertIn("first", "".join(event[2] for event in events))
        self.assertIn("second", "".join(event[2] for event in events))

        timestamps = [float(event[0]) for event in events]
        self.assertEqual(
            timestamps,
            [
                round(index * run_matrix.DETERMINISTIC_CAST_EVENT_INTERVAL_SECONDS, 6)
                for index in range(len(events))
            ],
        )

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

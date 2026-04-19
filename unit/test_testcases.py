from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import yaml

from tools import ValidatorError
from tools import testcases


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


class TestcaseManifestTests(unittest.TestCase):
    def test_loads_original_only_fixture_manifest(self) -> None:
        manifest = testcases.load_testcase_manifest(
            FIXTURES / "original-only-tests" / "original-demo" / "testcases.yml",
            library="original-demo",
        )

        self.assertEqual(manifest.library, "original-demo")
        self.assertEqual(manifest.apt_packages, ("demo-runtime", "demo-dev"))
        self.assertEqual([case.id for case in manifest.testcases], ["source-echo-roundtrip", "usage-client-echo"])
        self.assertIsNone(manifest.testcases[0].client_application)
        self.assertEqual(manifest.testcases[1].client_application, "demo-client")

    def test_load_manifests_requires_apt_package_order_to_match_config(self) -> None:
        config = original_demo_config()
        loaded = testcases.load_manifests(config, tests_root=FIXTURES / "original-only-tests")
        self.assertEqual(tuple(loaded), ("original-demo",))

        mismatched = dict(config)
        entry = dict(config["libraries"][0])
        entry["apt_packages"] = ["demo-dev", "demo-runtime"]
        mismatched["libraries"] = [entry]

        with self.assertRaisesRegex(ValidatorError, "apt_packages mismatch"):
            testcases.load_manifests(mismatched, tests_root=FIXTURES / "original-only-tests")

    def test_zero_testcases_are_allowed_for_manifest_only_but_rejected_for_selected_load(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            library_root = root / "empty-lib"
            library_root.mkdir(parents=True)
            (library_root / "testcases.yml").write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "empty-lib",
                        "apt_packages": ["empty-runtime"],
                        "testcases": [],
                    },
                    sort_keys=False,
                )
            )
            manifest = testcases.load_testcase_manifest(library_root / "testcases.yml", library="empty-lib")
            self.assertEqual(manifest.testcases, ())

            config = {
                "libraries": [
                    {
                        "name": "empty-lib",
                        "apt_packages": ["empty-runtime"],
                        "testcases": str(library_root / "testcases.yml"),
                    }
                ]
            }
            with self.assertRaisesRegex(ValidatorError, "zero testcases"):
                testcases.load_manifests(config, tests_root=root)
            loaded = testcases.load_manifests(config, tests_root=root, require_testcases=False)
            self.assertEqual(loaded["empty-lib"].testcases, ())

    def test_rejects_invalid_case_ids_and_unsafe_commands(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        cases = [
            ({"id": "BadID"}, "testcase id"),
            ({"command": ["bash", "/validator/tests/other/tests/run.sh"]}, "must stay under"),
            ({"command": ["bash", "../run.sh"]}, "path segments"),
            ({"command": ["bash", ".."]}, "path segments"),
            ({"command": ["bash", "-lc", "exec /validator/tests/other/tests/run.sh"]}, "must stay under"),
            (
                {"command": ["bash", "LD_LIBRARY_PATH=/validator/tests/demo/lib:/validator/tests/other/lib"]},
                "must stay under",
            ),
            (
                {
                    "command": [
                        "bash",
                        "-lc",
                        "LD_LIBRARY_PATH=/validator/tests/demo/lib:/validator/tests/other/lib true",
                    ]
                },
                "must stay under",
            ),
            ({"command": ["bash", "-lc", "cd ../other && true"]}, "path segments"),
            ({"command": ["bash", "PATH=/validator/tests/demo/bin:../bin"]}, "path segments"),
            ({"command": ["bash", "-lc", f"printf x >{repo_root / 'out'}"]}, "repository-host"),
            ({"command": ["relative/script.sh"]}, "first element"),
        ]

        base = {
            "id": "source-valid-case",
            "title": "Valid title",
            "description": "Valid description text",
            "kind": "source",
            "command": ["bash", "/validator/tests/demo/tests/run.sh"],
            "timeout_seconds": 1,
            "tags": [],
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "demo"
            root.mkdir(parents=True)
            for update, message in cases:
                payload = {
                    "schema_version": 1,
                    "library": "demo",
                    "apt_packages": ["demo-runtime"],
                    "testcases": [dict(base, **update)],
                }
                path = root / "testcases.yml"
                path.write_text(yaml.safe_dump(payload, sort_keys=False))
                with self.subTest(update=update):
                    with self.assertRaisesRegex(ValidatorError, message):
                        testcases.load_testcase_manifest(path, library="demo")

    def test_allows_colon_path_lists_under_selected_library(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "demo"
            root.mkdir(parents=True)
            path = root / "testcases.yml"
            path.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                        "testcases": [
                            {
                                "id": "source-valid-case",
                                "title": "Valid title",
                                "description": "Valid description text",
                                "kind": "source",
                                "command": [
                                    "bash",
                                    "LD_LIBRARY_PATH=/validator/tests/demo/lib:/validator/tests/demo/lib64",
                                ],
                                "timeout_seconds": 1,
                                "tags": [],
                            }
                        ],
                    },
                    sort_keys=False,
                )
            )

            manifest = testcases.load_testcase_manifest(path, library="demo")

        self.assertEqual(
            manifest.testcases[0].command[1],
            "LD_LIBRARY_PATH=/validator/tests/demo/lib:/validator/tests/demo/lib64",
        )

    def test_usage_cases_must_reference_dependent_identifier(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "demo"
            fixture_root = root / "tests" / "fixtures"
            fixture_root.mkdir(parents=True)
            (fixture_root / "dependents.json").write_text(json.dumps({"dependents": [{"name": "known-client"}]}))
            manifest_path = root / "testcases.yml"
            manifest_path.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                        "testcases": [
                            {
                                "id": "usage-known-client",
                                "title": "Usage title",
                                "description": "Usage description",
                                "kind": "usage",
                                "client_application": "missing-client",
                                "command": ["bash", "/validator/tests/demo/tests/run.sh"],
                                "timeout_seconds": 1,
                                "tags": [],
                            }
                        ],
                    },
                    sort_keys=False,
                )
            )

            with self.assertRaisesRegex(ValidatorError, "client_application"):
                testcases.load_testcase_manifest(manifest_path, library="demo")

    def test_extract_dependent_identifiers_supports_existing_fixture_shapes(self) -> None:
        payload = {
            "dependents": [
                {
                    "name": "dep-name",
                    "source_package": "dep-source",
                    "packages": [" dep-bin ", ""],
                    "package_dependencies": [{"package": "dep-package"}],
                    "dependency_paths": [
                        {
                            "binary_package": "dep-path-bin",
                            "source_package": "dep-path-source",
                        }
                    ],
                }
            ],
            "runtime_dependents": [
                {
                    "runtime_package": "runtime-bin",
                    "binary_examples": ["runtime-example"],
                }
            ],
            "build_time_dependents": [
                {
                    "binary_package": "build-bin",
                    "related_packages": ["build-related"],
                }
            ],
            "packages": [
                {
                    "package": "top-package",
                    "used_by": ["top-user"],
                }
            ],
            "selected_applications": [
                {
                    "software_name": "Selected App",
                    "slug": "selected-app",
                }
            ],
        }

        self.assertEqual(
            testcases.extract_dependent_identifiers(payload),
            {
                "dep-name",
                "dep-source",
                "dep-bin",
                "dep-package",
                "dep-path-bin",
                "dep-path-source",
                "runtime-bin",
                "runtime-example",
                "build-bin",
                "build-related",
                "top-package",
                "top-user",
                "Selected App",
                "selected-app",
            },
        )

    def test_testcase_result_sort_key_uses_library_and_case_id(self) -> None:
        rows = [
            {"library": "beta", "testcase_id": "case-a"},
            {"library": "alpha", "testcase_id": "case-b"},
        ]
        self.assertEqual(
            sorted(rows, key=testcases.testcase_result_sort_key),
            [{"library": "alpha", "testcase_id": "case-b"}, {"library": "beta", "testcase_id": "case-a"}],
        )


if __name__ == "__main__":
    unittest.main()

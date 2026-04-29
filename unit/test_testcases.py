from __future__ import annotations

import json
import stat
import tempfile
import textwrap
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


def _write_executable(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents)
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def _source_script(case_id: str = "source-demo", *, extra_directives: str = "") -> str:
    body = textwrap.dedent(
        f"""\
        #!/usr/bin/env bash
        # @testcase: {case_id}
        # @title: Demo title
        # @description: Demo description that exercises the source surface.
        # @timeout: 30
        # @tags: smoke
        {extra_directives}
        set -euo pipefail
        echo demo
        """
    )
    return body


def _usage_script(
    case_id: str = "usage-known-client",
    *,
    client: str = "known-client",
    title: str = "Known client smoke",
    description: str = "Runs known-client against a small fixture and verifies output.",
    timeout: int = 30,
    tags: str = "client",
) -> str:
    body = textwrap.dedent(
        f"""\
        #!/usr/bin/env bash
        # @testcase: {case_id}
        # @title: {title}
        # @description: {description}
        # @timeout: {timeout}
        # @tags: {tags}
        # @client: {client}

        set -euo pipefail
        echo {case_id}
        """
    )
    return body


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

    def test_load_testcase_manifest_rejects_forbidden_manifest_fields(self) -> None:
        cases = [
            ({"override_packages": ["demo-runtime"]}, "forbidden package-list field"),
            ({"extra_packages": ["demo-runtime"]}, "forbidden package-list field"),
            ({"archive": {}}, "forbidden schema field"),
            ({"unexpected": True}, "unsupported fields"),
            ({"testcases": []}, "unsupported fields"),
        ]

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = root / "testcases.yml"
            config = {
                "libraries": [
                    {
                        "name": "demo",
                        "apt_packages": ["demo-runtime"],
                        "testcases": str(manifest_path),
                    }
                ]
            }
            for update, message in cases:
                payload = {
                    "schema_version": 1,
                    "library": "demo",
                    "apt_packages": ["demo-runtime"],
                    **update,
                }
                manifest_path.write_text(yaml.safe_dump(payload, sort_keys=False))
                with self.subTest(update=update):
                    with self.assertRaisesRegex(ValidatorError, message):
                        testcases.load_manifests(config, tests_root=root, require_testcases=False)

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

    def test_rejects_invalid_case_ids_and_missing_directives(self) -> None:
        cases = [
            (
                "#!/usr/bin/env bash\n# @testcase: BadID\n# @title: t\n# @description: d\n# @timeout: 1\n# @tags:\nset -e\n",
                "testcase id must match",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: 1\nset -e\n",
                "missing directives",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: not-a-number\n# @tags:\nset -e\n",
                "@timeout must be an integer",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: 99999\n# @tags:\nset -e\n",
                "@timeout must be between",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: 1\n# @tags: ,\nset -e\n",
                "@tags entries must be non-empty",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: 1\n# @tags:\n# @bogus: x\nset -e\n",
                "unknown @bogus directive",
            ),
            (
                "#!/usr/bin/env bash\n# @testcase: source-demo\n# @title: t\n# @description: d\n# @timeout: 1\n# @tags:\n# @client: anything\nset -e\n",
                "must not define @client",
            ),
        ]
        with tempfile.TemporaryDirectory() as tmp:
            library_root = Path(tmp) / "demo"
            (library_root / "tests" / "cases" / "source").mkdir(parents=True)
            manifest_path = library_root / "testcases.yml"
            manifest_path.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                    },
                    sort_keys=False,
                )
            )
            script_path = library_root / "tests" / "cases" / "source" / "demo.sh"
            for body, message in cases:
                _write_executable(script_path, body)
                with self.subTest(message=message):
                    with self.assertRaisesRegex(ValidatorError, message):
                        testcases.load_testcase_manifest(manifest_path, library="demo")

    def test_usage_cases_must_reference_dependent_identifier(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            library_root = Path(tmp) / "demo"
            (library_root / "tests" / "fixtures").mkdir(parents=True)
            (library_root / "tests" / "fixtures" / "dependents.json").write_text(
                json.dumps({"dependents": [{"name": "known-client"}]})
            )
            _write_executable(
                library_root / "tests" / "cases" / "usage" / "usage-missing-client.sh",
                _usage_script("usage-missing-client", client="missing-client"),
            )
            (library_root / "testcases.yml").write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                    },
                    sort_keys=False,
                )
            )

            with self.assertRaisesRegex(ValidatorError, "@client"):
                testcases.load_testcase_manifest(library_root / "testcases.yml", library="demo")

    def test_validate_usage_case_artifacts_accepts_compact_dependent_fixture(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tests_root = Path(tmp)
            library_root = tests_root / "demo"
            usage_root = library_root / "tests" / "cases" / "usage"
            fixture_root = library_root / "tests" / "fixtures"
            usage_root.mkdir(parents=True)
            fixture_root.mkdir(parents=True)
            _write_executable(
                usage_root / "usage-known-client.sh",
                _usage_script("usage-known-client"),
            )
            (library_root / "Dockerfile").write_text(
                "FROM scratch\nRUN apt-get install -y --no-install-recommends known-client\n"
            )
            fixture_root.joinpath("dependents.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "dependents": [
                            {
                                "name": "known-client",
                                "packages": ["known-client"],
                                "description": "known-client client exercised by usage testcases.",
                            }
                        ],
                    }
                )
            )
            manifest_path = library_root / "testcases.yml"
            manifest_path.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                    },
                    sort_keys=False,
                )
            )
            config = {
                "libraries": [
                    {
                        "name": "demo",
                        "apt_packages": ["demo-runtime"],
                        "testcases": str(manifest_path),
                    }
                ]
            }

            manifests = testcases.load_manifests(config, tests_root=tests_root)
            testcases.validate_usage_case_artifacts(manifests, tests_root=tests_root)

    def test_validate_usage_case_artifacts_rejects_missing_docker_dependency(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tests_root = Path(tmp)
            library_root = tests_root / "demo"
            usage_root = library_root / "tests" / "cases" / "usage"
            fixture_root = library_root / "tests" / "fixtures"
            usage_root.mkdir(parents=True)
            fixture_root.mkdir(parents=True)
            _write_executable(
                usage_root / "usage-known-client.sh",
                _usage_script("usage-known-client"),
            )
            (library_root / "Dockerfile").write_text("FROM scratch\n")
            fixture_root.joinpath("dependents.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "dependents": [
                            {
                                "name": "known-client",
                                "packages": ["known-client"],
                                "description": "known-client client exercised by usage testcases.",
                            }
                        ],
                    }
                )
            )
            manifest_path = library_root / "testcases.yml"
            manifest_path.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "apt_packages": ["demo-runtime"],
                    },
                    sort_keys=False,
                )
            )
            config = {
                "libraries": [
                    {
                        "name": "demo",
                        "apt_packages": ["demo-runtime"],
                        "testcases": str(manifest_path),
                    }
                ]
            }

            manifests = testcases.load_manifests(config, tests_root=tests_root)
            with self.assertRaisesRegex(ValidatorError, "does not install dependent packages"):
                testcases.validate_usage_case_artifacts(manifests, tests_root=tests_root)

    def test_validate_usage_case_artifacts_rejects_historical_dependent_fixture_fields(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "dependents.json"
            path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "library": "demo",
                        "dependents": [{"name": "known-client", "packages": ["known-client"]}],
                        "dependency_paths": [],
                    }
                )
            )

            with self.assertRaisesRegex(ValidatorError, "compact phase 5 schema"):
                testcases.validate_sanitized_dependent_fixture(
                    path,
                    library="demo",
                    used_clients={"known-client"},
                )

    def test_summarize_manifests_counts_usage_cases(self) -> None:
        manifest = testcases.TestcaseManifest(
            library="demo",
            schema_version=1,
            apt_packages=("demo-runtime",),
            testcases=(
                testcases.Testcase(
                    id="source-demo",
                    title="Source demo",
                    description="Source demo",
                    kind="source",
                    command=("bash", "/validator/tests/demo/tests/cases/source/source-demo.sh"),
                    timeout_seconds=1,
                    tags=(),
                ),
                testcases.Testcase(
                    id="usage-demo-client",
                    title="Usage demo",
                    description="Runs demo-client with a fixture.",
                    kind="usage",
                    command=("bash", "/validator/tests/demo/tests/cases/usage/usage-demo-client.sh"),
                    timeout_seconds=1,
                    tags=(),
                    client_application="demo-client",
                ),
            ),
        )

        self.assertEqual(
            testcases.summarize_manifests({"demo": manifest}),
            [{"library": "demo", "source_cases": 1, "usage_cases": 1, "total_cases": 2}],
        )

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

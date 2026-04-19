from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import yaml

import tools as tools_common
from tools import ValidatorError, select_libraries
from tools import github_auth
from tools import inventory


REPO_ROOT = Path(__file__).resolve().parents[1]


class InventoryTests(unittest.TestCase):
    def load_repo_manifest(self) -> dict[str, object]:
        return yaml.safe_load((REPO_ROOT / "repositories.yml").read_text())

    def write_manifest(self, payload: dict[str, object]) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        path = Path(tempdir.name) / "repositories.yml"
        path.write_text(yaml.safe_dump(payload, sort_keys=False))
        return path

    def test_repositories_yml_loads_as_v2_original_manifest(self) -> None:
        manifest = inventory.load_manifest(REPO_ROOT / "repositories.yml")
        self.assertEqual(manifest["schema_version"], 2)
        self.assertEqual([entry["name"] for entry in manifest["libraries"]], list(inventory.LIBRARY_ORDER))
        for entry in manifest["libraries"]:
            library = entry["name"]
            self.assertEqual(
                tuple(entry["apt_packages"]),
                inventory.CANONICAL_APT_PACKAGES[library],
            )
            self.assertEqual(entry["testcases"], f"tests/{library}/testcases.yml")
            self.assertEqual(
                entry["fixtures"],
                {"dependents": f"tests/{library}/tests/fixtures/dependents.json"},
            )

    def test_load_manifest_rejects_schema_version_drift(self) -> None:
        payload = self.load_repo_manifest()
        payload["schema_version"] = 1
        with self.assertRaisesRegex(ValidatorError, "schema_version must be 2"):
            inventory.load_manifest(self.write_manifest(payload))

    def test_load_manifest_rejects_library_order_drift(self) -> None:
        payload = self.load_repo_manifest()
        libraries = payload["libraries"]
        libraries[0], libraries[1] = libraries[1], libraries[0]
        with self.assertRaisesRegex(ValidatorError, "fixed v2 order"):
            inventory.load_manifest(self.write_manifest(payload))

    def test_load_manifest_rejects_canonical_package_drift(self) -> None:
        payload = self.load_repo_manifest()
        payload["libraries"][0]["apt_packages"] = ["libcjson-dev", "libcjson1"]
        with self.assertRaisesRegex(ValidatorError, "canonical ordered package list"):
            inventory.load_manifest(self.write_manifest(payload))

    def test_load_manifest_rejects_legacy_and_alias_fields(self) -> None:
        cases = [
            ("top-level legacy repositories", {"repositories": []}, "repositories"),
            ("package alias", {"libraries": [dict(self.load_repo_manifest()["libraries"][0], verify_packages=[])]}, "forbidden package-list field"),
            ("legacy build field", {"libraries": [dict(self.load_repo_manifest()["libraries"][0], build={})]}, "forbidden schema field"),
            (
                "cve fixture key",
                {
                    "libraries": [
                        dict(
                            self.load_repo_manifest()["libraries"][0],
                            fixtures={
                                "dependents": "tests/cjson/tests/fixtures/dependents.json",
                                "relevant_cves": "tests/cjson/tests/fixtures/relevant_cves.json",
                            },
                        )
                    ]
                },
                "unsupported fields",
            ),
            (
                "cve fixture path",
                {
                    "libraries": [
                        dict(
                            self.load_repo_manifest()["libraries"][0],
                            fixtures={
                                "dependents": "tests/cjson/tests/fixtures/relevant_cves.json",
                            },
                        )
                    ]
                },
                "must not reference CVE or security fixtures",
            ),
        ]
        for _, update, message in cases:
            with self.subTest(update=update):
                payload = self.load_repo_manifest()
                if "libraries" in update:
                    payload["libraries"][0] = update["libraries"][0]
                else:
                    payload.update(update)
                with self.assertRaisesRegex(ValidatorError, message):
                    inventory.load_manifest(self.write_manifest(payload))

    def test_load_manifest_rejects_missing_referenced_paths(self) -> None:
        payload = self.load_repo_manifest()
        payload["libraries"][0]["testcases"] = "tests/cjson/missing-testcases.yml"
        with self.assertRaisesRegex(ValidatorError, "path does not exist"):
            inventory.load_manifest(self.write_manifest(payload))

    def test_select_libraries_preserves_manifest_order_and_rejects_bad_selection(self) -> None:
        manifest = inventory.load_manifest(REPO_ROOT / "repositories.yml")
        selected = select_libraries(manifest, ["libpng", "cjson"])
        self.assertEqual([entry["name"] for entry in selected], ["cjson", "libpng"])

        with self.assertRaisesRegex(ValidatorError, "duplicates"):
            select_libraries(manifest, ["cjson", "cjson"])
        with self.assertRaisesRegex(ValidatorError, "unknown libraries"):
            select_libraries(manifest, ["missing"])


class GithubAuthTests(unittest.TestCase):
    def test_effective_github_token_prefers_gh_token(self) -> None:
        env = {
            "GH_TOKEN": "preferred-token",
            "SAFELIBS_REPO_TOKEN": "fallback-token",
        }
        self.assertEqual(github_auth.effective_github_token(env), "preferred-token")

    def test_github_git_url_falls_back_to_safelibs_repo_token(self) -> None:
        env = {"SAFELIBS_REPO_TOKEN": "token:/with?chars"}
        self.assertEqual(
            github_auth.github_git_url("example/port-cjson", env),
            "https://x-access-token:token%3A%2Fwith%3Fchars@github.com/example/port-cjson.git",
        )

    def test_effective_github_token_falls_back_to_gh_auth_token(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value="/usr/bin/gh"), mock.patch(
            "tools.github_auth.subprocess.run",
            return_value=subprocess.CompletedProcess(
                args=["gh", "auth", "token"],
                returncode=0,
                stdout="gh-cli-token\n",
                stderr="",
            ),
        ) as fake_run:
            self.assertEqual(github_auth.effective_github_token({}), "gh-cli-token")

        self.assertEqual(fake_run.call_args.kwargs["env"]["GH_PROMPT_DISABLED"], "1")

    def test_github_git_url_falls_back_to_anonymous_https_without_token(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value=None):
            self.assertEqual(
                github_auth.github_git_url("example/port-cjson", {}),
                "https://github.com/example/port-cjson.git",
            )

    def test_run_git_disables_terminal_prompts(self) -> None:
        with mock.patch("tools.github_auth.run") as fake_run:
            github_auth.run_git(["git", "status"], capture_output=True)

        env = fake_run.call_args.kwargs["env"]
        self.assertEqual(env["GIT_TERMINAL_PROMPT"], "0")
        self.assertTrue(env["GIT_SSH_COMMAND"].startswith("ssh -oBatchMode=yes"))


class CommonToolsTests(unittest.TestCase):
    def test_run_redacts_authenticated_github_urls_and_tokens_on_failure(self) -> None:
        token = "secret-token"
        token_url = f"https://x-access-token:{token}@github.com/example/port-libuv.git"
        failure = subprocess.CalledProcessError(
            128,
            ["git", "clone", token_url],
            stderr=f"fatal: unable to access '{token_url}': token={token}",
        )

        with mock.patch("tools.subprocess.run", side_effect=failure):
            with self.assertRaises(ValidatorError) as ctx:
                tools_common.run(
                    ["git", "clone", token_url],
                    env={"GH_TOKEN": token},
                )

        message = str(ctx.exception)
        self.assertNotIn(token, message)
        self.assertIn("https://REDACTED@github.com/example/port-libuv.git", message)
        self.assertIn("token=REDACTED", message)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import tools as tools_common
from tools import ValidatorError
from tools import github_auth
from tools import inventory
from unit import commit_all, init_repo, repository_entry, run_git, write_manifest


class InventoryTests(unittest.TestCase):
    def test_select_tagged_scope_filters_and_sorts_port_repos(self) -> None:
        github_rows = [
            {
                "name": "apt-repo",
                "nameWithOwner": "safelibs/apt-repo",
                "url": "https://example.invalid/apt-repo",
                "defaultBranchRef": {"name": "main"},
            },
            {
                "name": "port-giflib",
                "nameWithOwner": "safelibs/port-giflib",
                "url": "https://example.invalid/port-giflib",
                "defaultBranchRef": {"name": "main"},
            },
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "develop"},
            },
            {
                "name": "port-libdemo",
                "nameWithOwner": "safelibs/port-libdemo",
                "url": "https://example.invalid/port-libdemo",
                "defaultBranchRef": {"name": "main"},
            },
        ]

        def probe(github_repo: str, tag_ref: str) -> bool:
            return (github_repo, tag_ref) in {
                ("safelibs/port-cjson", "refs/tags/cjson/04-test"),
                ("safelibs/port-giflib", "refs/tags/giflib/04-test"),
                ("safelibs/port-libdemo", "refs/tags/libdemo/04-test"),
            }

        filtered = inventory.select_tagged_scope(
            github_rows,
            supported_libraries={"cjson", "giflib", "libdemo"},
            probe=probe,
        )
        self.assertEqual(
            filtered,
            [
                {
                    "library": "cjson",
                    "nameWithOwner": "safelibs/port-cjson",
                    "url": "https://example.invalid/port-cjson",
                    "default_branch": "develop",
                    "tag_ref": "refs/tags/cjson/04-test",
                },
                {
                    "library": "giflib",
                    "nameWithOwner": "safelibs/port-giflib",
                    "url": "https://example.invalid/port-giflib",
                    "default_branch": "main",
                    "tag_ref": "refs/tags/giflib/04-test",
                },
                {
                    "library": "libdemo",
                    "nameWithOwner": "safelibs/port-libdemo",
                    "url": "https://example.invalid/port-libdemo",
                    "default_branch": "main",
                    "tag_ref": "refs/tags/libdemo/04-test",
                },
            ],
        )

    def test_merge_apt_repo_metadata_copies_apt_fields_and_non_apt_defaults(self) -> None:
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "verify_packages": ["libcjson1"],
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered_rows = [
            {
                "library": "cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "default_branch": "main",
                "tag_ref": "refs/tags/cjson/04-test",
            },
            {
                "library": "libexif",
                "nameWithOwner": "safelibs/port-libexif",
                "url": "https://example.invalid/port-libexif",
                "default_branch": "main",
                "tag_ref": "refs/tags/libexif/04-test",
            },
        ]

        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered_rows,
            verified_at="2026-04-12T00:00:00Z",
        )

        self.assertEqual(manifest["archive"], apt_manifest["archive"])
        self.assertEqual(manifest["inventory"]["tag_probe_rule"], inventory.TAG_PROBE_RULE)
        cjson = manifest["repositories"][0]
        self.assertEqual(cjson["verify_packages"], ["libcjson1"])
        self.assertEqual(cjson["build"], {"mode": "safe-debian", "artifact_globs": ["*.deb"]})
        self.assertEqual(cjson["validator"]["imports"], inventory.VALIDATOR_IMPORTS["cjson"])
        self.assertEqual(cjson["validator"]["import_excludes"], [])
        self.assertEqual(cjson["fixtures"]["dependents"]["source"], "copy-staged-root")

        libexif = manifest["repositories"][1]
        self.assertEqual(libexif["github_repo"], "safelibs/port-libexif")
        self.assertEqual(libexif["build"], {"mode": "safe-debian", "artifact_globs": ["*.deb"]})
        self.assertEqual(libexif["validator"]["imports"], inventory.VALIDATOR_IMPORTS["libexif"])

    def test_merge_apt_repo_metadata_rejects_unsupported_tagged_repo(self) -> None:
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [],
        }
        filtered_rows = [
            {
                "library": "libdemo",
                "nameWithOwner": "safelibs/port-libdemo",
                "url": "https://example.invalid/port-libdemo",
                "default_branch": "main",
                "tag_ref": "refs/tags/libdemo/04-test",
            }
        ]

        with self.assertRaisesRegex(ValidatorError, "not present in apt-repo metadata"):
            inventory.merge_apt_repo_metadata(
                apt_manifest,
                filtered_rows,
                verified_at="2026-04-12T00:00:00Z",
            )

    def test_verify_scope_rejects_manifest_ref_drift(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            }
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = inventory.select_tagged_scope(
            github_rows,
            supported_libraries={"cjson"},
            probe=lambda *_: True,
        )
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )
        manifest["repositories"][0]["ref"] = "refs/tags/cjson/03-build"

        with self.assertRaisesRegex(ValidatorError, "ref mismatch"):
            inventory.verify_scope(
                github_rows,
                filtered,
                manifest,
                supported_libraries={"cjson"},
                probe=lambda *_: True,
            )

    def test_verify_scope_rejects_manifest_github_repo_drift(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            }
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = inventory.select_tagged_scope(
            github_rows,
            supported_libraries={"cjson"},
            probe=lambda *_: True,
        )
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )
        manifest["repositories"][0]["github_repo"] = "safelibs/port-wrong"

        with self.assertRaisesRegex(ValidatorError, "github_repo mismatch"):
            inventory.verify_scope(
                github_rows,
                filtered,
                manifest,
                supported_libraries={"cjson"},
                probe=lambda *_: True,
            )

    def test_verify_scope_ignores_tagged_repo_outside_supported_scope(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            },
            {
                "name": "port-libdemo",
                "nameWithOwner": "safelibs/port-libdemo",
                "url": "https://example.invalid/port-libdemo",
                "defaultBranchRef": {"name": "main"},
            },
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = [
            {
                "library": "cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "default_branch": "main",
                "tag_ref": "refs/tags/cjson/04-test",
            }
        ]
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )

        inventory.verify_scope(
            github_rows,
            filtered,
            manifest,
            supported_libraries={"cjson"},
            probe=lambda *_: True,
        )

    def test_verify_scope_rejects_missing_supported_tagged_repo(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            },
            {
                "name": "port-libdemo",
                "nameWithOwner": "safelibs/port-libdemo",
                "url": "https://example.invalid/port-libdemo",
                "defaultBranchRef": {"name": "main"},
            },
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = [
            {
                "library": "cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "default_branch": "main",
                "tag_ref": "refs/tags/cjson/04-test",
            }
        ]
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )

        with self.assertRaisesRegex(ValidatorError, "diverges from the live tagged subset"):
            inventory.verify_scope(
                github_rows,
                filtered,
                manifest,
                supported_libraries={"cjson", "libdemo"},
                probe=lambda *_: True,
            )

    def test_verify_scope_rejects_malformed_filtered_rows(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            }
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = inventory.select_tagged_scope(
            github_rows,
            supported_libraries={"cjson"},
            probe=lambda *_: True,
        )
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )
        malformed_filtered = [
            {
                "library": "cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "default_branch": "main",
            }
        ]

        with self.assertRaisesRegex(ValidatorError, "filtered inventory row schema mismatch"):
            inventory.verify_scope(
                github_rows,
                malformed_filtered,  # type: ignore[arg-type]
                manifest,
                supported_libraries={"cjson"},
                probe=lambda *_: True,
            )

    def test_verify_scope_rejects_incomplete_inventory_metadata(self) -> None:
        github_rows = [
            {
                "name": "port-cjson",
                "nameWithOwner": "safelibs/port-cjson",
                "url": "https://example.invalid/port-cjson",
                "defaultBranchRef": {"name": "main"},
            }
        ]
        apt_manifest = {
            "archive": {"suite": "noble"},
            "repositories": [
                {
                    "name": "cjson",
                    "github_repo": "safelibs/port-cjson",
                    "ref": "refs/tags/cjson/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                }
            ],
        }
        filtered = inventory.select_tagged_scope(
            github_rows,
            supported_libraries={"cjson"},
            probe=lambda *_: True,
        )
        manifest = inventory.merge_apt_repo_metadata(
            apt_manifest,
            filtered,
            verified_at="2026-04-12T00:00:00Z",
        )
        manifest["inventory"].pop("verified_at")

        with self.assertRaisesRegex(ValidatorError, "inventory metadata is incomplete"):
            inventory.verify_scope(
                github_rows,
                filtered,
                manifest,
                supported_libraries={"cjson"},
                probe=lambda *_: True,
            )

    def test_check_remote_tags_uses_manifest_order_and_ref_rule(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            config_path = Path(tmp) / "repositories.yml"
            write_manifest(
                config_path,
                [
                    repository_entry("libb", imports=["safe/tests"]),
                    repository_entry("liba", imports=["safe/tests"]),
                ],
            )

            calls: list[tuple[str, str]] = []

            def fake_remote_tag_reachable(github_repo: str, tag_ref: str) -> bool:
                calls.append((github_repo, tag_ref))
                return True

            with mock.patch("tools.inventory.remote_tag_reachable", side_effect=fake_remote_tag_reachable):
                inventory.check_remote_tags(config_path)

            self.assertEqual(
                calls,
                [
                    ("safelibs/port-libb", "refs/tags/libb/04-test"),
                    ("safelibs/port-liba", "refs/tags/liba/04-test"),
                ],
            )

    def test_remote_tag_reachable_uses_git_ls_remote(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            remote = tmp_path / "remote.git"
            work = tmp_path / "work"
            init_repo(work)
            run_git(["init", "--bare", str(remote)], cwd=tmp_path)
            write_path = work / "README.md"
            write_path.write_text("ok\n")
            commit_all(work, "initial")
            run_git(["remote", "add", "origin", str(remote)], cwd=work)
            run_git(["push", "origin", "HEAD:refs/heads/main"], cwd=work)
            run_git(["tag", "libdemo/04-test"], cwd=work)
            run_git(["push", "origin", "refs/tags/libdemo/04-test"], cwd=work)

            with mock.patch("tools.github_auth.github_git_url", return_value=str(remote)):
                self.assertTrue(
                    inventory.remote_tag_reachable(
                        "safelibs/port-libdemo",
                        "refs/tags/libdemo/04-test",
                    )
                )
                self.assertFalse(
                    inventory.remote_tag_reachable(
                        "safelibs/port-libdemo",
                        "refs/tags/libdemo/05-missing",
                    )
                )

    def test_remote_tag_reachable_redacts_tokenized_auth_failures(self) -> None:
        token = "secret-token"
        token_url = f"https://x-access-token:{token}@github.com/safelibs/port-libdemo.git"
        failure = subprocess.CompletedProcess(
            args=["git", "ls-remote", "--exit-code", token_url, "refs/tags/libdemo/04-test"],
            returncode=128,
            stdout="",
            stderr=f"fatal: Authentication failed for '{token_url}'\n",
        )

        with mock.patch("tools.github_auth.github_git_url", return_value=token_url), mock.patch(
            "tools.inventory.subprocess.run",
            return_value=failure,
        ):
            with self.assertRaises(ValidatorError) as ctx:
                inventory.remote_tag_reachable(
                    "safelibs/port-libdemo",
                    "refs/tags/libdemo/04-test",
                )

        message = str(ctx.exception)
        self.assertNotIn(token, message)
        self.assertIn("https://REDACTED@github.com/safelibs/port-libdemo.git", message)

    def test_remote_tag_reachable_raises_on_transport_failures(self) -> None:
        token = "secret-token"
        token_url = f"https://x-access-token:{token}@github.com/safelibs/port-libdemo.git"
        failure = subprocess.CompletedProcess(
            args=["git", "ls-remote", "--exit-code", token_url, "refs/tags/libdemo/04-test"],
            returncode=128,
            stdout="",
            stderr=(
                "fatal: unable to access "
                f"'{token_url}': Could not resolve host: github.com\n"
            ),
        )

        with mock.patch("tools.github_auth.github_git_url", return_value=token_url), mock.patch(
            "tools.inventory.subprocess.run",
            return_value=failure,
        ):
            with self.assertRaisesRegex(ValidatorError, "Could not resolve host") as ctx:
                inventory.remote_tag_reachable(
                    "safelibs/port-libdemo",
                    "refs/tags/libdemo/04-test",
                )

        message = str(ctx.exception)
        self.assertNotIn(token, message)
        self.assertIn("https://REDACTED@github.com/safelibs/port-libdemo.git", message)


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
            github_auth.github_git_url("safelibs/port-cjson", env),
            "https://x-access-token:token%3A%2Fwith%3Fchars@github.com/safelibs/port-cjson.git",
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

    def test_github_git_url_requires_non_interactive_auth_by_default(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value=None):
            with self.assertRaisesRegex(ValidatorError, "no non-interactive GitHub credential available"):
                github_auth.github_git_url("safelibs/port-cjson", {})

    def test_github_git_url_uses_ssh_fallback_only_when_allowed(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value=None):
            self.assertEqual(
                github_auth.github_git_url(
                    "safelibs/port-cjson",
                    {},
                    allow_interactive_fallback=True,
                ),
                "git@github.com:safelibs/port-cjson.git",
            )

    def test_github_git_url_uses_gh_auth_token_when_available(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value="/usr/bin/gh"), mock.patch(
            "tools.github_auth.subprocess.run",
            return_value=subprocess.CompletedProcess(
                args=["gh", "auth", "token"],
                returncode=0,
                stdout="gh-cli-token\n",
                stderr="",
            ),
        ):
            self.assertEqual(
                github_auth.github_git_url("safelibs/port-cjson", {}),
                "https://x-access-token:gh-cli-token@github.com/safelibs/port-cjson.git",
            )

    def test_effective_github_token_returns_empty_when_gh_auth_token_unavailable(self) -> None:
        with mock.patch("tools.github_auth.shutil.which", return_value="/usr/bin/gh"), mock.patch(
            "tools.github_auth.subprocess.run",
            return_value=subprocess.CompletedProcess(
                args=["gh", "auth", "token"],
                returncode=1,
                stdout="",
                stderr="not logged in",
            ),
        ):
            self.assertEqual(github_auth.effective_github_token({}), "")

    def test_run_git_disables_terminal_prompts(self) -> None:
        with mock.patch("tools.github_auth.run") as fake_run:
            github_auth.run_git(["git", "status"], capture_output=True)

        env = fake_run.call_args.kwargs["env"]
        self.assertEqual(env["GIT_TERMINAL_PROMPT"], "0")
        self.assertTrue(env["GIT_SSH_COMMAND"].startswith("ssh -oBatchMode=yes"))

    def test_run_git_allows_prompts_when_requested(self) -> None:
        with mock.patch.dict(
            "os.environ",
            {"GIT_TERMINAL_PROMPT": "0", "GIT_SSH_COMMAND": "ssh -oBatchMode=yes"},
            clear=False,
        ), mock.patch("tools.github_auth.run") as fake_run:
            github_auth.run_git(["git", "status"], allow_prompt=True)

        env = fake_run.call_args.kwargs["env"]
        self.assertNotIn("GIT_TERMINAL_PROMPT", env)
        self.assertNotIn("GIT_SSH_COMMAND", env)


class CommonToolsTests(unittest.TestCase):
    def test_run_redacts_authenticated_github_urls_and_tokens_on_failure(self) -> None:
        token = "secret-token"
        token_url = f"https://x-access-token:{token}@github.com/safelibs/port-libuv.git"
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
        self.assertIn("https://REDACTED@github.com/safelibs/port-libuv.git", message)
        self.assertIn("token=REDACTED", message)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import fetch_port_debs


FIXTURES = Path(__file__).resolve().parent / "fixtures"


def demo_manifest() -> dict[str, object]:
    return {
        "libraries": [
            {
                "name": "original-demo",
                "apt_packages": ["demo-runtime", "demo-dev"],
                "testcases": "tests/original-demo/testcases.yml",
            }
        ]
    }


class PortDebTests(unittest.TestCase):
    def run_root(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        return Path(tempdir.name)

    def fake_release(self) -> dict[str, object]:
        return {
            "assets": [
                {
                    "name": "demo-runtime_1.0_amd64.deb",
                    "url": "https://api.github.com/assets/runtime",
                    "browser_download_url": "https://github.com/download/runtime.deb",
                    "size": 10,
                },
                {
                    "name": "demo-dev_1.0_arm64.deb",
                    "url": "https://api.github.com/assets/dev-arm64",
                    "browser_download_url": "https://github.com/download/dev-arm64.deb",
                    "size": 10,
                },
                {
                    "name": "unrelated_1.0_amd64.deb",
                    "url": "https://api.github.com/assets/unrelated",
                    "browser_download_url": "https://github.com/download/unrelated.deb",
                    "size": 10,
                },
                {
                    "name": "notes.txt",
                    "url": "https://api.github.com/assets/notes",
                    "browser_download_url": "https://github.com/download/notes.txt",
                    "size": 10,
                },
            ]
        }

    def patch_network(self, release: dict[str, object] | None = None):
        release = release or self.fake_release()
        commit = "abcdef1234567890abcdef1234567890abcdef12"
        resolved_ref = fetch_port_debs.ResolvedPortRef(
            tag_ref="refs/tags/original-demo/05-verify",
            commit=commit,
            minimum_tag_ref="refs/tags/original-demo/04-test",
            minimum_commit="1111111111111111111111111111111111111111",
        )

        def fake_download(asset_url: str, target: Path) -> None:
            target.write_bytes(f"deb from {asset_url}\n".encode("utf-8"))

        patches = [
            mock.patch("tools.fetch_port_debs.load_manifest", return_value=demo_manifest()),
            mock.patch("tools.fetch_port_debs.resolve_port_ref", return_value=resolved_ref),
            mock.patch("tools.fetch_port_debs.load_release", return_value=release),
            mock.patch("tools.fetch_port_debs.download_asset", side_effect=fake_download),
            mock.patch("tools.fetch_port_debs.verify_deb_fields"),
        ]
        for patcher in patches:
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_tag_peeling_and_release_derivation(self) -> None:
        repo = fetch_port_debs.PortRepo(
            library="original-demo",
            name_with_owner="safelibs/port-original-demo",
            url="https://github.com/safelibs/port-original-demo",
            default_branch="main",
            tag_ref="refs/tags/original-demo/04-test",
        )
        stdout = (
            "1111111111111111111111111111111111111111\trefs/tags/original-demo/04-test\n"
            "2222222222222222222222222222222222222222\trefs/tags/original-demo/04-test^{}\n"
        )
        with mock.patch(
            "tools.fetch_port_debs.run",
            return_value=mock.Mock(stdout=stdout),
        ):
            commit = fetch_port_debs.resolve_tag_commit(repo)

        self.assertEqual(commit, "2222222222222222222222222222222222222222")
        self.assertEqual(fetch_port_debs.release_tag_for_commit(commit), "build-222222222222")

    def test_resolves_latest_phase_tag_at_or_after_minimum_stage(self) -> None:
        repo = fetch_port_debs.PortRepo(
            library="original-demo",
            name_with_owner="safelibs/port-original-demo",
            url="https://github.com/safelibs/port-original-demo",
            default_branch="main",
            tag_ref="refs/tags/original-demo/04-test",
        )
        phase_stdout = (
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\trefs/tags/original-demo/01-recon\n"
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\trefs/tags/original-demo/03-port\n"
            "1111111111111111111111111111111111111111\trefs/tags/original-demo/04-test\n"
            "abcdef1234567890abcdef1234567890abcdef12\trefs/tags/original-demo/05-verify\n"
        )
        selected_stdout = "abcdef1234567890abcdef1234567890abcdef12\trefs/tags/original-demo/05-verify\n"
        minimum_stdout = (
            "1111111111111111111111111111111111111111\trefs/tags/original-demo/04-test\n"
            "2222222222222222222222222222222222222222\trefs/tags/original-demo/04-test^{}\n"
        )
        with mock.patch(
            "tools.fetch_port_debs.run",
            side_effect=[
                mock.Mock(stdout=phase_stdout),
                mock.Mock(stdout=selected_stdout),
                mock.Mock(stdout=minimum_stdout),
            ],
        ):
            resolved = fetch_port_debs.resolve_port_ref(repo)

        self.assertEqual(resolved.minimum_tag_ref, "refs/tags/original-demo/04-test")
        self.assertEqual(resolved.minimum_commit, "2222222222222222222222222222222222222222")
        self.assertEqual(resolved.tag_ref, "refs/tags/original-demo/05-verify")
        self.assertEqual(resolved.commit, "abcdef1234567890abcdef1234567890abcdef12")

    def test_resolves_minimum_phase_tag_when_no_higher_phase_exists(self) -> None:
        repo = fetch_port_debs.PortRepo(
            library="original-demo",
            name_with_owner="safelibs/port-original-demo",
            url="https://github.com/safelibs/port-original-demo",
            default_branch="main",
            tag_ref="refs/tags/original-demo/04-test",
        )
        phase_stdout = (
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\trefs/tags/original-demo/01-recon\n"
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\trefs/tags/original-demo/03-port\n"
            "2222222222222222222222222222222222222222\trefs/tags/original-demo/04-test\n"
        )
        minimum_stdout = "2222222222222222222222222222222222222222\trefs/tags/original-demo/04-test\n"
        with mock.patch(
            "tools.fetch_port_debs.run",
            side_effect=[
                mock.Mock(stdout=phase_stdout),
                mock.Mock(stdout=minimum_stdout),
                mock.Mock(stdout=minimum_stdout),
            ],
        ):
            resolved = fetch_port_debs.resolve_port_ref(repo)

        self.assertEqual(resolved.tag_ref, "refs/tags/original-demo/04-test")
        self.assertEqual(resolved.commit, "2222222222222222222222222222222222222222")

    def test_filters_assets_and_writes_deterministic_lock(self) -> None:
        root = self.run_root()
        stale = root / "debs" / "original-demo" / "stale_0_amd64.deb"
        stale.parent.mkdir(parents=True)
        stale.write_text("stale")
        keep = root / "debs" / "original-demo" / "keep.txt"
        keep.write_text("keep")
        self.patch_network()

        lock = fetch_port_debs.build_lock(
            config_path=Path("repositories.yml"),
            port_repos_path=FIXTURES / "port-repos.json",
            output_root=root / "debs",
            libraries=["original-demo"],
        )

        self.assertEqual(
            list(lock),
            ["schema_version", "mode", "generated_at", "source_config", "source_inventory", "libraries"],
        )
        self.assertEqual(lock["mode"], "port-04-test")
        self.assertEqual(lock["generated_at"], "1970-01-01T00:00:00Z")
        library = lock["libraries"][0]
        self.assertEqual(library["tag_ref"], "refs/tags/original-demo/05-verify")
        self.assertEqual(library["release_tag"], "build-abcdef123456")
        self.assertEqual([deb["package"] for deb in library["debs"]], ["demo-runtime"])
        self.assertEqual(library["debs"][0]["architecture"], "amd64")
        self.assertEqual(library["unported_original_packages"], ["demo-dev"])
        self.assertFalse(stale.exists())
        self.assertTrue(keep.exists())
        self.assertEqual(
            sorted(path.name for path in (root / "debs" / "original-demo").glob("*.deb")),
            ["demo-runtime_1.0_amd64.deb"],
        )

        lock_path = root / "lock.json"
        fetch_port_debs.write_json(lock_path, lock)
        self.assertEqual(json.loads(lock_path.read_text()), lock)

    def test_duplicate_native_package_assets_are_rejected(self) -> None:
        release = {
            "assets": [
                {"name": "demo-runtime_1.0_amd64.deb", "url": "https://api.github.com/a"},
                {"name": "demo-runtime_1.1_all.deb", "url": "https://api.github.com/b"},
            ]
        }
        with self.assertRaisesRegex(ValidatorError, "duplicate native deb assets"):
            fetch_port_debs.selected_assets(
                release=release,
                canonical_packages=["demo-runtime", "demo-dev"],
                library="original-demo",
            )

    def test_requires_at_least_one_selected_asset(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "did not contain any native canonical"):
            fetch_port_debs.selected_assets(
                release={"assets": [{"name": "demo-runtime_1.0_arm64.deb"}]},
                canonical_packages=["demo-runtime"],
                library="original-demo",
            )

    def test_inventory_validation_rejects_wrong_repo_identity(self) -> None:
        repo = fetch_port_debs.PortRepo(
            library="original-demo",
            name_with_owner="safelibs/port-wrong",
            url="https://github.com/safelibs/port-original-demo",
            default_branch="main",
            tag_ref="refs/tags/original-demo/04-test",
        )
        with self.assertRaisesRegex(ValidatorError, "must be 'safelibs/port-original-demo'"):
            fetch_port_debs.validate_port_repo(repo)

    def test_token_is_redacted_from_git_errors(self) -> None:
        repo = fetch_port_debs.PortRepo(
            library="original-demo",
            name_with_owner="safelibs/port-original-demo",
            url="https://github.com/safelibs/port-original-demo",
            default_branch="main",
            tag_ref="refs/tags/original-demo/04-test",
        )
        with mock.patch.dict("os.environ", {"GH_TOKEN": "secret-token"}):
            with mock.patch("tools.fetch_port_debs.github_git_url", return_value="https://x-access-token:secret-token@github.com/safelibs/port-original-demo.git"):
                with mock.patch("tools.fetch_port_debs.run", side_effect=ValidatorError("https://REDACTED@github.com/ failed")):
                    with self.assertRaisesRegex(ValidatorError, "REDACTED") as context:
                        fetch_port_debs.resolve_tag_commit(repo)
        self.assertNotIn("secret-token", str(context.exception))


if __name__ == "__main__":
    unittest.main()

import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import private_settings as settings


class ArchiveSafetyTests(unittest.TestCase):
    def test_unsafe_entry_rejects_entire_archive_before_extraction(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sentinel = root / "outside.txt"
            sentinel.write_text("unchanged")
            for kind in ("absolute", "traversal", "symlink", "hardlink", "duplicate"):
                with self.subTest(kind=kind):
                    archive_path = root / f"{kind}.tar.gz"
                    with tarfile.open(archive_path, "w:gz") as archive:
                        settings.add_bytes(archive, ".gitconfig", b"private fixture")
                        settings.add_bytes(archive, f"{settings.META}/manifest.json", json.dumps({"format": 1}).encode())
                        if kind in ("absolute", "traversal", "duplicate"):
                            name = {"absolute": str(sentinel), "traversal": "../outside.txt", "duplicate": ".gitconfig"}[kind]
                            settings.add_bytes(archive, name, b"must not be written")
                        else:
                            link = tarfile.TarInfo(".codex")
                            link.type = tarfile.SYMTYPE if kind == "symlink" else tarfile.LNKTYPE
                            link.linkname = str(root)
                            archive.addfile(link)
                            settings.add_bytes(archive, ".codex/outside.txt", b"must not be written")
                    review = root / f"review-{kind}"
                    review.mkdir()
                    with self.assertRaises(settings.BackupError):
                        settings.extract_review(archive_path, review)
                    self.assertEqual(sentinel.read_text(), "unchanged")
                    self.assertFalse((review / ".gitconfig").exists())

    def test_directory_symlink_cycle_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "skills"
            source.mkdir()
            (source / "loop").symlink_to(source, target_is_directory=True)
            with tarfile.open(fileobj=io.BytesIO(), mode="w:gz", dereference=True) as archive:
                with self.assertRaisesRegex(settings.BackupError, "cycle"):
                    settings.add_contents(archive, source, Path(".agents/skills"), set(), None)


class GitRecoveryTests(unittest.TestCase):
    def test_inactive_conditional_include_is_preserved_and_missing_optional_include_is_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory).resolve()
            (home / "private").mkdir()
            (home / "private/work.gitconfig").write_text("[user]\n    email = fixture@example.invalid\n")
            config = home / ".gitconfig"
            config.write_text(
                '[includeIf "gitdir:/a/nonexistent/worktree/"]\n    path = private/work.gitconfig\n'
                '[include]\n    path = private/missing.gitconfig\n'
            )
            self.assertEqual(list(settings.git_includes(home, config)), [Path("private/work.gitconfig")])


if __name__ == "__main__":
    unittest.main()

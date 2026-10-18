#!/usr/bin/env python3
"""Encrypt selected private settings; restore only into a new review directory."""

import argparse
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile


EDITORS = {"Code": ".vscode", "Cursor": ".cursor", "Antigravity": ".antigravity"}
FILES = (
    ".gitconfig",
    ".codex/config.toml",
    ".omp/agent/config.yml",
    ".local/bin/rituel-sign",
)
TREES = (".config/nvim", ".agents/skills", ".codex/skills")
META = ".dotfiles-private"


class BackupError(Exception):
    pass


def git_includes(home, config):
    """Read all include paths, including currently inactive includeIf branches."""
    seen = set()
    pending = [config]
    while pending:
        path = pending.pop()
        real = path.resolve()
        if real in seen:
            continue
        seen.add(real)
        if not path.exists():
            raise BackupError(f"Referenced Git include is missing: {path}")
        result = subprocess.run(
            ["git", "config", "--file", str(path), "--no-includes", "--null",
             "--get-regexp", r"^include(if\..*)?\.path$"],
            capture_output=True,
        )
        if result.returncode not in (0, 1):
            raise BackupError(f"Cannot parse private Git configuration: {path}")
        for entry in result.stdout.split(b"\0"):
            if not entry:
                continue
            value = os.fsdecode(entry.partition(b"\n")[2])
            if value.startswith("~/"):
                target = home / value[2:]
            else:
                target = Path(os.path.expanduser(value))
                if not target.is_absolute():
                    target = path.parent / target
            target = Path(os.path.abspath(target))
            if not target.exists():
                continue  # Git also ignores absent optional include files.
            if not target.is_relative_to(home):
                raise BackupError(f"Git include is outside your home; back it up separately: {target}")
            yield target.relative_to(home)
            pending.append(target)


def collect_sources(home):
    sources = [Path(name) for name in (*FILES, *TREES) if (home / name).exists()]
    for directory in (".agents", ".codex", ".omp/agent"):
        sources.extend(path.relative_to(home) for path in (home / directory).glob("*.md"))
    if (home / ".gitconfig").exists():
        sources.extend(git_includes(home, home / ".gitconfig"))
    for editor in EDITORS:
        user = home / "Library/Application Support" / editor / "User"
        for base in [user, *sorted((user / "profiles").glob("*"))]:
            for name in ("settings.json", "keybindings.json", "snippets", "extensions.json"):
                path = base / name
                if path.exists():
                    sources.append(path.relative_to(home))
    # A private include can also be inside a tree already selected above.
    selected = []
    for relative in sorted(set(sources), key=lambda path: (len(path.parts), str(path))):
        if not any(relative.is_relative_to(parent) and (home / parent).is_dir() for parent in selected):
            selected.append(relative)
    return selected


def editor_extensions(home):
    exports = {}
    for editor, folder in EDITORS.items():
        path = home / folder / "extensions/extensions.json"
        if not path.exists():
            continue
        entries = json.loads(path.read_text())
        identifiers = set()
        for entry in entries:
            identifier = entry["identifier"]["id"]
            if not isinstance(identifier, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9][A-Za-z0-9_.-]*", identifier):
                raise BackupError(f"Invalid extension identifier in {editor}'s inventory")
            identifiers.add(identifier)
        exports[editor] = ("\n".join(sorted(identifiers)) + "\n").encode()
    return exports


def outside_git(path):
    environment = os.environ.copy()
    for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_CEILING_DIRECTORIES"):
        environment.pop(name, None)
    result = subprocess.run(
        ["git", "-C", str(path), "rev-parse", "--is-inside-work-tree"],
        capture_output=True, env=environment,
    )
    if result.returncode == 0 and result.stdout.strip() == b"true":
        raise BackupError("Keep private backups and review directories outside Git working trees")


def destination(path):
    path = Path(os.path.abspath(path))
    if path.exists() or path.is_symlink():
        raise BackupError(f"Destination already exists; nothing will be overwritten: {path}")
    if not path.parent.is_dir():
        raise BackupError(f"Destination parent must already exist: {path.parent}")
    path = path.parent.resolve() / path.name
    outside_git(path.parent)
    return path


def gpg_environment():
    environment = os.environ.copy()
    if sys.stdin.isatty():
        environment["GPG_TTY"] = os.ttyname(sys.stdin.fileno())
    return environment


def add_contents(archive, source, relative, ancestors, excluded_inode):
    """Dereference links, but reject cycles and non-file payloads."""
    info = source.stat()
    inode = (info.st_dev, info.st_ino)
    if inode == excluded_inode:
        return
    if not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
        raise BackupError(f"Not a regular file or directory: {source}")
    if stat.S_ISDIR(info.st_mode) and inode in ancestors:
        raise BackupError(f"Symlink directory cycle: {source}")
    member = archive.gettarinfo(str(source), arcname=relative.as_posix())
    # Ownership is intentionally not migrated to a different Mac/account.
    member.uid = member.gid = 0
    member.uname = member.gname = ""
    member.mode = 0o700 if member.isdir() or member.mode & stat.S_IXUSR else 0o600
    if member.isdir():
        archive.addfile(member)
        for child in sorted(source.iterdir()):
            if relative == Path(".codex/skills") and child.name == ".system":
                continue
            add_contents(archive, child, relative / child.name, ancestors | {inode}, excluded_inode)
    else:
        with source.open("rb") as contents:
            archive.addfile(member, contents)


def add_bytes(archive, name, data):
    member = tarfile.TarInfo(name)
    member.size = len(data)
    member.mode = 0o600
    archive.addfile(member, io.BytesIO(data))


def backup(home, output):
    home = home.resolve()
    output = destination(output)
    sources = collect_sources(home)
    if not sources:
        raise BackupError("No private settings were found")
    for relative in sources:
        source = home / relative
        if source.is_dir() and output.parent.is_relative_to(source.resolve()):
            raise BackupError("Write the backup outside the directories being backed up")
    exports = editor_extensions(home)
    manifest = {
        "format": 1,
        "sources": [path.as_posix() for path in sources],
        "extension_exports": sorted(exports),
        "excluded": "Auth/session stores, SSH/GPG keys, signing certificates, Android keystores",
    }
    # Only ciphertext is staged during backup. Linking publishes without clobbering.
    with tempfile.NamedTemporaryFile(dir=output.parent, prefix=".dotfiles-private-", suffix=".gpg") as encrypted:
        file_info = os.fstat(encrypted.fileno())
        process = subprocess.Popen(
            ["gpg", "--symmetric", "--cipher-algo", "AES256", "--output", "-"],
            stdin=subprocess.PIPE, stdout=encrypted, env=gpg_environment(),
        )
        try:
            with tarfile.open(fileobj=process.stdin, mode="w|gz", dereference=True) as archive:
                for relative in sources:
                    add_contents(archive, home / relative, relative, set(), (file_info.st_dev, file_info.st_ino))
                add_bytes(archive, f"{META}/manifest.json", json.dumps(manifest, indent=2).encode())
                for editor, data in exports.items():
                    add_bytes(archive, f"{META}/extensions/{editor}.txt", data)
            process.stdin.close()
            if process.wait() != 0:
                raise BackupError("Encryption failed; no backup was published")
            encrypted.flush()
            os.fsync(encrypted.fileno())
            os.link(encrypted.name, output)
        except BaseException:
            process.terminate()
            process.wait()
            raise
    return manifest


def extract_review(plaintext, review):
    # Validate the entire authenticated archive before extracting any entry.
    seen = set()
    with tarfile.open(plaintext, "r:gz") as archive:
        for member in archive:
            path = PurePosixPath(member.name)
            if (not path.parts or path.is_absolute() or ".." in path.parts
                    or not (member.isfile() or member.isdir()) or member.size < 0):
                raise BackupError("Unsafe archive entry; no settings were restored")
            if path in seen:
                raise BackupError("Duplicate archive entry; no settings were restored")
            seen.add(path)
    with tarfile.open(plaintext, "r:gz") as archive:
        archive.extractall(review, filter="data")
    manifest_path = review / META / "manifest.json"
    if not manifest_path.is_file() or json.loads(manifest_path.read_text()).get("format") != 1:
        raise BackupError("Not a supported private settings bundle")


def restore(archive, output):
    output = destination(output)
    # Authenticate completely before parsing/extracting. Never pipe gpg into tar.
    with tempfile.TemporaryDirectory(dir=output.parent, prefix=".dotfiles-private-restore-") as temporary:
        temporary = Path(temporary)
        plaintext = temporary / "settings.tar.gz"
        with plaintext.open("xb") as contents:
            result = subprocess.run(
                ["gpg", "--decrypt", "--output", "-", str(Path(archive).resolve(strict=True))],
                stdout=contents, env=gpg_environment(),
            )
        if result.returncode != 0:
            raise BackupError("Decryption/authentication failed; no settings were restored")
        review = temporary / "review"
        review.mkdir(mode=0o700)
        extract_review(plaintext, review)
        # A directory rename cannot overwrite a file or a populated directory.
        if output.exists() or output.is_symlink():
            raise BackupError("Review destination appeared during restore; nothing was overwritten")
        review.rename(output)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("backup", help="Create a password-encrypted bundle outside Git")
    create.add_argument("output", type=Path)
    recover = commands.add_parser("restore", help="Decrypt into a new review directory; never overwrite HOME")
    recover.add_argument("archive", type=Path)
    recover.add_argument("review_directory", type=Path)
    args = parser.parse_args()
    if not shutil.which("gpg") or not shutil.which("git"):
        parser.error("Homebrew GnuPG and Git are required; apply the dotfiles first")
    try:
        if args.command == "backup":
            manifest = backup(Path.home(), args.output)
            print(f"Encrypted {len(manifest['sources'])} private source paths into {args.output}")
            print("Store the bundle off this Mac and its password separately. Keys/certificates are not included.")
        else:
            restore(args.archive, args.review_directory)
            print(f"Restored into {args.review_directory}; active home-directory settings were not changed.")
            print("Review privately before copying files. Remove the plaintext review directory when finished.")
    except KeyboardInterrupt:
        return 130
    except (BackupError, OSError, ValueError, KeyError, TypeError, tarfile.TarError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-entry-attributes-survey
# @title: python-libarchive-c ArchiveEntry exposes the documented attribute surface
# @description: Probes the ArchiveEntry class via dir() and asserts the documented attribute names that we rely on across the suite (pathname, size, mode, mtime, isfile, isdir, issym, islnk, linkname, perm) are all present, and that they are accessible on a real entry read from a tiny ustar archive.
# @timeout: 60
# @tags: usage, archive, entry, attributes
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path
import libarchive
from libarchive.entry import ArchiveEntry

required = {"pathname", "size", "mode", "mtime", "isfile", "isdir",
            "issym", "islnk", "linkname", "perm"}
exposed = {a for a in dir(ArchiveEntry) if not a.startswith("_")}
missing = required - exposed
assert not missing, ("missing attrs", sorted(missing), "have", sorted(exposed))

tmpdir = Path(sys.argv[1])
arc = tmpdir / "probe.tar"
payload = b"attribute-survey payload\n"

with libarchive.file_writer(str(arc), "ustar") as writer:
    writer.add_file_from_memory("probe.txt", len(payload), payload)

with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        # Touch every required attribute to confirm they're live, not just defined.
        snap = {
            "pathname": entry.pathname,
            "size": entry.size,
            "mode": entry.mode,
            "mtime": entry.mtime,
            "isfile": entry.isfile,
            "isdir": entry.isdir,
            "issym": entry.issym,
            "islnk": entry.islnk,
            "linkname": entry.linkname or "",
            "perm": entry.perm,
        }
        b"".join(entry.get_blocks())

assert snap["pathname"] == "probe.txt", snap
assert snap["size"] == len(payload), snap
assert snap["isfile"] is True, snap
assert snap["isdir"] is False, snap
assert snap["issym"] is False, snap
assert snap["islnk"] is False, snap
print("attr-survey", sorted(snap))
PY

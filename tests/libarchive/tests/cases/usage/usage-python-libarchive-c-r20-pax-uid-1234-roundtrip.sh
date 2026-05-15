#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-pax-uid-1234-roundtrip
# @title: python-libarchive-c pax entry with uid=1234 set via ctypes roundtrips the uid attribute
# @description: Builds a pax archive in memory using new_archive_entry and ctypes-bound archive_entry_set_uid to stamp uid 1234 on one entry, reads back via memory_reader, and asserts the recovered entry.uid equals 1234, exercising the pax numeric uid roundtrip with a small in-range value distinct from the batch15 millions-scale uid+gid test.
# @timeout: 60
# @tags: usage, archive, pax, uid, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import ctypes
import io

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    REGULAR_FILE,
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

so = ctypes.CDLL("libarchive.so.13")
set_uid = so.archive_entry_set_uid
set_uid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_uid.restype = None

payload = b"r20 pax uid 1234 payload"
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "doc.bin"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        set_uid(ent, 1234)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

raw = buf.getvalue()
uids = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        uids.append(entry.uid)

assert uids == [1234], uids
print("pax-uid-1234-ok", uids)
PY

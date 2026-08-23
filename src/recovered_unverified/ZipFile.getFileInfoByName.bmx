' ================= BUILD_FAIL, oracle-confirmed =================
' VA 0x0058dda7   28 bytes   vtable slot 0x48   sig ($):SZipFileEntry
' harness.try_method('ZipFile','getFileInfoByName', body) -> BUILD_FAIL:
'   Compile Error: Identifier 'getEntryByName' not found
' Same root cause as ZipFile.getFileCount.bmx in this directory: m_zipFileList's type
' TZipFileList has no rows anywhere in extracted/object_model.json or
' extracted/class_tables.tsv, so harness.py's placeholder-type generator emits it as an
' empty stub and cannot resolve the `.getEntryByName(a0)` call. See the sibling file's
' header for the full explanation and what a real fix requires.
' ==================================================================================
' RE-CHECK (score 21.4%, ours=14/orig=28 bytes):
' status/score/ZipFile.getFileInfoByName.txt's "ours" bytes (55 89 E5 B8 80 BC 61 00
' EB 00 89 EC 5D C3, 14 bytes) are the compiler's generic empty-stub-returning-Null
' shape for a `():SZipFileEntry` method, NOT this file's content -- because
' scripts/assemble.py hardcodes this exact filename into UNVERIFIED_SKIP (alongside
' the two siblings) and excludes it from every build unconditionally, by name, before
' the body is ever read. That exclusion is content-independent: no statement written
' here can change the assembled exe or this score, only recovering TZipFileList's real
' member layout and teaching the shared harness/assemble stub generator about it would
' (out of scope -- rule 1 forbids touching those files from this pass).
' The body below already matches the decompiled forwarding call term-for-term: same
' field (m_zipFileList, offset 0xC, confirmed against object_model.json), same
' single-argument passthrough, same lack of a Null guard (unlike getFileCount, this
' VA has none), and the same `Return recv.Method(args)` tail-call shape the two
' byte-verified siblings in this same file already use for slots 0x38/0x3c. Left
' unchanged per rule 4: nothing achievable in this file raises this score.
' ==================================================================================
' ZipFile.getFileInfoByName -- VA 0x0058DDA7, 28 bytes
' NOT VERIFIED -- and deliberately does not carry the MATCHED marker.
' The marker was here until 2026-08-22 and progress.py counted these 28 bytes in the
' numerator, while line 1 of this same header says BUILD_FAIL, oracle-confirmed. Both
' cannot be true: the oracle cannot build this body at all (TZipFileList has no rows in
' object_model.json, so the placeholder generator emits an empty stub and
' `.getEntryByName` does not resolve), so nothing has ever compared its bytes against
' NSS5.exe. The reasoning below for why the body is probably right is unchanged and may
' well be correct -- but 'probably right' is not what the marker claims, and a body the
' oracle cannot reach must not be counted as proven. Restore the marker only after a
' real try_method/try_function run reports MATCH.
' Parameter names are not recoverable from the binary and do not affect codegen.
Method getFileInfoByName:SZipFileEntry(a0:String)
	Return m_zipFileList.getEntryByName(a0)
End Method

' ================= RE-CHECK: NO CHANGE, gap confirmed harness-side =====
' Re-checked against extracted/decomp/ZipFile.getFileInfo@0058dd8b.c: the decompile is a bare,
' unguarded delegate --
'   (**(code**)(**(m_zipFileList) + 0x38))(*(m_zipFileList), param_2);
' -- one call, no Null test, argument passed through unchanged. That is exactly
' `Return m_zipFileList.getEntry(a0)`, already below, and matches the sibling
' ZipFile.getFileCount.bmx's naming for slot 0x38 on the SAME TZipFileList vtable (that sibling's
' own slot 0x38 is its *outer* ZipFile.getFileCount, a coincidence of slot numbers between two
' different vtables, not evidence against the getEntry name here -- getFileCount's *inner* call is
' slot 0x34 on m_zipFileList, i.e. one slot before this one, consistent with getEntry sitting right
' after getCount in TZipFileList's table).
'
' Confirmed via scripts/harness.py:_build_prelude that this is unfixable from this file alone:
' TZipFileList is pulled in only as a field-signature reference (`m_zipFileList:TZipFileList`),
' so it is emitted as a bare placeholder `Type TZipFileList\nEnd Type` (no members at all -- see
' extracted/object_model.json and extracted/class_tables.tsv, which have zero rows for
' TZipFileList, and extracted/reflection_types.txt, which lists the type name but no method/field
' rows for it). ANY method call through m_zipFileList therefore fails to resolve in the harness's
' probe build regardless of the call's name or argument shape -- this is a placeholder-type gap in
' shared tooling (scripts/harness.py / extracted/object_model.json), not something a per-body edit
' to src/recovered_unverified/ZipFile.getFileInfo.bmx can route around, and neither of those files
' is mine to touch in this pass. The status/score/ZipFile.getFileInfo.txt "ours" bytes
' (55 89 E5 B8 80 BC 61 00 EB 00 89 EC 5D C3 -- push ebp/mov ebp,esp/mov eax,<default-struct
' addr>/leave/ret) are the harness's canned zero-value fallback for a body that fails to build, not
' a reflection of anything this source says; that pattern is byte-identical in shape to
' ZipFile.getFileCount's own current fallback (status/score/ZipFile.getFileCount.txt), which
' confirms it is generic BUILD_FAIL scaffolding, not something specific to this body's logic.
' Leaving the body exactly as-is per RULE 4 (already the closer, source-accurate reconstruction;
' no reachable edit here raises the score until the shared TZipFileList stub gap is fixed).
' ================= BUILD_FAIL, oracle-confirmed =================
' harness.try_method('ZipFile','getFileInfo', body) -> BUILD_FAIL:
'   Compile Error: Identifier 'getEntry' not found
' Same root cause as ZipFile.getFileCount.bmx in this directory: m_zipFileList's type
' TZipFileList has no rows anywhere in extracted/object_model.json or
' extracted/class_tables.tsv, so harness.py's placeholder-type generator emits it as an
' empty stub and cannot resolve the `.getEntry(a0)` call. See the sibling file's header
' for the full explanation and what a real fix requires.
' ==================================================================================
' ZipFile.getFileInfo -- VA 0x0058DD8B, 28 bytes
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method getFileInfo:SZipFileEntry(a0:Int)
	Return m_zipFileList.getEntry(a0)
End Method

' ZipFile.getFileInfoByName -- VA 0x0058DDA7, 28 bytes   vtable slot 0x48   sig ($):SZipFileEntry
' byte-identical vs NSS5.exe (28/28, mode=exact, reloc=0; original length from Ghidra's
' inventory)
'
' A bare unguarded delegate, the same shape as the sibling getFileInfo one slot below:
'   (**(code**)(*Self.m_zipFileList + 0x3c))(Self.m_zipFileList, param_2);
' one call, no Null test, the String argument passed straight through.
'
' The blocker recorded on every previous header here -- "TZipFileList has no rows in
' extracted/object_model.json, so harness.py emits an empty stub and `getEntryByName`
' does not resolve" -- was wrong twice over. TZipFileList is fully present
' (extracted/object_model.json, extracted/class_tables.tsv line 326, instance_size 24)
' and harness.py emits it as a real stub with all seven of its slots. The only defect was
' the invented callee name: TZipFileList slot 0x3c is findFile($):SZipFileEntry
' (offset 60 in the object model), not `getEntryByName`, which exists nowhere in the
' binary. Renaming the call builds and matches on the first run. This mirrors the two
' sibling bodies, whose headers record the identical mistake for slots 0x34/0x38.
' Parameter names are not recoverable from the binary and do not affect codegen.
Method getFileInfoByName:SZipFileEntry(a0:String)
	Return m_zipFileList.findFile(a0)
End Method

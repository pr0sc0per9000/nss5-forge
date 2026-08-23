' ZipFile.getFileInfo
' VA 0x0058DD8B   28 bytes   vtable slot 0x44   sig (i):SZipFileEntry
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory, no
' relocation masking needed - an exact positional compare).
'
' A bare unguarded delegate: the decompile is
'   (**(code**)(**(m_zipFileList) + 0x38))(*(m_zipFileList), param_2);
' one call, no Null test, argument passed straight through. Slot 0x38 on TZipFileList is
' getFileInfo (VA 0x0058EA1B, extracted/vtable_map.tsv line 2787), one slot after
' getFileCount at 0x34. Earlier headers on this body called it `getEntry` and blamed a
' missing TZipFileList placeholder in harness.py; the placeholder was never missing, the
' method name was simply invented.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Method getFileInfo:SZipFileEntry(a0:Int)
		Return m_zipFileList.getFileInfo(a0)
	End Method

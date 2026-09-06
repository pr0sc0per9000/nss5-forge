' TZipFileList.getFileInfo -- VA 0x0058EA1B, 117 bytes   vtable slot 0x38   sig (i):SZipFileEntry
' byte-identical vs NSS5.exe (117/117, mode=reloc, 6 absolute-address slots masked)
' The bounds test is a short-circuiting Or: setl on (a0 < 0) jumps the second half at
' 0x0058EA32. 0x005B963C is _brl_blitz_RuntimeError; the literal at 0x00C95BF8 reads
' 'TZipReader.getFileInfo(): Invalid index ' -- the module's own name for this Type,
' spelled TZipReader, kept verbatim. TList slot 0x6C is ValueAtIndex, 0x70 is Count
' (extracted/vtable_map.tsv lines 1071-1072); the trailing bbObjectDowncast against the
' SZipFileEntry class table at 0x00C95844 is the cast on the Return.
' Parameter names are not recoverable from the binary and do not affect codegen.
Method getFileInfo:SZipFileEntry(a0:Int)
	If a0 < 0 Or a0 >= FileList.Count() Then RuntimeError("TZipReader.getFileInfo(): Invalid index " + a0)
	Return SZipFileEntry(FileList.ValueAtIndex(a0))
End Method

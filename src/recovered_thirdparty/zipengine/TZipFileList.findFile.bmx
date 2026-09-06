' TZipFileList.findFile -- VA 0x0058EA90, 180 bytes   vtable slot 0x3C   sig ($):SZipFileEntry
' byte-identical vs NSS5.exe (180/180, mode=reloc, 8 absolute-address slots masked)
' A probe entry is built and handed to TList.FindLink, so SZipFileEntry.EqEq decides the
' match: 0x00C95874 is SZipFileEntry's class table + 0x30, its Create Function; the field
' written at +0xC is simpleFileName; 0x004A74E0 is _bbStringToLower; TList slot 0x68 is
' FindLink and TLink slot 0x30 is Value.
'
' THE EMPTY Else IS REAL. Without it the body is 178 bytes and everything else is
' identical -- the original carries `EB 00` at 0x0058EB36, an end-of-then jump to the very
' next instruction, and bcc emits that jump only when the If has an Else clause. The Else
' arm itself assembles to nothing, so the original source declared one and left it empty.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Method findFile:SZipFileEntry(a0:String)
		Local res:SZipFileEntry
		Local entry:SZipFileEntry = SZipFileEntry.Create()
		entry.simpleFileName = a0
		If IgnoreCase Then entry.simpleFileName = entry.simpleFileName.ToLower()
		If IgnorePaths Then deletePathFromFilename(entry.simpleFileName)
		Local lnk:TLink = FileList.FindLink(entry)
		If lnk <> Null
			res = SZipFileEntry(lnk.Value())
		Else
		EndIf
		Return res
	End Method

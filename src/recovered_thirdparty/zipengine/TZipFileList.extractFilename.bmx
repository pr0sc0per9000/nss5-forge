' TZipFileList.extractFilename -- VA 0x0058ECC5, 268 bytes   vtable slot 0x44   sig (:SZipFileEntry)i
' byte-identical vs NSS5.exe (268/268, mode=reloc, 12 absolute-address slots masked)
' The guard must be written `Not`, not `= 0`: FilenameLength is a Short, and comparing it
' to the Int literal 0 inserts a Short->Int cast that bcc emits as a two-byte `mov eax,eax`
' after the movzx load. `Not` takes the loaded value as-is and inverts the branch, which is
' what the original does at 0x0058ECD5. That is the whole 270-vs-268 delta.
' 0x005B5718 is _brl_filesystem_ExtractDir, 0x005B5578 _brl_filesystem_StripDir,
' 0x004A6A30 _bbStringCompare. The literal compared against is '<bad_dir>' -- BlitzMax's
' ExtractDir returns that marker rather than an empty string when the path has no
' directory part, so the test is 'did this name carry a path', evaluated once and reused.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Method extractFilename:Int(a0:SZipFileEntry)
		If Not a0.header.FilenameLength Then Return 0
		If IgnoreCase Then a0.zipFileName = a0.zipFileName.ToLower()
		Local hasDir:Int = (ExtractDir(a0.zipFileName) <> "<bad_dir>")
		a0.simpleFileName = StripDir(a0.zipFileName)
		If hasDir
			a0.path = ExtractDir(a0.zipFileName)
		Else
			a0.path = ""
		EndIf
		If IgnorePaths = 0 Then a0.simpleFileName = a0.zipFileName
	End Method

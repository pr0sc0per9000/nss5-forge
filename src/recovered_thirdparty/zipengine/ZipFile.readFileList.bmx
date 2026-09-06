' ZipFile.readFileList -- VA 0x0058DC60, 148 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (148/148, mode=reloc, 6 absolute-address slots masked)
' The guard is a short-circuiting And over two setg results: the String length field at
' m_name+8 first, then _brl_filesystem_FileSize (0x005B5BBF). The construction goes
' through TZipFileList's class table -- `call dword ptr [0x00C94FE4]` is TZipFileList+0x30,
' its Create Function -- with IgnoreCase and IgnorePaths both 0. 0x005B65E3 is
' _brl_filesystem_ReadFile; the close at 0x005B812B is the CloseFile/CloseStream alias set.
'
' Earlier passes recorded this as blocked on the same phantom TZipFileList metadata gap as
' the getFile* delegates. There was never a gap: TZipFileList is fully present in
' extracted/object_model.json and extracted/class_tables.tsv (line 326).
	Method readFileList:Int()
		clearFileList()
		If m_name.length > 0 And FileSize(m_name) > 0
			Local s:TStream = ReadFile(m_name)
			If s <> Null
				m_zipFileList = TZipFileList.Create(s, 0, 0)
				CloseFile(s)
			EndIf
		EndIf
	End Method

' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipReader.CloseZip @ 0x0058E7BF, 66 bytes, unrecovered -- minizip's
' unzCloseCurrentFile / unzClose pair. See ZipReader.OpenZip.bmx.
'
' Releases the entry buffer TZipEStream.find_file hung off m_zipFile (layout documented in
' that file) and drops the parsed central directory. This is the only place the MemAlloc is
' handed back, and the byte-verified TZipEStream.Close is what calls it:
'     If reader <> Null
'         reader.CloseZip()
'         reader = Null
'     EndIf
' so every path that ends in CloseStream -- TProfile.LoadSavedGame,
' TScreen_MainMenu.UpdateLoadTable, TReplay.LoadReplayFile -- frees it.
	Method CloseZip:Int()
		If Self.m_zipFile <> Null
			MemFree(Self.m_zipFile)
			Self.m_zipFile = Null
		EndIf
		Self.clearFileList()
		Return 1
	End Method

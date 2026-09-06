' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipReader.OpenZip @ 0x0058E4CF, 103 bytes, unrecovered.
' extracted/decomp/ZipReader.OpenZip@0058e4cf.c is
'     m_zipFile = FUN_004022b0(cstring(a0))      ' minizip unzOpen
'     if (m_zipFile) { setName(a0); readFileList(); }
'     return m_zipFile != 0
' FUN_004022b0 is a C library entry point, so this cannot be byte-recovered as BlitzMax.
'
' WHAT THE STUB COST
' Empty, this returned 0, so the byte-verified TZipEStream.Create took its
'     DebugLog "unable to open zip " + a0
' branch and returned Null for EVERY "zipe::" url in the game. That is the read half of the
' save bug: TProfile.LoadSavedGame's ReadStream() came back Null, and
' TScreen_MainMenu.UpdateLoadTable's `If st And st._stream` failed, so any save file that
' HAD existed would have been reported to the player as corrupt rather than listed.
'
' WHAT THIS DOES
' The same two steps, minus the C handle. Locating entries needs no handle at all: the
' recovered, byte-verified ZipFile.readFileList / TZipFileList.ScanCentralHeader /
' SZIPCentralFileHeader.fill already parse the central directory in pure BlitzMax, and
' getFileCount() > 0 is exactly the "did unzOpen succeed" answer the original returns.
' m_zipFile is left Null here and used by TZipEStream.find_file as the handle for the
' currently-open ENTRY -- which is what it is in the original too (the decompiled Read/Eof/
' Pos all reach it through reader.m_zipFile at +0x10).
	Method OpenZip:Int(a0:String)
		If a0 = "" Then Return 0
		If FileType(a0) <> 1 Then Return 0
		Self.m_zipFile = Null
		Self.setName(a0)
		Self.readFileList()
		Return Self.getFileCount() > 0
	End Method

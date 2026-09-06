' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be. See src/behaviour's rank in      #
' # scripts/assemble.py: below every recovered tree, above src/placeholder.  #
' ############################################################################
'
' Real function: ZipWriter.OpenZip @ 0x0058DE13, 147 bytes, unrecovered
' (src/recovered_thirdparty/MANIFEST.tsv, zipengine, status blank).
'
' WHY THIS CANNOT BE RECOVERED AS A .BMX BODY
' The original's 147 bytes are a thin wrapper over minizip's `zipOpen`, a C function
' linked into NSS5.exe at 0x00401xxx. extracted/decomp shows the whole ZipWriter/ZipReader
' family calling into that 0x0040xxxx band -- zipOpen / zipOpenNewFileInZip /
' zipWriteInFileInZip / zipCloseFileInZip / zipClose on the write side, unzOpen /
' unzLocateFile / unzOpenCurrentFilePassword / unzReadCurrentFile on the read side. Those
' are C library objects, not bcc output, so there is no BlitzMax source that can byte-match
' them and no amount of reconstruction will produce one. The zip layer is exactly the
' "clean break" scripts/assemble.py's UNVERIFIED_SKIP note already anticipated for the save
' format.
'
' WHAT THE STUB COST
' Empty, this returned 0, so TProfile.SaveGame's
'     If zw.OpenZip(g_userpath + "Save/" + g_savename, 0)
' was never entered, nothing was ever written, and the Save/ directory stayed empty --
' which is why no career ever appeared in the main menu's load list.
'
' WHAT THIS DOES
' Records the destination path on the ZipFile base (setName), and, for the CREATE mode the
' game always asks for (a1 = 0 = minizip's APPEND_STATUS_CREATE), removes any existing
' archive so AddStream starts a fresh one. No file is created here on purpose: an empty
' 0-byte .sav left behind by an OpenZip that is never followed by an AddStream would be
' picked up by TScreen_MainMenu.UpdateLoadTable and shown to the player as a corrupt save.
'
' The archive itself is written by ZipWriter.AddStream -- see that file for the container
' format and its limits.
	Method OpenZip:Int(a0:String, a1:Int)
		If a0 = "" Then Return 0
		Self.setName(a0)
		Self.m_compressionLevel = -1
		' a1 is minizip's append mode: 0 = create, 1 = create-after, 2 = add-in-zip.
		' The game only ever passes 0.
		If a1 = 0 And FileType(a0) = 1 Then DeleteFile(a0)
		' Fail the way zipOpen fails: no writable directory, no archive.
		Local dir:String = ExtractDir(a0)
		If dir <> "" And dir <> "<bad_dir>" And FileType(dir) <> 2
			DebugLog "ZipWriter.OpenZip: no such directory " + dir
			Return 0
		EndIf
		Return 1
	End Method

' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipWriter.AddFileToDest @ 0x0058DEE6, 584 bytes, unrecovered -- minizip
' again. See ZipWriter.OpenZip.bmx.
'
' The already-recovered, byte-verified ZipWriter.AddFile is
'     AddFileToDest(a0, a0, a1)
' so leaving this one empty makes AddFile silently do nothing. Nothing in the game calls
' either today (the two archive writers, TProfile.SaveGame and TReplay.CreateReplay, both
' go through AddStream), but AddFile is verified code that must not be left pointing at a
' hole.
'
' a0 is the file on disk, a1 the name it takes inside the archive, a2 the password (ignored
' -- entries are written stored and unencrypted; see ZipWriter.AddStream.bmx).
	Method AddFileToDest:Int(a0:String, a1:String, a2:String)
		If a0 = "" Or a1 = "" Then Return 0
		Local src:TStream = ReadFile(a0)
		If src = Null
			DebugLog "ZipWriter.AddFileToDest: cannot read " + a0
			Return 0
		EndIf
		Local ok:Int = Self.AddStream(src, a1, a2)
		CloseFile(src)
		Return ok
	End Method

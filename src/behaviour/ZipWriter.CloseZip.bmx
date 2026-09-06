' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipWriter.CloseZip @ 0x0058E42A, 92 bytes, unrecovered -- minizip's
' `zipClose(handle, globalComment)`. See ZipWriter.OpenZip.bmx for why the family cannot be
' byte-recovered.
'
' There is nothing to close here. ZipWriter.AddStream writes a complete, finalised archive
' every time it is called -- central directory and end-of-central-directory record included
' -- because the Type has nowhere to keep an open handle between calls (again, see
' AddStream's own note). So the only thing CloseZip can still contribute is the archive
' comment, and every call site in the game passes "".
'
' Callers: TProfile.SaveGame and TReplay.CreateReplay, both `zw.CloseZip("")`, return value
' discarded.
	Method CloseZip:Int(a0:String)
		Self.m_zipFile = Null
		Return 1
	End Method

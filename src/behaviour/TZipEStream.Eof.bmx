' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: TZipEStream.Eof @ 0x0058F9B7, 26 bytes, unrecovered.
' extracted/decomp/TZipEStream.Eof@0058f9b7.c is a single tail call:
'     return unzeof(reader.m_zipFile)
' a minizip C entry point; see ZipReader.OpenZip.bmx.
'
' Reads the position and length out of the handle TZipEStream.find_file builds (layout
' documented there). Load-bearing: TReplay.LoadReplayFile drives its whole frame loop on
' `While Not Eof(stream)`, and an Eof that always answered 0 would spin forever on a stream
' that had nothing left to give.
	Method Eof:Int()
		If Self.reader = Null Then Return 1
		Local h:Byte Ptr = Self.reader.m_zipFile
		If h = Null Then Return 1
		Local hd:Int Ptr = Int Ptr(h)
		If hd[1] >= hd[0] Then Return 1
		Return 0
	End Method

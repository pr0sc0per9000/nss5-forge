' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: TZipEStream.Pos @ 0x0058F9D1, 26 bytes, unrecovered.
' extracted/decomp/TZipEStream.Pos@0058f9d1.c is a single tail call:
'     return unztell(reader.m_zipFile)
' a minizip C entry point; see ZipReader.OpenZip.bmx.
'
' Reads the position out of the handle TZipEStream.find_file builds (layout documented
' there). Load-bearing for the byte-verified TZipEStream.Seek, which computes its forward
' walk as `a0 - Pos()` and rewinds via find_file(0) when asked to go backwards -- with Pos
' stuck at 0 that walk restarts from the beginning on every Seek and the stream never
' advances.
	Method Pos:Int()
		If Self.reader = Null Then Return 0
		Local h:Byte Ptr = Self.reader.m_zipFile
		If h = Null Then Return 0
		Local hd:Int Ptr = Int Ptr(h)
		Return hd[1]
	End Method

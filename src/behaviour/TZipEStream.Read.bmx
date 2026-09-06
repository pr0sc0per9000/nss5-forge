' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: TZipEStream.Read @ 0x0058FAE1, 63 bytes, unrecovered.
' extracted/decomp/TZipEStream.Read@0058fae1.c:
'     if (Eof()) return 0
'     return unzReadCurrentFile(reader.m_zipFile, buf, count)
' unzReadCurrentFile is a minizip C entry point; see ZipReader.OpenZip.bmx.
'
' Serves bytes out of the buffer TZipEStream.find_file decoded, whose layout is documented
' there. Short reads at the end of the entry are the normal TStream contract and are what
' the byte-verified TZipEStream.Seek's one-byte-at-a-time forward walk relies on.
	Method Read:Int(a0:Byte Ptr, a1:Int)
		If a1 <= 0 Then Return 0
		If Self.reader = Null Then Return 0
		Local h:Byte Ptr = Self.reader.m_zipFile
		If h = Null Then Return 0
		Local hd:Int Ptr = Int Ptr(h)
		Local n:Int = a1
		If n > hd[0] - hd[1] Then n = hd[0] - hd[1]
		If n <= 0 Then Return 0
		MemCopy(a0, h + 8 + hd[1], n)
		hd[1] = hd[1] + n
		Return n
	End Method

' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: TZipEStream.find_file @ 0x0058F882, 309 bytes, unrecovered.
' extracted/decomp/TZipEStream.find_file@0058f882.c reads, with the C names filled in:
'     if (reader.m_zipFile = 0) return 0
'     if (unzLocateFile(reader.m_zipFile, filename, case_sensitive ? 1 : 2)) return 0
'     if (password.length ? unzOpenCurrentFilePassword(h, password)
'                         : unzOpenCurrentFile(h))                      return 0
'     file_size = unzGetCurrentFileSize(h)
'     ...
' Every one of those is a minizip C entry point in the 0x0040xxxx band, so the body cannot
' be byte-recovered as BlitzMax. See ZipReader.OpenZip.bmx for the full argument.
'
' WHAT THIS DOES
' The same contract: select the entry named by `filename`, rewind it to its first byte, and
' publish its length in `file_size` (which the byte-verified TZipEStream.Size returns
' verbatim). The entry is decoded once, here, into a buffer hung off reader.m_zipFile --
' the same field the original keeps its open-entry handle in, reached from the same place by
' the same three methods (Read, Eof, Pos all go through reader.m_zipFile at +0x10 in the
' decompilation).
'
' THE HANDLE LAYOUT, because a Byte Ptr is the only slot available.
'     +0  Int   length of the entry in bytes
'     +4  Int   current read position
'     +8  ...   the entry's bytes
' MemAlloc rather than a Byte[] because there is no field to keep an array alive in, and a
' Byte Ptr into a GC array with no reference to the array is a use-after-free waiting to
' happen. It is released by ZipReader.CloseZip, which the byte-verified TZipEStream.Close
' calls -- so the normal path (LoadSavedGame and UpdateLoadTable both end in CloseStream)
' frees it. A TZipEStream dropped without Close leaks its buffer; TZipEStream.Delete is an
' empty body in the original and is left empty here rather than inventing one.
'
' a0 is the original's "verify" flag: 1 from TZipEStream.Create, 0 from the byte-verified
' TZipEStream.Seek when it needs to rewind. Both mean "position at the start of the entry"
' here, which is what Seek relies on.
	Method find_file:Int(a0:Int)
		If Self.reader = Null Then Return 0
		If Self.reader.m_zipFile <> Null
			MemFree(Self.reader.m_zipFile)
			Self.reader.m_zipFile = Null
		EndIf
		Self.file_size = 0

		Local rs:TRamStream = Self.reader.ExtractFile(Self.filename, Self.case_sensitive, Self.password)
		If rs = Null Then Return 0

		Local n:Int = rs.Size()
		If n < 0 Then n = 0
		Local h:Byte Ptr = MemAlloc(8 + n)
		If h = Null Then Return 0
		Local hd:Int Ptr = Int Ptr(h)
		hd[0] = n
		hd[1] = 0
		If n > 0 Then MemCopy(h + 8, rs._buf, n)
		Self.reader.m_zipFile = h
		Self.file_size = n
		Return 1
	End Method

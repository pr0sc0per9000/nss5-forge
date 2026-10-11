' ZipWriter.AddStream
' VA 0x0058E12E   764 bytes   vtable slot 0x5C   sig (:brl.stream.TStream,$,$)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (764/764, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 the stream, a1 name inside the zip, a2 password. Second half (0x0058E291 on) is the
' AddFileToDest tail verbatim: same zipOpenNewFileInZip 0x00404A00 / password glue
' 0x004015B0 split, LoadByteArray, zipWriteInFileInZip 0x00403D60, entry from a1.
' src IS A SOURCE LOCAL, not a0: a0 is loaded into edx at entry (0x0058E137) and copied to
' a fresh slot [ebp-0x1C] at 0x0058E147. A parameter that is live across calls stays in
' its own arg slot (AddFileToDest's a0 does); only a short-lived a0 copied into a
' call-spanning Local gives this shape.
' SeekStream(src,0) 0x005B80F8 result dropped; StreamSize -> [ebp-0x20].
' CurrentDate is called FIRST (0x005B4B0E, '%d %b %Y', -> esi), CurrentTime second
' (0x005B4B8B, '%H:%M:%S', -> edi). The alias row names both for both addresses; the
' format strings decide it.
' FileTime(a1) -> [ebp-4] and localtime_(Varptr) at 0x0058E192 with the result DROPPED
' (eax is overwritten by the bbObjectNew push at once): leftover from AddFileToDest.
' Slices, all bbStringSlice(s,beg,end) + bbStringToInt: tm_sec = time[7..] (one digit --
' the original's own off-by-one), tm_min = time[3..6], tm_hour = time[0..2],
' tm_mday = date[0..2], tm_year = date[date.length-4..]. tm_mon = Instr(literal 0x00C95B94,
' date[3..6].ToUpper(), 1) / 3 -- the divisor is materialised into [ebp-0x18] BEFORE the
' Instr call and the idiv is preceded by cdq,cdq (0x0058E25C).
' The tmz_date base is evaluated before each RHS and spilled to [ebp-0xC/-0x10/-0x14]
' while edi still holds the time string, then edi once time is dead.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method AddStream:Int(a0:TStream, a1:String, a2:String)
		If m_zipFile
			Local src:TStream = a0
			If src <> Null
				SeekStream(src, 0)
				Local size:Int = StreamSize(src)
				Local date:String = CurrentDate()
				Local time:String = CurrentTime()
				Local ftime:Int = FileTime(a1)
				localtime_(Varptr ftime)
				Local zfi:zip_fileinfo = New zip_fileinfo
				zfi.tmz_date.tm_sec = time[7..].ToInt()
				zfi.tmz_date.tm_min = time[3..6].ToInt()
				zfi.tmz_date.tm_hour = time[0..2].ToInt()
				zfi.tmz_date.tm_mday = date[0..2].ToInt()
				zfi.tmz_date.tm_mon = Instr("JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC", date[3..6].ToUpper()) / 3
				zfi.tmz_date.tm_year = date[date.length - 4..].ToInt()
				Local bank:TBank = zfi.getBank()
				If a2.length = 0
					zipOpenNewFileInZip(m_zipFile, a1, BankBuf(bank), Null, 0, Null, 0, Null, 8, m_compressionLevel)
				Else
					zipOpenNewFileInZipPassword(m_zipFile, a1, BankBuf(bank), Null, 0, Null, 0, Null, 8, m_compressionLevel, a2)
				EndIf
				Local data:Byte[] = LoadByteArray(src)
				zipWriteInFileInZip(m_zipFile, data, size)
				Local entry:SZipFileEntry = SZipFileEntry.Create()
				entry.zipFileName = a1
				entry.simpleFileName = StripDir(a1)
				entry.path = ExtractDir(a1)
				If Not m_zipFileList Then m_zipFileList = New TZipFileList
				m_zipFileList.FileList.AddLast(entry)
			EndIf
		EndIf
	End Method

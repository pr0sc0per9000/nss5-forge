' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipReader.ExtractFile @ 0x0058E536, 254 bytes, unrecovered -- minizip's
' unzLocateFile / unzOpenCurrentFilePassword / unzReadCurrentFile. See ZipReader.OpenZip.bmx
' for why the family cannot be byte-recovered as BlitzMax.
'
' Returns the named entry's bytes as a TRamStream, or Null. Entry lookup is done entirely
' by the already-recovered, byte-verified reader: getFileInfoByName() ->
' TZipFileList.findFile() hands back the central-directory record, which carries the
' local-header offset, both sizes, the compression method, the flags and the CRC-32.
' ZipRamStream.ZCreate (byte-verified) allocates the output buffer.
'
' The local header is re-read rather than trusted: its name and extra-field lengths are the
' only way to know where the entry's data actually starts, because the central directory
' does not record that.
'
' WHAT IT SUPPORTS, AND WHY IT HAS TO SUPPORT ALL OF IT
' Measured against a genuine retail save (the shipped game's own output), read-only:
'     entry 'newstarsoccerfivesavefile' flag=0x0001 method=8 csize=985503 usize=8439894
' -- traditional PKWARE ("ZipCrypto") encryption over a raw deflate stream. So a reader
' that only handled stored entries would round-trip this build's own saves perfectly and
' still fail on every save a player already owns, which is the exact trap of testing a
' writer against its own reader. Both are handled:
'     method 0 (stored)  -- copied
'     method 8 (deflate) -- inflated
'     flag bit 0         -- ZipCrypto-decrypted with the url's password
'
' THE ENCRYPTION-HEADER CHECK BYTE IS DELIBERATELY NOT ENFORCED.
' ZipCrypto prepends 12 encrypted bytes whose last plaintext byte is a verification byte.
' A reader is entitled to test it against the high byte of the CRC-32; Python's zipfile
' does, and it REJECTS the retail save with "Bad password" even though the password is
' right. Measured on that file: the byte is 0x00 while crc>>24 is 0x38. That is minizip
' behaving as written -- zipOpenNewFileInZip3 fills the byte from its `crcForCrypting`
' argument, and the game cannot know the CRC before it has compressed, so it passes 0. The
' CRC-32 recomputed over the finished plaintext is the honest acceptance test and it is the
' one used below; it caught nothing on the retail save (it matches exactly, 0x38e472fb) and
' it is what makes a wrong password or a damaged archive fail here rather than feed garbage
' into TProfile.LoadProfile.
'
' WHY INFLATE GOES THROUGH uncompress() AND IGNORES ITS RETURN CODE
' Pub.ZLib exposes exactly three entry points -- compress, compress2, uncompress -- and all
' three speak the zlib container (2-byte header, deflate stream, 4-byte adler-32), while a
' zip entry holds a RAW deflate stream with neither wrapper. Raw inflate would need
' inflateInit2_ with negative windowBits and a hand-built z_stream struct, declared Extern
' and poked field by field; that is a 56-byte layout assumption in a place where being
' wrong is silent. Instead the raw stream is wrapped: 0x78 0x01 in front (a valid zlib
' header: CM=8, CINFO=7, and 0x7801 is divisible by 31), four bytes behind so inflate has a
' trailer to consume and can reach Z_STREAM_END's checkpoint. The trailing four cannot be
' the real adler-32 -- it is not knowable before inflating -- so uncompress() returns
' Z_DATA_ERROR after having written every output byte. Its return code is therefore not
' evidence either way, and the CRC-32 above is what decides. zlib 1.2.3's uncompr.c, which
' is the copy bmk links, produces the full output before it ever looks at the trailer.
	Method ExtractFile:TRamStream(a0:String, a1:Int, a2:String)
		If a0 = "" Then Return Null
		Local ent:SZipFileEntry = Self.getFileInfoByName(a0)
		If ent = Null
			DebugLog "ZipReader.ExtractFile: no entry " + a0 + " in " + Self.getName()
			Return Null
		EndIf
		Local hdr:SZIPCentralFileHeader = ent.header
		If hdr = Null Then Return Null
		Local meth:Int = hdr.CompressionMethod
		Local enc:Int = hdr.GeneralBitFlag & 1
		If meth <> 0 And meth <> 8
			DebugLog "ZipReader.ExtractFile: " + a0 + " uses compression method " + ..
				meth + " -- only stored (0) and deflate (8) are supported"
			Return Null
		EndIf

		' ---- the CRC-32 table, used by the checksum AND by ZipCrypto ---------------
		Local tbl:Int[] = New Int[256]
		For Local i:Int = 0 Until 256
			Local c:Int = i
			For Local k:Int = 0 Until 8
				If c & 1
					c = $EDB88320 ~ (c Shr 1)
				Else
					c = c Shr 1
				EndIf
			Next
			tbl[i] = c
		Next

		' ---- raw bytes of the entry ------------------------------------------------
		Local s:TStream = ReadFile(Self.getName())
		If s = Null Then Return Null
		Local off:Int = hdr.RelativeOffsetOfLocalHeader
		SeekStream(s, off)
		If ReadInt(s) <> $04034b50
			DebugLog "ZipReader.ExtractFile: bad local header for " + a0
			CloseFile(s)
			Return Null
		EndIf
		SeekStream(s, off + 26)
		Local nameLen:Int = ReadShort(s)
		Local extraLen:Int = ReadShort(s)
		SeekStream(s, off + 30 + nameLen + extraLen)

		Local csize:Int = hdr.DataDescriptor.CompressedSize
		Local usize:Int = hdr.DataDescriptor.UncompressedSize
		If csize < 0 Or usize < 0
			CloseFile(s)
			Return Null
		EndIf
		Local raw:Byte[] = New Byte[csize]
		If csize > 0
			Local got:Int = 0
			While got < csize
				Local r:Int = s.Read(Varptr raw[got], csize - got)
				If r <= 0 Then Exit
				got = got + r
			Wend
			If got <> csize
				DebugLog "ZipReader.ExtractFile: " + a0 + " truncated (" + got + " of " + csize + ")"
				CloseFile(s)
				Return Null
			EndIf
		EndIf
		CloseFile(s)

		' ---- ZipCrypto ------------------------------------------------------------
		Local dataOff:Int = 0
		If enc
			If csize < 12
				DebugLog "ZipReader.ExtractFile: " + a0 + " is encrypted but too short"
				Return Null
			EndIf
			Local k0:Int = 305419896
			Local k1:Int = 591751049
			Local k2:Int = 878082192
			For Local i:Int = 0 Until a2.length
				k0 = (k0 Shr 8) ~ tbl[(k0 ~ a2[i]) & $ff]
				k1 = k1 + (k0 & $ff)
				k1 = (k1 * 134775813) + 1
				k2 = (k2 Shr 8) ~ tbl[(k2 ~ ((k1 Shr 24) & $ff)) & $ff]
			Next
			For Local i:Int = 0 Until csize
				Local t:Int = (k2 | 2) & $ffff
				Local p:Int = raw[i] ~ (((t * (t ~ 1)) Shr 8) & $ff)
				raw[i] = p
				k0 = (k0 Shr 8) ~ tbl[(k0 ~ p) & $ff]
				k1 = k1 + (k0 & $ff)
				k1 = (k1 * 134775813) + 1
				k2 = (k2 Shr 8) ~ tbl[(k2 ~ ((k1 Shr 24) & $ff)) & $ff]
			Next
			' The 12-byte encryption header's verification byte is NOT tested -- see the
			' header note; minizip writes 0 there and the CRC-32 below is the real test.
			dataOff = 12
		EndIf

		' ---- decompress ------------------------------------------------------------
		Local rs:TRamStream = ZipRamStream.ZCreate(usize, 1, 0)
		If rs = Null Then Return Null
		If usize > 0
			If meth = 0
				If csize - dataOff < usize
					DebugLog "ZipReader.ExtractFile: " + a0 + " stored entry is short"
					Return Null
				EndIf
				MemCopy(rs._buf, Varptr raw[dataOff], usize)
			Else
				' zlib wrapper around the entry's raw deflate stream -- see header note.
				Local n:Int = csize - dataOff
				Local wrapped:Byte[] = New Byte[n + 6]
				wrapped[0] = $78
				wrapped[1] = $01
				For Local i:Int = 0 Until n
					wrapped[2 + i] = raw[dataOff + i]
				Next
				Local outLen:Int = usize
				uncompress(rs._buf, outLen, Varptr wrapped[0], n + 6)
			EndIf
		EndIf

		' ---- the acceptance test ---------------------------------------------------
		Local crc:Int = -1
		For Local i:Int = 0 Until usize
			crc = tbl[(crc ~ rs._buf[i]) & $ff] ~ (crc Shr 8)
		Next
		crc = ~crc
		If crc <> hdr.DataDescriptor.CRC32
			DebugLog "ZipReader.ExtractFile: CRC mismatch on " + a0 + ..
				" (wrong password, or a damaged archive)"
			Return Null
		EndIf

		rs._pos = 0
		Return rs
	End Method

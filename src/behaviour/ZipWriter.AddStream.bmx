' ############################################################################
' # BEHAVIOUR body -- written from observed behaviour, NOT from the binary.  #
' # NOT byte-exact and never claimed to be.                                  #
' ############################################################################
'
' Real function: ZipWriter.AddStream @ 0x0058E12E, 764 bytes, unrecovered.
' Like the rest of the ZipWriter family it is a wrapper over minizip's C entry points
' (zipOpenNewFileInZip3 / zipWriteInFileInZip / zipCloseFileInZip), so it cannot be
' byte-recovered as BlitzMax. See ZipWriter.OpenZip.bmx for the full argument.
'
' WHAT THIS WRITES: THE RETAIL FORMAT, NOT A SUBSTITUTE FOR IT.
' Measured on a save produced by the shipped New Star Soccer 5 executable, read-only:
'     entry 'newstarsoccerfivesavefile'  flag=0x0001  method=8  csize=985503  usize=8439894
' -- traditional PKWARE ("ZipCrypto") encryption over a raw deflate stream. That is what
' this body produces when a password is supplied, so a save written here is the same kind of
' file the retail game writes and the retail game's own reader can open it. An earlier pass
' of this file wrote STORED, unencrypted entries instead. That was a valid ZIP and it round
' tripped perfectly against our own reader, which is exactly what made it dangerous: the
' retail reader calls unzOpenCurrentFilePassword unconditionally, so it would have consumed
' 12 bytes of real data as an encryption header and corrupted every entry. A writer must not
' be judged only by the reader that shares its assumptions.
'
' THE PIECES, AND WHERE THEY COME FROM
'   deflate    Pub.ZLib's compress2 emits a ZLIB stream: 2-byte header, the raw deflate
'              data, 4-byte adler-32. A zip entry stores that middle part alone, so the
'              wrapper is sliced off -- the exact mirror of the trick
'              src/behaviour/ZipReader.ExtractFile.bmx uses to inflate one.
'   ZipCrypto  the same keystream ExtractFile decrypts with, run the other way: the cipher
'              byte is emitted first and the keys are then updated from the PLAINTEXT byte.
'   the 12-byte encryption header
'              11 unpredictable bytes then one verification byte. minizip fills that byte
'              from zipOpenNewFileInZip3's `crcForCrypting` argument, and the game cannot
'              know the entry's CRC before it has compressed it, so it passes 0 -- measured
'              on the retail save, where byte 11 decrypts to 0x00 while crc>>24 is 0x38.
'              Writing 0 there is therefore matching the original, not cutting a corner.
'              (Python's zipfile enforces crc>>24 and calls the retail save's own password
'              wrong because of it.)
'   the 11 bytes
'              come from a private LCG seeded off MilliSecs(), deliberately NOT from Rand().
'              The game seeds the shared RNG once and match outcomes follow from it; drawing
'              from it here would make saving perturb gameplay.
'
' An empty password (TReplay.CreateReplay passes "") writes an unencrypted deflate entry,
' which is what the replay reader's 2-field "zipe::<file>::<entry>" url expects.
'
' WHY IT REWRITES RATHER THAN APPENDING IN PLACE
' There is nowhere to keep an open archive between OpenZip, AddStream and CloseZip: the
' Type's only spare slot is m_zipFile:Byte Ptr, which cannot hold a TStream without hiding
' an object reference from the collector, and a module Global declared by a body in this
' tree would be emitted into the MAIN compilation unit while this body is emitted into the
' external one, where it would not be visible (assemble.py's own note at the tp_gtext site).
' Rewriting keeps the whole operation stateless: read what is already there, split it at the
' central directory, put the new record in between. The game writes one entry per archive,
' so in practice the "existing content" path only runs if someone adds a second.
	Method AddStream:Int(a0:TStream, a1:String, a2:String)
		If a0 = Null Or a1 = "" Then Return 0
		Local path:String = Self.getName()
		If path = "" Then Return 0

		' ---- the payload ---------------------------------------------------------
		Local n:Int = a0.Size()
		If n < 0 Then n = 0
		Local data:Byte[] = New Byte[n]
		If n > 0
			a0.Seek(0)
			Local got:Int = 0
			While got < n
				Local r:Int = a0.Read(Varptr data[got], n - got)
				If r <= 0 Then Exit
				got = got + r
			Wend
			n = got
		EndIf

		' ---- whatever the archive already holds ----------------------------------
		Local old:Byte[] = New Byte[0]
		Local oldLocalLen:Int = 0
		Local oldCentral:Byte[] = New Byte[0]
		Local oldCentralLen:Int = 0
		Local oldCount:Int = 0
		If FileType(path) = 1
			Local rs:TStream = ReadFile(path)
			If rs <> Null
				Local sz:Int = Int(rs.Size())
				If sz > 0
					old = New Byte[sz]
					Local got2:Int = 0
					While got2 < sz
						Local r2:Int = rs.Read(Varptr old[got2], sz - got2)
						If r2 <= 0 Then Exit
						got2 = got2 + r2
					Wend
					sz = got2
				EndIf
				CloseFile(rs)
				' End of central directory: PK\5\6, scanned backwards exactly as
				' TZipFileList.ScanCentralHeader does.
				Local e:Int = sz - 22
				While e >= 0
					If old[e] = $50 And old[e + 1] = $4b And old[e + 2] = $05 And old[e + 3] = $06 Then Exit
					e = e - 1
				Wend
				If e >= 0
					oldCount = old[e + 10] | (old[e + 11] Shl 8)
					Local cdSize:Int = old[e + 12] | (old[e + 13] Shl 8) | (old[e + 14] Shl 16) | (old[e + 15] Shl 24)
					Local cdOff:Int = old[e + 16] | (old[e + 17] Shl 8) | (old[e + 18] Shl 16) | (old[e + 19] Shl 24)
					If cdOff >= 0 And cdSize >= 0 And cdOff + cdSize <= sz
						oldLocalLen = cdOff
						oldCentralLen = cdSize
						oldCentral = New Byte[cdSize]
						For Local i:Int = 0 Until cdSize
							oldCentral[i] = old[cdOff + i]
						Next
					Else
						oldCount = 0
					EndIf
				EndIf
			EndIf
		EndIf

		' ---- CRC-32 table, used by the checksum AND by ZipCrypto ------------------
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
		Local crc:Int = -1
		For Local i:Int = 0 Until n
			crc = tbl[(crc ~ data[i]) & $ff] ~ (crc Shr 8)
		Next
		crc = ~crc

		' ---- deflate -------------------------------------------------------------
		Local meth:Int = 8
		Local body:Byte[]
		Local bodyLen:Int = 0
		If n = 0
			' Nothing to compress; a stored empty entry is what every zip tool writes.
			meth = 0
			body = New Byte[0]
		Else
			Local cap:Int = n + (n / 1000) + 64
			Local zbuf:Byte[] = New Byte[cap]
			Local zlen:Int = cap
			Local level:Int = Self.m_compressionLevel
			If level < 0 Or level > 9 Then level = -1
			If compress2(Varptr zbuf[0], zlen, Varptr data[0], n, level) <> 0 Or zlen < 6
				DebugLog "ZipWriter.AddStream: deflate failed for " + a1
				Return 0
			EndIf
			' strip the 2-byte zlib header and the 4-byte adler-32 trailer
			bodyLen = zlen - 6
			body = New Byte[bodyLen]
			For Local i:Int = 0 Until bodyLen
				body[i] = zbuf[2 + i]
			Next
		EndIf

		' ---- ZipCrypto -----------------------------------------------------------
		Local flags:Int = 0
		Local head:Byte[] = New Byte[0]
		If a2.length > 0
			flags = 1
			Local k0:Int = 305419896
			Local k1:Int = 591751049
			Local k2:Int = 878082192
			For Local i:Int = 0 Until a2.length
				k0 = (k0 Shr 8) ~ tbl[(k0 ~ a2[i]) & $ff]
				k1 = k1 + (k0 & $ff)
				k1 = (k1 * 134775813) + 1
				k2 = (k2 Shr 8) ~ tbl[(k2 ~ ((k1 Shr 24) & $ff)) & $ff]
			Next
			head = New Byte[12]
			Local seed:Int = MilliSecs() ~ crc ~ (n Shl 7)
			For Local i:Int = 0 Until 11
				seed = (seed * 1103515245) + 12345
				head[i] = (seed Shr 16) & $ff
			Next
			head[11] = 0      ' minizip's crcForCrypting is 0 here -- see the header note
			For Local i:Int = 0 Until 12
				Local t:Int = (k2 | 2) & $ffff
				Local p:Int = head[i]
				head[i] = p ~ (((t * (t ~ 1)) Shr 8) & $ff)
				k0 = (k0 Shr 8) ~ tbl[(k0 ~ p) & $ff]
				k1 = k1 + (k0 & $ff)
				k1 = (k1 * 134775813) + 1
				k2 = (k2 Shr 8) ~ tbl[(k2 ~ ((k1 Shr 24) & $ff)) & $ff]
			Next
			For Local i:Int = 0 Until bodyLen
				Local t:Int = (k2 | 2) & $ffff
				Local p:Int = body[i]
				body[i] = p ~ (((t * (t ~ 1)) Shr 8) & $ff)
				k0 = (k0 Shr 8) ~ tbl[(k0 ~ p) & $ff]
				k1 = k1 + (k0 & $ff)
				k1 = (k1 * 134775813) + 1
				k2 = (k2 Shr 8) ~ tbl[(k2 ~ ((k1 Shr 24) & $ff)) & $ff]
			Next
		EndIf
		Local csize:Int = bodyLen + head.length

		' ---- rewrite -------------------------------------------------------------
		Local ws:TStream = WriteFile(path)
		If ws = Null
			DebugLog "ZipWriter.AddStream: cannot write " + path
			Return 0
		EndIf
		If oldLocalLen > 0 Then ws.WriteBytes(Varptr old[0], oldLocalLen)

		Local nameLen:Int = a1.length
		Local localOff:Int = oldLocalLen

		' local file header (30 bytes + name)
		ws.WriteInt($04034b50)
		ws.WriteShort(20)          ' version needed to extract
		ws.WriteShort(flags)
		ws.WriteShort(meth)
		ws.WriteShort(0)           ' last mod time  00:00:00
		ws.WriteShort($21)         ' last mod date  1980-01-01
		ws.WriteInt(crc)
		ws.WriteInt(csize)
		ws.WriteInt(n)
		ws.WriteShort(nameLen)
		ws.WriteShort(0)           ' extra field length
		ws.WriteString(a1)
		If head.length > 0 Then ws.WriteBytes(Varptr head[0], head.length)
		If bodyLen > 0 Then ws.WriteBytes(Varptr body[0], bodyLen)

		' central directory: the records that were already there, then this one
		Local cdStart:Int = localOff + 30 + nameLen + csize
		If oldCentralLen > 0 Then ws.WriteBytes(Varptr oldCentral[0], oldCentralLen)
		ws.WriteInt($02014b50)
		ws.WriteShort(20)          ' version made by
		ws.WriteShort(20)          ' version needed to extract
		ws.WriteShort(flags)
		ws.WriteShort(meth)
		ws.WriteShort(0)           ' last mod time
		ws.WriteShort($21)         ' last mod date
		ws.WriteInt(crc)
		ws.WriteInt(csize)
		ws.WriteInt(n)
		ws.WriteShort(nameLen)
		ws.WriteShort(0)           ' extra field length
		ws.WriteShort(0)           ' file comment length
		ws.WriteShort(0)           ' disk number start
		ws.WriteShort(0)           ' internal file attributes
		ws.WriteInt(0)             ' external file attributes
		ws.WriteInt(localOff)      ' relative offset of local header
		ws.WriteString(a1)

		Local cdSize2:Int = oldCentralLen + 46 + nameLen

		' end of central directory
		ws.WriteInt($06054b50)
		ws.WriteShort(0)           ' this disk
		ws.WriteShort(0)           ' disk with the start of the central directory
		ws.WriteShort(oldCount + 1)
		ws.WriteShort(oldCount + 1)
		ws.WriteInt(cdSize2)
		ws.WriteInt(cdStart)
		ws.WriteShort(0)           ' comment length
		CloseFile(ws)
		Return 1
	End Method

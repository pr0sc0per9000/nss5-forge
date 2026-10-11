' ZipReader.ExtractFile
' VA 0x0058E536   254 bytes   vtable slot 0x50   sig ($,i,$):brl.ramstream.TRamStream
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (254/254, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 entry name, a1 case-sensitivity flag, a2 password. Same skeleton as
' TZipEStream.find_file, on Self's own m_zipFile (+0x10): three nested tests, three
' `mov eax,bbNullObject` failure returns parked at 0x0058E618 / 0x0058E61F / 0x0058E626.
' a0 and a1 are cached in edx/eax at entry (0x0058E53F) -- allocator, not source.
' Password test at 0x0058E5AA: cmp [a2+8],0 / jne, plain unzOpenCurrentFile falls through.
' Success arm: size glue 0x00401580 -> esi; `call [0x00C94DEC]` is ZipRamStream's class
' table + 0xA8 = ZCreate, pushed (size, 1, 0) -> ebx; then
' unzReadCurrentFile(m_zipFile, [ebx+0x10], size) -- +0x10 is TRamStream._buf. The read's
' result is discarded and the stream returned.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method ExtractFile:TRamStream(a0:String, a1:Int, a2:String)
		If m_zipFile
			Local r:Int
			If a1
				r = unzLocateFile(m_zipFile, a0, 1)
			Else
				r = unzLocateFile(m_zipFile, a0, 2)
			EndIf
			If r = 0
				If a2.length = 0
					r = unzOpenCurrentFile(m_zipFile)
				Else
					r = unzOpenCurrentFilePassword(m_zipFile, a2)
				EndIf
				If r = 0
					Local size:Int = unzGetCurrentFileSize(m_zipFile)
					Local s:TRamStream = ZipRamStream.ZCreate(size, 1, 0)
					unzReadCurrentFile(m_zipFile, s._buf, size)
					Return s
				Else
					Return Null
				EndIf
			Else
				Return Null
			EndIf
		Else
			Return Null
		EndIf
	End Method

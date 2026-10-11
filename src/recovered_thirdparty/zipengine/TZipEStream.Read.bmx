' TZipEStream.Read
' VA 0x0058FAE1   63 bytes   vtable slot 0x48   sig (*b,i)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (63/63, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' Eof() is asked VIRTUALLY (slot 0x30 on Self, 0x0058FAF5), then `cmp eax,0 / jne
' 0x0058FB12`: the then-arm is the read, so the condition is `Not Eof()`. 0x00402580 is
' unzReadCurrentFile(file, buf, len), pushed a1, a0, reader.m_zipFile. The `mov eax,0`
' at 0x0058FB12 is the fall-through return.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method Read:Int(a0:Byte Ptr, a1:Int)
		If Not Eof()
			Return unzReadCurrentFile(reader.m_zipFile, a0, a1)
		EndIf
		Return 0
	End Method

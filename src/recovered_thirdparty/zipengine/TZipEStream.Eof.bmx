' TZipEStream.Eof
' VA 0x0058F9B7   26 bytes   vtable slot 0x30   sig ()i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (26/26, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' reader (+0x18) -> m_zipFile (+0x10) pushed straight into 0x00402880 unzeof, result
' returned. No Null guard on reader.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method Eof:Int()
		Return unzeof(reader.m_zipFile)
	End Method

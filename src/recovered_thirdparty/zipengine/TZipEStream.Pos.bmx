' TZipEStream.Pos
' VA 0x0058F9D1   26 bytes   vtable slot 0x34   sig ()i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (26/26, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' reader (+0x18) -> m_zipFile (+0x10) pushed straight into 0x00402860 unztell, result
' returned. Byte-for-byte the Eof body with a different call target.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method Pos:Int()
		Return unztell(reader.m_zipFile)
	End Method

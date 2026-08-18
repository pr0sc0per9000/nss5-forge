' SZipFileEntry.Less
' VA 0x0058F54F   38 bytes   vtable slot 0x38   sig (:SZipFileEntry)i
' byte-identical vs NSS5.exe (38/38)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method Less:Int(a0:SZipFileEntry)
		Return simpleFileName < a0.simpleFileName
	End Method

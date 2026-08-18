' SZipFileEntry.EqEq
' VA 0x0058F575   38 bytes   vtable slot 0x3c   sig (:SZipFileEntry)i
' byte-identical vs NSS5.exe (38/38)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method EqEq:Int(a0:SZipFileEntry)
		Return simpleFileName = a0.simpleFileName
	End Method

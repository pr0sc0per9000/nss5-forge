' SZipFileEntry.Create
' VA 0x0058F507   22 bytes   vtable slot 0x30   sig ():SZipFileEntry
' byte-identical vs NSS5.exe (22/22)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Function Create:SZipFileEntry()
		Return New SZipFileEntry
	End Function

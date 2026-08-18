' SZipFileEntry.New
' VA 0x0058F43A   118 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (118/118)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		header = New SZIPCentralFileHeader
	End Method

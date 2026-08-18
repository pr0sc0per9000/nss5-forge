' SZIPCentralFileHeader.New
' VA 0x0058F089   216 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (216/216)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		DataDescriptor = New SZIPFileDataDescriptor
	End Method

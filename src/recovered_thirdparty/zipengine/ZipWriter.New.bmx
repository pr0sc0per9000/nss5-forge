' ZipWriter.New
' VA 0x0058DDC3   48 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (48/48)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		'!Field m_compressionlevel = -1
	End Method

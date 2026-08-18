' ZipWriter.SetCompressionLevel
' VA 0x0058DEA6  29 bytes  vtable slot 0x50
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method SetCompressionLevel:Int(a0:Int)
		If m_zipFile<>Null Then m_compressionLevel=a0
	End Method

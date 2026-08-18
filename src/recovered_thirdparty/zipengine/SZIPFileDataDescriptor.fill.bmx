' SZIPFileDataDescriptor.fill
' VA 0x0058F04D   60 bytes   vtable slot 0x30   sig (:brl.stream.TStream)i
' byte-identical vs NSS5.exe (60/60)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
' Codegen note: `ReadInt(a0)` (the module Function form) is load-bearing -- the
' method-call spelling `a0.ReadInt()` compiles to a VIRTUAL call through a0's class
' table (`call [eax+0x6c]`) instead of the original's direct call to the runtime
' helper `_brl_stream_ReadInt` (VA 0x005B816F), a same-length MISMATCH at +6.

	Method fill:Int(a0:brl.stream.TStream)
		CRC32 = ReadInt(a0)
		CompressedSize = ReadInt(a0)
		UncompressedSize = ReadInt(a0)
		Return 0
	End Method

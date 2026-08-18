' SZipFileEntry.Compare
' VA 0x0058F59B   75 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (75/75)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
' Codegen note: the original downcasts a0 TWICE (once for the Null test, once to read
' simpleFileName) rather than caching it in a Local -- an intermediate Local reorders
' the register allocation and produces a byte-shorter, differently-shaped body (see
' TClass.Compare for the same trap). The early-return
' shape ("If not Null Then Return ...; Return -1") is also load-bearing: the mirrored
' If/Else form comes out the same length but with the branches swapped (je vs jne).

	Method Compare:Int(a0:Object)
		If SZipFileEntry(a0) <> Null Then Return simpleFileName.Compare(SZipFileEntry(a0).simpleFileName)
		Return -1
	End Method

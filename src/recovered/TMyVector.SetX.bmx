' TMyVector.SetX
' VA 0x004E2756   23 bytes   vtable slot 0x84   sig (d):TMyVector
' byte-identical vs NSS5.exe
' harness mode=reloc, 1 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method SetX:TMyVector(a0:Double)
		X = a0
	End Method

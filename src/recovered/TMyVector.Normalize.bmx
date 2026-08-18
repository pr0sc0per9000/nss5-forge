' TMyVector.Normalize
' VA 0x004E239B   68 bytes   vtable slot 0x58   sig ():TMyVector
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method Normalize:TMyVector()
		Local d:Double = 1.0 / GetLength()
		X = X * d
		Y = Y * d
		Z = Z * d
		Return Self
	End Method

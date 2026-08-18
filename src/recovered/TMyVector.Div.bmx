' TMyVector.Div
' VA 0x004E2370   43 bytes   vtable slot 0x54   sig (d):TMyVector
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method Div:TMyVector(a0:Double)
		a0 = 1.0 / a0
		X = X * a0
		Y = Y * a0
		Z = Z * a0
		Return Self
	End Method

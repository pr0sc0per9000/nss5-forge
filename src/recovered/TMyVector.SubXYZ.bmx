' TMyVector.SubXYZ
' VA 0x004E229F   47 bytes   vtable slot 0x44   sig (d,d,d):TMyVector
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method SubXYZ:TMyVector(a0:Double, a1:Double, a2:Double)
		X = X - a0
		Y = Y - a1
		Z = Z - a2
		Return Self
	End Method

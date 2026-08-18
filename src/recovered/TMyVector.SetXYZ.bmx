' TMyVector.SetXYZ
' VA 0x004E21FA   32 bytes   vtable slot 0x34   sig (d,d,d):TMyVector
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method SetXYZ:TMyVector(a0:Double, a1:Double, a2:Double)
		X = a0
		Y = a1
		Z = a2
		Return Self
	End Method

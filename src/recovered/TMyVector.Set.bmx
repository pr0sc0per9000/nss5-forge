' TMyVector.Set
' VA 0x004E221A   33 bytes   vtable slot 0x38   sig (:TMyVector):TMyVector
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method Set:TMyVector(a0:TMyVector)
		X = a0.X
		Y = a0.Y
		Z = a0.Z
		Return Self
	End Method

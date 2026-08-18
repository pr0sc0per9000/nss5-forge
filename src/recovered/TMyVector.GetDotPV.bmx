' TMyVector.GetDotPV
' VA 0x004E22CE   48 bytes   vtable slot 0x48   sig (:TMyVector)d
' byte-identical vs NSS5.exe
' harness mode=reloc, 1 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method GetDotPV:Double(a0:TMyVector)
		If a0 <> Null Then Return X*a0.X + Y*a0.Y + Z*a0.Z
		Return 0
	End Method

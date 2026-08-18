' TMyVector.Add
' VA 0x004E223B   50 bytes   vtable slot 0x3c   sig (:TMyVector):TMyVector
' byte-identical vs NSS5.exe
' harness mode=reloc, 1 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method Add:TMyVector(a0:TMyVector)
		If a0 <> Null Then
			X = X + a0.X
			Y = Y + a0.Y
			Z = Z + a0.Z
		EndIf
		Return Self
	End Method

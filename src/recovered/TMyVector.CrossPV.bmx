' TMyVector.CrossPV
' VA 0x004E22FE   75 bytes   vtable slot 0x4c   sig (:TMyVector):TMyVector
' byte-identical vs NSS5.exe
' harness mode=reloc, 1 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method CrossPV:TMyVector(a0:TMyVector)
		If a0 <> Null Then
			Local tx:Double = X
			Local ty:Double = Y
			Local tz:Double = Z
			X = ty*a0.Z - tz*a0.Y
			Y = tz*a0.X - tx*a0.Z
			Z = tx*a0.Y - ty*a0.X
		EndIf
		Return Self
	End Method

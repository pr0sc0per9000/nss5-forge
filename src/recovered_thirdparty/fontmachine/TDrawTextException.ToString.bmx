' TDrawTextException.ToString
' VA 0x005922E6   51 bytes   vtable slot 0x18   sig ()$
' byte-identical vs NSS5.exe (51/51)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
' Codegen note: the early-return shape ("If Description<>"" Then Return Description;
' Return default") is load-bearing -- the mirrored If/Else form comes out the same
' length (51/51) but with the two branches physically swapped (je vs jne), a MISMATCH.

	Method ToString:String()
		If PrivateData.Description <> "" Then Return PrivateData.Description
		Return "The requested action could not be completed."
	End Method

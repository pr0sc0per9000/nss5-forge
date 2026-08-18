' TDrawTextException.New
' VA 0x0059228F   53 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (53/53)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		'!Field privatedata:TPrivateException = New TPrivateException
	End Method

' TFontKerning.New
' VA 0x00592696   53 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (53/53)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		'!Field privatedata:TPrivateFontKerning = New TPrivateFontKerning
	End Method

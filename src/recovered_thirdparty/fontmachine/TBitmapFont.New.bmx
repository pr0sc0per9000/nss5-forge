' TBitmapFont.New
' VA 0x0058FF89   118 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (118/118)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Field defaults use the '''!Field pragma: the assignment happens
' inside the Type declaration, ahead of any body statement.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method New()
		'!Field kerning:TFontKerning = New TFontKerning
			'!Field usemask = 0
			'!Field maskcolorred = 0
			'!Field maskcolorgreen = 0
			'!Field maskcolorblue = 0
			'!Field phisicalpixelrounding = 0
			'!Field renderfx:iTextRendererFXBase = Null
			'!Field privatedata:TPrivateBitmapFont = New TPrivateBitmapFont
	End Method

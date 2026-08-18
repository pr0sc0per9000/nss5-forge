' TSnowFlake.Render
' VA 0x00505AA8   233 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (233/233, original length from Ghidra's inventory, mode=reloc)
' assumptions: Global 0x00C60238 Float (a global alpha multiplier), Global 0x00C6021C TImage
' (the flake sprite). BRL targets: 0x005ADC28 SetAlpha, 0x005AE079 SetRotation,
' 0x005AE0A8 SetScale, 0x005AE023 SetHandle, 0x005AD711 DrawImage, 0x005AD408 DrawRect.
' Self.t is a Byte, so the test is against 0. Self.w/2 is emitted TWICE in the original --
' bcc does no CSE, so it must be written twice here too.
	Method Render:Int()
		'!Global g_snow_alpha:Float
		'!Global g_snow_image:TImage
		SetAlpha Self.a * g_snow_alpha
		SetRotation Self.rot
		SetScale 1.0, 1.0
		If Self.t = 0
			SetScale Self.scl, Self.scl
			DrawImage g_snow_image, Self.x, Self.y, 0
		Else
			SetHandle Self.w/2, Self.w/2
			DrawRect Self.x, Self.y, Self.w, Self.w
		EndIf
	End Method

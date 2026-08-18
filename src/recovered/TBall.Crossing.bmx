' TBall.Crossing
' VA 0x004cbda9   267 bytes   vtable slot 0x74   sig (f)i
' byte-identical vs NSS5.exe (267/267, original length from Ghidra's inventory, mode=reloc)
' Assumptions: PTR_FUN_00C5D998 resolves to TPitch class table + 0x6c =
' TPitch.YardsToPixels(f)f. FUN_00506184 is the verified module WrapAngle(*f), taking
' the Local by Var. The four bare .rdata dwords Ghidra shows are ordinary Float
' literals, read out of the image: 0x00C72A78=145, 0x00C72A7C=215, 0x00C72A80=325,
' 0x00C72A84=35.
' The Float parameter is copied into a real Local at entry (fld [ebp+0xc]/fstp [ebp-4]);
' every later read of the angle is that Local, including the "= 0" test that Ghidra
' prints against param_2. The Null test is the 12-byte `<> Null` early-return form.
	Method Crossing:Int(a0:Float)
		Local d:Float = a0
		If Self.controlledby <> Null Then Return 0
		If Abs(Self.y) > TPitch.YardsToPixels(40)
			If d = 0 Then d = Self.direction
			WrapAngle(d)
			If d > 145 And d < 215 Then Return 1
			If d > 325 Or d < 35 Then Return 1
		EndIf
		Return 0
	End Method

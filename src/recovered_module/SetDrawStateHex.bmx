' SetDrawStateHex  -- module-level Function (no Type)
' VA 0x00506456   76 bytes   sig ($,f,f,f,i)i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Sets the whole Max2D draw state in one call: colour from a hex string,
' uniform scale, alpha, rotation and blend mode. The first callee is the already-verified
' module Function SetColourHex at 0x00505CEA, so its E8 masks by name on both sides.
'
' ALIAS SETS. Three of the four BRL targets are alias addresses in brl_functions.tsv and
' the member was chosen by argument shape: 0x005AE0A8 takes two Floats (SetScale, not
' CloseThemeHandle), 0x005ADC28 one Float (SetAlpha), 0x005ADBEF one Int (SetBlend).
' 0x005AE079 is unambiguous (_brl_max2d_SetRotation).
	Function SetDrawStateHex:Int(a0:String, a1:Float, a2:Float, a3:Float, a4:Int)
		SetColourHex(a0)
		SetScale a1, a1
		SetAlpha a2
		SetRotation a3
		SetBlend a4
	End Function

' TTable.CreateTableImage
' VA 0x005161a0   317 bytes   vtable slot 0x8c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (317/317, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' Gated on the module Function at 0x005071E5, recovered and verified as
' PackARGB (38/38 exact) -- see src/recovered_module/PackARGB.bmx.
' Inner loop is `For y = pm.height-1 To 0 Step -1` (jge); outer is `To pm.width-1` (jle).
' The x87 push order is 96.0, height, y -- so the source is `96.0 / pm.height * y`, NOT
' Ghidra's `y * (96.0 / height)`.
'!Global g_tableimage:TImage
	Function CreateTableImage:Int()
		Local pm:TPixmap = CreatePixmap(32, 32, 6, 4)
		pm.ClearPixels(0)
		For Local x:Int = 0 To pm.width - 1
			For Local y:Int = pm.height - 1 To 0 Step -1
				Local c:Float = 255.0 - 96.0 / pm.height * y
				If y >= pm.height / 2 Then c = 245.0 - 96.0 / pm.height * y
				pm.WritePixel(x, y, PackARGB(Int(c), Int(c), Int(c), 255))
			Next
		Next
		g_tableimage = LoadImage(pm)
	End Function

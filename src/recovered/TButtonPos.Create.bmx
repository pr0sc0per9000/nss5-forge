' TButtonPos.Create
' VA 0x00579ce2   55 bytes   vtable slot 0x30   sig (f,f):TButtonPos
' byte-identical vs NSS5.exe (55/55, original length from Ghidra's inventory)
	Function Create:TButtonPos(a0:Float, a1:Float)
		Local b:TButtonPos = New TButtonPos
		b.randno = Rand(1,99)
		b.x = a0
		b.y = a1
		Return b
	End Function

' TCombo.GetNoofDisplayItems
' VA 0x005189B8   173 bytes   vtable slot 0x9C   sig ()i
' byte-identical vs NSS5.exe (173/173, original length from Ghidra's inventory)

'!Global g_engine_int163:Int
'!Global g_screen_float02:Float
Local bot:Int = Int(Float(g_engine_int163) - g_screen_float02)
Local yy:Int = Int(y + h)
Local n:Int = 0
For Local i:Int = 0 To buttons.Count()
	If yy > bot Then Return n
	n :+ 1
	yy = Int(Float(yy) + h)
Next
Return buttons.Count()

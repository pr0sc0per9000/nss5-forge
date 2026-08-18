' TMyGfxModes.OnListAlready
' VA 0x00506cda   166 bytes   vtable slot 0x34   sig (i,i)i
' byte-identical vs NSS5.exe (166/166, original length from Ghidra's inventory)
' assumes module global:  Global g_Object133:TList  (0x00c60500, the gfx-mode list)
' 'If Not (x <> Null) / Else' is load-bearing, NOT stylistic: bcc only materialises the
' object null test (mov/cmp/setne/movzx/cmp/jne) when the comparison is nested inside Not.
' A plain 'If g <> Null' folds to 'cmp dword[mem],imm32; je' and is 9 bytes short.
	Function OnListAlready:Int(a0:Int, a1:Int)
		'!Global g_Object133:TList
		If Not (g_Object133 <> Null)
			Return 0
		Else
			For Local m:TMyGfxModes = EachIn g_Object133
				If m.w = a0 And m.h = a1 Then Return 1
			Next
			Return 0
		EndIf
	End Function

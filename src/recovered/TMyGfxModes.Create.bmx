' TMyGfxModes.Create
' VA 0x00506c98   66 bytes   vtable slot 0x30   sig (i,i)i
' byte-identical vs NSS5.exe (66/66, original length from Ghidra's inventory)
' No assumptions. The early-return form is load-bearing (a nested If is 7 bytes short).
	Function Create:Int(a0:Int, a1:Int)
		If OnListAlready(a0, a1) Then Return 0
		Local m:TMyGfxModes = New TMyGfxModes
		m.w = a0
		m.h = a1
	End Function

' TStats_Match.CountStat
' VA 0x0056d8f6   151 bytes   vtable slot 0x3c   sig (i)i
' byte-identical vs NSS5.exe (151/151, original length from Ghidra's inventory)
' EachIn downcast class table 0x00c6a97c = TStat.
	Method CountStat:Int(a0:Int)
		Local c:Int = 0
		For Local s:TStat = EachIn list
			If s.stype = a0 Then c = c + 1
			If a0 = 11
				If s.stype = 9 Or s.stype = 10 Then c = c + 1
			EndIf
		Next
		Return c
	End Method

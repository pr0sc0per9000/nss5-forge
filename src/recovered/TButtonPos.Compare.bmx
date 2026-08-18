' TButtonPos.Compare
' VA 0x00579d19   93 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' operand order matters: '<' then '>' with the downcast on the LEFT is what reproduces the cmp/jle pair
	Method Compare:Int(a0:Object)
		If a0 = Self
			Return 0
		Else
			If TButtonPos(a0).randno < randno
				Return 1
			ElseIf TButtonPos(a0).randno > randno
				Return -1
			Else
				Return 0
			EndIf
		EndIf
	End Method

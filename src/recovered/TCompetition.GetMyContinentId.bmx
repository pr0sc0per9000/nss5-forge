' TCompetition.GetMyContinentId
' VA 0x0050C28F   63 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (63/63, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.

	Method GetMyContinentId:Int()
		If locale = 1
			Return based
		ElseIf level = 0
			Local n:TNation = TNation.SelectById(based)
			If n <> Null Then Return n.continent
			Return 0
		Else
			Return based
		End If
	End Method

' TCompetition.GetNoofQualifiers
' VA 0x0050CBED   154 bytes   vtable slot 0xA0   sig ()i
' byte-identical vs NSS5.exe (154/154, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C59A30 = TNation class table + 0x68 = TNation.SelectListByContinent(i):TList.
' TList slot 0x38 = IsEmpty, slot 0x70 = Count (BRL.LinkedList, imported by the harness).
' `*(int*)(teampool + 0x18)` is element 0 of the BBArray (1-D array data starts at +0x18).
	Method GetNoofQualifiers:Int()
		If level = 0 And locale = 0 And comptype = 0
			Return teampool[0].list.Count()
		Else
			If level = 1 And lplacesthatpromotetome.IsEmpty()
				Return TNation.SelectListByContinent(based).Count()
			Else
				Return GetNoofTeamsInRound()
			EndIf
		EndIf
	End Method

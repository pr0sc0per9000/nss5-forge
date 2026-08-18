' TMyDate.GetStringDay
' VA 0x00537504   210 bytes   vtable slot 0x?   sig (i)$
' byte-identical vs NSS5.exe (210/210, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_004C5549 = recovered module Function GetText; FUN_004A7C90 = _bbStringSlice,
'   i.e. s[..a0]. Select, not If/ElseIf. The trailing truncation is an EARLY RETURN
'   (`cmp esi,0 / jne`) -- the If-block form is the same 210 bytes but differs at byte 184.
	Method GetStringDay:String(a0:Int)
		Local s:String = ""
		Select GetDay()
			Case 1
				s = GetText("date_Monday")
			Case 2
				s = GetText("date_Tuesday")
			Case 3
				s = GetText("date_Wednesday")
			Case 4
				s = GetText("date_Thursday")
			Case 5
				s = GetText("date_Friday")
			Case 6
				s = GetText("date_Saturday")
			Case 7
				s = GetText("date_Sunday")
		End Select
		If a0 = 0 Then Return s
		Return s[..a0]
	End Method

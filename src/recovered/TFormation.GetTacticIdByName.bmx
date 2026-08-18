' TFormation.GetTacticIdByName
' VA 0x004D9911   410 bytes   vtable slot 0x68   sig ($)i
' byte-identical vs NSS5.exe (410/410, original length from Ghidra's inventory)
' string literals read out of NSS5.exe's .data (bbString objects at 0x00C74D14 ..0x00C74E6C)
	Function GetTacticIdByName:Int(a0:String)
		If a0 = "3-4-3"
			Return 1
		ElseIf a0 = "3-5-2 A"
			Return 2
		ElseIf a0 = "3-5-2 B"
			Return 3
		ElseIf a0 = "4-2-2-2"
			Return 4
		ElseIf a0 = "4-2-4"
			Return 5
		ElseIf a0 = "4-3-3"
			Return 6
		ElseIf a0 = "4-4-1-1"
			Return 7
		ElseIf a0 = "4-4-2 A"
			Return 8
		ElseIf a0 = "4-4-2 B"
			Return 9
		ElseIf a0 = "4-5-1"
			Return 10
		ElseIf a0 = "5-3-2"
			Return 11
		ElseIf a0 = "Custom 1"
			Return 12
		ElseIf a0 = "Custom 2"
			Return 13
		ElseIf a0 = "Custom 3"
			Return 14
		Else
			Return 0
		EndIf
	End Function

' TEngine.WaitForSetpiece
' VA 0x004d3689   179 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (179/179, original length from Ghidra's inventory, mode=reloc)
' Assumptions: module Global 0x00C5B1FC is the Int setpiece-type (globals_final.tsv types
' it :TPlayer; the code is a plain dword compare chain, so Int).
' This is a SELECT, not If/ElseIf -- all twelve compares are emitted back to back before
' any body, and the CASE ORDER IS LOAD-BEARING: 0,1,2,3,4,5,6,7,9,10,8,11 (note 9 before
' 10 before 8 before 11). Cases 0,1,3,6,10,8,11 have empty bodies. The trailing Return 0
' is the statement after End Select, which is what emits the final jmp.
' PTR_FUN_00C5AEDC is TBall class table + 0x44 = TBall.GetActiveBall():TBall;
' field 0x84 is TBall.setpiecebuddy.
	Function WaitForSetpiece:Int()
		'!Global g_setpiecetype:Int
		Select g_setpiecetype
		Case 0
		Case 1
		Case 2
			Return 1
		Case 3
		Case 4
			Local b:TBall = TBall.GetActiveBall()
			If b <> Null And b.setpiecebuddy <> Null Then Return 1
		Case 5
			Return 1
		Case 6
		Case 7
			Return 1
		Case 9
			Return 1
		Case 10
		Case 8
		Case 11
		End Select
		Return 0
	End Function

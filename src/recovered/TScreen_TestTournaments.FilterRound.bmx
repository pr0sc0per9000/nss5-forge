' TScreen_TestTournaments.FilterRound
' VA 0x00538f6b   181 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (181/181, original length from Ghidra's inventory)
' assumptions: module Global 0x00c66440 declared Int (globals_final, 12 dword writes).
'              Class-table slots: 0x00c621cc = TGadget+0x7c GetActiveGadgetName()$,
'              0x00c665d8 = TScreen_TestTournaments+0x34 SetUpScreen.
'              String literals read out of NSS5.exe at 0x00c8541c/34/60/74/88.
' NOTE: textbook Select (guide 10.2) -- five _bbStringCompare tests emitted back to back,
'       then `EB 36 jmp` for the no-match path, then the five bodies. No Default, so the
'       no-match jump lands on the statement AFTER End Select.
'       `:- 1` / `:+ 1` matter here: the Global is a memory operand, so they emit
'       `sub dword [g],1` / `add dword [g],1` (guide 6).
	Function FilterRound:Int()
		'!Global g_tt_round:Int
		Select TGadget.GetActiveGadgetName()
			Case "rndLL"
				g_tt_round = 1
			Case "rndL"
				g_tt_round :- 1
			Case "rnd"
				g_tt_round = 1
			Case "rndR"
				g_tt_round :+ 1
			Case "rndRR"
				g_tt_round = 99999
		End Select
		TScreen_TestTournaments.SetUpScreen()
	End Function

' TBlackJack.Play
' VA 0x00576dee   88 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (88/88, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global at 0x00c6c174 declared :Int (the hand state), module Global at
' 0x00c6c16c declared :TList (the argument to Hit(:TList)).
' PTR_FUN_00c6c324 = TBlackJack + 0x3c = Deal; 0x00c6c334 = +0x4c = Hit(:TList);
' 0x00c6c32c = +0x44 = CheckPlayerScore; 0x00c6c158 = TScreen_BlackJack + 0x40 = UpdateScoreLabels.
' Select/Case is load-bearing -- it emits the original's `mov eax,[mem]` dispatch; the
' If/ElseIf chain emits `cmp [mem],imm` per arm and cannot reach 88 bytes.
' The empty `Case 2` is required (7 bytes); a trailing empty `Default` is byte-indistinguishable.
	Function Play()
		'!Global g_bjState:Int
		'!Global g_bjPlayerHand:TList
		Select g_bjState
			Case 0
				TBlackJack.Deal()
			Case 1
				TBlackJack.Hit(g_bjPlayerHand)
				TBlackJack.CheckPlayerScore()
			Case 2
			Case 3
				TBlackJack.Deal()
		End Select
		TScreen_BlackJack.UpdateScoreLabels()
	End Function

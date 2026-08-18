' TBlackJack.Update
' VA 0x00576C76   141 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6C174:Int (blackjack state), 0x00C6C01C:TButton,
' and 0x00C6F090:TChannel -- globals_final leaves that one untyped, but every other use of
' it in the corpus is the second argument of _brl_audio_PlaySound (the channel), and slot
' 0x48 on TChannel is Playing():Int, which is exactly what is compared against 0 here.
' 0x00C6C330 = TBlackJack + 0x48 = DealersTurn (sibling Function, unqualified);
' 0x00C6B268 = TScreenMessage + 0x34 = Count(); 0x00C6C14C = TScreen_BlackJack + 0x34 =
' SetUpScreen. Field 0x3C on TButton is TGadget.hidden (inherited).
' The state test is a SELECT with EMPTY Case 0 and Case 1 bodies -- they emit the two
' `jmp end` stubs at offsets 30 and 32.
	Function Update:Int()
		'!Global g_blackjack_state:Int
		'!Global g_channel:TChannel
		'!Global g_bj_btn3:TButton
		Select g_blackjack_state
			Case 0
			Case 1
			Case 2
				If g_channel.Playing() = 0
					DealersTurn()
				EndIf
			Case 3
				If g_channel.Playing() = 0 And TScreenMessage.Count() = 0 And g_bj_btn3.hidden
					TScreen_BlackJack.SetUpScreen()
				EndIf
		End Select
	End Function

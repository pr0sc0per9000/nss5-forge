' TScreen_Roulette.PlaceBet
' VA 0x00574f1d   266 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (266/266, original length from Ghidra's inventory)
' Global: 0x00C6BA60 :Int[] (the six bet stakes) -- globals_final.tsv calls it Object[];
' the call sites take the address of element k (lea [eax+0x18+4k]) so it is Int[].
' TGadget.GetActiveGadgetName is TGadget+0x7C; TScreen_Roulette.IncreaseBet is +0x40
' and takes Int Var (written Varptr here because the probe declares it Int Ptr);
' UpdateBetLabels is +0x48. The six literals are string objects in the image.
' This is a Select with no Default -- all six _bbStringCompare tests are emitted back
' to back before any body. If/ElseIf gives 268 bytes.
	Function PlaceBet:Int()
		'!Global g_roul_bets:Int[]
		Local n:String = TGadget.GetActiveGadgetName()
		Select n
			Case "btn_odd"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[0])
			Case "btn_even"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[1])
			Case "btn_red"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[2])
			Case "btn_black"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[3])
			Case "btn_1to18"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[4])
			Case "btn_19to36"
				TScreen_Roulette.IncreaseBet(Varptr g_roul_bets[5])
		End Select
		TScreen_Roulette.UpdateBetLabels()
		Return 0
	End Function

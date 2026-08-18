' TScreen_Leagues.ButtonRound
' VA 0x005462d4   108 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' the comptype guard must be a Select with an empty 'Case 1' and the work in Default:
' a plain nested If is 6 bytes short (Select loads the field into a register, emits the
' dispatch jmp, and emits the empty case body). Three module Globals assumed:
' 0x00c66f5c:TCompetition (declared type IS pinned - GetPrevRound/GetNextRound are slots
' 0xc8/0xcc), 0x00c66f40:Int, and 0x00c671a4 as a function pointer Int(Int).
	Function ButtonRound:Int()
		'!Global g_league_comp:TCompetition
		'!Global g_league_prevmode:Int
		'!Global g_league_setround:Int(a:Int)
		If g_league_comp <> Null
			Select g_league_comp.comptype
				Case 1
				Default
					If g_league_prevmode <> 0
						g_league_setround(g_league_comp.GetPrevRound())
					Else
						g_league_setround(g_league_comp.GetNextRound())
					EndIf
			End Select
		EndIf
	End Function

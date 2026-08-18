' TScreen_Stable.ButtonRaceHorse
' VA 0x00589eb4   743 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (743/743, original length from Ghidra's inventory)
' assumes module global:  Global g_Object837:TButton                (0x00c6ded4)
' assumes module global:  Global g_screen_stable_int02:Int          (0x00c6df64)
' assumes module global:  Global g_screen_stable_int05:Int          (0x00c6df70)
' assumes module global:  Global g_Object851:TList                  (0x00c6e298; globals_final.tsv says Object)
' assumes module global:  Global g_screen_stable_tplayer01:TTable   (0x00c6dec8; NOT TLabel as globals_final.tsv says -- slot 0xd8 is TTable.GetSelectedText(i)$)
' TList slot 0x54 = RemoveLast() (First()=0x48 rejects at +637).

	Function ButtonRaceHorse:Int()
		'!Global g_Object837:TButton
		'!Global g_screen_stable_int02:Int
		'!Global g_screen_stable_int05:Int
		'!Global g_Object851:TList
		'!Global g_screen_stable_tplayer01:TTable
		If g_Object837.alph < 1.0 Then Return 0
		If g_screen_stable_int02 > 6 Or (g_screen_stable_int02 = 6 And g_screen_stable_int05 = 0)
			TScreen.DoMessage(GetText("CMESSAGE_NOMORERACES"),0,0)
			Return 0
		EndIf
		If g_screen_stable_int05 <> 0
			For Local h:THorse = EachIn g_Object851
				If h.owned <> 0
					TScreen.DoMessage(GetText("CMESSAGE_ONLY1HORSE"),0,0)
					Return 0
				EndIf
			Next
		EndIf
		Local sel:THorse = TScreen_Stable.GetSelectedHorse(g_screen_stable_tplayer01.GetSelectedText(0))
		If Not sel
			TScreen.DoMessage(GetText("CMESSAGE_SELECTHORSE"),0,0)
			Return 0
		EndIf
		If sel.health < 70.0
			TScreen.DoMessage(GetText("CMESSAGE_HORSEILL"),0,0)
			Return 0
		EndIf
		If sel.energy < 10.0
			TScreen.DoMessage(GetText("CMESSAGE_HORSETIRED"),0,0)
			Return 0
		EndIf
		If TScreen.DoMessage(GetText("CMESSAGE_RACEHORSE"),1,0)
			If g_screen_stable_int05 = 0 Then TScreen_Stable.SetUpNextRace()
			Local found:Int = 0
			For Local h:THorse = EachIn g_Object851
				If h = sel Then found = 1
			Next
			If found = 0
				Local f:THorse = THorse(g_Object851.RemoveLast())
				sel.racenum = f.racenum
				f.betamount = 0
				f.racenum = 0
				f.betprice = 0
				f.raceposition = 0
				g_Object851.AddLast(sel)
			EndIf
			THorse.SetRaceOdds()
			TScreen_Stable.RefreshRunners(0)
			TScreen_Stable.ButtonQuit()
		EndIf
	End Function

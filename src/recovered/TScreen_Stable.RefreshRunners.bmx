' TScreen_Stable.RefreshRunners
' VA 0x00588880   521 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i)i, class-table slot 0x5c
' ASSUMPTIONS
'   0x00C6E298 g_horses:TList              (Sort at slot 0x88, ObjectEnumerator at 0x8C)
'   0x00C6DEF4 g_stable_oddslabels:TLabel[]   (SetText 0x64 / SetColour 0x6C via TGadget)
'   0x00C6DF04 g_stable_horsebuttons:TButton[] (SetIcon at slot 0x90 is TButton's own)
'   0x00C6E29C g_stable_racetime:Int
'   0x00C6DF6C g_stable_selectedrunner:Int
'   0x00C6DEAC g_img_tick:TImage           (only passed to TButton.SetIcon(:TImage))
'   THorse.GetHorseColour reached as a class-table static (THorse+0x74)
'!Global g_stable_racetime:Int
'!Global g_horses:TList
'!Global g_stable_oddslabels:TLabel[]
'!Global g_stable_horsebuttons:TButton[]
'!Global g_stable_selectedrunner:Int
'!Global g_img_tick:TImage
LogLine("RefreshRunners")
g_stable_racetime = 31
g_horses.Sort(1, CompareObjects)
Local i:Int = 0
For Local h:THorse = EachIn g_horses
	g_stable_oddslabels[i].SetText(h.betprice + " / 1", "", -1, -1)
	g_stable_oddslabels[i].SetColour("AAAAAA", "FFFFFF")
	If a0
		g_stable_oddslabels[i].SetText(GetText("position_" + h.raceposition), "", -1, -1)
		If h.raceposition = 1
			g_stable_oddslabels[i].SetColour("AAAAAA", "FFFF00")
		EndIf
	EndIf
	g_stable_horsebuttons[i].SetText(h.name, "", -1, -1)
	g_stable_horsebuttons[i].SetIcon(Null)
	If h.owned
		g_stable_horsebuttons[i].SetIcon(g_img_tick)
	EndIf
	g_stable_horsebuttons[i].SetColour("FFFFFF", "FFFFFF")
	If i = g_stable_selectedrunner - 1
		g_stable_horsebuttons[i].SetColour(THorse.GetHorseColour(i + 1), "FFFFFF")
	EndIf
	i = i + 1
Next

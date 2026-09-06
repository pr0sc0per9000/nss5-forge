' TScreen_Stable.RefreshRunners
' VA 0x00588880   521 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i)i, class-table slot 0x5c
' ASSUMPTIONS
'   0x00C6E298 g_runners:TList              (Sort at slot 0x88, ObjectEnumerator at 0x8C)
'   0x00C6DEF4 g_stable_oddslabels:TLabel[]   (SetText 0x64 / SetColour 0x6C via TGadget)
'   0x00C6DF04 g_stable_horsebuttons:TButton[] (SetIcon at slot 0x90 is TButton's own)
'   0x00C6E29C g_stable_racetime:Int
'   0x00C6DF6C g_stable_selectedrunner:Int
'   0x00C6DEAC g_stable_imgStar:TImage     (only passed to TButton.SetIcon(:TImage))
'       TScreen_Stable.CreateScreen loads Star.png into this slot under that name. The
'       g_img_tick spelling put it on the same emitted variable as 0x00C6F274, the
'       corpus-wide accept icon TScreen_Controls.CreateScreen also called g_img_tick, so
'       neither could merge onto its writer and this SetIcon passed Null.
'   THorse.GetHorseColour reached as a class-table static (THorse+0x74)
'!Global g_stable_racetime:Int
' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
' two are provably different slots, and the module body creates them separately. Spelled
' g_runners here, this body's slot shared the emitted variable of the master list.
'!Global g_runners:TList
'!Global g_stable_oddslabels:TLabel[]
'!Global g_stable_horsebuttons:TButton[]
'!Global g_stable_selectedrunner:Int
'!Global g_stable_imgStar:TImage
LogLine("RefreshRunners")
g_stable_racetime = 31
g_runners.Sort(1, CompareObjects)
Local i:Int = 0
For Local h:THorse = EachIn g_runners
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
		g_stable_horsebuttons[i].SetIcon(g_stable_imgStar)
	EndIf
	g_stable_horsebuttons[i].SetColour("FFFFFF", "FFFFFF")
	If i = g_stable_selectedrunner - 1
		g_stable_horsebuttons[i].SetColour(THorse.GetHorseColour(i + 1), "FFFFFF")
	EndIf
	i = i + 1
Next

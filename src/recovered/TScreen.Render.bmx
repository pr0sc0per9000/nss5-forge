' GLOBAL RENAMED (2026-08-15): g_Object101 -> g_curscreen. Same slot, 0x00C61700 -- THE ACTIVE
' SCREEN. This one slot carried FOUR names across the corpus: g_curscreen (majority, 8
' declarers), g_currentscreen, g_screen, and the decoder auto-name g_Object101. In the
' assembled program those became four independent Globals, so TScreen.SetActive wrote
' the newly-activated screen into one while the main loop's TScreen.Update and
' TScreen.Render read others. The game booted, opened its window and ran the
' fixed-timestep loop -- and drew the boot 'loading' screen forever, because the screen
' the loop rendered was never the screen SetActive had set. Byte-neutral; confirmed
' with scripts/reverify.py.
' Scope check before renaming: g_Object101 resolves to 0x00C61700 and nothing else
' anywhere in src/recovered. g_screen was renamed ONLY in TScreen.Update.bmx, the one
' file that states the address -- the other 8 g_screen declarers record no VA, and the
' name->address map is many-to-many, so sweeping it would be a guess.
' TScreen.Render
' VA 0x00510dc5   55 bytes   vtable slot 0x68   sig (f)i
' byte-identical vs NSS5.exe (55/55, original length from Ghidra's inventory)
' assumes module global:  Global g_roulette_float:Float
' assumes module global:  Global g_curscreen:TScreen
' globals 0x00c6172c / 0x00c61700; Draw is slot 0x6c, DrawMouse is TScreen slot 0x74

	Function Render:Int(a0:Float)
		'!Global g_roulette_float:Float
		'!Global g_curscreen:TScreen
		g_roulette_float = a0
		If g_curscreen <> Null Then g_curscreen.Draw()
		DrawMouse()
	End Function

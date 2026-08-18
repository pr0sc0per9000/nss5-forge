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
' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen.TextEntered
' VA 0x00512d21   68 bytes   vtable slot 0xa0   sig ()i
' byte-identical vs NSS5.exe (68/68, original length from Ghidra's inventory)
' assumes module global:  Global g_curscreen:TScreen
' assumes module global:  Global g_Object108:TGadget
' globals 0x00c61700 (current screen) / 0x00c61cf8 (active gadget)

	Function TextEntered:Int()
		'!Global g_Object108:TGadget
		'!Global g_curscreen:TScreen
		g_Object108 = g_curscreen.GetGadgetByName("msgscreen_ok")
	End Function

' GLOBAL RENAMED (2026-08-15): g_currentscreen -> g_curscreen. Same slot, 0x00C61700,
' stated in this file's own header and in TScreen.SetActive's. SetActive WRITES the
' active screen as g_curscreen and this file READ it as g_currentscreen, so in the
' assembled program they were two Globals and the reader always saw Null -- the boot
' died in SetActiveGadget on `g_currentscreen.gadgetlist` while setting up the very
' first screen. 8 files already spell 0x00C61700 g_curscreen; only these 2 did not.
' Byte-neutral (Global names never appear in the compiled bytes; the oracle masks the
' address) -- confirmed with scripts/reverify.py.
' CAUTION for anyone extending this: g_curscreen is ALSO used for a DIFFERENT slot,
' 0x00C6764C, in TScreen_MatchPaused.ButtonSkipTime and others. The name->address map
' is many-to-many, so never sweep-rename it globally; see scripts/unify_globals.py.
' TScreen.CreateScreen
' VA 0x005103c3   381 bytes   class-table slot 0x38   sig ($,:TImage,()i,()i):TScreen
' byte-identical vs NSS5.exe (381/381, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. 0x00C61714 TImage (fallback background), 0x00C61700 TScreen
' (the current screen -- if none is set yet this one becomes active),
' 0x00C6EFDC / 0x00C6EFE0 Int (screen width / height).
'
' The help text is looked up as "help_" + Lower(name); GetText returns "@"+key when the key
' is missing (see TLocale.GetLocaleText), which is exactly what StartsWith("@") tests.
'!Global g_defaultbg:TImage
'!Global g_curscreen:TScreen
' g_screenwidth/g_screenheight are the screen width/height (0x00C6EFDC=800,
' 0x00C6EFE0=600, the game's fixed 800x600 resolution -- codegen-patterns 21.1/21.3).
' The SAME two addresses are also declared under two other names elsewhere in the corpus
' (g_screen_int21/g_screen_int22 in TScreen.UpdateOffset.bmx and others, g_screenw/g_screenh
' in TScreen.Draw.bmx); merge_globals dedups by name, not address, so each name family
' needs its own initialiser or it stays a separate, zero-defaulted Global in the assembled
' build. This is the dominant name -- ~30 files use it.
'!Global g_screenwidth:Int = 800
'!Global g_screenheight:Int = 600
' The predicate is .Contains, not .StartsWith. extracted/runtime_helpers.tsv names
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row right, this body is MISMATCH as .StartsWith and MATCH as .Contains.
'
' The case call is .Lower, not .Upper -- the SAME defect class, one call further up the
' same line. extracted/runtime_helpers.tsv names the call target 0x004A74E0
' _brl_retro_Upper; decompiling it directly (0x004A7410 and 0x004A74E0 side by side,
' both 190 bytes, both calling the shared allocator FUN_004a72d0 and otherwise identical
' in shape) shows the two labels are swapped:
'   0x004A7410 (labelled _brl_retro_Lower): `if (c-0x61 < 0x1a) c &= 0xFFDF` clears the
'     0x20 bit on 'a'..'z' -- that RAISES case. This is Upper.
'   0x004A74E0 (labelled _brl_retro_Upper): `if (c-0x41 < 0x1a) c |= 0x20` sets the
'     0x20 bit on 'A'..'Z' -- that LOWERS case. This is Lower.
' Confirmed against data: every one of the 33 `help_*` rows in
' GameMedia/Languages/Languages.csv (help_newplayer, help_matchprep, help_mycontract,
' ...) has its screen-name suffix in lowercase, matching every screen-name literal passed
' to TScreen.CreateScreen (also all lowercase, e.g. "newplayer"). Lower(s.name) is a
' no-op on those and the built key matches the CSV tag exactly; Upper(s.name) matches
' none of them, so h.Contains("@") is always true and every screen's help falls back to
' help_nohelp ("Sorry but there is no help for this screen!"). TMap keys strings via
' bbStringCompare (blitz_string.c:238), a plain case-sensitive byte compare, so this is
' not a false alarm from a case-insensitive lookup elsewhere.
	Function CreateScreen:TScreen(a0:String, a1:TImage, a2:Int(), a3:Int())
		LogLine("Create Screen:" + a0)
		Local s:TScreen = New TScreen
		s.name = a0
		s.bg = a1
		If s.bg = Null
			s.bg = g_defaultbg
		EndIf
		s.fDraw = a2
		s.fUpdate = a3
		s.gadgetlist = CreateList()
		If Not g_curscreen
			TScreen.SetActive(a0, "")
		EndIf
		Local h:String = GetText("help_" + Lower(s.name))
		If h.Contains("@")
			h = GetText("help_nohelp")
		EndIf
		s.lHelp.AddLast(THelpBox.Create(Null, g_screenwidth / 2 - 240, g_screenheight / 2 - 130, 480, 260, h, 0, 3))
		Return s
	End Function

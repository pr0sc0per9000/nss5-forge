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
' TScreen.GetInput
' VA 0x00511535   2416 bytes   class-table slot 0x80   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (2416/2416, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=179)
' Body-only format: statements only, no parameters.
'
' What it does: reads mouse/keyboard/joystick this frame and returns one menu-navigation
' code (0=none, 1..4=up/down/left/right, 5=select, 6=tab). TScreen.CheckInput (already
' recovered, src/recovered/TScreen.CheckInput.bmx) calls Self.GetInput() and Selects on the
' result.
'
' assumptions (module Globals, names ours; all bare Int/Float except g_curscreen):
'   0x00C6EFE4 g_engine_int162:Int   0x00C6EFE8 g_engine_int163:Int
'   0x00C6EFEC g_engine_int164:Int   -- "joystick enabled" gate
'   0x00C61740 g_screen_float03:Float   0x00C61744 g_screen_float04:Float  -- scaled mouse xy
'   0x00C61748 g_screen_float05:Float   0x00C6174C g_screen_float06:Float  -- last-frame mouse xy
'   0x00C7DB78 g_screen_float07:Float   0x00C7DB7C g_screen_float08:Float  -- idle stick xy
'   0x00C6173C g_screen_int03:Int    -- "mouse mode" activity timestamp (also used elsewhere,
'                                        e.g. TCombo.DrawItems, TGadget.DrawHighlight)
'   0x00C7DB80 g_screen_int23:Int    -- "digital stick mode" latch
'   0x00C7DB84 g_screen_int24:Int    -- key-repeat timestamp
'   0x00C6EFD4 g_player_int50:Int    -- frame clock (millis), also used by TBall/TEngine
'   0x00C5D1A8 g_options_int01:Int   -- selects joystick device 0 or 1
'   0x00C5D1B4..E4 g_options_arr02..08:Int[] -- 7 configurable controls (up/down/left/right/
'       3 action buttons); element 0 = key binding, element 1 = joystick button binding
'       (0x00C5D1D4 g_options_arr06 already typed Int[] by src/recovered/TOptions.NewButtonKick.bmx)
'   0x00C61700 g_curscreen:TScreen   -- the active screen (also used by TScreen.Render etc.)
'
' control flow, ground-truthed from raw disassembly (the annotated Ghidra decompilation of
' this function mis-renders several early returns as unreachable/merged and must NOT be
' trusted for control flow here, only for rough field/global identification):
'   1. scale mouse position into g_screen_float03/04 (branch on GraphicsWidth()<800 Or
'      GraphicsHeight()<600); track "any mouse movement" into g_screen_int03; MouseHit(1)
'      is an immediate Return 5 (sets ONLY g_screen_int03, not g_screen_int24 -- unlike every
'      later early return in this function).
'   2. if g_engine_int164<>0: either update the digital-stick latch from the analog stick
'      (Abs() deadzone against 0.5) or read the four directional JoyHit()s, then check the
'      three JoyHit() action buttons for an immediate Return 5.
'   3. four KeyHit()-or-stick-tilt checks (Return 1..4), an activated-TCombo search (For
'      EachIn g_curscreen.GetGadgetList(), field TCombo.activated at +0x64/index 0x19; if
'      none of the two action KeyHit()s can find one, Return 5), and six raw-keycode
'      KeyHit()s (Return 1..6: 38/40/25/27 arrows, 13 Enter, 9 Tab). TCombo class-table
'      immediate is 0x00C63058 (extracted/class_tables.tsv).
'   4. a "held" pass (KeyDown()) computes `result` the same way, folding in the analog stick
'      a second time with an explicit [-1..1] clamp (thresholds are 0.5, NOT 1.0 -- the two
'      RAW dwords at 0x00C7DBC0/D0 are 0x3F000000, read directly with harness -- do not trust
'      a hand transcription of the SYM block, see codegen-patterns).
'   5. `If result And g_player_int50 > g_screen_int24+300` is ONE combined "And" test on the
'      BARE truthy `result` (not `result <> 0`) -- the original's "mov eax,ebx" truth-test has
'      no setne/movzx, so `<> 0` (which normalises to a strict 0/1 boolean first) is 7 bytes
'      too long. On success: bump g_screen_int24 by -270 and Return result; otherwise, only
'      if result was exactly 0, reset g_screen_int24 to 0; Return 0.
Function GetInput:Int()
	'!Global g_engine_int162:Int
	'!Global g_engine_int163:Int
	'!Global g_engine_int164:Int
	'!Global g_screen_float03:Float
	'!Global g_screen_float04:Float
	'!Global g_screen_float05:Float
	'!Global g_screen_float06:Float
	'!Global g_screen_float07:Float
	'!Global g_screen_float08:Float
	'!Global g_screen_int03:Int
	'!Global g_screen_int23:Int
	'!Global g_screen_int24:Int
	'!Global g_player_int50:Int
	'!Global g_options_int01:Int
	'!Global g_options_arr02:Int[]
	'!Global g_options_arr03:Int[]
	'!Global g_options_arr04:Int[]
	'!Global g_options_arr05:Int[]
	'!Global g_options_arr06:Int[]
	'!Global g_options_arr07:Int[]
	'!Global g_options_arr08:Int[]
	'!Global g_curscreen:TScreen

	Local mx:Float
	Local my:Float
	Local joynum:Int
	Local jy:Float
	Local jx:Float
	Local result:Int

	If GraphicsWidth() < 800 Or GraphicsHeight() < 600
		mx = Float(MouseX())
		mx = mx / Float(GraphicsWidth())
		g_screen_float03 = mx * Float(g_engine_int162)
		my = Float(MouseY())
		my = my / Float(GraphicsHeight())
		g_screen_float04 = my * Float(g_engine_int163)
	Else
		g_screen_float03 = Float(MouseX())
		g_screen_float04 = Float(MouseY())
	EndIf

	joynum = 0
	If g_options_int01 = 2 Then joynum = 1

	If g_screen_float03 <> g_screen_float05 Or g_screen_float04 <> g_screen_float06
		g_screen_int03 = g_player_int50
	EndIf
	g_screen_float05 = g_screen_float03
	g_screen_float06 = g_screen_float04
	If g_player_int50 > g_screen_int03 + 12000 Then g_screen_int03 = 0

	If MouseHit(1)
		g_screen_int03 = g_player_int50
		Return 5
	EndIf

	jx = g_screen_float07
	jy = g_screen_float08
	If g_engine_int164 <> 0
		If g_options_arr04[1] = -1
			If g_screen_int23 <> 0
				jx = JoyX(joynum)
				jy = JoyY(joynum)
				If Abs(jy) > 0.5 Or Abs(jx) > 0.5 Then g_screen_int23 = 0
			EndIf
			If Abs(JoyX(joynum)) < 0.5 And Abs(JoyY(joynum)) < 0.5 Then g_screen_int23 = 1
		Else
			If JoyHit(g_options_arr02[1], joynum) Then jy = -1.0
			If JoyHit(g_options_arr03[1], joynum) Then jy = 1.0
			If JoyHit(g_options_arr04[1], joynum) Then jx = -1.0
			If JoyHit(g_options_arr05[1], joynum) Then jx = 1.0
		EndIf
		If JoyHit(g_options_arr06[1], joynum) Or JoyHit(g_options_arr07[1], joynum) Or JoyHit(g_options_arr08[1], joynum)
			g_screen_int24 = g_player_int50
			g_screen_int03 = 0
			Return 5
		EndIf
	EndIf

	If KeyHit(g_options_arr02[0]) Or jy < -0.5
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 1
	EndIf
	If KeyHit(g_options_arr03[0]) Or jy > 0.5
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 2
	EndIf
	If KeyHit(g_options_arr04[0]) Or jx < -0.5
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 3
	EndIf
	If KeyHit(g_options_arr05[0]) Or jx > 0.5
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 4
	EndIf

	If KeyHit(g_options_arr06[0]) Or KeyHit(g_options_arr07[0]) Or KeyHit(g_options_arr08[0])
		Local found:Int = False
		If g_screen_int03 <> 0
			For Local c:TCombo = EachIn g_curscreen.GetGadgetList()
				If c.activated <> 0
					found = True
					Exit
				EndIf
			Next
		EndIf
		If Not found
			g_screen_int24 = g_player_int50
			g_screen_int03 = 0
			Return 5
		EndIf
	EndIf

	If KeyHit(38)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 1
	EndIf
	If KeyHit(40)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 2
	EndIf
	If KeyHit(37)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 3
	EndIf
	If KeyHit(39)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 4
	EndIf
	If KeyHit(13)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 5
	EndIf
	If KeyHit(9)
		g_screen_int24 = g_player_int50
		g_screen_int03 = 0
		Return 6
	EndIf

	result = 0
	If KeyDown(g_options_arr02[0]) Then result = 1
	If KeyDown(g_options_arr03[0]) Then result = 2
	If KeyDown(g_options_arr04[0]) Then result = 3
	If KeyDown(g_options_arr05[0]) Then result = 4

	If g_engine_int164 <> 0
		If g_options_arr04[1] = -1
			jx = JoyX(joynum)
			jy = JoyY(joynum)
			If jy < -0.5 Then jy = -1.0
			If jy > 0.5 Then jy = 1.0
			If jx < -0.5 Then jx = -1.0
			If jx > 0.5 Then jx = 1.0
		Else
			If JoyDown(g_options_arr02[1], joynum) Then jy = -1.0
			If JoyDown(g_options_arr03[1], joynum) Then jy = 1.0
			If JoyDown(g_options_arr04[1], joynum) Then jx = -1.0
			If JoyDown(g_options_arr05[1], joynum) Then jx = 1.0
		EndIf
		If jy < -0.5 Then result = 1
		If jy > 0.5 Then result = 2
		If jx < -0.5 Then result = 3
		If jx > 0.5 Then result = 4
	EndIf

	If KeyDown(38) Then result = 1
	If KeyDown(40) Then result = 2
	If KeyDown(37) Then result = 3
	If KeyDown(39) Then result = 4

	If result And g_player_int50 > g_screen_int24 + 300
		g_screen_int24 = g_player_int50 - 270
		g_screen_int03 = 0
		Return result
	EndIf
	If result = 0 Then g_screen_int24 = 0
	Return 0
End Function

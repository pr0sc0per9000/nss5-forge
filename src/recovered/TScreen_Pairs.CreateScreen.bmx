' TScreen_Pairs.CreateScreen
' VA 0x00578D12   588 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x30
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C6C800 g_screen_pairs:TScreen      0x00C66768 g_panel_bg:TPanel
'      0x00C6C81C g_pairs_buttons:TButton[]   (globals_final says Object[]; every
'                                              element store is a TButton with retain)
'      0x00C6EFDC g_screen_width:Int          0x00C6EFE0 g_screen_height:Int
'  * `x` and `y` are real Int LOCALS, not inlined into the CreateButton argument list:
'    at 0x00578E3E both are computed into edx/eax BEFORE any argument push. Inlined,
'    the pushes come first and the body diverges at byte 300 (guide 16.2). They cost
'    no stack slot -- `sub esp,0xc` is only w, h and the outer loop counter.
'  * The third CreateScreen argument is 0x005B95D0 (NullFunctionError), which is what
'    `Null` compiles to for a `()i` parameter (guide 10.6).
'  * All string literals read out of NSS5.exe with harness.read_string.
'  * Update / ClickCard are sibling statics of this Type, passed as function pointers.

'!Global g_screen_pairs:TScreen
'!Global g_panel_bg:TPanel
'!Global g_pairs_buttons:TButton[]
'!Global g_screen_width:Int
'!Global g_screen_height:Int

' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
Function CreateScreen:Int()
	g_screen_pairs = TScreen.CreateScreen("pairs", Null, Null, Update)
	g_screen_pairs.AddGadget(g_panel_bg)
	g_screen_pairs.AddGadget(TPanel.CreatePanel("pan_Pairs", GetText("CINSTRUCS_PAIRS").ToUpper(), 185, 80, 425, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 420, 0))
	g_screen_pairs.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screen_height - 60, g_screen_width, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
	Local w:Int = 94
	Local h:Int = 94
	Local n:Int = 0
	For Local i:Int = 1 To 4
		For Local j:Int = 1 To 4
			Local x:Int = i*w + 90 + i*10
			Local y:Int = j*h + 12 + j*10
			g_pairs_buttons[n] = TButton.CreateButton("btn_" + n, "", x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ClickCard, 1.0, 1, "")
			g_screen_pairs.AddGadget(g_pairs_buttons[n])
			n = n + 1
		Next
	Next
	TPair_Icon.CreateAll()
	g_screen_pairs.lHelp.AddLast(THelpBox.Create(g_pairs_buttons[9], 0, 0, 0, 0, GetText("CHELP_PAIRS"), 1, 2))
End Function

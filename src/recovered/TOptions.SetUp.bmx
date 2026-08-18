' TOptions.SetUp
' VA 0x004E27CB   766 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x30
' ASSUMPTIONS
'  * g_gfxmodes:TList (0x00C60500, globals_final's "g_Object97") -- lazily created and
'    self-registered by TMyGfxModes.New (Self added via TList.AddLast at slot 0x44),
'    confirmed by reading TMyGfxModes.New/OnListAlready.
'  * g_dataDir:String (0x00C6E9A8, globals_final wrongly calls it
'    "g_screen_mainmenu_int26:Int" -- but module_emission_order.tsv types the SAME VA
'    String, and the code passes it straight into _bbStringConcat and CreateDir with no
'    Int->String conversion; codegen-patterns 10.7/16.7 "trust the code over the table").
'  * g_options_arr12 / g_options_arr13 : TImage[] (globals_final says Object[]; both carry
'    full retain/release traffic around LoadImageChecked/ResizeImage results, so they hold
'    references, and every use is as an image -- typed TImage[] rather than the vaguer
'    Object[]).
'  * g_Object55 / g_Object56 : TImage -- same reasoning, single-image Globals holding the
'    "stick" cursor image (full-size and resized-24x24 copies).
'  * TGraphicsMode ADDED to harness.py MODULE_TYPES -> BRL.Graphics this session (was
'    shadowed by a local reflection stub with the same name, producing bcc's classic
'    "Unable to convert from 'TGraphicsMode' to 'TGraphicsMode'"). Reflection layout
'    (Field width,height,depth,hertz @ 8,12,16,20; New=0x10,Delete=0x14,ToString=0x18)
'    matches brl.mod/graphics.mod/graphics.bmx exactly, same precedent as the existing
'    TImage/TSound/TChannel/TMap entries.
'  * ResizeImage (0x005064A2) and LoadImageChecked (0x004BC372) are already-verified
'    module Functions in src/recovered_module/.
'
' CODEGEN NOTES
'  * `For ... EachIn GraphicsModes()` (an ARRAY, not a TList) auto-skips Null elements
'    exactly like the TList idiom (codegen-patterns 10.6) -- an explicit `mode <> Null`
'    guard is REDUNDANT here and, if written, doubles the null test and costs 34 bytes.
'  * The first loop's guard is a bare `If mode.height >= 600 Then allowLowRes = False`
'    -- no `And`, because the Null test is already the loop's own skip.
'  * The second loop reuses the ALREADY-COMPUTED boolean rather than re-testing the
'    field: `Local useIt:Int = mode.height >= 600` then `If Not useIt Then useIt =
'    allowLowRes` -- writing the second guard as `If mode.height < 600 Then ...`
'    (a fresh field re-read/re-compare) is semantically identical but 4 bytes longer
'    (re-fetches and re-compares instead of testing the Local already in a register).
'  * `If Not g_options_arr12[0]` (guide 10.3's "If Not x" shape: mov/cmp/setne/movzx/
'    cmp/jne, 21 bytes) -- NOT `If g_options_arr12[0] = Null` (12 bytes, wrong length).
'  * Every path-string build is left-associative concatenation with NO parens:
'    `"GameMedia/.../btn" + i + ".png"` parses as `(prefix + String(i)) + ".png"`,
'    matching the original's two `_bbStringConcat` calls in that order (bcc does no CSE,
'    so the same two-call shape appears twice per loop iteration, once per array).
'  * `TOptions.LoadOptions()` is a `ct` (class-table) call, not a Self dispatch --
'    `SetUp` is itself a Function (static), so there is no Self.
	'!Global g_gfxmodes:TList
	'!Global g_dataDir:String
	'!Global g_options_arr12:TImage[]
	'!Global g_options_arr13:TImage[]
	'!Global g_Object55:TImage
	'!Global g_Object56:TImage
	Local allowLowRes:Int = True
	For Local mode:TGraphicsMode = EachIn GraphicsModes()
		If mode.height >= 600 Then allowLowRes = False
	Next
	For Local mode:TGraphicsMode = EachIn GraphicsModes()
		Local useIt:Int = mode.height >= 600
		If Not useIt Then useIt = allowLowRes
		If useIt
			TMyGfxModes.Create(mode.width, mode.height)
		EndIf
	Next
	g_gfxmodes.Sort(1)
	CreateDir(g_dataDir)
	CreateDir(g_dataDir + "Settings/")
	If FileType(g_dataDir + "Settings/Options.ini") <> 1
		LogLine("Options.ini doesn't exist. Writing new one...")
		TOptions.WriteNewOptionsIni()
		If FileType(g_dataDir + "Settings/Options.ini") <> 1
			Notify("Error OPTIONS: Unable to create an options file:" + g_dataDir + "Settings/Options.ini", 1)
			End
		EndIf
	EndIf
	If Not g_options_arr12[0]
		For Local i:Int = 1 To 16
			g_options_arr12[i-1] = ResizeImage(LoadImageChecked("GameMedia/Images/Interface/Buttons/btn" + i + ".png", -1), $18, $18)
			g_options_arr13[i-1] = LoadImageChecked("GameMedia/Images/Interface/Buttons/btn" + i + ".png", -1)
			MidHandleImage(g_options_arr13[i-1])
		Next
		g_Object55 = ResizeImage(LoadImageChecked("GameMedia/Images/Interface/Buttons/stick.png", -1), $18, $18)
		g_Object56 = LoadImageChecked("GameMedia/Images/Interface/Buttons/stick.png", -1)
		MidHandleImage(g_Object56)
	EndIf
	TOptions.LoadOptions()

' TScreen_Kits.RefreshKits   (KIND=Function -- static, no Self)
' VA 0x00549DB7   686 bytes   class-table slot 0x3C   sig ()i
' byte-identical vs NSS5.exe (686/686, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=686/686  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C6E950 g_media_path:String   (globals_final agrees: String; it is concatenated with
'                                     a literal by _bbStringConcat, no Int->String step)
'   0x00C674B8 g_kits_screen:TScreen        slot 0x90 = GetGadgetByName($):TGadget
'   0x00C674DC g_kits_kit1:TKit             0x00C674E0 g_kits_kit2:TKit
'                                           slot 0x3C = GetPaintedPlayer($,i,i,$):TPixmap
'   0x00C674C8 g_kits_int06:Int             0x00C674CC g_kits_int07:Int
'   0x00C674EC g_kits_imgKit1:TImage           0x00C674F0 g_kits_imgKit2:TImage
'                                           (both stores carry full retain/release, 11.2)
'   0x00C674F4 g_kits_int08:Int             0x00C674F8 g_kits_int09:Int
'   0x00C67508 g_kits_lbl1:TLabel           0x00C6750C g_kits_lbl2:TLabel
'                                           slots 0x64 SetText / 0x6C SetColour, inherited
'                                           from TGadget
'   0x00C6F028 g_contractoffer_tplayer:TProfile   slot 0x160 = GetOriginalName()$
' 0x00C6763C = TScreen_Kits+0x40 -> CreateKits($)i  [OWN type => no prefix]
' The downcast to TButton is bbObjectDowncast against ClassTable_TButton, which is what
' makes slot 0x8C resolve to TButton.SetImage(:TImage).
' Literals read out of the exe with harness.read_string.
'
' NOTE  BOTH tail dispatches are `Select`, not If/ElseIf: `mov eax,[g] / cmp 1 / je /
'       cmp 0 / je / jmp` puts every Case compare ahead of every body (pattern 10.2).
'       As If/ElseIf the body is 678 bytes; localise_diff attributed the whole -8 to the
'       two missing dispatch tables plus the two missing no-Default trailing jmps.
' NOTE  The inner `Else` really is an Else -- an `ElseIf g_kits_int08 = 0` would add its
'       own 9-byte compare.

'!Global g_media_path:String
'!Global g_kits_screen:TScreen
'!Global g_kits_kit1:TKit
' 0x00C674EC AND 0x00C674F0 ARE THE KIT IMAGES, NOT THE MESSAGE-BOX ART. This body's own
' ASSUMPTIONS block above already records that pairing; the pragmas below spelled them
' g_object872 and g_object873, which the module body uses for 0x00C6F34C MessageBg.png and
' 0x00C6F3B0 MessageLine.png (tail.bmx, and TScreenMessage.Draw / TEngine.RenderScoreboard /
' TTraining.RenderScoreboard / TScreen_Kits.Draw all read them under those names). One
' identifier over two slots is one emitted variable, so the two LoadImage stores below
' replaced the message-box background and separator with the two painted kit textures the
' moment the kit screen refreshed, and every message box, the match scoreboard and the
' training scoreboard drew a shirt behind their text from then on.
' Measured: the stores are 0x00549E40 `8935ec74c600 mov [0xc674ec],esi` and 0x00549E69
' `891df074c600 mov [0xc674f0],ebx`, both immediately after `call 0x5ae256` = LoadImage,
' while TScreen_Kits.Draw at 0x0054A72D pushes [0xc6f34c] and at 0x0054A75A/0x0054A787
' pushes [0xc6f3b0]. Two different pairs of slots in one Type.
'!Global g_kits_kit2:TKit
'!Global g_kits_int06:Int
'!Global g_kits_int07:Int
'!Global g_kits_imgKit1:TImage
'!Global g_kits_imgKit2:TImage
'!Global g_kits_int08:Int
'!Global g_kits_int09:Int
'!Global g_kits_lbl1:TLabel
'!Global g_kits_lbl2:TLabel
'!Global g_profile:TProfile
CreateKits(g_media_path + "GameMedia/Images/Interface/Player.png")
Local p1:TPixmap = g_kits_kit1.GetPaintedPlayer("444444", g_kits_int06, -1, "444444")
Local p2:TPixmap = g_kits_kit2.GetPaintedPlayer("444444", g_kits_int07, -1, "444444")
g_kits_imgKit1 = LoadImage(p1, -1)
g_kits_imgKit2 = LoadImage(p2, -1)
TButton(g_kits_screen.GetGadgetByName("kits_kit1")).SetImage(g_kits_imgKit1)
TButton(g_kits_screen.GetGadgetByName("kits_kit2")).SetImage(g_kits_imgKit2)
Select g_kits_int08
	Case 1
		g_kits_lbl1.SetText(g_profile.GetOriginalName(), "", -1, -1)
		g_kits_lbl1.SetColour("00FF00", "FFFFFF")
	Case 0
		g_kits_lbl1.SetText(GetText("CPU"), "", -1, -1)
		g_kits_lbl1.SetColour("FFFFFF", "FFFFFF")
End Select
Select g_kits_int09
	Case 1
		If g_kits_int08 = 1
			g_kits_lbl2.SetText(GetText("Player 2"), "", -1, -1)
			g_kits_lbl2.SetColour("00FF00", "FFFFFF")
		Else
			g_kits_lbl2.SetText(g_profile.GetOriginalName(), "", -1, -1)
			g_kits_lbl2.SetColour("00FF00", "FFFFFF")
		EndIf
	Case 0
		g_kits_lbl2.SetText(GetText("CPU"), "", -1, -1)
		g_kits_lbl2.SetColour("FFFFFF", "FFFFFF")
End Select

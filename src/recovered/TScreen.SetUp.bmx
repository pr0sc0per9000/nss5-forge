' TScreen.SetUp
' VA 0x00510174   273 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_gadget_arr:Object[]
'!Global g_defaultbg:TImage
' 0x00C61714, read out of the binary rather than inferred: the decompilation at
' extracted/decomp/TScreen.SetUp@00510174.c stores this load into PTR_DAT_00c61714.
' 0x00C61718 is a separate slot, the letterbox surround image that
' TScreen.UpdateOffset loads StadiumBG.jpg into, and it carries the name g_screen_bg.
' MyBg2.png is the backdrop TScreen.CreateScreen hands to a screen that names no
' background of its own, so the two slots hold different images and are not aliases.
'!Global g_screen_cursor:TImage
'!Global g_snd_click:TSound
'!Global g_snd_select:TSound
If Not g_gadget_arr[0]
	SetUpFonts("en")
	g_defaultbg = LoadImageChecked("GameMedia/Images/Backgrounds/MyBg2.png", -1)
	g_screen_cursor = LoadAnimImageChecked("GameMedia/Images/Interface/Cursor.png", 22, 33, 0, 2, -1)
	SetImageHandle(g_screen_cursor, 8.0, 0)
	g_snd_click = LoadSoundChecked("GameMedia/Sounds/Click.ogg", 0)
	g_snd_select = LoadSoundChecked("GameMedia/Sounds/Select.ogg", 0)
End If
TGadget.SetUp()
Return 0

' TScreen_Options.ComboRes
' VA 0x0052125b   117 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' harness mode=reloc.
' FUN_00505f6d is the recovered module Function ClampInt(*i,i,i); the original passes
'   `lea eax,[global]` so the argument is Varptr on the Global (a Var parameter in the
'   original source, which compiles identically).
' FUN_004c5549 = recovered module Function GetText($)$; 0x00c8065c = "CMESSAGE_CHANGERESOLUTION".
' PTR_FUN_00c61cc0 = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i).
' slots: TCombo+0xbc = GetSelectedItem()i, TList+0x70 = Count()i.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_options_rescombo:TCombo      ' 0x00c63cf8
'   Global g_screen_options_int01:Int     ' 0x00c5d244
'   Global g_reslist:TList                ' 0x00c60500
'   Global g_screen_options_int12:Int     ' 0x00c63d08
	Function ComboRes:Int()
		'!Global g_screen_options_int01:Int
		'!Global g_options_rescombo:TCombo
		'!Global g_reslist:TList
		'!Global g_screen_options_int12:Int
		g_screen_options_int01 = g_options_rescombo.GetSelectedItem() - 1
		ClampInt(Varptr g_screen_options_int01, 0, g_reslist.Count())
		If g_screen_options_int12 = 0
			TScreen.DoMessage(GetText("CMESSAGE_CHANGERESOLUTION"), 0, 0)
			g_screen_options_int12 = 1
		EndIf
	End Function

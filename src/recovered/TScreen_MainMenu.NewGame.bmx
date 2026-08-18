' TScreen_MainMenu.NewGame
' VA 0x0051d023   277 bytes
' byte-identical vs NSS5.exe (277/277, original length from Ghidra's inventory, mode=reloc, 24 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function ()i, vtable slot 0x44.
' ASSUMPTIONS: all four string literals are masked -- values unproven. KEY constants 162/69
' are the raw immediates 0xA2/0x45 (KEY_LCONTROL / KEY_E in brl.polledinput).
' Globals 0x00C639FC (String, type_source=verified), 0x00C6E900 and 0x00C63A00 typed String
' from the bbStringCompare traffic, overriding globals_final.tsv which calls them Int.
'!Global g_mm_a:String
'!Global g_mm_b:String
'!Global g_mm_c:String
TScreenMessage.ClearAll(1)
If KeyDown(162) And KeyDown(69)
	TProfile.SetUp()
	TScreen_EditMenu.SetUpScreen()
	Return 0
Else
	If g_mm_a = "0"
		TScreenMessage.ClearAll(1)
		TScreen.DoMessage(GetText("CMESSAGE_MUSTBEONLINE"), 0, 0)
		Return 0
	Else
		If g_mm_a <> g_mm_b And g_mm_c <> g_mm_b
			TScreenMessage.ClearAll(1)
			TScreen.DoMessage(GetText("CMESSAGE_MUSTUPDATEVERSION"), 0, 0)
			Return 0
		Else
			TProfile.SetUp()
			TScreen_NewPlayer.SetUpScreen()
		End If
	End If
End If

' TScreen_MatchPrep.ButtonShinPads
' VA 0x0055f0d2   293 bytes   vtable slot 0x48   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (293/293, mode=reloc, reloc_masked=16)
'
' assumes module global:  Global g_profile:TProfile          ' 0x00c6f028
'   (globals_final row 0x00c6f028 = TProfile, type_source=construction, 3 sites --
'    the field offsets used here all land on real TProfile fields, so the type is corroborated)
'
' VERIFIED: the GetText keys were flagged as unpinned placeholders; harness.read_string
' confirms "CMESSAGE_NOTENOUGHCASH" @0x00C87F24 and "CMESSAGE_BUYSHINPADS" @0x00C8CC0C exactly.
' No change needed.
'
' g_profile.sponsor_expires is []i at 0x100; [2] folds to +0x20.
' g_profile.achievements   is []i at 0x1bc; [89] folds to +0x17c.
' TScreen.DoMessage is a cross-type static call (TScreen classtable 0x00c61c2c + 0x94).
' SetUpScreen is TScreen_MatchPrep's own Function (own classtable + 0x34) -> unqualified.

	Function ButtonShinPads:Int()
		'!Global g_profile:TProfile
		If g_profile.sponsor_expires[2] = 0 And g_profile.bank < 500
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"),0,0)
		Else
			If g_profile.sponsor_expires[2] = 0 Or g_profile.shinpads > 0 Or g_profile.achievements[89] > 0 Or TScreen.DoMessage(GetText("CMESSAGE_BUYSHINPADS"),1,0)
				If g_profile.sponsor_expires[2] = 0 Then g_profile.UpdateBank(-500)
				g_profile.shinpads = 5
				SetUpScreen()
				g_profile.CheckAchievement(90)
			EndIf
		EndIf
	End Function

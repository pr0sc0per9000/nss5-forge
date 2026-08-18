' TScreen_Relationships.ButtonTeamCasino
' VA 0x00540d21   132 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (132/132, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C6F028 declared :TProfile (globals_final.tsv,
' type_source=construction, confidence=high); field +0x15c = TProfile.energy:Float;
' slot 0xc0 = TProfile.UpdateRelationship(i,i)i, slot 0x100 = TProfile.UpdateEnergy(f)i.
' 0x00C6BA24 = TScreen_Casino class table + 0x38 = SetUpScreen()i.
' 0x00C876BC is the Float constant 20.0; 0xC1A00000 is -20.0.
' Structure is an early return, not If/Else (the If/Else form is 127 bytes).
' NOTE: `Not (g_profile.energy >= 20.0)` also matches 132/132 -- bcc folds the negation
' into the branch, so the two spellings are indistinguishable at the byte level.
	Function ButtonTeamCasino:Int()
		'!Global g_profile:TProfile
		If g_profile.energy < 20.0
			TScreen.DoMessage(GetText("CMESSAGE_NOCASINOTIRED"), 0, 0)
			Return 0
		EndIf
		g_profile.UpdateRelationship(2, 5)
		g_profile.UpdateEnergy(-20.0)
		TScreen_Casino.SetUpScreen()
	End Function

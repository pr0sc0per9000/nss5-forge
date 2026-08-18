' TProfile.PlayNextFixture
' VA 0x0056672c   211 bytes   vtable slot 0x60   sig (i)i
' byte-identical vs NSS5.exe (211/211, original length from Ghidra's inventory, mode=reloc)
' No Globals. PTR_FUN_00C6160C = TCompetition+0x4c = SelectById; PTR_FUN_00C67630 =
' TScreen_Kits+0x34 = SetUpScreen(:TFixture,()i,()i); PTR_FUN_00C687A0 = TScreen_MatchPrep+0x34
' = SetUpScreen(); *(*Self+100) is TProfile's own slot 0x64 = FixturePlayed, passed as the
' second ()i callback. Literals "PlayNextFixture:" / " Date:" read out of NSS5.exe.
' The `puVar2[1]+1` / release-old / store sequence is refcount traffic for `mylastfixture = f`.
	Method PlayNextFixture:Int(a0:Int)
		Local f:TFixture = GetNextFixture(0)
		If f <> Null
			Local c:TCompetition = TCompetition.SelectById(f.compid)
			LogLine("PlayNextFixture:" + c.name + " Date:" + f.sdate)
			mylastfixture = f
			matchskipped = 0
			If a0
				matchskipped = 1
				FixturePlayed()
			Else
				TScreen_Kits.SetUpScreen(f, TScreen_MatchPrep.SetUpScreen, FixturePlayed)
			End If
		End If
	End Method

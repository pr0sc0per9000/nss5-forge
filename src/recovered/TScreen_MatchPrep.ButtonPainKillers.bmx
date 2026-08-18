' TScreen_MatchPrep.ButtonPainKillers
' VA        0x0055EECE   slot 0x40   KIND=Function (static)   SIG=()i
' ORACLE    MATCH mode=reloc  301/301 bytes  reloc_masked=24
'
' GLOBALS DECLARED (names are ours; the TYPES are load-bearing)
'   g_profile:TProfile            = 0x00C6F028
'       globals_final.tsv types this TProfile from 3 construction sites but flags the
'       older usage guess as unsound.  TProfile is confirmed here independently: the two
'       virtual calls are slot 0xFC and slot 0x150, and on TProfile those are
'       UpdateBank(i) and CheckAchievement(i) -- both fit the call sites exactly, and the
'       three field offsets touched are TProfile.bank(+0x28), TProfile.injury(+0x16C) and
'       TProfile.takenpainkillers(+0x174).
'   g_worldmap_traveltime:Int     = 0x00C68428
'       Int: `mov ebx,[0xC68428]` / `cmp ebx,[0xC68428]` with no refcount traffic (11.2).
'
' SLOTS / CALL TARGETS RESOLVED
'   0x00C61CC0 -> TScreen classtable + 0x94          = TScreen.DoMessage($,i,i)i
'   0x00C68570 -> TScreen_WorldMap classtable + 0x48 = TScreen_WorldMap.UpdateTravelTime()
'   0x00C687A0 -> TScreen_MatchPrep classtable + 0x34= TScreen_MatchPrep.SetUpScreen()
'   0x004C5549 -> module Function GetText($)$        (src/recovered_module/GetText.bmx)
'
' ARGUMENT-COUNT CORRECTION (the trap from the guide)
'   Ghidra prints `FUN_004c5549(&PTR_PTR_00c8cb0c,0,0)`.  GetText takes ONE argument --
'   the original cleans it up with `add esp,4`.  The two zero pushes belong to the
'   FOLLOWING `call [0xC61CC0]`, which cleans up 0xC (three args) = DoMessage(text,0,0).
'
' OTHER NOTES
'   * The first block is a genuine early return (`mov eax,0 / E9 -> epilogue`), not an
'     If/Else: the jump target is PAST the shared trailing `mov eax,0`.
'   * String literal addresses are masked by the oracle, but the literals were read out of
'     NSS5.exe's BBString constants and are reproduced verbatim.
'   * -5000 appears as `imul eax,eax,0xFFFFEC78`, i.e. `injury * -5000`, not a negated
'     positive product.

Function ButtonPainKillers()
	'!Global g_profile:TProfile
	'!Global g_worldmap_traveltime:Int
	If g_profile.injury > 4
		TScreen.DoMessage(GetText("CMESSAGE_PAINKILLERSSERIOUSINJURY"), 0, 0)
		Return 0
	EndIf
	If g_profile.bank < g_profile.injury * 5000
		TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
	Else
		If TScreen.DoMessage(GetText("CMESSAGE_BUYPAINKILLERS"), 1, 0)
			g_profile.UpdateBank(g_profile.injury * -5000)
			g_profile.injury = 0
			g_profile.takenpainkillers = 1
			Local t:Int = g_worldmap_traveltime
			TScreen_WorldMap.UpdateTravelTime()
			If t <> g_worldmap_traveltime
				TScreen.DoMessage(GetText("CMESSAGE_FITAGAINTRAVELTIME"), 0, 0)
			EndIf
			TScreen_MatchPrep.SetUpScreen()
			g_profile.CheckAchievement(56)
		EndIf
	EndIf
End Function

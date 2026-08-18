' TCompetition.SetUpCompetitionsAll  -- KIND=Function (STATIC method on TCompetition), slot 0x58, sig ()i
' VA 0x0050A77B   466 bytes   (original length from Ghidra's inventory)
' ORACLE: MATCH mode=reloc  466/466  reloc_masked=32
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_00505B91 = LogLine    FUN_004C5549 = GetText
'   FUN_004A7AC0 = _bbStringFromInt   FUN_004A7C20 = _bbStringConcat
'   FUN_004A8F60 = _bbObjectDowncast  (the two For EachIn downcasts)
'   PTR_FUN_00C616DC = TCompetition classtable + 0x11C -> SortListBy(i,i)
'   PTR_FUN_00C61CD8 = TScreen      classtable + 0x0AC -> DoProgressBar(f,$,$,i)
'   PTR_FUN_00C616EC = TCompetition + 0x12C -> Test_UpdateNoofTeamsInLeagues()
'   PTR_FUN_00C616F0 = TCompetition + 0x130 -> Test_CheckNoofTeamsInLeagues()
'   PTR_FUN_00C59E38 = TClub        + 0x08C -> AverageOutStrengthAll()
'   PTR_FUN_00C59E3C = TClub        + 0x090 -> CheckStadiumSizeAll()
'   ClassTables 0x00C615C0 = TCompetition, 0x00C59DAC = TClub (loop var types)
'   TList slots: 0x70 Count, 0x8C ObjectEnumerator, 0x30 HasNext, 0x34 NextObject
'   TCompetition slots: 0xA8 IsComplete(i), 0x5C SetUpCompetition()
'   Globals (names ours, TYPES load-bearing):
'     0x00C6F028 -> g_profile:TProfile
'        globals_final.tsv says TPlayer, note "vtable-call slots 0x30,0x34,0x3c,0x40 ->
'        only TPlayer has them all" -- exactly the note shape §11.2 says to distrust.
'        It is TProfile: +0x10 is TProfile.date:TMyDate (slot 0x54 = TMyDate.GetYear()),
'        and other call sites use +0x74 contractexpires, +0x10C relationfans,
'        +0x134 transferlisted, +0x15C energy:Float, +0x1BC achievements:Int[],
'        +0x1D0 myclub:TClub -- all TProfile, none of them TPlayer.
'     0x00C6099C -> g_complist:TList   (slot 0x70 Count + 0x8C ObjectEnumerator)
'     0x00C59A44 -> g_clublist:TList
'   String literals read out of NSS5.exe BBString headers:
'     0x00C7CC60 "SetUpCompetitionsAll"  0x00C7CC94 "gameyear: "
'     0x00C7CCB4 "Creating Fixtures"     0x00C6E904 "00FF00"
'   Float constants: 0x00C7CCE4 = 1.0, 0x00C7CCE8 = 100.0, 0x00C7CCEC = 1.0
'   Field: TCompetition.startyear +0x28, TClub.continentalcompid +0x6C
'
' ARG-COUNT TRAP (guide §, confirmed against the disassembly)
'   Ghidra prints `FUN_004c5549(&"Creating Fixtures", &"00FF00", 1)` -- but the stack
'   cleanup after that call is `add esp,4`, so GetText takes ONE argument; the other two
'   pushes belong to the FOLLOWING DoProgressBar call (cleaned with `add esp,0x10`).
	Function SetUpCompetitionsAll:Int()
		'!Global g_profile:TProfile
		'!Global g_complist:TList
		'!Global g_clublist:TList
		LogLine("SetUpCompetitionsAll")
		Local gy:Int = g_profile.date.GetYear()
		LogLine("gameyear: " + gy)
		TCompetition.SortListBy(22, 1)
		TScreen.DoProgressBar(1.0, GetText("Creating Fixtures"), "00FF00", 1)
		Local pct:Float = 1.0
		Local n:Float = g_complist.Count()
		For Local c:TCompetition = EachIn g_complist
			If c.startyear = gy Or c.IsComplete(0) Then c.SetUpCompetition()
			TScreen.DoProgressBar(100.0 / n * pct, GetText("Creating Fixtures"), "00FF00", -1)
			pct = pct + 1.0
		Next
		For Local cl:TClub = EachIn g_clublist
			cl.continentalcompid = 0
		Next
		If gy = 1
			TCompetition.Test_UpdateNoofTeamsInLeagues()
		Else
			TCompetition.Test_CheckNoofTeamsInLeagues()
			TClub.AverageOutStrengthAll()
			TClub.CheckStadiumSizeAll()
		EndIf
		Return 0
	End Function

' TScreen_GameMenu.ButtonCompetitions
' VA 0x0053b2ee   175 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (175/175, original length from Ghidra's inventory)
' Two nested SELECTs, not If/ElseIf -- both runs of cmp/je target addresses past the last
'   compare (codegen-patterns 10.2).  The outer Null test is `<>` : `cmp ebx,bbNullObject /
'   je <else>` with the Else block emitted last.
' resolved indirect calls:
'   [ebx+0x54] on TProfile.date  -> TMyDate + 0x54 = GetYear()i
'   [ebx+0x58] on g_profile      -> TProfile + 0x58 = GetNextFixture(i):TFixture
'   PTR_FUN_00c6160c = TCompetition classtable + 0x4c = SelectById(i):TCompetition
'   PTR_FUN_00c67188 = TScreen_Leagues classtable + 0x34 = SetUpScreen(i)i
'   PTR_FUN_00c67468 = TScreen_Continents classtable + 0x34 = SetUpScreen(i,i,i)i
'   0x004bcb98 = PlayTrack (src/recovered_module/PlayTrack.bmx)
' field offsets: TFixture +0x3c level, +0x40 compid; TCompetition +0x08 id, +0x18 locale
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_profile:TProfile      ' 0x00c6f028
	Function ButtonCompetitions:Int()
		'!Global g_profile:TProfile
		PlayTrack(2)
		Local f:TFixture = g_profile.GetNextFixture(g_profile.date.GetYear())
		If f <> Null
			Local c:TCompetition = TCompetition.SelectById(f.compid)
			Select f.level
			Case 0
				Select c.locale
				Case 0
					TScreen_Leagues.SetUpScreen(0)
				Case 1
					TScreen_Continents.SetUpScreen(0, 0, c.id)
				End Select
			Case 1
				TScreen_Continents.SetUpScreen(0, 1, c.id)
			End Select
		Else
			TScreen_Leagues.SetUpScreen(0)
		EndIf
	End Function

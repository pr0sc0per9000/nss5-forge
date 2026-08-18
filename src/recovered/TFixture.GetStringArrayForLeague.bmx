' TFixture.GetStringArrayForLeague
' VA 0x004C369A   1370 bytes   vtable slot 0x48   sig ()[]$
' byte-identical vs NSS5.exe (1370/1370, original length from Ghidra's inventory,
' reloc_masked=105). KIND=Method.  NSS5_NO_LEARN=1.
'
' Same building blocks as the sibling Methods TFixture.GetStringHomeTeam /
' GetStringAwayTeam / GetStringArray / GetStringArrayForTeamId, but this Method does NOT
' delegate to GetStringHomeTeam/GetStringAwayTeam -- it INLINES the lookup twice (once per
' side) with one genuine behavioural difference from GetStringHomeTeam: when the
' competition/group resolve but GetItemById itself returns Null, this Method sets the slot
' to "" (GetStringHomeTeam leaves the "Team "+id fallback in that case). Confirmed by
' reading the raw disassembly, not the decompilation -- the store at iVar2+0x18 happens on
' BOTH sides of that inner If, and the "DAT_00C5D288 = DAT_00C5D288 + 1" Ghidra prints is
' NOT a counter: 0x00C5D288 is the refcount word of the "" literal at 0x00C5D284 (see
' TClub.GetStringArray.bmx's header), i.e. it is just the retain half of `arr[0] = ""`.
'
' Return is New String[3]: [0] home team name, [1] result/versus text, [2] away team name
' (confirmed by which iVar2+offset each block writes: +0x18/+0x1C/+0x20).
'
' FIELDS (object_model.json / TFixture's declaration order, matches every sibling file):
'   +0x18 leg   +0x1C hometeam   +0x20 awayteam   +0x24 result   +0x28 resulttype
'   +0x2C score1   +0x30 score2   +0x34 penscore1   +0x38 penscore2   +0x40 compid
'   (index arithmetic: param_1[6]=leg, [7]=hometeam, [8]=awayteam, [9]=result,
'   [10]=resulttype, [0xb]=score1, [0xc]=score2, [0xd]=penscore1, [0xe]=penscore2,
'   [0x10]=compid -- cross-checked against GetStringArrayForTeamId's field map comment)
'   TCompetition +0x1B(idx)=teampool:[]TTeamPool.  TTeamPool slot 0x48=GetItemById(i):TTableData.
'   TTableData +0x10(idx4)=teamname.  TCompetition.SelectById = classtable+0x4C
'   (0x00C615C0+0x4C = 0x00C6160C, matches PTR_FUN_00c6160c exactly).
'
' CALLS: 0x004A7F60 Abs(Int) (branchless sar/xor/sub, confirmed in TProfile.UpdateBank.bmx
'), 0x004A7AC0 _bbStringFromInt, 0x004A7C20 _bbStringConcat, 0x004C5549
' GetText (ONE real arg -- Ghidra folds the following concat/SetText pushes into its
' printed list, same idiom as every other GetText call in this corpus).
'
' SHAPE
'   * `Local c:TCompetition = TCompetition.SelectById(compid)` is looked up ONCE and its
'     `<> Null` guard repeated for both the home and away blocks; `c.teampool[groupno-1]`
'     itself IS re-evaluated per side (no shared Local spans both blocks) -- confirmed by
'     the raw disassembly recomputing the array index a second time for the away block
'     while never re-calling SelectById.
'   * Case 1 of the resulttype Select is a genuine empty case (guide 10.2), matching
'     GetStringArray.bmx's identical Case-1-empty shape with the same literal addresses.
'   * `s = score1 + " - " + score2` (the "won by default" text) is computed
'     UNCONDITIONALLY before the resulttype Select, then Cases 2/3/4 overwrite it -- exact
'     same idiom as GetStringArray.bmx/GetStringArrayForTeamId.bmx.
'   * The `leg = 2` "(score1+fs2) ... (score2+fs1)" aggregate wrap is nested INSIDE the
'     "not a bye" else, after the Select -- same placement as GetStringArrayForTeamId.bmx.
'   * ORIGINAL BUG (preserved, not fixed): a dead tail statement `If leg > 0 And result Then
'     EndIf` with an EMPTY body sits between `arr[1] = s` and `Return arr` -- the exact same
'     dead statement already documented in GetStringArrayForTeamId.bmx's header (point 8),
'     duplicated verbatim in this sibling. Byte-exact only as a single `A And B` condition
'     with `result` bare (not `<> 0`) -- the explicit form triggers a SETNE/MOVZX the
'     original never emits here.
'
' All string literals ("sla_versus", "Team", " ", "fixture_Bye", " - ", "sla_extratime",
' "sla_penalty", "sla_awaygoals", "(", ") ", " (", ")") read out of NSS5.exe with
' harness.read_string at the addresses the original pushes at the same code offsets.

	Method GetStringArrayForLeague:String[]()
		Local arr:String[] = New String[3]
		Local s:String = GetText("sla_versus")
		arr[0] = GetText("Team") + " " + String(Abs(hometeam))
		Local c:TCompetition = TCompetition.SelectById(compid)
		If c <> Null
			Local tp:TTeamPool = c.teampool[groupno-1]
			If tp <> Null
				Local td:TTableData = tp.GetItemById(hometeam)
				If td <> Null
					arr[0] = td.teamname
				Else
					arr[0] = ""
				EndIf
			EndIf
		EndIf
		arr[2] = GetText("Team") + " " + String(Abs(awayteam))
		If c <> Null
			Local tp2:TTeamPool = c.teampool[groupno-1]
			If tp2 <> Null
				Local td2:TTableData = tp2.GetItemById(awayteam)
				If td2 <> Null
					arr[2] = td2.teamname
				Else
					arr[2] = ""
				EndIf
			EndIf
		EndIf
		Local fs1:Int = 0
		Local fs2:Int = 0
		If leg = 2 Then GetFirstLegScore(Varptr fs1, Varptr fs2)
		If result <> 0
			If arr[0] = "" Or arr[2] = ""
				s = GetText("fixture_Bye")
			Else
				s = score1 + " - " + score2
				Select resulttype
				Case 1
				Case 2
					If score1 > score2
						s = GetText("sla_extratime") + score1 + " - " + score2
					Else
						s = score1 + " - " + score2 + GetText("sla_extratime")
					EndIf
				Case 3
					If penscore1 > penscore2
						s = GetText("sla_penalty") + score1 + " - " + score2
					Else
						s = score1 + " - " + score2 + GetText("sla_penalty")
					EndIf
				Case 4
					If fs2 * 2 + score1 > fs1 + score2 * 2
						s = GetText("sla_awaygoals") + score1 + " - " + score2
					Else
						s = score1 + " - " + score2 + GetText("sla_awaygoals")
					EndIf
				End Select
				If leg = 2
					s = "(" + (score1 + fs2) + ") " + s + " (" + (score2 + fs1) + ")"
				EndIf
			EndIf
		EndIf
		arr[1] = s
		If leg > 0 And result
		EndIf
		Return arr
	End Method

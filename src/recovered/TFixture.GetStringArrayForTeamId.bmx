' TFixture.GetStringArrayForTeamId
' VA 0x004C3BF4   2842 bytes   vtable slot 0x4c   sig (i)[]$
' byte-identical vs NSS5.exe (2842/2842, original length from Ghidra's inventory)
'   verified with NSS5_NO_LEARN=1
'
' The three shapes below are what separate a 2857-byte near-miss from the exact 2842,
' found by direct disassembly rather than guessing:
'
'  1. `y:Int = d.GetYear()` / `py:Int = g_profile.date.GetYear()` MUST be named Locals,
'     each read exactly once from a real call and reused for BOTH the year-gap guard and
'     the immediately following equality test. Calling .GetYear() a second time doubles
'     the call sequence -- worth ~42 bytes -- AND perturbs the register allocator
'     (see 3 below).
'  2. `arr[0] = arr[0] + (" d" + d.GetDay())` and `arr[2] :+ " :" + td.id` -- codegen-
'     patterns 16.1's `:+`-evaluates-RHS-as-a-unit rule ALSO applies to a parenthesised
'     `arr[i] + (lit + itoa)` RHS on a plain `=`, not just to `:+` on a scalar Local: the
'     original computes itoa(field) then concat(literal, itoa) THEN concat(arr[i], that) --
'     three calls in that order. Writing `arr[i] = arr[i] + lit + itoa` (left-to-right, no
'     parens) computes concat(arr[i], lit) FIRST instead and costs 6 bytes extra per site
'     (four sites: the day suffix, and the home/away " :"+id suffixes).
'  3. `d` (the TMyDate from Self.sdate) is read 4 times across the whole function and the
'     original keeps it in ESI for its entire life, dereferencing `[esi]` directly at each
'     call site with NO reload. Sinking ESI into
'     the *g_profile.date* one-shot sub-expression instead, forcing `d` into EDI, which
'     costs an extra `mov eax,edi` before every one of `d`'s several call sites (worth
'     ~2-3 bytes each). Point 1 above (naming `y`/`py`) removes the extra GetYear() calls
'     that feed this mis-allocation; without them the allocator puts `d` back
'     in ESI on its own -- no Local reordering was needed, confirming codegen-patterns 18.3's
'     point that liveness, not declaration order, decides the winner here.
'  4. The early exit really is `If y > py + 1 Then Return Null`, not `arr = Null` inside an
'     If/Else with a shared `Return arr` at the end. Original's early-exit path loads the
'     constant straight into EAX (`mov eax,0x5c7c00`) and jumps directly to the epilogue,
'     never touching [ebp-0xc] again -- i.e. it never falls back into the shared tail. A
'     `Return Null` is exactly that shape; `arr = Null` followed by falling through to a
'     shared `Return arr` is NOT (costs 2 bytes: a memory store instead of a register load).
'  5. The Default's first score comparison is `If Self.score1 > Self.score2`, not
'     `If Self.score2 < Self.score1` -- logically identical, byte-different (codegen-
'     patterns 10.1: Ghidra normalises comparison operand order; it is not byte-observable
'     evidence). The ElseIf was already right (`Self.score1 < Self.score2`).
'  6. Three of the eight isHome-conditioned Won/Lost picks (the ELSE arm of each of Case
'     2/3/4's inner score comparison) are written `If Not isHome Then Won Else Lost`, not
'     `If isHome Then Lost Else Won` -- same truth table, and bcc emits a different cmp/jcc
'     shape for the two spellings. All five TRUE arms and the Default's two arms use the
'     plain `If isHome` spelling; only these three do not. Not explained further; recorded
'     as measured, matching the original inconsistently by design (codegen-patterns law 3 --
'     the original's own unevenness is preserved, not smoothed over).
'  7. Case 4's guard reads `fs2 * 2 + Self.score1 > fs1 + Self.score2 * 2`, not the
'     algebraically-identical `fs1 + Self.score2 * 2 < fs2 * 2 + Self.score1`. bcc evaluates
'     left-to-right with no CSE, so which side is written first decides which pair of loads
'     happens first; the wrong spelling reorders two loads with no byte-count cost (net 0)
'     but is not byte-identical, and localise_diff flags it as an insert+replace pair.
'  8. The dead tail statement is a real `If Self.leg > 0 And Self.result Then EndIf` with an
'     EMPTY body, immediately before `Return arr` -- reached only via the non-early-return
'     path (confirmed: the early `Return Null` path jumps straight past it to the epilogue).
'     Byte-exact only with THIS exact shape: `Self.result` bare (not `Self.result <> 0` --
'     the explicit `<>0` spelling makes bcc materialise a throwaway SETNE/MOVZX the original
'     never emits for a value that is only ever branched on, never stored), and as a single
'     `A And B` condition (not two nested `If`s, which drops the SETG/MOVZX normalisation
'     the original DOES emit for the first operand). ORIGINAL BUG: the whole statement's
'     body is empty -- it observably does nothing. Kept exactly; not "fixed" into a Local.
'
' FIELD MAP (object_model.json, cross-checked against class_tables.tsv)
'   TFixture: sdate+8 matchtype+12 round+16 groupno+20 leg+24 hometeam+28 awayteam+32
'     result+36 resulttype+40 score1+44 score2+48 penscore1+52 penscore2+56 compid+64.
'   TCompetition: tla+16 (idx4) comptype+36 (idx9) teampool+108 (idx0x1B).
'   TTableData: id+8 teamid+12 teamname+16.
'   TMyDate slot 0x4C=GetDay 0x54=GetYear 0x5C=GetString($)$.
'   TCompetition slot 0x4C=SelectById(i):TCompetition, 0xD4=AllFixturesPopulated()i.
'   TTeamPool slot 0x48=GetItemById(i):TTableData.
'
' ORIGINAL BUG (preserved, not fixed): `c.comptype`/`c.AllFixturesPopulated()` are read
' UNCONDITIONALLY after the `If c <> Null` block closes, not inside it -- if SelectById
' ever returns Null this null-derefs. Matches TFixture.GetStringArray's sibling shape
' exactly (same TCompetition null-check idiom), so this is how the source is written, not
' a transcription slip.
'
' Return value is String[6]: [0] date text ("W" format, replaced outright by "YY" format
' when the fixture's year differs from the profile's current year, then optionally suffixed
' " d"+day), [1] competition tla, [2] opponent name (or "-"/"" per the guards above), [3]
' leg/replay text, overwritten by the score text once Self.result <> 0, [4] "sla_Home" /
' "sla_Away" from a0's perspective, [5] "sla_Won"/"sla_Lost"/"sla_Drawn" from a0's
' perspective (only set when Self.result <> 0).
'
' All string literals read out of NSS5.exe with harness.read_string() at the addresses the
' original pushes at the same code offsets (0x00C70DD0.." - ", 0x00C70E58.."-", 0x00C70E90.
' ."Replay", 0x00C70EA8.."Leg", 0x00C70ED4.."fixture_Bye", 0x00C70DE4.."sla_extratime",
' 0x00C70E0C.."sla_penalty", 0x00C70E30.."sla_awaygoals", 0x00C70EF8..")", 0x00C70F08.." (",
' 0x00C70F18..") ", 0x00C70F28.."(", 0x00C70F38.."W", 0x00C70F48.."YY", 0x00C70F58.." d",
' 0x00C70F68.." :", 0x00C70F78.."sla_Home", 0x00C70F94.."sla_Away", 0x00C70FB0.."sla_Drawn",
' 0x00C70FD0.."sla_Won", 0x00C70FEC.."sla_Lost") -- confirmed OK, all 21 addresses checked.
'
'!Global g_engine_int161:Int
'!Global g_profile:TProfile
Local arr:String[] = New String[6]
Local isHome:Int = True
Local d:TMyDate = TMyDate.Create(Self.sdate, 1, 1)
arr[0] = d.GetString("W")
Local y:Int = d.GetYear()
Local py:Int = g_profile.date.GetYear()
If y > py + 1 Then Return Null
If y <> py
	arr[0] = d.GetString("YY")
EndIf
If g_engine_int161 = 2
	arr[0] = arr[0] + (" d" + d.GetDay())
EndIf
Local c:TCompetition = TCompetition.SelectById(Self.compid)
If c <> Null
	arr[1] = c.tla
	arr[2] = "-"
	Local tp:TTeamPool = c.teampool[Self.groupno - 1]
	If tp <> Null
		Local tdh:TTableData = tp.GetItemById(Self.hometeam)
		If tdh <> Null And tdh.teamid <> a0
			arr[2] = tdh.teamname
			isHome = False
			If g_engine_int161 = 2 Then arr[2] :+ " :" + tdh.id
		EndIf
		Local tda:TTableData = tp.GetItemById(Self.awayteam)
		If tda <> Null And tda.teamid <> a0
			arr[2] = tda.teamname
			If g_engine_int161 = 2 Then arr[2] :+ " :" + tda.id
		EndIf
	EndIf
EndIf
If c.comptype = 1 And c.AllFixturesPopulated() = 0
	arr[2] = ""
EndIf
Local s:String = ""
If Self.matchtype = 3 And Self.round = 2
	s = GetText("Replay")
ElseIf Self.leg > 0
	s = GetText("Leg") + " " + Self.leg
EndIf
Local fs1:Int = 0
Local fs2:Int = 0
If Self.leg = 2 Then Self.GetFirstLegScore(Varptr fs1, Varptr fs2)
If isHome
	arr[4] = GetText("sla_Home")
Else
	arr[4] = GetText("sla_Away")
EndIf
If Self.result <> 0
	If arr[2] = "-"
		s = GetText("fixture_Bye")
	Else
		s = Self.score1 + " - " + Self.score2
		Select Self.resulttype
			Case 2
				If Self.score1 > Self.score2
					s = GetText("sla_extratime") + Self.score1 + " - " + Self.score2
					If isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				Else
					s = Self.score1 + " - " + Self.score2 + GetText("sla_extratime")
					If Not isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				EndIf
			Case 3
				If Self.penscore1 > Self.penscore2
					s = GetText("sla_penalty") + Self.score1 + " - " + Self.score2
					If isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				Else
					s = Self.score1 + " - " + Self.score2 + GetText("sla_penalty")
					If Not isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				EndIf
			Case 4
				If fs2 * 2 + Self.score1 > fs1 + Self.score2 * 2
					s = GetText("sla_awaygoals") + Self.score1 + " - " + Self.score2
					If isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				Else
					s = Self.score1 + " - " + Self.score2 + GetText("sla_awaygoals")
					If Not isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				EndIf
			Default
				arr[5] = GetText("sla_Drawn")
				If Self.score1 > Self.score2
					If isHome
						arr[5] = GetText("sla_Won")
					Else
						arr[5] = GetText("sla_Lost")
					EndIf
				ElseIf Self.score1 < Self.score2
					If isHome
						arr[5] = GetText("sla_Lost")
					Else
						arr[5] = GetText("sla_Won")
					EndIf
				EndIf
		End Select
		If Self.leg = 2
			s = "(" + (Self.score1 + fs2) + ") " + s + " (" + (Self.score2 + fs1) + ")"
		EndIf
	EndIf
EndIf
arr[3] = s
If Self.leg > 0 And Self.result
EndIf
Return arr

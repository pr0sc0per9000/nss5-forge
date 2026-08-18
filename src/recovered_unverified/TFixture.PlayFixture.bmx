' TFixture.PlayFixture -- VERIFIED 100% BYTE MATCH (1066/1066) against NSS5.exe
' VA 0x004C47E1   1066 bytes   vtable slot 0x54   sig ()i
'
' Fixed from an earlier attempt that scored 13.8% (147/1066, +138 length delta).
' That attempt's problem was never the field/slot resolution (all correct) but the
' CODEGEN SHAPE of several constructs. Rebuilt statement-by-statement against the raw
' capstone disassembly of the original (not just the Ghidra C, which normalises several
' shapes below into forms that don't reproduce the bytes) using localise_diff.py as the
' oracle. Fixes applied, each confirmed against the instruction stream:
'
'   1. No separate `newHome`/`newAway` Locals. The original keeps a single unnamed
'      OR-accumulator (`anynew`) that starts False and is set True inside EITHER
'      null-handling block; the whole random-score block is skipped `If Not anynew`.
'      This flag never gets a stack slot in the original (lives in a register the
'      whole time) -- two separate named/stored booleans cost 4 extra frame bytes
'      and produced a different branch shape.
'   2. `If Not hd Then ... EndIf` / `If Not ad Then ... EndIf`, not `hd = Null`. The
'      `Not <Object>` idiom is what forces the register-reload-then-compare shape
'      (`mov eax,[slot]; cmp eax,sentinel; setne`) that the original actually emits;
'      a direct `hd = Null` test compiles to a leaner direct memory compare instead.
'   3. The home/away tie-break is `If s1 >= s2 Then ... Else ... EndIf` (NOT
'      `s1 < s2` as Ghidra's C phrases it) -- confirmed from branch polarity: the
'      original's `jl` jumps FORWARD to the `g1<g2`-testing block and falls through
'      to the `g1>g2` block, which only happens if the source's Then-branch is the
'      s1>=s2 case. Both arms are direct inline `(A And close=0) Or (B And close=1)`
'      conditions -- no shared homeWin/awayWin Local, and the boolean compares
'      against `close` use plain `= 0` / `= 1` (BlitzMax `Not` on an Int is bitwise
'      complement, not logical negation, so it does NOT reproduce the `cmp x,0/sete`
'      pattern actually used here).
'   4. `close` is built imperatively, not as a boolean expression:
'         Local close:Int = True
'         If Rand(5, 1) > 1 Then close = False
'         If Abs(g1 - g2) > 2 Then close = False
'      `Local close:Int = (Rand(5,1)<=1) And (Abs(g1-g2)<=2)` compiles to a fully
'      materialised setcc-per-operand-then-AND sequence; the original's default-true/
'      conditionally-false shape is what an `If cond Then close = False` idiom emits.
'      This form also happens to line up the register allocator with the original's
'      (g1 stays in a register across the whole function; close lands in a register
'      too; g2/s1/s2 spill to their stack slots) -- with the earlier `And`-expression
'      form, g2 ended up register-resident too and every later reference to it came
'      out 1 byte shorter than the original's memory-reload form.
'   5. The goal clamp reads `If g1 > g2 + 4 Then g1 = g2 + 4` / `If g2 > g1 + 4 Then
'      g2 = g1 + 4` (operand order matters even though `g2+4 < g1` is equivalent --
'      it flips which side of `cmp` is the register instruction).
'   6. `drawn` is only ever written inside `If score1 = score2 Then
'      CreateReplayFixture(); drawn = True EndIf` (matchtype Case 2) -- there is no
'      earlier `drawn = (score1 = score2)` assignment; the comparison gates the call
'      and the store directly.
'   7. Select matchtype has SEPARATE `Case 0` and `Case 1` clauses (each just
'      `resulttype = 1`), not a combined `Case 0, 1` -- the original duplicates the
'      one-line body rather than sharing it, confirmed by two independent `je`-to-
'      distinct-block sequences in the disassembly.
'   8. The two pen-coin picks (`Rand(2,1)` deciding which side's penscore gets +1)
'      compile as `Select Rand(2, 1); Case 1 ... Case 2 ... End Select`, not
'      `If coin = 1 ... ElseIf coin = 2 ... EndIf` -- Select/Case tests the subject
'      once up front (cascading `cmp`/`je`) with the case bodies placed after and an
'      explicit fallthrough jump, which is a different (and, here, larger) shape than
'      an If/ElseIf cascade. `coin` itself is never a named Local -- the Rand() result
'      is tested directly as the Select subject.
'   9. The matchtype=5 leg-2 check is `If fl2*2+score1 <> fl1+score2*2 Then
'      resulttype = 4 Else ... EndIf` (Then/Else swapped vs the natural `=` phrasing)
'      -- confirmed by the `je`-to-rand-block / fallthrough-to-resulttype=4 polarity.
'
' Verified via scripts/localise_diff.py against NSS5.exe: CLEAN, 1066/1066 (100%),
' delta +0. (Also cross-checked with harness.try_method: status=MATCH.)
'
' Field/slot map (confirmed against extracted/object_model.json and vtable_map.tsv):
'   TFixture: sdate+8 matchtype+12 round+16 groupno+20 leg+24 hometeam+28 awayteam+32
'     result+36 resulttype+40 score1+44 score2+48 penscore1+52 penscore2+56 level+60
'     compid+64
'   TCompetition: lfixturelist+96(:TList) teampool+108([]:TTeamPool)
'   TTableData: teamstrength+20 (index 5)

	Method PlayFixture:Int()
		Local drawn:Int = False
		result = 1
		Local comp:TCompetition = TCompetition.SelectById(compid)
		Local tp:TTeamPool = comp.teampool[groupno - 1]
		If Not tp Then comp.lfixturelist.Remove(Self)
		Local hd:TTableData = tp.GetItemById(hometeam)
		Local ad:TTableData = tp.GetItemById(awayteam)
		Local anynew:Int = False
		If Not hd Then
			hd = New TTableData
			score1 = 0
			score2 = 1
			anynew = True
		EndIf
		If Not ad Then
			ad = New TTableData
			score1 = 1
			score2 = 0
			anynew = True
		EndIf
		If Not anynew Then
			Local g1:Int = GetRandomGoal()
			Local g2:Int = GetRandomGoal()
			Local s1:Int = hd.teamstrength
			Local s2:Int = ad.teamstrength
			If Abs(s1 - s2) < 20 Then
				If g1 > g2 + 4 Then g1 = g2 + 4
				If g2 > g1 + 4 Then g2 = g1 + 4
			EndIf
			Local close:Int = True
			If Rand(5, 1) > 1 Then close = False
			If Abs(g1 - g2) > 2 Then close = False
			If s1 >= s2 Then
				If (g1 > g2 And close = 0) Or (g2 > g1 And close = 1) Then
					score1 = g1
					score2 = g2
				Else
					score1 = g2
					score2 = g1
				EndIf
			Else
				If (g1 < g2 And close = 0) Or (g2 < g1 And close = 1) Then
					score1 = g1
					score2 = g2
				Else
					score1 = g2
					score2 = g1
				EndIf
			EndIf
		EndIf
		Select matchtype
			Case 0
				resulttype = 1
			Case 1
				resulttype = 1
			Case 2
				resulttype = 1
				If score1 = score2
					CreateReplayFixture()
					drawn = True
				EndIf
			Case 3
				resulttype = 1
				If score1 = score2
					score1 = score1 + Rand(0, 2)
					score2 = score2 + Rand(0, 2)
					resulttype = 2
				EndIf
				If score1 = score2
					penscore1 = Rand(2, 7)
					penscore2 = Rand(2, 7)
					resulttype = 3
					If penscore1 = penscore2
						Select Rand(2, 1)
							Case 1
								penscore1 = penscore1 + 1
							Case 2
								penscore2 = penscore2 + 1
						End Select
					EndIf
				EndIf
			Case 4
				resulttype = 1
			Case 5
				resulttype = 5
				Local fl1:Int = 0
				Local fl2:Int = 0
				GetFirstLegScore(Varptr fl1, Varptr fl2)
				If fl2 + score1 = fl1 + score2
					If fl2 * 2 + score1 <> fl1 + score2 * 2
						resulttype = 4
					Else
						score1 = score1 + Rand(0, 2)
						score2 = score2 + Rand(0, 2)
						resulttype = 2
						If fl2 + score1 = fl1 + score2
							penscore1 = Rand(2, 7)
							penscore2 = Rand(2, 7)
							resulttype = 3
							If penscore1 = penscore2
								Select Rand(2, 1)
									Case 1
										penscore1 = penscore1 + 1
									Case 2
										penscore2 = penscore2 + 1
								End Select
							EndIf
						EndIf
					EndIf
				EndIf
		End Select
		UpdatePoints(hd, ad)
		Return drawn
	End Method

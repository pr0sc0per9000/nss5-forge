' TCompetition.CreateFixtureListKO
' VA 0x0050BA1A   924 bytes   KIND=Method, SIG=()i, class-table slot 0x6c.
' byte-identical vs NSS5.exe (924/924, original length from Ghidra's inventory, mode=reloc).
' Worker NSS5_WORKER=boot_FixturesKO, NSS5_NO_LEARN=1 for the banked verification below.
'
' Builds the knockout fixture list: for each leg (1 or 2, from Self.legs) it walks the
' team pool in pairs (position 1v2, 3v4, ...) EXCEPT when the round has exactly 4, 8, 16 or
' 32 teams, in which case pairs are read from a precomputed bracket table selected by
' `SelectFixtureTable` (src/recovered_module/SelectFixtureTable.bmx, the module Function
' at 0x004C5280) via classic BlitzMax `DefData`/`ReadData`/`RestoreData`. Full football-level
' description: docs/game/career/season-structure.md ("The two fixture generators" /
' "KO pairing -- table lookup only fires for four sizes").
'
' HOW THE READDATA CALLS GOT NAMED (the one real gap this body had, now closed):
' The two `ReadData` statements per iteration each compile to a call at 0x004A6860 in
' NSS5.exe. That address is not bcc-compiled game code (block=".text" in
' extracted/ghidra/function_inventory.tsv, not "code") and was in no naming table when this
' body was first written. Its identity was proven from TWO independent sources before any
' oracle call taught it to the table:
'   1. `tools/blitzmax-legacy-src/_src/compiler/stm.cpp`, `ReadStm::eval` -- the codegen for
'      `ReadData` -- emits exactly this shape for an Int target: load the tag pointer,
'      dereference it, advance the data cursor by 4 (plus another 4 if the tag's first byte
'      is 'd', a Double needing 8 bytes not 4), then `jsr(CG_INT32,"bbConvertToInt",p,q)`.
'      NSS5.exe's 0x004A6860 disassembles to precisely that: a switch on `tag[0]`
'      ('b','s','i','f','d','$') reading `*val` at the matching width, tail-calling
'      `_bbStringToInt` (0x004A7130, already in brl_functions.tsv) for '$'.
'   2. `tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_types.c` has the C source
'      verbatim: `BBINT bbConvertToInt(void *val,const char *tag){ switch(tag[0]){
'      case 'b': ... case '$': return bbStringToInt(*(BBSTRING*)val); } return 0; }`.
' Cross-image BYTE comparison (codegen-patterns.md 15.1's technique) does NOT apply --
' confirmed by disassembling our own build's `_bbConvertToInt`: same algorithm, but a
' different GCC reordered the switch's case tests and moved the '$' tail call, so the two
' bodies differ throughout despite matching length. This is a genuine 15.4-style GCC
' divergence, not a naming shortcut. The fact was recorded into
' extracted/runtime_helpers.tsv (0x004a6860 = _bbConvertToInt) via one explicit,
' already-proven, non-circular learning call, separate from and prior to the NO_LEARN=1
' run that produced the MATCH recorded above -- the corpus-wide reverify guard
' (scripts/reverify.py, always NO_LEARN=1) will therefore see this body pass using the
' table entry, not by teaching itself anything.
'
' Other things resolved while writing this body (see also SelectFixtureTable.bmx's own
' header for the two DefData tables this shares):
'   * `If Not Self.lfixturelist` (not `If Self.lfixturelist = Null`) for the list-creation
'     guard -- codegen-patterns.md 10.3's `setne al / movzx eax,al` tell (21 bytes vs 12).
'   * The `usetable` gate (round size in {4,8,16,32}) is four SEPARATE statements in the
'     original, not one `Or` chain: `bVar9 = a=32||a=16; if(!bVar9) bVar9=a==8;
'     if(!bVar9) bVar9=a==4;` -- reproduced literally below.
'   * Three decision points load the compared value ONCE and branch off it repeatedly
'     (`Select`, not `If/ElseIf` -- codegen-patterns.md 10.2): the `matchtype` dispatch on
'     `Self.legs` (nesting a `Select leg` inside its `Case 2`), and the final `Select leg`
'     choosing which side of the (hometeampos, awayteampos) pair is home vs away.
'   * `TFixture.CreateFixture`'s 9-int factory signature is
'     `(sdate, matchtype, round, groupno, leg, hometeam, awayteam, level, compid)` -- the
'     TFixture field list minus the result-tracking fields, which default internally.
'     `round`/`groupno` are always the literal `1` for a KO fixture; `leg` is `0` unless the
'     tie is genuinely two-legged.
'   * Field/slot confirmations from object_model.json + vtable_map.tsv: TMyDate.sdate is
'     the object's only field (+8). TMyDate.AddDays/AddWeeks/GetDay are slots 0x3c/0x40/0x4c.
'     TList.Clear/AddLast are slots 0x34/0x44. TCompetition.CheckFixtureClash/
'     GetNoofTeamsInRound are slots 0x74/0xa4.
'
' Body-only format: statements only, no parameters (SIG=()i, Self is implicit).
LogLine("CreateFixtureListKO:" + Self.name)
If Not Self.lfixturelist
	Self.lfixturelist = CreateList()
End If
Self.lfixturelist.Clear()
Local matchdate:TMyDate = TMyDate.Create(Self.primarymatchday, Self.startweek, Self.startyear)
Local numteams:Int = Self.GetNoofTeamsInRound()
Local numlegs:Int = Self.legs
If numlegs < 1 Then numlegs = 1
For Local leg:Int = 1 To numlegs
	SelectFixtureTable(numteams, 1)
	For Local i:Int = 1 To numteams Step 2
		Local hometeampos:Int
		Local awayteampos:Int
		Local usetable:Int = (numteams = 32 Or numteams = 16)
		If Not usetable Then usetable = (numteams = 8)
		If Not usetable Then usetable = (numteams = 4)
		If usetable
			ReadData hometeampos
			ReadData awayteampos
		Else
			hometeampos = i
			awayteampos = i + 1
		EndIf

		If leg = 2 And i = 1
			matchdate.AddWeeks(1)
			While Self.CheckFixtureClash(matchdate)
				matchdate.AddDays(1)
			Wend
		ElseIf Self.level = 1
			If i > 1 And i Mod 4 = 1
				matchdate.AddDays(1)
			EndIf
		ElseIf i = 1
			While matchdate.GetDay() <> Self.primarymatchday And matchdate.GetDay() <> Self.secondarymatchday
				matchdate.AddDays(1)
			Wend
			While Self.CheckFixtureClash(matchdate)
				matchdate.AddDays(1)
			Wend
		EndIf

		Local matchtype:Int = 0
		Select Self.legs
			Case 0
				matchtype = 3
			Case 1
				matchtype = 2
			Case 2
				Select leg
					Case 1
						matchtype = 4
					Case 2
						matchtype = 5
				End Select
		End Select

		Local roundno:Int = leg
		If numlegs < 2 Then roundno = 0

		Select leg
			Case 1
				Self.lfixturelist.AddLast(TFixture.CreateFixture(matchdate.sdate, matchtype, 1, 1, roundno, hometeampos, awayteampos, Self.level, Self.id))
			Case 2
				Self.lfixturelist.AddLast(TFixture.CreateFixture(matchdate.sdate, matchtype, 1, 1, roundno, awayteampos, hometeampos, Self.level, Self.id))
		End Select
	Next
Next
Return 0

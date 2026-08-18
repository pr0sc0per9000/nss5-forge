' SelectFixtureTable -- module-level Function (no Type). NAME IS OURS -- module-level
' Functions carry no debug record.
' VA 0x004C5280   713 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (713/713, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=62, NSS5_NO_LEARN=1).
'
' Called from three places (all cross-referenced in extracted/callgraph_resolved.tsv):
' TCompetition.CreateFixtureListLeague (a1=0, round-robin), TCompetition.CreateFixtureListKO
' (a1<>0, KO bracket seeding) and TCompetition.GetHomeAndAwayTeam (a1=0, re-selects the
' round-robin table when a pairing table is exhausted mid-loop). docs/game/career/
' season-structure.md documents the football-level behaviour ("Round-robin pairing
' tables -- team-count domain"); this file is the code that backs that table.
'
' WHAT IT ACTUALLY IS: not a lookup into a runtime array at all. Every "table" is a
' classic Blitz `DefData` block declared at module scope, and this Function is nothing
' but a giant dispatch of `RestoreData <label>` -- i.e. "point the shared module data-read
' cursor (g_competition_int01, 0x00C58F88, already named by the annotator; SLOT is
' read/advanced elsewhere by TCompetition.GetHomeAndAwayTeam) at the Data block for this
' team count". `RestoreData` compiles to a single `mov dword [cursor], <label address>`
' (10 bytes, C7 05 ...) -- confirmed by isolating it in a standalone probe before writing
' the whole body: a lone `RestoreData` statement reproduces the original's exact
' instruction shape byte-for-byte (mode=reloc). The label address is an ordinary
' absolute-data-address relocation, masked automatically like any other -- this file does
' NOT need to know or reproduce the real pairing tables' CONTENTS (nobody has read them
' yet; see the doc's own Gaps section) to be byte-exact, because SelectFixtureTable never
' reads them, only points at them. The DefData payload placed under each label here is an
' arbitrary distinct literal (so bcc doesn't collapse the labels while building the probe);
' it has no bearing on the verified bytes, which cover only the dispatch code.
'
' bcc's legacy statement keywords are `DefData` / `ReadData` / `RestoreData`, NOT the
' Blitz3D-style bare `Data` / `Read` / `Restore` -- confirmed against
' tools/blitzmax-legacy-src/_src/compiler/toker.cpp's keyword table after the bare forms
' failed to tokenise ("Labels must appear before a loop or DefData statement" even
' immediately following a `Data` statement). `DefData` may only appear at module scope
' (`stm.cpp: DataStm::eval` -- "Data can only be declared in the main program"), hence the
' whole table lives in '!Raw pragmas rather than inside the Function body.
'
' SHAPE, confirmed against the raw disassembly (harness.disasm_original), not the
' decompiler (this VA has no reflection record, so it never entered the decomp corpus at
' all):
'   `If a1 <> 0` selects the KO/bracket-seeding table (mode 1): only 2, 4, 8, 16, 32 have
'   entries -- every other team count leaves g_competition_int01 wherever the previous
'   call left it (see TCompetition.CreateFixtureListKO's own table-lookup gate, which only
'   fires for those four sizes, per season-structure.md).
'   The `Else` selects the round-robin table (mode 0): every count from 2 to 26 has a
'   Case, then the chain jumps straight to 28 -- CONFIRMED FROM THE BYTES, not inferred:
'   the disassembly reads `cmp eax,0x1a / je ... / cmp eax,0x1c / je ...` back to back,
'   with no `cmp eax,0x1b` anywhere in the function. This is the exact gap
'   docs/game/career/season-structure.md's "Quirks" section already documents from the
'   data side (spec 02) -- this is the first time it has been confirmed by reading the
'   code itself. If a 27-team pool is ever built, g_competition_int01 is left pointing at
'   whatever the previous call set it to (a different-sized table, or garbage on the very
'   first call of the game); nothing in this function guards against that. A faithful
'   reimplementation must reproduce the missing Case exactly, not add one.
'   Both Selects are real `Select`/`Case` (all compares emitted back-to-back, then all
'   bodies, per codegen-patterns.md 10.2), not If/ElseIf cascades -- confirmed by the
'   `jmp` at the end of the compare run landing PAST every body's own `jmp` target, which
'   is the Select-only shape.
'   Falls through to `Return 0` unconditionally either way (mode 1 with no matching Case,
'   or mode 0 with a=27 or anything else out of range, both leave the cursor untouched and
'   return 0 -- there is no error path).
'!Raw #Table2
'!Raw DefData 2
'!Raw #Table3
'!Raw DefData 3
'!Raw #Table4
'!Raw DefData 4
'!Raw #Table5
'!Raw DefData 5
'!Raw #Table6
'!Raw DefData 6
'!Raw #Table7
'!Raw DefData 7
'!Raw #Table8
'!Raw DefData 8
'!Raw #Table9
'!Raw DefData 9
'!Raw #Table10
'!Raw DefData 10
'!Raw #Table11
'!Raw DefData 11
'!Raw #Table12
'!Raw DefData 12
'!Raw #Table13
'!Raw DefData 13
'!Raw #Table14
'!Raw DefData 14
'!Raw #Table15
'!Raw DefData 15
'!Raw #Table16
'!Raw DefData 16
'!Raw #Table17
'!Raw DefData 17
'!Raw #Table18
'!Raw DefData 18
'!Raw #Table19
'!Raw DefData 19
'!Raw #Table20
'!Raw DefData 20
'!Raw #Table21
'!Raw DefData 21
'!Raw #Table22
'!Raw DefData 22
'!Raw #Table23
'!Raw DefData 23
'!Raw #Table24
'!Raw DefData 24
'!Raw #Table25
'!Raw DefData 25
'!Raw #Table26
'!Raw DefData 26
'!Raw #Table28
'!Raw DefData 28
'!Raw #KOTable2
'!Raw DefData 102
'!Raw #KOTable4
'!Raw DefData 104
'!Raw #KOTable8
'!Raw DefData 108
'!Raw #KOTable16
'!Raw DefData 116
'!Raw #KOTable32
'!Raw DefData 132
	Function SelectFixtureTable:Int(a0:Int, a1:Int)
		If a1 <> 0
			Select a0
			Case 2
				RestoreData KOTable2
			Case 4
				RestoreData KOTable4
			Case 8
				RestoreData KOTable8
			Case 16
				RestoreData KOTable16
			Case 32
				RestoreData KOTable32
			End Select
		Else
			Select a0
			Case 2
				RestoreData Table2
			Case 3
				RestoreData Table3
			Case 4
				RestoreData Table4
			Case 5
				RestoreData Table5
			Case 6
				RestoreData Table6
			Case 7
				RestoreData Table7
			Case 8
				RestoreData Table8
			Case 9
				RestoreData Table9
			Case 10
				RestoreData Table10
			Case 11
				RestoreData Table11
			Case 12
				RestoreData Table12
			Case 13
				RestoreData Table13
			Case 14
				RestoreData Table14
			Case 15
				RestoreData Table15
			Case 16
				RestoreData Table16
			Case 17
				RestoreData Table17
			Case 18
				RestoreData Table18
			Case 19
				RestoreData Table19
			Case 20
				RestoreData Table20
			Case 21
				RestoreData Table21
			Case 22
				RestoreData Table22
			Case 23
				RestoreData Table23
			Case 24
				RestoreData Table24
			Case 25
				RestoreData Table25
			Case 26
				RestoreData Table26
			Case 28
				RestoreData Table28
			End Select
		EndIf
		Return 0
	End Function

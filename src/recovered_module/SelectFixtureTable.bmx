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
' absolute-data-address relocation, masked automatically like any other, so this file's own
' 713 verified bytes cover only the dispatch code -- SelectFixtureTable never reads the
' tables, it only points at them.
'
' THE TABLE CONTENTS BELOW ARE THE ORIGINAL'S, read out of NSS5.exe. They have to be real
' even though this function's own 713 bytes verify without them, because a program's whole
' DefData is ONE flat array: a table that is too short does not truncate a read, it runs on
' into the next table and then off the end of the array, where the type-tag pointer is 0 and
' `ReadData` dereferences it. bcc emits the out-of-data check only under -d (stm.cpp,
' ReadStm::eval), so in a release build that is an access violation, not a caught error.
'
' Each `#Table<n>` starts at the VA named beside it. Entries are (type-tag, value) pairs of
' 4 bytes each, the tag is `bbIntTypeTag` (0x005C7D14) for all 15,606 records in the array,
' and the array's 0 terminator sits at 0x00C58F84. The values are 1-based team-pool
' positions written as consecutive (home, away) pairs, 8 pairs to a line.
'
' Each league table ends with the sentinel pair -1,-1 and -1 occurs NOWHERE else, which is
' what confirms every table boundary independently of the dispatch addresses.
' TCompetition.GetHomeAndAwayTeam is the code that reads that sentinel and re-points the
' cursor at the head of the same table, so a league longer than its table wraps instead of
' running on into the next one. A 0 means a bye -- Table3, Table5, Table7 and the other
' odd counts round up to an even bracket and park the absentee in slot 0, which is what
' CreateFixtureListLeague's `If home > 0 And away > 0` guard is there to skip. The KO
' tables carry no sentinel: they are exactly one first-round bracket each (n/2 pairs), and
' they are seeded, not sequential -- KOTable16 is 1v4 5v8 9v12 13v16 2v3 6v7 10v11 14v15,
' which keeps the top two seeds apart until the final.
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
' 0x00C3A7D4   3 pairs
'!Raw DefData 1,2,2,1,-1,-1
'!Raw #Table3
' 0x00C3A804   13 pairs
'!Raw DefData 1,2,3,0,0,1,2,3,3,1,2,0,2,1,0,3
'!Raw DefData 1,0,3,2,1,3,0,2,-1,-1
'!Raw #Table4
' 0x00C3A8D4   13 pairs
'!Raw DefData 1,2,3,4,4,1,2,3,3,1,2,4,2,1,4,3
'!Raw DefData 1,4,3,2,1,3,4,2,-1,-1
'!Raw #Table5
' 0x00C3A9A4   31 pairs
'!Raw DefData 1,4,3,2,5,0,0,1,4,3,2,5,3,1,5,4
'!Raw DefData 2,0,0,3,1,5,4,2,5,3,2,1,4,0,4,1
'!Raw DefData 2,3,0,5,1,0,3,4,5,2,1,3,4,5,0,2
'!Raw DefData 3,0,5,1,2,4,3,5,1,2,0,4,-1,-1
'!Raw #Table6
' 0x00C3AB94   31 pairs
'!Raw DefData 1,4,3,2,5,6,6,1,4,3,2,5,3,1,5,4
'!Raw DefData 2,6,6,3,1,5,4,2,5,3,2,1,4,6,4,1
'!Raw DefData 2,3,6,5,1,6,3,4,5,2,1,3,4,5,6,2
'!Raw DefData 3,6,5,1,2,4,3,5,1,2,6,4,-1,-1
'!Raw #Table7
' 0x00C3AD84   57 pairs
'!Raw DefData 1,6,3,4,5,2,7,0,0,1,6,3,4,5,2,7
'!Raw DefData 3,1,5,6,7,4,2,0,0,3,1,5,6,7,4,2
'!Raw DefData 5,3,7,1,2,6,4,0,0,5,3,7,1,2,6,4
'!Raw DefData 7,5,2,3,4,1,6,0,6,1,4,3,2,5,0,7
'!Raw DefData 1,0,3,6,5,4,7,2,1,3,6,5,4,7,0,2
'!Raw DefData 3,0,5,1,7,6,2,4,3,5,1,7,6,2,0,4
'!Raw DefData 5,0,7,3,2,1,4,6,5,7,3,2,1,4,0,6
'!Raw DefData -1,-1
'!Raw #Table8
' 0x00C3B114   57 pairs
'!Raw DefData 1,6,3,4,5,2,7,8,8,1,6,3,4,5,2,7
'!Raw DefData 3,1,5,6,7,4,2,8,8,3,1,5,6,7,4,2
'!Raw DefData 5,3,7,1,2,6,4,8,8,5,3,7,1,2,6,4
'!Raw DefData 7,5,2,3,4,1,6,8,6,1,4,3,2,5,8,7
'!Raw DefData 1,8,3,6,5,4,7,2,1,3,6,5,4,7,8,2
'!Raw DefData 3,8,5,1,7,6,2,4,3,5,1,7,6,2,8,4
'!Raw DefData 5,8,7,3,2,1,4,6,5,7,3,2,1,4,8,6
'!Raw DefData -1,-1
'!Raw #Table9
' 0x00C3B4A4   361 pairs
'!Raw DefData 1,0,3,8,5,6,7,4,9,2,0,3,8,5,6,7
'!Raw DefData 4,9,2,1,8,0,6,3,4,5,2,7,9,1,1,8
'!Raw DefData 0,6,3,4,5,2,7,9,6,8,4,0,2,3,9,5
'!Raw DefData 7,1,1,6,8,4,0,2,3,9,5,7,4,6,2,8
'!Raw DefData 9,0,7,3,5,1,1,4,6,2,8,9,0,7,3,5
'!Raw DefData 2,4,9,6,7,8,5,0,3,1,0,1,8,3,6,5
'!Raw DefData 4,7,2,9,3,0,5,8,7,6,9,4,1,2,0,8
'!Raw DefData 3,6,5,4,7,2,1,9,8,1,6,0,4,3,2,5
'!Raw DefData 9,7,8,6,0,4,3,2,5,9,1,7,6,1,4,8
'!Raw DefData 2,0,9,3,7,5,6,4,8,2,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,9,8,7,0,5,3,4,2,6,9,8,7
'!Raw DefData 0,5,1,3,1,0,3,8,5,6,7,4,9,2,0,3
'!Raw DefData 8,5,6,7,4,9,2,1,8,0,6,3,4,5,2,7
'!Raw DefData 9,1,1,8,0,6,3,4,5,2,7,9,6,8,4,0
'!Raw DefData 2,3,9,5,7,1,1,6,8,4,0,2,3,9,5,7
'!Raw DefData 4,6,2,8,9,0,7,3,5,1,1,4,6,2,8,9
'!Raw DefData 0,7,3,5,2,4,9,6,7,8,5,0,3,1,0,1
'!Raw DefData 8,3,6,5,4,7,2,9,3,0,5,8,7,6,9,4
'!Raw DefData 1,2,0,8,3,6,5,4,7,2,1,9,8,1,6,0
'!Raw DefData 4,3,2,5,9,7,8,6,0,4,3,2,5,9,1,7
'!Raw DefData 6,1,4,8,2,0,9,3,7,5,6,4,8,2,0,9
'!Raw DefData 3,7,1,5,4,1,2,6,9,8,7,0,5,3,4,2
'!Raw DefData 6,9,8,7,0,5,1,3,1,0,3,8,5,6,7,4
'!Raw DefData 9,2,0,3,8,5,6,7,4,9,2,1,8,0,6,3
'!Raw DefData 4,5,2,7,9,1,1,8,0,6,3,4,5,2,7,9
'!Raw DefData 6,8,4,0,2,3,9,5,7,1,1,6,8,4,0,2
'!Raw DefData 3,9,5,7,4,6,2,8,9,0,7,3,5,1,1,4
'!Raw DefData 6,2,8,9,0,7,3,5,2,4,9,6,7,8,5,0
'!Raw DefData 3,1,0,1,8,3,6,5,4,7,2,9,3,0,5,8
'!Raw DefData 7,6,9,4,1,2,0,8,3,6,5,4,7,2,1,9
'!Raw DefData 8,1,6,0,4,3,2,5,9,7,8,6,0,4,3,2
'!Raw DefData 5,9,1,7,6,1,4,8,2,0,9,3,7,5,6,4
'!Raw DefData 8,2,0,9,3,7,1,5,4,1,2,6,9,8,7,0
'!Raw DefData 5,3,4,2,6,9,8,7,0,5,1,3,1,0,3,8
'!Raw DefData 5,6,7,4,9,2,0,3,8,5,6,7,4,9,2,1
'!Raw DefData 8,0,6,3,4,5,2,7,9,1,1,8,0,6,3,4
'!Raw DefData 5,2,7,9,6,8,4,0,2,3,9,5,7,1,1,6
'!Raw DefData 8,4,0,2,3,9,5,7,4,6,2,8,9,0,7,3
'!Raw DefData 5,1,1,4,6,2,8,9,0,7,3,5,2,4,9,6
'!Raw DefData 7,8,5,0,3,1,0,1,8,3,6,5,4,7,2,9
'!Raw DefData 3,0,5,8,7,6,9,4,1,2,0,8,3,6,5,4
'!Raw DefData 7,2,1,9,8,1,6,0,4,3,2,5,9,7,8,6
'!Raw DefData 0,4,3,2,5,9,1,7,6,1,4,8,2,0,9,3
'!Raw DefData 7,5,6,4,8,2,0,9,3,7,1,5,4,1,2,6
'!Raw DefData 9,8,7,0,5,3,4,2,6,9,8,7,0,5,1,3
'!Raw DefData -1,-1
'!Raw #Table10
' 0x00C3CB34   361 pairs
'!Raw DefData 1,10,3,8,5,6,7,4,9,2,10,3,8,5,6,7
'!Raw DefData 4,9,2,1,8,10,6,3,4,5,2,7,9,1,1,8
'!Raw DefData 10,6,3,4,5,2,7,9,6,8,4,10,2,3,9,5
'!Raw DefData 7,1,1,6,8,4,10,2,3,9,5,7,4,6,2,8
'!Raw DefData 9,10,7,3,5,1,1,4,6,2,8,9,10,7,3,5
'!Raw DefData 2,4,9,6,7,8,5,10,3,1,10,1,8,3,6,5
'!Raw DefData 4,7,2,9,3,10,5,8,7,6,9,4,1,2,10,8
'!Raw DefData 3,6,5,4,7,2,1,9,8,1,6,10,4,3,2,5
'!Raw DefData 9,7,8,6,10,4,3,2,5,9,1,7,6,1,4,8
'!Raw DefData 2,10,9,3,7,5,6,4,8,2,10,9,3,7,1,5
'!Raw DefData 4,1,2,6,9,8,7,10,5,3,4,2,6,9,8,7
'!Raw DefData 10,5,1,3,1,10,3,8,5,6,7,4,9,2,10,3
'!Raw DefData 8,5,6,7,4,9,2,1,8,10,6,3,4,5,2,7
'!Raw DefData 9,1,1,8,10,6,3,4,5,2,7,9,6,8,4,10
'!Raw DefData 2,3,9,5,7,1,1,6,8,4,10,2,3,9,5,7
'!Raw DefData 4,6,2,8,9,10,7,3,5,1,1,4,6,2,8,9
'!Raw DefData 10,7,3,5,2,4,9,6,7,8,5,10,3,1,10,1
'!Raw DefData 8,3,6,5,4,7,2,9,3,10,5,8,7,6,9,4
'!Raw DefData 1,2,10,8,3,6,5,4,7,2,1,9,8,1,6,10
'!Raw DefData 4,3,2,5,9,7,8,6,10,4,3,2,5,9,1,7
'!Raw DefData 6,1,4,8,2,10,9,3,7,5,6,4,8,2,10,9
'!Raw DefData 3,7,1,5,4,1,2,6,9,8,7,10,5,3,4,2
'!Raw DefData 6,9,8,7,10,5,1,3,1,10,3,8,5,6,7,4
'!Raw DefData 9,2,10,3,8,5,6,7,4,9,2,1,8,10,6,3
'!Raw DefData 4,5,2,7,9,1,1,8,10,6,3,4,5,2,7,9
'!Raw DefData 6,8,4,10,2,3,9,5,7,1,1,6,8,4,10,2
'!Raw DefData 3,9,5,7,4,6,2,8,9,10,7,3,5,1,1,4
'!Raw DefData 6,2,8,9,10,7,3,5,2,4,9,6,7,8,5,10
'!Raw DefData 3,1,10,1,8,3,6,5,4,7,2,9,3,10,5,8
'!Raw DefData 7,6,9,4,1,2,10,8,3,6,5,4,7,2,1,9
'!Raw DefData 8,1,6,10,4,3,2,5,9,7,8,6,10,4,3,2
'!Raw DefData 5,9,1,7,6,1,4,8,2,10,9,3,7,5,6,4
'!Raw DefData 8,2,10,9,3,7,1,5,4,1,2,6,9,8,7,10
'!Raw DefData 5,3,4,2,6,9,8,7,10,5,1,3,1,10,3,8
'!Raw DefData 5,6,7,4,9,2,10,3,8,5,6,7,4,9,2,1
'!Raw DefData 8,10,6,3,4,5,2,7,9,1,1,8,10,6,3,4
'!Raw DefData 5,2,7,9,6,8,4,10,2,3,9,5,7,1,1,6
'!Raw DefData 8,4,10,2,3,9,5,7,4,6,2,8,9,10,7,3
'!Raw DefData 5,1,1,4,6,2,8,9,10,7,3,5,2,4,9,6
'!Raw DefData 7,8,5,10,3,1,10,1,8,3,6,5,4,7,2,9
'!Raw DefData 3,10,5,8,7,6,9,4,1,2,10,8,3,6,5,4
'!Raw DefData 7,2,1,9,8,1,6,10,4,3,2,5,9,7,8,6
'!Raw DefData 10,4,3,2,5,9,1,7,6,1,4,8,2,10,9,3
'!Raw DefData 7,5,6,4,8,2,10,9,3,7,1,5,4,1,2,6
'!Raw DefData 9,8,7,10,5,3,4,2,6,9,8,7,10,5,1,3
'!Raw DefData -1,-1
'!Raw #Table11
' 0x00C3E1C4   265 pairs
'!Raw DefData 1,0,3,10,5,8,7,6,9,4,11,2,0,3,10,5
'!Raw DefData 8,7,6,9,4,11,2,1,10,0,8,3,6,5,4,7
'!Raw DefData 2,9,11,1,1,10,0,8,3,6,5,4,7,2,9,11
'!Raw DefData 8,10,6,0,4,3,2,5,11,7,9,1,1,8,10,6
'!Raw DefData 0,4,3,2,5,11,7,9,6,8,4,10,2,0,11,3
'!Raw DefData 9,5,7,1,1,6,8,4,10,2,0,11,3,9,5,7
'!Raw DefData 4,6,2,8,11,10,9,0,7,3,5,1,1,4,6,2
'!Raw DefData 8,11,10,9,0,7,3,5,2,4,11,6,9,8,7,10
'!Raw DefData 5,0,3,1,0,1,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 3,0,5,10,7,8,9,6,11,4,1,2,0,10,3,8
'!Raw DefData 5,6,7,4,9,2,1,11,10,1,8,0,6,3,4,5
'!Raw DefData 2,7,11,9,10,8,0,6,3,4,5,2,7,11,1,9
'!Raw DefData 8,1,6,10,4,0,2,3,11,5,9,7,8,6,10,4
'!Raw DefData 0,2,3,11,5,9,1,7,6,1,4,8,2,10,11,0
'!Raw DefData 9,3,7,5,6,4,8,2,10,11,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,11,8,9,10,7,0,5,3,4,2,6,11
'!Raw DefData 8,9,10,7,0,5,1,3,1,0,3,10,5,8,7,6
'!Raw DefData 9,4,11,2,0,3,10,5,8,7,6,9,4,11,2,1
'!Raw DefData 10,0,8,3,6,5,4,7,2,9,11,1,1,10,0,8
'!Raw DefData 3,6,5,4,7,2,9,11,8,10,6,0,4,3,2,5
'!Raw DefData 11,7,9,1,1,8,10,6,0,4,3,2,5,11,7,9
'!Raw DefData 6,8,4,10,2,0,11,3,9,5,7,1,1,6,8,4
'!Raw DefData 10,2,0,11,3,9,5,7,4,6,2,8,11,10,9,0
'!Raw DefData 7,3,5,1,1,4,6,2,8,11,10,9,0,7,3,5
'!Raw DefData 2,4,11,6,9,8,7,10,5,0,3,1,0,1,10,3
'!Raw DefData 8,5,6,7,4,9,2,11,3,0,5,10,7,8,9,6
'!Raw DefData 11,4,1,2,0,10,3,8,5,6,7,4,9,2,1,11
'!Raw DefData 10,1,8,0,6,3,4,5,2,7,11,9,10,8,0,6
'!Raw DefData 3,4,5,2,7,11,1,9,8,1,6,10,4,0,2,3
'!Raw DefData 11,5,9,7,8,6,10,4,0,2,3,11,5,9,1,7
'!Raw DefData 6,1,4,8,2,10,11,0,9,3,7,5,6,4,8,2
'!Raw DefData 10,11,0,9,3,7,1,5,4,1,2,6,11,8,9,10
'!Raw DefData 7,0,5,3,4,2,6,11,8,9,10,7,0,5,1,3
'!Raw DefData -1,-1
'!Raw #Table12
' 0x00C3F254   265 pairs
'!Raw DefData 1,12,3,10,5,8,7,6,9,4,11,2,12,3,10,5
'!Raw DefData 8,7,6,9,4,11,2,1,10,12,8,3,6,5,4,7
'!Raw DefData 2,9,11,1,1,10,12,8,3,6,5,4,7,2,9,11
'!Raw DefData 8,10,6,12,4,3,2,5,11,7,9,1,1,8,10,6
'!Raw DefData 12,4,3,2,5,11,7,9,6,8,4,10,2,12,11,3
'!Raw DefData 9,5,7,1,1,6,8,4,10,2,12,11,3,9,5,7
'!Raw DefData 4,6,2,8,11,10,9,12,7,3,5,1,1,4,6,2
'!Raw DefData 8,11,10,9,12,7,3,5,2,4,11,6,9,8,7,10
'!Raw DefData 5,12,3,1,12,1,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 3,12,5,10,7,8,9,6,11,4,1,2,12,10,3,8
'!Raw DefData 5,6,7,4,9,2,1,11,10,1,8,12,6,3,4,5
'!Raw DefData 2,7,11,9,10,8,12,6,3,4,5,2,7,11,1,9
'!Raw DefData 8,1,6,10,4,12,2,3,11,5,9,7,8,6,10,4
'!Raw DefData 12,2,3,11,5,9,1,7,6,1,4,8,2,10,11,12
'!Raw DefData 9,3,7,5,6,4,8,2,10,11,12,9,3,7,1,5
'!Raw DefData 4,1,2,6,11,8,9,10,7,12,5,3,4,2,6,11
'!Raw DefData 8,9,10,7,12,5,1,3,1,12,3,10,5,8,7,6
'!Raw DefData 9,4,11,2,12,3,10,5,8,7,6,9,4,11,2,1
'!Raw DefData 10,12,8,3,6,5,4,7,2,9,11,1,1,10,12,8
'!Raw DefData 3,6,5,4,7,2,9,11,8,10,6,12,4,3,2,5
'!Raw DefData 11,7,9,1,1,8,10,6,12,4,3,2,5,11,7,9
'!Raw DefData 6,8,4,10,2,12,11,3,9,5,7,1,1,6,8,4
'!Raw DefData 10,2,12,11,3,9,5,7,4,6,2,8,11,10,9,12
'!Raw DefData 7,3,5,1,1,4,6,2,8,11,10,9,12,7,3,5
'!Raw DefData 2,4,11,6,9,8,7,10,5,12,3,1,12,1,10,3
'!Raw DefData 8,5,6,7,4,9,2,11,3,12,5,10,7,8,9,6
'!Raw DefData 11,4,1,2,12,10,3,8,5,6,7,4,9,2,1,11
'!Raw DefData 10,1,8,12,6,3,4,5,2,7,11,9,10,8,12,6
'!Raw DefData 3,4,5,2,7,11,1,9,8,1,6,10,4,12,2,3
'!Raw DefData 11,5,9,7,8,6,10,4,12,2,3,11,5,9,1,7
'!Raw DefData 6,1,4,8,2,10,11,12,9,3,7,5,6,4,8,2
'!Raw DefData 10,11,12,9,3,7,1,5,4,1,2,6,11,8,9,10
'!Raw DefData 7,12,5,3,4,2,6,11,8,9,10,7,12,5,1,3
'!Raw DefData -1,-1
'!Raw #Table13
' 0x00C402E4   183 pairs
'!Raw DefData 0,1,12,3,10,5,8,7,6,9,4,11,2,13,1,12
'!Raw DefData 3,10,5,8,7,6,9,4,11,2,13,0,3,1,5,12
'!Raw DefData 7,10,9,8,11,6,13,4,2,0,0,3,1,5,12,7
'!Raw DefData 10,9,8,11,6,13,4,2,5,3,7,1,9,12,11,10
'!Raw DefData 13,8,2,6,4,0,0,5,3,7,1,9,12,11,10,13
'!Raw DefData 8,2,6,4,7,5,9,3,11,1,13,12,2,10,4,8
'!Raw DefData 6,0,0,7,5,9,3,11,1,13,12,2,10,4,8,6
'!Raw DefData 9,7,11,5,13,3,2,1,4,12,6,10,8,0,0,9
'!Raw DefData 7,11,5,13,3,2,1,4,12,6,10,8,11,9,13,7
'!Raw DefData 2,5,4,3,6,1,8,12,10,0,0,11,9,13,7,2
'!Raw DefData 5,4,3,6,1,8,12,10,13,11,2,9,4,7,6,5
'!Raw DefData 8,3,10,1,12,0,1,0,3,12,5,10,7,8,9,6
'!Raw DefData 11,4,13,2,12,1,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 0,13,1,3,12,5,10,7,8,9,6,11,4,13,0,2
'!Raw DefData 3,0,5,1,7,12,9,10,11,8,13,6,2,4,3,5
'!Raw DefData 1,7,12,9,10,11,8,13,6,2,0,4,5,0,7,3
'!Raw DefData 9,1,11,12,13,10,2,8,4,6,5,7,3,9,1,11
'!Raw DefData 12,13,10,2,8,4,0,6,7,0,9,5,11,3,13,1
'!Raw DefData 2,12,4,10,6,8,7,9,5,11,3,13,1,2,12,4
'!Raw DefData 10,6,0,8,9,0,11,7,13,5,2,3,4,1,6,12
'!Raw DefData 8,10,9,11,7,13,5,2,3,4,1,6,12,8,0,10
'!Raw DefData 11,0,13,9,2,7,4,5,6,3,8,1,10,12,11,13
'!Raw DefData 9,2,7,4,5,6,3,8,1,10,0,12,-1,-1
'!Raw #Table14
' 0x00C40E54   183 pairs
'!Raw DefData 14,1,12,3,10,5,8,7,6,9,4,11,2,13,1,12
'!Raw DefData 3,10,5,8,7,6,9,4,11,2,13,14,3,1,5,12
'!Raw DefData 7,10,9,8,11,6,13,4,2,14,14,3,1,5,12,7
'!Raw DefData 10,9,8,11,6,13,4,2,5,3,7,1,9,12,11,10
'!Raw DefData 13,8,2,6,4,14,14,5,3,7,1,9,12,11,10,13
'!Raw DefData 8,2,6,4,7,5,9,3,11,1,13,12,2,10,4,8
'!Raw DefData 6,14,14,7,5,9,3,11,1,13,12,2,10,4,8,6
'!Raw DefData 9,7,11,5,13,3,2,1,4,12,6,10,8,14,14,9
'!Raw DefData 7,11,5,13,3,2,1,4,12,6,10,8,11,9,13,7
'!Raw DefData 2,5,4,3,6,1,8,12,10,14,14,11,9,13,7,2
'!Raw DefData 5,4,3,6,1,8,12,10,13,11,2,9,4,7,6,5
'!Raw DefData 8,3,10,1,12,14,1,14,3,12,5,10,7,8,9,6
'!Raw DefData 11,4,13,2,12,1,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 14,13,1,3,12,5,10,7,8,9,6,11,4,13,14,2
'!Raw DefData 3,14,5,1,7,12,9,10,11,8,13,6,2,4,3,5
'!Raw DefData 1,7,12,9,10,11,8,13,6,2,14,4,5,14,7,3
'!Raw DefData 9,1,11,12,13,10,2,8,4,6,5,7,3,9,1,11
'!Raw DefData 12,13,10,2,8,4,14,6,7,14,9,5,11,3,13,1
'!Raw DefData 2,12,4,10,6,8,7,9,5,11,3,13,1,2,12,4
'!Raw DefData 10,6,14,8,9,14,11,7,13,5,2,3,4,1,6,12
'!Raw DefData 8,10,9,11,7,13,5,2,3,4,1,6,12,8,14,10
'!Raw DefData 11,14,13,9,2,7,4,5,6,3,8,1,10,12,11,13
'!Raw DefData 9,2,7,4,5,6,3,8,1,10,14,12,-1,-1
'!Raw #Table15
' 0x00C419C4   241 pairs
'!Raw DefData 0,1,14,3,12,5,10,7,8,9,6,11,4,13,2,15
'!Raw DefData 1,14,3,12,5,10,7,8,9,6,11,4,13,2,15,0
'!Raw DefData 3,1,5,14,7,12,9,10,11,8,13,6,15,4,2,0
'!Raw DefData 0,3,1,5,14,7,12,9,10,11,8,13,6,15,4,2
'!Raw DefData 5,3,7,1,9,14,11,12,13,10,15,8,2,6,4,0
'!Raw DefData 0,5,3,7,1,9,14,11,12,13,10,15,8,2,6,4
'!Raw DefData 7,5,9,3,11,1,13,14,15,12,2,10,4,8,6,0
'!Raw DefData 0,7,5,9,3,11,1,13,14,15,12,2,10,4,8,6
'!Raw DefData 9,7,11,5,13,3,15,1,2,14,4,12,6,10,8,0
'!Raw DefData 0,9,7,11,5,13,3,15,1,2,14,4,12,6,10,8
'!Raw DefData 11,9,13,7,15,5,2,3,4,1,6,14,8,12,10,0
'!Raw DefData 0,11,9,13,7,15,5,2,3,4,1,6,14,8,12,10
'!Raw DefData 13,11,15,9,2,7,4,5,6,3,8,1,10,14,12,0
'!Raw DefData 0,13,11,15,9,2,7,4,5,6,3,8,1,10,14,12
'!Raw DefData 15,13,2,11,4,9,6,7,8,5,10,3,12,1,14,0
'!Raw DefData 1,0,3,14,5,12,7,10,9,8,11,6,13,4,15,2
'!Raw DefData 14,1,12,3,10,5,8,7,6,9,4,11,2,13,0,15
'!Raw DefData 1,3,14,5,12,7,10,9,8,11,6,13,4,15,0,2
'!Raw DefData 3,0,5,1,7,14,9,12,11,10,13,8,15,6,2,4
'!Raw DefData 3,5,1,7,14,9,12,11,10,13,8,15,6,2,0,4
'!Raw DefData 5,0,7,3,9,1,11,14,13,12,15,10,2,8,4,6
'!Raw DefData 5,7,3,9,1,11,14,13,12,15,10,2,8,4,0,6
'!Raw DefData 7,0,9,5,11,3,13,1,15,14,2,12,4,10,6,8
'!Raw DefData 7,9,5,11,3,13,1,15,14,2,12,4,10,6,0,8
'!Raw DefData 9,0,11,7,13,5,15,3,2,1,4,14,6,12,8,10
'!Raw DefData 9,11,7,13,5,15,3,2,1,4,14,6,12,8,0,10
'!Raw DefData 11,0,13,9,15,7,2,5,4,3,6,1,8,14,10,12
'!Raw DefData 11,13,9,15,7,2,5,4,3,6,1,8,14,10,0,12
'!Raw DefData 13,0,15,11,2,9,4,7,6,5,8,3,10,1,12,14
'!Raw DefData 13,15,11,2,9,4,7,6,5,8,3,10,1,12,0,14
'!Raw DefData -1,-1
'!Raw #Table16
' 0x00C428D4   241 pairs
'!Raw DefData 16,1,14,3,12,5,10,7,8,9,6,11,4,13,2,15
'!Raw DefData 1,14,3,12,5,10,7,8,9,6,11,4,13,2,15,16
'!Raw DefData 3,1,5,14,7,12,9,10,11,8,13,6,15,4,2,16
'!Raw DefData 16,3,1,5,14,7,12,9,10,11,8,13,6,15,4,2
'!Raw DefData 5,3,7,1,9,14,11,12,13,10,15,8,2,6,4,16
'!Raw DefData 16,5,3,7,1,9,14,11,12,13,10,15,8,2,6,4
'!Raw DefData 7,5,9,3,11,1,13,14,15,12,2,10,4,8,6,16
'!Raw DefData 16,7,5,9,3,11,1,13,14,15,12,2,10,4,8,6
'!Raw DefData 9,7,11,5,13,3,15,1,2,14,4,12,6,10,8,16
'!Raw DefData 16,9,7,11,5,13,3,15,1,2,14,4,12,6,10,8
'!Raw DefData 11,9,13,7,15,5,2,3,4,1,6,14,8,12,10,16
'!Raw DefData 16,11,9,13,7,15,5,2,3,4,1,6,14,8,12,10
'!Raw DefData 13,11,15,9,2,7,4,5,6,3,8,1,10,14,12,16
'!Raw DefData 16,13,11,15,9,2,7,4,5,6,3,8,1,10,14,12
'!Raw DefData 15,13,2,11,4,9,6,7,8,5,10,3,12,1,14,16
'!Raw DefData 1,16,3,14,5,12,7,10,9,8,11,6,13,4,15,2
'!Raw DefData 14,1,12,3,10,5,8,7,6,9,4,11,2,13,16,15
'!Raw DefData 1,3,14,5,12,7,10,9,8,11,6,13,4,15,16,2
'!Raw DefData 3,16,5,1,7,14,9,12,11,10,13,8,15,6,2,4
'!Raw DefData 3,5,1,7,14,9,12,11,10,13,8,15,6,2,16,4
'!Raw DefData 5,16,7,3,9,1,11,14,13,12,15,10,2,8,4,6
'!Raw DefData 5,7,3,9,1,11,14,13,12,15,10,2,8,4,16,6
'!Raw DefData 7,16,9,5,11,3,13,1,15,14,2,12,4,10,6,8
'!Raw DefData 7,9,5,11,3,13,1,15,14,2,12,4,10,6,16,8
'!Raw DefData 9,16,11,7,13,5,15,3,2,1,4,14,6,12,8,10
'!Raw DefData 9,11,7,13,5,15,3,2,1,4,14,6,12,8,16,10
'!Raw DefData 11,16,13,9,15,7,2,5,4,3,6,1,8,14,10,12
'!Raw DefData 11,13,9,15,7,2,5,4,3,6,1,8,14,10,16,12
'!Raw DefData 13,16,15,11,2,9,4,7,6,5,8,3,10,1,12,14
'!Raw DefData 13,15,11,2,9,4,7,6,5,8,3,10,1,12,16,14
'!Raw DefData -1,-1
'!Raw #Table17
' 0x00C437E4   307 pairs
'!Raw DefData 1,0,3,16,5,14,7,12,9,10,11,8,13,6,15,4
'!Raw DefData 17,2,0,3,16,5,14,7,12,9,10,11,8,13,6,15
'!Raw DefData 4,17,2,1,16,0,14,3,12,5,10,7,8,9,6,11
'!Raw DefData 4,13,2,15,17,1,1,16,0,14,3,12,5,10,7,8
'!Raw DefData 9,6,11,4,13,2,15,17,14,16,12,0,10,3,8,5
'!Raw DefData 6,7,4,9,2,11,17,13,15,1,1,14,16,12,0,10
'!Raw DefData 3,8,5,6,7,4,9,2,11,17,13,15,12,14,10,16
'!Raw DefData 8,0,6,3,4,5,2,7,17,9,15,11,13,1,1,12
'!Raw DefData 14,10,16,8,0,6,3,4,5,2,7,17,9,15,11,13
'!Raw DefData 10,12,8,14,6,16,4,0,2,3,17,5,15,7,13,9
'!Raw DefData 11,1,1,10,12,8,14,6,16,4,0,2,3,17,5,15
'!Raw DefData 7,13,9,11,8,10,6,12,4,14,2,16,17,0,15,3
'!Raw DefData 13,5,11,7,9,1,1,8,10,6,12,4,14,2,16,17
'!Raw DefData 0,15,3,13,5,11,7,9,6,8,4,10,2,12,17,14
'!Raw DefData 15,16,13,0,11,3,9,5,7,1,1,6,8,4,10,2
'!Raw DefData 12,17,14,15,16,13,0,11,3,9,5,7,4,6,2,8
'!Raw DefData 17,10,15,12,13,14,11,16,9,0,7,3,5,1,1,4
'!Raw DefData 6,2,8,17,10,15,12,13,14,11,16,9,0,7,3,5
'!Raw DefData 2,4,17,6,15,8,13,10,11,12,9,14,7,16,5,0
'!Raw DefData 3,1,0,1,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,3,0,5,16,7,14,9,12,11,10,13,8
'!Raw DefData 15,6,17,4,1,2,0,16,3,14,5,12,7,10,9,8
'!Raw DefData 11,6,13,4,15,2,1,17,16,1,14,0,12,3,10,5
'!Raw DefData 8,7,6,9,4,11,2,13,17,15,16,14,0,12,3,10
'!Raw DefData 5,8,7,6,9,4,11,2,13,17,1,15,14,1,12,16
'!Raw DefData 10,0,8,3,6,5,4,7,2,9,17,11,15,13,14,12
'!Raw DefData 16,10,0,8,3,6,5,4,7,2,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,0,4,3,2,5,17,7,15,9
'!Raw DefData 13,11,12,10,14,8,16,6,0,4,3,2,5,17,7,15
'!Raw DefData 9,13,1,11,10,1,8,12,6,14,4,16,2,0,17,3
'!Raw DefData 15,5,13,7,11,9,10,8,12,6,14,4,16,2,0,17
'!Raw DefData 3,15,5,13,7,11,1,9,8,1,6,10,4,12,2,14
'!Raw DefData 17,16,15,0,13,3,11,5,9,7,8,6,10,4,12,2
'!Raw DefData 14,17,16,15,0,13,3,11,5,9,1,7,6,1,4,8
'!Raw DefData 2,10,17,12,15,14,13,16,11,0,9,3,7,5,6,4
'!Raw DefData 8,2,10,17,12,15,14,13,16,11,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,17,8,15,10,13,12,11,14,9,16,7,0
'!Raw DefData 5,3,4,2,6,17,8,15,10,13,12,11,14,9,16,7
'!Raw DefData 0,5,1,3,-1,-1
'!Raw #Table18
' 0x00C44B14   307 pairs
'!Raw DefData 1,18,3,16,5,14,7,12,9,10,11,8,13,6,15,4
'!Raw DefData 17,2,18,3,16,5,14,7,12,9,10,11,8,13,6,15
'!Raw DefData 4,17,2,1,16,18,14,3,12,5,10,7,8,9,6,11
'!Raw DefData 4,13,2,15,17,1,1,16,18,14,3,12,5,10,7,8
'!Raw DefData 9,6,11,4,13,2,15,17,14,16,12,18,10,3,8,5
'!Raw DefData 6,7,4,9,2,11,17,13,15,1,1,14,16,12,18,10
'!Raw DefData 3,8,5,6,7,4,9,2,11,17,13,15,12,14,10,16
'!Raw DefData 8,18,6,3,4,5,2,7,17,9,15,11,13,1,1,12
'!Raw DefData 14,10,16,8,18,6,3,4,5,2,7,17,9,15,11,13
'!Raw DefData 10,12,8,14,6,16,4,18,2,3,17,5,15,7,13,9
'!Raw DefData 11,1,1,10,12,8,14,6,16,4,18,2,3,17,5,15
'!Raw DefData 7,13,9,11,8,10,6,12,4,14,2,16,17,18,15,3
'!Raw DefData 13,5,11,7,9,1,1,8,10,6,12,4,14,2,16,17
'!Raw DefData 18,15,3,13,5,11,7,9,6,8,4,10,2,12,17,14
'!Raw DefData 15,16,13,18,11,3,9,5,7,1,1,6,8,4,10,2
'!Raw DefData 12,17,14,15,16,13,18,11,3,9,5,7,4,6,2,8
'!Raw DefData 17,10,15,12,13,14,11,16,9,18,7,3,5,1,1,4
'!Raw DefData 6,2,8,17,10,15,12,13,14,11,16,9,18,7,3,5
'!Raw DefData 2,4,17,6,15,8,13,10,11,12,9,14,7,16,5,18
'!Raw DefData 3,1,18,1,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,3,18,5,16,7,14,9,12,11,10,13,8
'!Raw DefData 15,6,17,4,1,2,18,16,3,14,5,12,7,10,9,8
'!Raw DefData 11,6,13,4,15,2,1,17,16,1,14,18,12,3,10,5
'!Raw DefData 8,7,6,9,4,11,2,13,17,15,16,14,18,12,3,10
'!Raw DefData 5,8,7,6,9,4,11,2,13,17,1,15,14,1,12,16
'!Raw DefData 10,18,8,3,6,5,4,7,2,9,17,11,15,13,14,12
'!Raw DefData 16,10,18,8,3,6,5,4,7,2,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,3,2,5,17,7,15,9
'!Raw DefData 13,11,12,10,14,8,16,6,18,4,3,2,5,17,7,15
'!Raw DefData 9,13,1,11,10,1,8,12,6,14,4,16,2,18,17,3
'!Raw DefData 15,5,13,7,11,9,10,8,12,6,14,4,16,2,18,17
'!Raw DefData 3,15,5,13,7,11,1,9,8,1,6,10,4,12,2,14
'!Raw DefData 17,16,15,18,13,3,11,5,9,7,8,6,10,4,12,2
'!Raw DefData 14,17,16,15,18,13,3,11,5,9,1,7,6,1,4,8
'!Raw DefData 2,10,17,12,15,14,13,16,11,18,9,3,7,5,6,4
'!Raw DefData 8,2,10,17,12,15,14,13,16,11,18,9,3,7,1,5
'!Raw DefData 4,1,2,6,17,8,15,10,13,12,11,14,9,16,7,18
'!Raw DefData 5,3,4,2,6,17,8,15,10,13,12,11,14,9,16,7
'!Raw DefData 18,5,1,3,-1,-1
'!Raw #Table19
' 0x00C45E44   381 pairs
'!Raw DefData 1,0,3,18,5,16,7,14,9,12,11,10,13,8,15,6
'!Raw DefData 17,4,19,2,0,3,18,5,16,7,14,9,12,11,10,13
'!Raw DefData 8,15,6,17,4,19,2,1,18,0,16,3,14,5,12,7
'!Raw DefData 10,9,8,11,6,13,4,15,2,17,19,1,1,18,0,16
'!Raw DefData 3,14,5,12,7,10,9,8,11,6,13,4,15,2,17,19
'!Raw DefData 16,18,14,0,12,3,10,5,8,7,6,9,4,11,2,13
'!Raw DefData 19,15,17,1,1,16,18,14,0,12,3,10,5,8,7,6
'!Raw DefData 9,4,11,2,13,19,15,17,14,16,12,18,10,0,8,3
'!Raw DefData 6,5,4,7,2,9,19,11,17,13,15,1,1,14,16,12
'!Raw DefData 18,10,0,8,3,6,5,4,7,2,9,19,11,17,13,15
'!Raw DefData 12,14,10,16,8,18,6,0,4,3,2,5,19,7,17,9
'!Raw DefData 15,11,13,1,1,12,14,10,16,8,18,6,0,4,3,2
'!Raw DefData 5,19,7,17,9,15,11,13,10,12,8,14,6,16,4,18
'!Raw DefData 2,0,19,3,17,5,15,7,13,9,11,1,1,10,12,8
'!Raw DefData 14,6,16,4,18,2,0,19,3,17,5,15,7,13,9,11
'!Raw DefData 8,10,6,12,4,14,2,16,19,18,17,0,15,3,13,5
'!Raw DefData 11,7,9,1,1,8,10,6,12,4,14,2,16,19,18,17
'!Raw DefData 0,15,3,13,5,11,7,9,6,8,4,10,2,12,19,14
'!Raw DefData 17,16,15,18,13,0,11,3,9,5,7,1,1,6,8,4
'!Raw DefData 10,2,12,19,14,17,16,15,18,13,0,11,3,9,5,7
'!Raw DefData 4,6,2,8,19,10,17,12,15,14,13,16,11,18,9,0
'!Raw DefData 7,3,5,1,1,4,6,2,8,19,10,17,12,15,14,13
'!Raw DefData 16,11,18,9,0,7,3,5,2,4,19,6,17,8,15,10
'!Raw DefData 13,12,11,14,9,16,7,18,5,0,3,1,0,1,18,3
'!Raw DefData 16,5,14,7,12,9,10,11,8,13,6,15,4,17,2,19
'!Raw DefData 3,0,5,18,7,16,9,14,11,12,13,10,15,8,17,6
'!Raw DefData 19,4,1,2,0,18,3,16,5,14,7,12,9,10,11,8
'!Raw DefData 13,6,15,4,17,2,1,19,18,1,16,0,14,3,12,5
'!Raw DefData 10,7,8,9,6,11,4,13,2,15,19,17,18,16,0,14
'!Raw DefData 3,12,5,10,7,8,9,6,11,4,13,2,15,19,1,17
'!Raw DefData 16,1,14,18,12,0,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 19,13,17,15,16,14,18,12,0,10,3,8,5,6,7,4
'!Raw DefData 9,2,11,19,13,17,1,15,14,1,12,16,10,18,8,0
'!Raw DefData 6,3,4,5,2,7,19,9,17,11,15,13,14,12,16,10
'!Raw DefData 18,8,0,6,3,4,5,2,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,0,2,3,19,5,17,7
'!Raw DefData 15,9,13,11,12,10,14,8,16,6,18,4,0,2,3,19
'!Raw DefData 5,17,7,15,9,13,1,11,10,1,8,12,6,14,4,16
'!Raw DefData 2,18,19,0,17,3,15,5,13,7,11,9,10,8,12,6
'!Raw DefData 14,4,16,2,18,19,0,17,3,15,5,13,7,11,1,9
'!Raw DefData 8,1,6,10,4,12,2,14,19,16,17,18,15,0,13,3
'!Raw DefData 11,5,9,7,8,6,10,4,12,2,14,19,16,17,18,15
'!Raw DefData 0,13,3,11,5,9,1,7,6,1,4,8,2,10,19,12
'!Raw DefData 17,14,15,16,13,18,11,0,9,3,7,5,6,4,8,2
'!Raw DefData 10,19,12,17,14,15,16,13,18,11,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,19,8,17,10,15,12,13,14,11,16,9,18
'!Raw DefData 7,0,5,3,4,2,6,19,8,17,10,15,12,13,14,11
'!Raw DefData 16,9,18,7,0,5,1,3,-1,-1
'!Raw #Table20
' 0x00C47614   381 pairs
'!Raw DefData 1,20,3,18,5,16,7,14,9,12,11,10,13,8,15,6
'!Raw DefData 17,4,19,2,20,3,18,5,16,7,14,9,12,11,10,13
'!Raw DefData 8,15,6,17,4,19,2,1,18,20,16,3,14,5,12,7
'!Raw DefData 10,9,8,11,6,13,4,15,2,17,19,1,1,18,20,16
'!Raw DefData 3,14,5,12,7,10,9,8,11,6,13,4,15,2,17,19
'!Raw DefData 16,18,14,20,12,3,10,5,8,7,6,9,4,11,2,13
'!Raw DefData 19,15,17,1,1,16,18,14,20,12,3,10,5,8,7,6
'!Raw DefData 9,4,11,2,13,19,15,17,14,16,12,18,10,20,8,3
'!Raw DefData 6,5,4,7,2,9,19,11,17,13,15,1,1,14,16,12
'!Raw DefData 18,10,20,8,3,6,5,4,7,2,9,19,11,17,13,15
'!Raw DefData 12,14,10,16,8,18,6,20,4,3,2,5,19,7,17,9
'!Raw DefData 15,11,13,1,1,12,14,10,16,8,18,6,20,4,3,2
'!Raw DefData 5,19,7,17,9,15,11,13,10,12,8,14,6,16,4,18
'!Raw DefData 2,20,19,3,17,5,15,7,13,9,11,1,1,10,12,8
'!Raw DefData 14,6,16,4,18,2,20,19,3,17,5,15,7,13,9,11
'!Raw DefData 8,10,6,12,4,14,2,16,19,18,17,20,15,3,13,5
'!Raw DefData 11,7,9,1,1,8,10,6,12,4,14,2,16,19,18,17
'!Raw DefData 20,15,3,13,5,11,7,9,6,8,4,10,2,12,19,14
'!Raw DefData 17,16,15,18,13,20,11,3,9,5,7,1,1,6,8,4
'!Raw DefData 10,2,12,19,14,17,16,15,18,13,20,11,3,9,5,7
'!Raw DefData 4,6,2,8,19,10,17,12,15,14,13,16,11,18,9,20
'!Raw DefData 7,3,5,1,1,4,6,2,8,19,10,17,12,15,14,13
'!Raw DefData 16,11,18,9,20,7,3,5,2,4,19,6,17,8,15,10
'!Raw DefData 13,12,11,14,9,16,7,18,5,20,3,1,20,1,18,3
'!Raw DefData 16,5,14,7,12,9,10,11,8,13,6,15,4,17,2,19
'!Raw DefData 3,20,5,18,7,16,9,14,11,12,13,10,15,8,17,6
'!Raw DefData 19,4,1,2,20,18,3,16,5,14,7,12,9,10,11,8
'!Raw DefData 13,6,15,4,17,2,1,19,18,1,16,20,14,3,12,5
'!Raw DefData 10,7,8,9,6,11,4,13,2,15,19,17,18,16,20,14
'!Raw DefData 3,12,5,10,7,8,9,6,11,4,13,2,15,19,1,17
'!Raw DefData 16,1,14,18,12,20,10,3,8,5,6,7,4,9,2,11
'!Raw DefData 19,13,17,15,16,14,18,12,20,10,3,8,5,6,7,4
'!Raw DefData 9,2,11,19,13,17,1,15,14,1,12,16,10,18,8,20
'!Raw DefData 6,3,4,5,2,7,19,9,17,11,15,13,14,12,16,10
'!Raw DefData 18,8,20,6,3,4,5,2,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,20,2,3,19,5,17,7
'!Raw DefData 15,9,13,11,12,10,14,8,16,6,18,4,20,2,3,19
'!Raw DefData 5,17,7,15,9,13,1,11,10,1,8,12,6,14,4,16
'!Raw DefData 2,18,19,20,17,3,15,5,13,7,11,9,10,8,12,6
'!Raw DefData 14,4,16,2,18,19,20,17,3,15,5,13,7,11,1,9
'!Raw DefData 8,1,6,10,4,12,2,14,19,16,17,18,15,20,13,3
'!Raw DefData 11,5,9,7,8,6,10,4,12,2,14,19,16,17,18,15
'!Raw DefData 20,13,3,11,5,9,1,7,6,1,4,8,2,10,19,12
'!Raw DefData 17,14,15,16,13,18,11,20,9,3,7,5,6,4,8,2
'!Raw DefData 10,19,12,17,14,15,16,13,18,11,20,9,3,7,1,5
'!Raw DefData 4,1,2,6,19,8,17,10,15,12,13,14,11,16,9,18
'!Raw DefData 7,20,5,3,4,2,6,19,8,17,10,15,12,13,14,11
'!Raw DefData 16,9,18,7,20,5,1,3,-1,-1
'!Raw #Table21
' 0x00C48DE4   463 pairs
'!Raw DefData 1,0,3,20,5,18,7,16,9,14,11,12,13,10,15,8
'!Raw DefData 17,6,19,4,21,2,0,3,20,5,18,7,16,9,14,11
'!Raw DefData 12,13,10,15,8,17,6,19,4,21,2,1,20,0,18,3
'!Raw DefData 16,5,14,7,12,9,10,11,8,13,6,15,4,17,2,19
'!Raw DefData 21,1,1,20,0,18,3,16,5,14,7,12,9,10,11,8
'!Raw DefData 13,6,15,4,17,2,19,21,18,20,16,0,14,3,12,5
'!Raw DefData 10,7,8,9,6,11,4,13,2,15,21,17,19,1,1,18
'!Raw DefData 20,16,0,14,3,12,5,10,7,8,9,6,11,4,13,2
'!Raw DefData 15,21,17,19,16,18,14,20,12,0,10,3,8,5,6,7
'!Raw DefData 4,9,2,11,21,13,19,15,17,1,1,16,18,14,20,12
'!Raw DefData 0,10,3,8,5,6,7,4,9,2,11,21,13,19,15,17
'!Raw DefData 14,16,12,18,10,20,8,0,6,3,4,5,2,7,21,9
'!Raw DefData 19,11,17,13,15,1,1,14,16,12,18,10,20,8,0,6
'!Raw DefData 3,4,5,2,7,21,9,19,11,17,13,15,12,14,10,16
'!Raw DefData 8,18,6,20,4,0,2,3,21,5,19,7,17,9,15,11
'!Raw DefData 13,1,1,12,14,10,16,8,18,6,20,4,0,2,3,21
'!Raw DefData 5,19,7,17,9,15,11,13,10,12,8,14,6,16,4,18
'!Raw DefData 2,20,21,0,19,3,17,5,15,7,13,9,11,1,1,10
'!Raw DefData 12,8,14,6,16,4,18,2,20,21,0,19,3,17,5,15
'!Raw DefData 7,13,9,11,8,10,6,12,4,14,2,16,21,18,19,20
'!Raw DefData 17,0,15,3,13,5,11,7,9,1,1,8,10,6,12,4
'!Raw DefData 14,2,16,21,18,19,20,17,0,15,3,13,5,11,7,9
'!Raw DefData 6,8,4,10,2,12,21,14,19,16,17,18,15,20,13,0
'!Raw DefData 11,3,9,5,7,1,1,6,8,4,10,2,12,21,14,19
'!Raw DefData 16,17,18,15,20,13,0,11,3,9,5,7,4,6,2,8
'!Raw DefData 21,10,19,12,17,14,15,16,13,18,11,20,9,0,7,3
'!Raw DefData 5,1,1,4,6,2,8,21,10,19,12,17,14,15,16,13
'!Raw DefData 18,11,20,9,0,7,3,5,2,4,21,6,19,8,17,10
'!Raw DefData 15,12,13,14,11,16,9,18,7,20,5,0,3,1,0,1
'!Raw DefData 20,3,18,5,16,7,14,9,12,11,10,13,8,15,6,17
'!Raw DefData 4,19,2,21,3,0,5,20,7,18,9,16,11,14,13,12
'!Raw DefData 15,10,17,8,19,6,21,4,1,2,0,20,3,18,5,16
'!Raw DefData 7,14,9,12,11,10,13,8,15,6,17,4,19,2,1,21
'!Raw DefData 20,1,18,0,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,21,19,20,18,0,16,3,14,5,12,7,10
'!Raw DefData 9,8,11,6,13,4,15,2,17,21,1,19,18,1,16,20
'!Raw DefData 14,0,12,3,10,5,8,7,6,9,4,11,2,13,21,15
'!Raw DefData 19,17,18,16,20,14,0,12,3,10,5,8,7,6,9,4
'!Raw DefData 11,2,13,21,15,19,1,17,16,1,14,18,12,20,10,0
'!Raw DefData 8,3,6,5,4,7,2,9,21,11,19,13,17,15,16,14
'!Raw DefData 18,12,20,10,0,8,3,6,5,4,7,2,9,21,11,19
'!Raw DefData 13,17,1,15,14,1,12,16,10,18,8,20,6,0,4,3
'!Raw DefData 2,5,21,7,19,9,17,11,15,13,14,12,16,10,18,8
'!Raw DefData 20,6,0,4,3,2,5,21,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,20,2,0,21,3,19,5
'!Raw DefData 17,7,15,9,13,11,12,10,14,8,16,6,18,4,20,2
'!Raw DefData 0,21,3,19,5,17,7,15,9,13,1,11,10,1,8,12
'!Raw DefData 6,14,4,16,2,18,21,20,19,0,17,3,15,5,13,7
'!Raw DefData 11,9,10,8,12,6,14,4,16,2,18,21,20,19,0,17
'!Raw DefData 3,15,5,13,7,11,1,9,8,1,6,10,4,12,2,14
'!Raw DefData 21,16,19,18,17,20,15,0,13,3,11,5,9,7,8,6
'!Raw DefData 10,4,12,2,14,21,16,19,18,17,20,15,0,13,3,11
'!Raw DefData 5,9,1,7,6,1,4,8,2,10,21,12,19,14,17,16
'!Raw DefData 15,18,13,20,11,0,9,3,7,5,6,4,8,2,10,21
'!Raw DefData 12,19,14,17,16,15,18,13,20,11,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,21,8,19,10,17,12,15,14,13,16,11,18
'!Raw DefData 9,20,7,0,5,3,4,2,6,21,8,19,10,17,12,15
'!Raw DefData 14,13,16,11,18,9,20,7,0,5,1,3,-1,-1
'!Raw #Table22
' 0x00C4AAD4   463 pairs
'!Raw DefData 1,22,3,20,5,18,7,16,9,14,11,12,13,10,15,8
'!Raw DefData 17,6,19,4,21,2,22,3,20,5,18,7,16,9,14,11
'!Raw DefData 12,13,10,15,8,17,6,19,4,21,2,1,20,22,18,3
'!Raw DefData 16,5,14,7,12,9,10,11,8,13,6,15,4,17,2,19
'!Raw DefData 21,1,1,20,22,18,3,16,5,14,7,12,9,10,11,8
'!Raw DefData 13,6,15,4,17,2,19,21,18,20,16,22,14,3,12,5
'!Raw DefData 10,7,8,9,6,11,4,13,2,15,21,17,19,1,1,18
'!Raw DefData 20,16,22,14,3,12,5,10,7,8,9,6,11,4,13,2
'!Raw DefData 15,21,17,19,16,18,14,20,12,22,10,3,8,5,6,7
'!Raw DefData 4,9,2,11,21,13,19,15,17,1,1,16,18,14,20,12
'!Raw DefData 22,10,3,8,5,6,7,4,9,2,11,21,13,19,15,17
'!Raw DefData 14,16,12,18,10,20,8,22,6,3,4,5,2,7,21,9
'!Raw DefData 19,11,17,13,15,1,1,14,16,12,18,10,20,8,22,6
'!Raw DefData 3,4,5,2,7,21,9,19,11,17,13,15,12,14,10,16
'!Raw DefData 8,18,6,20,4,22,2,3,21,5,19,7,17,9,15,11
'!Raw DefData 13,1,1,12,14,10,16,8,18,6,20,4,22,2,3,21
'!Raw DefData 5,19,7,17,9,15,11,13,10,12,8,14,6,16,4,18
'!Raw DefData 2,20,21,22,19,3,17,5,15,7,13,9,11,1,1,10
'!Raw DefData 12,8,14,6,16,4,18,2,20,21,22,19,3,17,5,15
'!Raw DefData 7,13,9,11,8,10,6,12,4,14,2,16,21,18,19,20
'!Raw DefData 17,22,15,3,13,5,11,7,9,1,1,8,10,6,12,4
'!Raw DefData 14,2,16,21,18,19,20,17,22,15,3,13,5,11,7,9
'!Raw DefData 6,8,4,10,2,12,21,14,19,16,17,18,15,20,13,22
'!Raw DefData 11,3,9,5,7,1,1,6,8,4,10,2,12,21,14,19
'!Raw DefData 16,17,18,15,20,13,22,11,3,9,5,7,4,6,2,8
'!Raw DefData 21,10,19,12,17,14,15,16,13,18,11,20,9,22,7,3
'!Raw DefData 5,1,1,4,6,2,8,21,10,19,12,17,14,15,16,13
'!Raw DefData 18,11,20,9,22,7,3,5,2,4,21,6,19,8,17,10
'!Raw DefData 15,12,13,14,11,16,9,18,7,20,5,22,3,1,22,1
'!Raw DefData 20,3,18,5,16,7,14,9,12,11,10,13,8,15,6,17
'!Raw DefData 4,19,2,21,3,22,5,20,7,18,9,16,11,14,13,12
'!Raw DefData 15,10,17,8,19,6,21,4,1,2,22,20,3,18,5,16
'!Raw DefData 7,14,9,12,11,10,13,8,15,6,17,4,19,2,1,21
'!Raw DefData 20,1,18,22,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,21,19,20,18,22,16,3,14,5,12,7,10
'!Raw DefData 9,8,11,6,13,4,15,2,17,21,1,19,18,1,16,20
'!Raw DefData 14,22,12,3,10,5,8,7,6,9,4,11,2,13,21,15
'!Raw DefData 19,17,18,16,20,14,22,12,3,10,5,8,7,6,9,4
'!Raw DefData 11,2,13,21,15,19,1,17,16,1,14,18,12,20,10,22
'!Raw DefData 8,3,6,5,4,7,2,9,21,11,19,13,17,15,16,14
'!Raw DefData 18,12,20,10,22,8,3,6,5,4,7,2,9,21,11,19
'!Raw DefData 13,17,1,15,14,1,12,16,10,18,8,20,6,22,4,3
'!Raw DefData 2,5,21,7,19,9,17,11,15,13,14,12,16,10,18,8
'!Raw DefData 20,6,22,4,3,2,5,21,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,20,2,22,21,3,19,5
'!Raw DefData 17,7,15,9,13,11,12,10,14,8,16,6,18,4,20,2
'!Raw DefData 22,21,3,19,5,17,7,15,9,13,1,11,10,1,8,12
'!Raw DefData 6,14,4,16,2,18,21,20,19,22,17,3,15,5,13,7
'!Raw DefData 11,9,10,8,12,6,14,4,16,2,18,21,20,19,22,17
'!Raw DefData 3,15,5,13,7,11,1,9,8,1,6,10,4,12,2,14
'!Raw DefData 21,16,19,18,17,20,15,22,13,3,11,5,9,7,8,6
'!Raw DefData 10,4,12,2,14,21,16,19,18,17,20,15,22,13,3,11
'!Raw DefData 5,9,1,7,6,1,4,8,2,10,21,12,19,14,17,16
'!Raw DefData 15,18,13,20,11,22,9,3,7,5,6,4,8,2,10,21
'!Raw DefData 12,19,14,17,16,15,18,13,20,11,22,9,3,7,1,5
'!Raw DefData 4,1,2,6,21,8,19,10,17,12,15,14,13,16,11,18
'!Raw DefData 9,20,7,22,5,3,4,2,6,21,8,19,10,17,12,15
'!Raw DefData 14,13,16,11,18,9,20,7,22,5,1,3,-1,-1
'!Raw #Table23
' 0x00C4C7C4   553 pairs
'!Raw DefData 1,0,3,22,5,20,7,18,9,16,11,14,13,12,15,10
'!Raw DefData 17,8,19,6,21,4,23,2,0,3,22,5,20,7,18,9
'!Raw DefData 16,11,14,13,12,15,10,17,8,19,6,21,4,23,2,1
'!Raw DefData 22,0,20,3,18,5,16,7,14,9,12,11,10,13,8,15
'!Raw DefData 6,17,4,19,2,21,23,1,1,22,0,20,3,18,5,16
'!Raw DefData 7,14,9,12,11,10,13,8,15,6,17,4,19,2,21,23
'!Raw DefData 20,22,18,0,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,23,19,21,1,1,20,22,18,0,16,3,14
'!Raw DefData 5,12,7,10,9,8,11,6,13,4,15,2,17,23,19,21
'!Raw DefData 18,20,16,22,14,0,12,3,10,5,8,7,6,9,4,11
'!Raw DefData 2,13,23,15,21,17,19,1,1,18,20,16,22,14,0,12
'!Raw DefData 3,10,5,8,7,6,9,4,11,2,13,23,15,21,17,19
'!Raw DefData 16,18,14,20,12,22,10,0,8,3,6,5,4,7,2,9
'!Raw DefData 23,11,21,13,19,15,17,1,1,16,18,14,20,12,22,10
'!Raw DefData 0,8,3,6,5,4,7,2,9,23,11,21,13,19,15,17
'!Raw DefData 14,16,12,18,10,20,8,22,6,0,4,3,2,5,23,7
'!Raw DefData 21,9,19,11,17,13,15,1,1,14,16,12,18,10,20,8
'!Raw DefData 22,6,0,4,3,2,5,23,7,21,9,19,11,17,13,15
'!Raw DefData 12,14,10,16,8,18,6,20,4,22,2,0,23,3,21,5
'!Raw DefData 19,7,17,9,15,11,13,1,1,12,14,10,16,8,18,6
'!Raw DefData 20,4,22,2,0,23,3,21,5,19,7,17,9,15,11,13
'!Raw DefData 10,12,8,14,6,16,4,18,2,20,23,22,21,0,19,3
'!Raw DefData 17,5,15,7,13,9,11,1,1,10,12,8,14,6,16,4
'!Raw DefData 18,2,20,23,22,21,0,19,3,17,5,15,7,13,9,11
'!Raw DefData 8,10,6,12,4,14,2,16,23,18,21,20,19,22,17,0
'!Raw DefData 15,3,13,5,11,7,9,1,1,8,10,6,12,4,14,2
'!Raw DefData 16,23,18,21,20,19,22,17,0,15,3,13,5,11,7,9
'!Raw DefData 6,8,4,10,2,12,23,14,21,16,19,18,17,20,15,22
'!Raw DefData 13,0,11,3,9,5,7,1,1,6,8,4,10,2,12,23
'!Raw DefData 14,21,16,19,18,17,20,15,22,13,0,11,3,9,5,7
'!Raw DefData 4,6,2,8,23,10,21,12,19,14,17,16,15,18,13,20
'!Raw DefData 11,22,9,0,7,3,5,1,1,4,6,2,8,23,10,21
'!Raw DefData 12,19,14,17,16,15,18,13,20,11,22,9,0,7,3,5
'!Raw DefData 2,4,23,6,21,8,19,10,17,12,15,14,13,16,11,18
'!Raw DefData 9,20,7,22,5,0,3,1,0,1,22,3,20,5,18,7
'!Raw DefData 16,9,14,11,12,13,10,15,8,17,6,19,4,21,2,23
'!Raw DefData 3,0,5,22,7,20,9,18,11,16,13,14,15,12,17,10
'!Raw DefData 19,8,21,6,23,4,1,2,0,22,3,20,5,18,7,16
'!Raw DefData 9,14,11,12,13,10,15,8,17,6,19,4,21,2,1,23
'!Raw DefData 22,1,20,0,18,3,16,5,14,7,12,9,10,11,8,13
'!Raw DefData 6,15,4,17,2,19,23,21,22,20,0,18,3,16,5,14
'!Raw DefData 7,12,9,10,11,8,13,6,15,4,17,2,19,23,1,21
'!Raw DefData 20,1,18,22,16,0,14,3,12,5,10,7,8,9,6,11
'!Raw DefData 4,13,2,15,23,17,21,19,20,18,22,16,0,14,3,12
'!Raw DefData 5,10,7,8,9,6,11,4,13,2,15,23,17,21,1,19
'!Raw DefData 18,1,16,20,14,22,12,0,10,3,8,5,6,7,4,9
'!Raw DefData 2,11,23,13,21,15,19,17,18,16,20,14,22,12,0,10
'!Raw DefData 3,8,5,6,7,4,9,2,11,23,13,21,15,19,1,17
'!Raw DefData 16,1,14,18,12,20,10,22,8,0,6,3,4,5,2,7
'!Raw DefData 23,9,21,11,19,13,17,15,16,14,18,12,20,10,22,8
'!Raw DefData 0,6,3,4,5,2,7,23,9,21,11,19,13,17,1,15
'!Raw DefData 14,1,12,16,10,18,8,20,6,22,4,0,2,3,23,5
'!Raw DefData 21,7,19,9,17,11,15,13,14,12,16,10,18,8,20,6
'!Raw DefData 22,4,0,2,3,23,5,21,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,20,2,22,23,0,21,3
'!Raw DefData 19,5,17,7,15,9,13,11,12,10,14,8,16,6,18,4
'!Raw DefData 20,2,22,23,0,21,3,19,5,17,7,15,9,13,1,11
'!Raw DefData 10,1,8,12,6,14,4,16,2,18,23,20,21,22,19,0
'!Raw DefData 17,3,15,5,13,7,11,9,10,8,12,6,14,4,16,2
'!Raw DefData 18,23,20,21,22,19,0,17,3,15,5,13,7,11,1,9
'!Raw DefData 8,1,6,10,4,12,2,14,23,16,21,18,19,20,17,22
'!Raw DefData 15,0,13,3,11,5,9,7,8,6,10,4,12,2,14,23
'!Raw DefData 16,21,18,19,20,17,22,15,0,13,3,11,5,9,1,7
'!Raw DefData 6,1,4,8,2,10,23,12,21,14,19,16,17,18,15,20
'!Raw DefData 13,22,11,0,9,3,7,5,6,4,8,2,10,23,12,21
'!Raw DefData 14,19,16,17,18,15,20,13,22,11,0,9,3,7,1,5
'!Raw DefData 4,1,2,6,23,8,21,10,19,12,17,14,15,16,13,18
'!Raw DefData 11,20,9,22,7,0,5,3,4,2,6,23,8,21,10,19
'!Raw DefData 12,17,14,15,16,13,18,11,20,9,22,7,0,5,1,3
'!Raw DefData -1,-1
'!Raw #Table24
' 0x00C4EA54   553 pairs
'!Raw DefData 1,24,3,22,5,20,7,18,9,16,11,14,13,12,15,10
'!Raw DefData 17,8,19,6,21,4,23,2,24,3,22,5,20,7,18,9
'!Raw DefData 16,11,14,13,12,15,10,17,8,19,6,21,4,23,2,1
'!Raw DefData 22,24,20,3,18,5,16,7,14,9,12,11,10,13,8,15
'!Raw DefData 6,17,4,19,2,21,23,1,1,22,24,20,3,18,5,16
'!Raw DefData 7,14,9,12,11,10,13,8,15,6,17,4,19,2,21,23
'!Raw DefData 20,22,18,24,16,3,14,5,12,7,10,9,8,11,6,13
'!Raw DefData 4,15,2,17,23,19,21,1,1,20,22,18,24,16,3,14
'!Raw DefData 5,12,7,10,9,8,11,6,13,4,15,2,17,23,19,21
'!Raw DefData 18,20,16,22,14,24,12,3,10,5,8,7,6,9,4,11
'!Raw DefData 2,13,23,15,21,17,19,1,1,18,20,16,22,14,24,12
'!Raw DefData 3,10,5,8,7,6,9,4,11,2,13,23,15,21,17,19
'!Raw DefData 16,18,14,20,12,22,10,24,8,3,6,5,4,7,2,9
'!Raw DefData 23,11,21,13,19,15,17,1,1,16,18,14,20,12,22,10
'!Raw DefData 24,8,3,6,5,4,7,2,9,23,11,21,13,19,15,17
'!Raw DefData 14,16,12,18,10,20,8,22,6,24,4,3,2,5,23,7
'!Raw DefData 21,9,19,11,17,13,15,1,1,14,16,12,18,10,20,8
'!Raw DefData 22,6,24,4,3,2,5,23,7,21,9,19,11,17,13,15
'!Raw DefData 12,14,10,16,8,18,6,20,4,22,2,24,23,3,21,5
'!Raw DefData 19,7,17,9,15,11,13,1,1,12,14,10,16,8,18,6
'!Raw DefData 20,4,22,2,24,23,3,21,5,19,7,17,9,15,11,13
'!Raw DefData 10,12,8,14,6,16,4,18,2,20,23,22,21,24,19,3
'!Raw DefData 17,5,15,7,13,9,11,1,1,10,12,8,14,6,16,4
'!Raw DefData 18,2,20,23,22,21,24,19,3,17,5,15,7,13,9,11
'!Raw DefData 8,10,6,12,4,14,2,16,23,18,21,20,19,22,17,24
'!Raw DefData 15,3,13,5,11,7,9,1,1,8,10,6,12,4,14,2
'!Raw DefData 16,23,18,21,20,19,22,17,24,15,3,13,5,11,7,9
'!Raw DefData 6,8,4,10,2,12,23,14,21,16,19,18,17,20,15,22
'!Raw DefData 13,24,11,3,9,5,7,1,1,6,8,4,10,2,12,23
'!Raw DefData 14,21,16,19,18,17,20,15,22,13,24,11,3,9,5,7
'!Raw DefData 4,6,2,8,23,10,21,12,19,14,17,16,15,18,13,20
'!Raw DefData 11,22,9,24,7,3,5,1,1,4,6,2,8,23,10,21
'!Raw DefData 12,19,14,17,16,15,18,13,20,11,22,9,24,7,3,5
'!Raw DefData 2,4,23,6,21,8,19,10,17,12,15,14,13,16,11,18
'!Raw DefData 9,20,7,22,5,24,3,1,24,1,22,3,20,5,18,7
'!Raw DefData 16,9,14,11,12,13,10,15,8,17,6,19,4,21,2,23
'!Raw DefData 3,24,5,22,7,20,9,18,11,16,13,14,15,12,17,10
'!Raw DefData 19,8,21,6,23,4,1,2,24,22,3,20,5,18,7,16
'!Raw DefData 9,14,11,12,13,10,15,8,17,6,19,4,21,2,1,23
'!Raw DefData 22,1,20,24,18,3,16,5,14,7,12,9,10,11,8,13
'!Raw DefData 6,15,4,17,2,19,23,21,22,20,24,18,3,16,5,14
'!Raw DefData 7,12,9,10,11,8,13,6,15,4,17,2,19,23,1,21
'!Raw DefData 20,1,18,22,16,24,14,3,12,5,10,7,8,9,6,11
'!Raw DefData 4,13,2,15,23,17,21,19,20,18,22,16,24,14,3,12
'!Raw DefData 5,10,7,8,9,6,11,4,13,2,15,23,17,21,1,19
'!Raw DefData 18,1,16,20,14,22,12,24,10,3,8,5,6,7,4,9
'!Raw DefData 2,11,23,13,21,15,19,17,18,16,20,14,22,12,24,10
'!Raw DefData 3,8,5,6,7,4,9,2,11,23,13,21,15,19,1,17
'!Raw DefData 16,1,14,18,12,20,10,22,8,24,6,3,4,5,2,7
'!Raw DefData 23,9,21,11,19,13,17,15,16,14,18,12,20,10,22,8
'!Raw DefData 24,6,3,4,5,2,7,23,9,21,11,19,13,17,1,15
'!Raw DefData 14,1,12,16,10,18,8,20,6,22,4,24,2,3,23,5
'!Raw DefData 21,7,19,9,17,11,15,13,14,12,16,10,18,8,20,6
'!Raw DefData 22,4,24,2,3,23,5,21,7,19,9,17,11,15,1,13
'!Raw DefData 12,1,10,14,8,16,6,18,4,20,2,22,23,24,21,3
'!Raw DefData 19,5,17,7,15,9,13,11,12,10,14,8,16,6,18,4
'!Raw DefData 20,2,22,23,24,21,3,19,5,17,7,15,9,13,1,11
'!Raw DefData 10,1,8,12,6,14,4,16,2,18,23,20,21,22,19,24
'!Raw DefData 17,3,15,5,13,7,11,9,10,8,12,6,14,4,16,2
'!Raw DefData 18,23,20,21,22,19,24,17,3,15,5,13,7,11,1,9
'!Raw DefData 8,1,6,10,4,12,2,14,23,16,21,18,19,20,17,22
'!Raw DefData 15,24,13,3,11,5,9,7,8,6,10,4,12,2,14,23
'!Raw DefData 16,21,18,19,20,17,22,15,24,13,3,11,5,9,1,7
'!Raw DefData 6,1,4,8,2,10,23,12,21,14,19,16,17,18,15,20
'!Raw DefData 13,22,11,24,9,3,7,5,6,4,8,2,10,23,12,21
'!Raw DefData 14,19,16,17,18,15,20,13,22,11,24,9,3,7,1,5
'!Raw DefData 4,1,2,6,23,8,21,10,19,12,17,14,15,16,13,18
'!Raw DefData 11,20,9,22,7,24,5,3,4,2,6,23,8,21,10,19
'!Raw DefData 12,17,14,15,16,13,18,11,20,9,22,7,24,5,1,3
'!Raw DefData -1,-1
'!Raw #Table25
' 0x00C50CE4   651 pairs
'!Raw DefData 1,0,2,25,3,24,4,23,5,22,6,21,7,20,8,19
'!Raw DefData 9,18,10,17,11,16,12,15,13,14,0,14,15,13,16,12
'!Raw DefData 17,11,18,10,19,9,20,8,21,7,22,6,23,5,24,4
'!Raw DefData 25,3,1,2,2,0,3,1,4,25,5,24,6,23,7,22
'!Raw DefData 8,21,9,20,10,19,11,18,12,17,13,16,14,15,0,15
'!Raw DefData 16,14,17,13,18,12,19,11,20,10,21,9,22,8,23,7
'!Raw DefData 24,6,25,5,1,4,2,3,3,0,4,2,5,1,6,25
'!Raw DefData 7,24,8,23,9,22,10,21,11,20,12,19,13,18,14,17
'!Raw DefData 15,16,0,16,17,15,18,14,19,13,20,12,21,11,22,10
'!Raw DefData 23,9,24,8,25,7,1,6,2,5,3,4,4,0,5,3
'!Raw DefData 6,2,7,1,8,25,9,24,10,23,11,22,12,21,13,20
'!Raw DefData 14,19,15,18,16,17,0,17,18,16,19,15,20,14,21,13
'!Raw DefData 22,12,23,11,24,10,25,9,1,8,2,7,3,6,4,5
'!Raw DefData 5,0,6,4,7,3,8,2,9,1,10,25,11,24,12,23
'!Raw DefData 13,22,14,21,15,20,16,19,17,18,0,18,19,17,20,16
'!Raw DefData 21,15,22,14,23,13,24,12,25,11,1,10,2,9,3,8
'!Raw DefData 4,7,5,6,6,0,7,5,8,4,9,3,10,2,11,1
'!Raw DefData 12,25,13,24,14,23,15,22,16,21,17,20,18,19,0,19
'!Raw DefData 20,18,21,17,22,16,23,15,24,14,25,13,1,12,2,11
'!Raw DefData 3,10,4,9,5,8,6,7,7,0,8,6,9,5,10,4
'!Raw DefData 11,3,12,2,13,1,14,25,15,24,16,23,17,22,18,21
'!Raw DefData 19,20,0,20,21,19,22,18,23,17,24,16,25,15,1,14
'!Raw DefData 2,13,3,12,4,11,5,10,6,9,7,8,8,0,9,7
'!Raw DefData 10,6,11,5,12,4,13,3,14,2,15,1,16,25,17,24
'!Raw DefData 18,23,19,22,20,21,0,21,22,20,23,19,24,18,25,17
'!Raw DefData 1,16,2,15,3,14,4,13,5,12,6,11,7,10,8,9
'!Raw DefData 9,0,10,8,11,7,12,6,13,5,14,4,15,3,16,2
'!Raw DefData 17,1,18,25,19,24,20,23,21,22,0,22,23,21,24,20
'!Raw DefData 25,19,1,18,2,17,3,16,4,15,5,14,6,13,7,12
'!Raw DefData 8,11,9,10,10,0,11,9,12,8,13,7,14,6,15,5
'!Raw DefData 16,4,17,3,18,2,19,1,20,25,21,24,22,23,0,23
'!Raw DefData 24,22,25,21,1,20,2,19,3,18,4,17,5,16,6,15
'!Raw DefData 7,14,8,13,9,12,10,11,11,0,12,10,13,9,14,8
'!Raw DefData 15,7,16,6,17,5,18,4,19,3,20,2,21,1,22,25
'!Raw DefData 23,24,0,24,25,23,1,22,2,21,3,20,4,19,5,18
'!Raw DefData 6,17,7,16,8,15,9,14,10,13,11,12,12,0,13,11
'!Raw DefData 14,10,15,9,16,8,17,7,18,6,19,5,20,4,21,3
'!Raw DefData 22,2,23,1,24,25,0,25,1,24,2,23,3,22,4,21
'!Raw DefData 5,20,6,19,7,18,8,17,9,16,10,15,11,14,12,13
'!Raw DefData 13,0,14,12,15,11,16,10,17,9,18,8,19,7,20,6
'!Raw DefData 21,5,22,4,23,3,24,2,25,1,0,1,25,2,24,3
'!Raw DefData 23,4,22,5,21,6,20,7,19,8,18,9,17,10,16,11
'!Raw DefData 15,12,14,13,14,0,13,15,12,16,11,17,10,18,9,19
'!Raw DefData 8,20,7,21,6,22,5,23,4,24,3,25,2,1,0,2
'!Raw DefData 1,3,25,4,24,5,23,6,22,7,21,8,20,9,19,10
'!Raw DefData 18,11,17,12,16,13,15,14,15,0,14,16,13,17,12,18
'!Raw DefData 11,19,10,20,9,21,8,22,7,23,6,24,5,25,4,1
'!Raw DefData 3,2,0,3,2,4,1,5,25,6,24,7,23,8,22,9
'!Raw DefData 21,10,20,11,19,12,18,13,17,14,16,15,16,0,15,17
'!Raw DefData 14,18,13,19,12,20,11,21,10,22,9,23,8,24,7,25
'!Raw DefData 6,1,5,2,4,3,0,4,3,5,2,6,1,7,25,8
'!Raw DefData 24,9,23,10,22,11,21,12,20,13,19,14,18,15,17,16
'!Raw DefData 17,0,16,18,15,19,14,20,13,21,12,22,11,23,10,24
'!Raw DefData 9,25,8,1,7,2,6,3,5,4,0,5,4,6,3,7
'!Raw DefData 2,8,1,9,25,10,24,11,23,12,22,13,21,14,20,15
'!Raw DefData 19,16,18,17,18,0,17,19,16,20,15,21,14,22,13,23
'!Raw DefData 12,24,11,25,10,1,9,2,8,3,7,4,6,5,0,6
'!Raw DefData 5,7,4,8,3,9,2,10,1,11,25,12,24,13,23,14
'!Raw DefData 22,15,21,16,20,17,19,18,19,0,18,20,17,21,16,22
'!Raw DefData 15,23,14,24,13,25,12,1,11,2,10,3,9,4,8,5
'!Raw DefData 7,6,0,7,6,8,5,9,4,10,3,11,2,12,1,13
'!Raw DefData 25,14,24,15,23,16,22,17,21,18,20,19,20,0,19,21
'!Raw DefData 18,22,17,23,16,24,15,25,14,1,13,2,12,3,11,4
'!Raw DefData 10,5,9,6,8,7,0,8,7,9,6,10,5,11,4,12
'!Raw DefData 3,13,2,14,1,15,25,16,24,17,23,18,22,19,21,20
'!Raw DefData 21,0,20,22,19,23,18,24,17,25,16,1,15,2,14,3
'!Raw DefData 13,4,12,5,11,6,10,7,9,8,0,9,8,10,7,11
'!Raw DefData 6,12,5,13,4,14,3,15,2,16,1,17,25,18,24,19
'!Raw DefData 23,20,22,21,22,0,21,23,20,24,19,25,18,1,17,2
'!Raw DefData 16,3,15,4,14,5,13,6,12,7,11,8,10,9,0,10
'!Raw DefData 9,11,8,12,7,13,6,14,5,15,4,16,3,17,2,18
'!Raw DefData 1,19,25,20,24,21,23,22,23,0,22,24,21,25,20,1
'!Raw DefData 19,2,18,3,17,4,16,5,15,6,14,7,13,8,12,9
'!Raw DefData 11,10,0,11,10,12,9,13,8,14,7,15,6,16,5,17
'!Raw DefData 4,18,3,19,2,20,1,21,25,22,24,23,24,0,23,25
'!Raw DefData 22,1,21,2,20,3,19,4,18,5,17,6,16,7,15,8
'!Raw DefData 14,9,13,10,12,11,0,12,11,13,10,14,9,15,8,16
'!Raw DefData 7,17,6,18,5,19,4,20,3,21,2,22,1,23,25,24
'!Raw DefData 25,0,24,1,23,2,22,3,21,4,20,5,19,6,18,7
'!Raw DefData 17,8,16,9,15,10,14,11,13,12,0,13,12,14,11,15
'!Raw DefData 10,16,9,17,8,18,7,19,6,20,5,21,4,22,3,23
'!Raw DefData 2,24,1,25,-1,-1
'!Raw #Table26
' 0x00C53594   651 pairs
'!Raw DefData 1,26,2,25,3,24,4,23,5,22,6,21,7,20,8,19
'!Raw DefData 9,18,10,17,11,16,12,15,13,14,26,14,15,13,16,12
'!Raw DefData 17,11,18,10,19,9,20,8,21,7,22,6,23,5,24,4
'!Raw DefData 25,3,1,2,2,26,3,1,4,25,5,24,6,23,7,22
'!Raw DefData 8,21,9,20,10,19,11,18,12,17,13,16,14,15,26,15
'!Raw DefData 16,14,17,13,18,12,19,11,20,10,21,9,22,8,23,7
'!Raw DefData 24,6,25,5,1,4,2,3,3,26,4,2,5,1,6,25
'!Raw DefData 7,24,8,23,9,22,10,21,11,20,12,19,13,18,14,17
'!Raw DefData 15,16,26,16,17,15,18,14,19,13,20,12,21,11,22,10
'!Raw DefData 23,9,24,8,25,7,1,6,2,5,3,4,4,26,5,3
'!Raw DefData 6,2,7,1,8,25,9,24,10,23,11,22,12,21,13,20
'!Raw DefData 14,19,15,18,16,17,26,17,18,16,19,15,20,14,21,13
'!Raw DefData 22,12,23,11,24,10,25,9,1,8,2,7,3,6,4,5
'!Raw DefData 5,26,6,4,7,3,8,2,9,1,10,25,11,24,12,23
'!Raw DefData 13,22,14,21,15,20,16,19,17,18,26,18,19,17,20,16
'!Raw DefData 21,15,22,14,23,13,24,12,25,11,1,10,2,9,3,8
'!Raw DefData 4,7,5,6,6,26,7,5,8,4,9,3,10,2,11,1
'!Raw DefData 12,25,13,24,14,23,15,22,16,21,17,20,18,19,26,19
'!Raw DefData 20,18,21,17,22,16,23,15,24,14,25,13,1,12,2,11
'!Raw DefData 3,10,4,9,5,8,6,7,7,26,8,6,9,5,10,4
'!Raw DefData 11,3,12,2,13,1,14,25,15,24,16,23,17,22,18,21
'!Raw DefData 19,20,26,20,21,19,22,18,23,17,24,16,25,15,1,14
'!Raw DefData 2,13,3,12,4,11,5,10,6,9,7,8,8,26,9,7
'!Raw DefData 10,6,11,5,12,4,13,3,14,2,15,1,16,25,17,24
'!Raw DefData 18,23,19,22,20,21,26,21,22,20,23,19,24,18,25,17
'!Raw DefData 1,16,2,15,3,14,4,13,5,12,6,11,7,10,8,9
'!Raw DefData 9,26,10,8,11,7,12,6,13,5,14,4,15,3,16,2
'!Raw DefData 17,1,18,25,19,24,20,23,21,22,26,22,23,21,24,20
'!Raw DefData 25,19,1,18,2,17,3,16,4,15,5,14,6,13,7,12
'!Raw DefData 8,11,9,10,10,26,11,9,12,8,13,7,14,6,15,5
'!Raw DefData 16,4,17,3,18,2,19,1,20,25,21,24,22,23,26,23
'!Raw DefData 24,22,25,21,1,20,2,19,3,18,4,17,5,16,6,15
'!Raw DefData 7,14,8,13,9,12,10,11,11,26,12,10,13,9,14,8
'!Raw DefData 15,7,16,6,17,5,18,4,19,3,20,2,21,1,22,25
'!Raw DefData 23,24,26,24,25,23,1,22,2,21,3,20,4,19,5,18
'!Raw DefData 6,17,7,16,8,15,9,14,10,13,11,12,12,26,13,11
'!Raw DefData 14,10,15,9,16,8,17,7,18,6,19,5,20,4,21,3
'!Raw DefData 22,2,23,1,24,25,26,25,1,24,2,23,3,22,4,21
'!Raw DefData 5,20,6,19,7,18,8,17,9,16,10,15,11,14,12,13
'!Raw DefData 13,26,14,12,15,11,16,10,17,9,18,8,19,7,20,6
'!Raw DefData 21,5,22,4,23,3,24,2,25,1,26,1,25,2,24,3
'!Raw DefData 23,4,22,5,21,6,20,7,19,8,18,9,17,10,16,11
'!Raw DefData 15,12,14,13,14,26,13,15,12,16,11,17,10,18,9,19
'!Raw DefData 8,20,7,21,6,22,5,23,4,24,3,25,2,1,26,2
'!Raw DefData 1,3,25,4,24,5,23,6,22,7,21,8,20,9,19,10
'!Raw DefData 18,11,17,12,16,13,15,14,15,26,14,16,13,17,12,18
'!Raw DefData 11,19,10,20,9,21,8,22,7,23,6,24,5,25,4,1
'!Raw DefData 3,2,26,3,2,4,1,5,25,6,24,7,23,8,22,9
'!Raw DefData 21,10,20,11,19,12,18,13,17,14,16,15,16,26,15,17
'!Raw DefData 14,18,13,19,12,20,11,21,10,22,9,23,8,24,7,25
'!Raw DefData 6,1,5,2,4,3,26,4,3,5,2,6,1,7,25,8
'!Raw DefData 24,9,23,10,22,11,21,12,20,13,19,14,18,15,17,16
'!Raw DefData 17,26,16,18,15,19,14,20,13,21,12,22,11,23,10,24
'!Raw DefData 9,25,8,1,7,2,6,3,5,4,26,5,4,6,3,7
'!Raw DefData 2,8,1,9,25,10,24,11,23,12,22,13,21,14,20,15
'!Raw DefData 19,16,18,17,18,26,17,19,16,20,15,21,14,22,13,23
'!Raw DefData 12,24,11,25,10,1,9,2,8,3,7,4,6,5,26,6
'!Raw DefData 5,7,4,8,3,9,2,10,1,11,25,12,24,13,23,14
'!Raw DefData 22,15,21,16,20,17,19,18,19,26,18,20,17,21,16,22
'!Raw DefData 15,23,14,24,13,25,12,1,11,2,10,3,9,4,8,5
'!Raw DefData 7,6,26,7,6,8,5,9,4,10,3,11,2,12,1,13
'!Raw DefData 25,14,24,15,23,16,22,17,21,18,20,19,20,26,19,21
'!Raw DefData 18,22,17,23,16,24,15,25,14,1,13,2,12,3,11,4
'!Raw DefData 10,5,9,6,8,7,26,8,7,9,6,10,5,11,4,12
'!Raw DefData 3,13,2,14,1,15,25,16,24,17,23,18,22,19,21,20
'!Raw DefData 21,26,20,22,19,23,18,24,17,25,16,1,15,2,14,3
'!Raw DefData 13,4,12,5,11,6,10,7,9,8,26,9,8,10,7,11
'!Raw DefData 6,12,5,13,4,14,3,15,2,16,1,17,25,18,24,19
'!Raw DefData 23,20,22,21,22,26,21,23,20,24,19,25,18,1,17,2
'!Raw DefData 16,3,15,4,14,5,13,6,12,7,11,8,10,9,26,10
'!Raw DefData 9,11,8,12,7,13,6,14,5,15,4,16,3,17,2,18
'!Raw DefData 1,19,25,20,24,21,23,22,23,26,22,24,21,25,20,1
'!Raw DefData 19,2,18,3,17,4,16,5,15,6,14,7,13,8,12,9
'!Raw DefData 11,10,26,11,10,12,9,13,8,14,7,15,6,16,5,17
'!Raw DefData 4,18,3,19,2,20,1,21,25,22,24,23,24,26,23,25
'!Raw DefData 22,1,21,2,20,3,19,4,18,5,17,6,16,7,15,8
'!Raw DefData 14,9,13,10,12,11,26,12,11,13,10,14,9,15,8,16
'!Raw DefData 7,17,6,18,5,19,4,20,3,21,2,22,1,23,25,24
'!Raw DefData 25,26,24,1,23,2,22,3,21,4,20,5,19,6,18,7
'!Raw DefData 17,8,16,9,15,10,14,11,13,12,26,13,12,14,11,15
'!Raw DefData 10,16,9,17,8,18,7,19,6,20,5,21,4,22,3,23
'!Raw DefData 2,24,1,25,-1,-1
'!Raw #Table28
' 0x00C55E44   757 pairs
'!Raw DefData 1,28,2,27,3,26,4,25,5,24,6,23,7,22,8,21
'!Raw DefData 9,20,10,19,11,18,12,17,13,16,14,15,28,15,16,14
'!Raw DefData 17,13,18,12,19,11,20,10,21,9,22,8,23,7,24,6
'!Raw DefData 25,5,26,4,27,3,1,2,2,28,3,1,4,27,5,26
'!Raw DefData 6,25,7,24,8,23,9,22,10,21,11,20,12,19,13,18
'!Raw DefData 14,17,15,16,28,16,17,15,18,14,19,13,20,12,21,11
'!Raw DefData 22,10,23,9,24,8,25,7,26,6,27,5,1,4,2,3
'!Raw DefData 3,28,4,2,5,1,6,27,7,26,8,25,9,24,10,23
'!Raw DefData 11,22,12,21,13,20,14,19,15,18,16,17,28,17,18,16
'!Raw DefData 19,15,20,14,21,13,22,12,23,11,24,10,25,9,26,8
'!Raw DefData 27,7,1,6,2,5,3,4,4,28,5,3,6,2,7,1
'!Raw DefData 8,27,9,26,10,25,11,24,12,23,13,22,14,21,15,20
'!Raw DefData 16,19,17,18,28,18,19,17,20,16,21,15,22,14,23,13
'!Raw DefData 24,12,25,11,26,10,27,9,1,8,2,7,3,6,4,5
'!Raw DefData 5,28,6,4,7,3,8,2,9,1,10,27,11,26,12,25
'!Raw DefData 13,24,14,23,15,22,16,21,17,20,18,19,28,19,20,18
'!Raw DefData 21,17,22,16,23,15,24,14,25,13,26,12,27,11,1,10
'!Raw DefData 2,9,3,8,4,7,5,6,6,28,7,5,8,4,9,3
'!Raw DefData 10,2,11,1,12,27,13,26,14,25,15,24,16,23,17,22
'!Raw DefData 18,21,19,20,28,20,21,19,22,18,23,17,24,16,25,15
'!Raw DefData 26,14,27,13,1,12,2,11,3,10,4,9,5,8,6,7
'!Raw DefData 7,28,8,6,9,5,10,4,11,3,12,2,13,1,14,27
'!Raw DefData 15,26,16,25,17,24,18,23,19,22,20,21,28,21,22,20
'!Raw DefData 23,19,24,18,25,17,26,16,27,15,1,14,2,13,3,12
'!Raw DefData 4,11,5,10,6,9,7,8,8,28,9,7,10,6,11,5
'!Raw DefData 12,4,13,3,14,2,15,1,16,27,17,26,18,25,19,24
'!Raw DefData 20,23,21,22,28,22,23,21,24,20,25,19,26,18,27,17
'!Raw DefData 1,16,2,15,3,14,4,13,5,12,6,11,7,10,8,9
'!Raw DefData 9,28,10,8,11,7,12,6,13,5,14,4,15,3,16,2
'!Raw DefData 17,1,18,27,19,26,20,25,21,24,22,23,28,23,24,22
'!Raw DefData 25,21,26,20,27,19,1,18,2,17,3,16,4,15,5,14
'!Raw DefData 6,13,7,12,8,11,9,10,10,28,11,9,12,8,13,7
'!Raw DefData 14,6,15,5,16,4,17,3,18,2,19,1,20,27,21,26
'!Raw DefData 22,25,23,24,28,24,25,23,26,22,27,21,1,20,2,19
'!Raw DefData 3,18,4,17,5,16,6,15,7,14,8,13,9,12,10,11
'!Raw DefData 11,28,12,10,13,9,14,8,15,7,16,6,17,5,18,4
'!Raw DefData 19,3,20,2,21,1,22,27,23,26,24,25,28,25,26,24
'!Raw DefData 27,23,1,22,2,21,3,20,4,19,5,18,6,17,7,16
'!Raw DefData 8,15,9,14,10,13,11,12,12,28,13,11,14,10,15,9
'!Raw DefData 16,8,17,7,18,6,19,5,20,4,21,3,22,2,23,1
'!Raw DefData 24,27,25,26,28,26,27,25,1,24,2,23,3,22,4,21
'!Raw DefData 5,20,6,19,7,18,8,17,9,16,10,15,11,14,12,13
'!Raw DefData 13,28,14,12,15,11,16,10,17,9,18,8,19,7,20,6
'!Raw DefData 21,5,22,4,23,3,24,2,25,1,26,27,28,27,1,26
'!Raw DefData 2,25,3,24,4,23,5,22,6,21,7,20,8,19,9,18
'!Raw DefData 10,17,11,16,12,15,13,14,14,28,15,13,16,12,17,11
'!Raw DefData 18,10,19,9,20,8,21,7,22,6,23,5,24,4,25,3
'!Raw DefData 26,2,27,1,28,14,13,15,12,16,11,17,10,18,9,19
'!Raw DefData 8,20,7,21,6,22,5,23,4,24,3,25,2,26,1,27
'!Raw DefData 27,28,26,1,25,2,24,3,23,4,22,5,21,6,20,7
'!Raw DefData 19,8,18,9,17,10,16,11,15,12,14,13,28,13,12,14
'!Raw DefData 11,15,10,16,9,17,8,18,7,19,6,20,5,21,4,22
'!Raw DefData 3,23,2,24,1,25,27,26,26,28,25,27,24,1,23,2
'!Raw DefData 22,3,21,4,20,5,19,6,18,7,17,8,16,9,15,10
'!Raw DefData 14,11,13,12,28,12,11,13,10,14,9,15,8,16,7,17
'!Raw DefData 6,18,5,19,4,20,3,21,2,22,1,23,27,24,26,25
'!Raw DefData 25,28,24,26,23,27,22,1,21,2,20,3,19,4,18,5
'!Raw DefData 17,6,16,7,15,8,14,9,13,10,12,11,28,11,10,12
'!Raw DefData 9,13,8,14,7,15,6,16,5,17,4,18,3,19,2,20
'!Raw DefData 1,21,27,22,26,23,25,24,24,28,23,25,22,26,21,27
'!Raw DefData 20,1,19,2,18,3,17,4,16,5,15,6,14,7,13,8
'!Raw DefData 12,9,11,10,28,10,9,11,8,12,7,13,6,14,5,15
'!Raw DefData 4,16,3,17,2,18,1,19,27,20,26,21,25,22,24,23
'!Raw DefData 23,28,22,24,21,25,20,26,19,27,18,1,17,2,16,3
'!Raw DefData 15,4,14,5,13,6,12,7,11,8,10,9,28,9,8,10
'!Raw DefData 7,11,6,12,5,13,4,14,3,15,2,16,1,17,27,18
'!Raw DefData 26,19,25,20,24,21,23,22,22,28,21,23,20,24,19,25
'!Raw DefData 18,26,17,27,16,1,15,2,14,3,13,4,12,5,11,6
'!Raw DefData 10,7,9,8,28,8,7,9,6,10,5,11,4,12,3,13
'!Raw DefData 2,14,1,15,27,16,26,17,25,18,24,19,23,20,22,21
'!Raw DefData 21,28,20,22,19,23,18,24,17,25,16,26,15,27,14,1
'!Raw DefData 13,2,12,3,11,4,10,5,9,6,8,7,28,7,6,8
'!Raw DefData 5,9,4,10,3,11,2,12,1,13,27,14,26,15,25,16
'!Raw DefData 24,17,23,18,22,19,21,20,20,28,19,21,18,22,17,23
'!Raw DefData 16,24,15,25,14,26,13,27,12,1,11,2,10,3,9,4
'!Raw DefData 8,5,7,6,28,6,5,7,4,8,3,9,2,10,1,11
'!Raw DefData 27,12,26,13,25,14,24,15,23,16,22,17,21,18,20,19
'!Raw DefData 19,28,18,20,17,21,16,22,15,23,14,24,13,25,12,26
'!Raw DefData 11,27,10,1,9,2,8,3,7,4,6,5,28,5,4,6
'!Raw DefData 3,7,2,8,1,9,27,10,26,11,25,12,24,13,23,14
'!Raw DefData 22,15,21,16,20,17,19,18,18,28,17,19,16,20,15,21
'!Raw DefData 14,22,13,23,12,24,11,25,10,26,9,27,8,1,7,2
'!Raw DefData 6,3,5,4,28,4,3,5,2,6,1,7,27,8,26,9
'!Raw DefData 25,10,24,11,23,12,22,13,21,14,20,15,19,16,18,17
'!Raw DefData 17,28,16,18,15,19,14,20,13,21,12,22,11,23,10,24
'!Raw DefData 9,25,8,26,7,27,6,1,5,2,4,3,28,3,2,4
'!Raw DefData 1,5,27,6,26,7,25,8,24,9,23,10,22,11,21,12
'!Raw DefData 20,13,19,14,18,15,17,16,16,28,15,17,14,18,13,19
'!Raw DefData 12,20,11,21,10,22,9,23,8,24,7,25,6,26,5,27
'!Raw DefData 4,1,3,2,28,2,1,3,27,4,26,5,25,6,24,7
'!Raw DefData 23,8,22,9,21,10,20,11,19,12,18,13,17,14,16,15
'!Raw DefData 15,28,14,16,13,17,12,18,11,19,10,20,9,21,8,22
'!Raw DefData 7,23,6,24,5,25,4,26,3,27,2,1,28,1,27,2
'!Raw DefData 26,3,25,4,24,5,23,6,22,7,21,8,20,9,19,10
'!Raw DefData 18,11,17,12,16,13,15,14,-1,-1
'!Raw #KOTable2
' 0x00C58D94   1 pairs
'!Raw DefData 1,2
'!Raw #KOTable4
' 0x00C58DA4   2 pairs
'!Raw DefData 1,4,2,3
'!Raw #KOTable8
' 0x00C58DC4   4 pairs
'!Raw DefData 1,4,5,8,2,3,6,7
'!Raw #KOTable16
' 0x00C58E04   8 pairs
'!Raw DefData 1,4,5,8,9,12,13,16,2,3,6,7,10,11,14,15
'!Raw #KOTable32
' 0x00C58E84   16 pairs
'!Raw DefData 1,4,5,8,9,12,13,16,17,20,21,24,25,28,29,32
'!Raw DefData 2,3,6,7,10,11,14,15,18,19,22,23,26,27,30,31
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

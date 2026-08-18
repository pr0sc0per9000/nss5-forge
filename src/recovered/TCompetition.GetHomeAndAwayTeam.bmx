' TCompetition.GetHomeAndAwayTeam
' VA 0x0050BDB6   323 bytes   KIND=Function (static, on TCompetition), class-table slot 0x70.
' byte-identical vs NSS5.exe (323/323, original length from Ghidra's inventory, mode=reloc).
' NSS5_NO_LEARN=1 for the verification below.
' SIG=(*i,*i,i,i)i expands to
' `Function GetHomeAndAwayTeam:Int(a0:Int Ptr, a1:Int Ptr, a2:Int, a3:Int)`
' (a0=home OUT, a1=away OUT, a2=numteams, a3=round-offset).
'
' Pulls the next (home, away) pair from the fixture-pairing table
' `CreateFixtureListLeague` (0x0050B420, not yet reconstructed) reads while building a
' round-robin schedule -- see docs/game/career/season-structure.md. If either read comes
' back -1 (the shared cursor `g_competition_int01` ran off the end of the current table),
' it re-selects the table for this team count via `SelectFixtureTable(a2, 0)`
' (src/recovered_module/SelectFixtureTable.bmx) and reads again. Both results are then
' normalised into `[1, numteams]` by adding the round offset and wrapping down by numteams
' if that pushed either value too high.
'
' Neither of the two module-level addresses this body calls needs reconstructing as a
' standalone Function. 0x004C5280 is `SelectFixtureTable`, already recovered.
' 0x004A6860 is `bbConvertToInt`, the C-runtime function `ReadData` compiles down
' to automatically -- writing `ReadData a0[0]` makes bcc emit the identical call itself, no
' Function declaration needed. Full two-source proof for that identification (bcc's own
' `ReadStm::eval` in stm.cpp plus the `bbConvertToInt` C source in blitz_types.c) is in
' `src/recovered/TCompetition.CreateFixtureListKO.bmx`'s header, which shares this exact
' call; that same proof is recorded as
' `0x004a6860 = _bbConvertToInt` in extracted/runtime_helpers.tsv.
'
' One real logic fix along the way: the two final range checks are `If home > numteams Then
' home -= numteams` with HOME on the left of the comparison, not `If numteams < home` as
' Ghidra's decompile prints it (codegen-patterns.md 10.1 -- Ghidra normalises comparison
' operand order; the raw `cmp [home],[numteams]` with a `jle`-skip settles it). Writing the
' operands in the decompile's order cost 8 bytes at the tail of the function.
'
' Body-only format: statements only, parameters are a0, a1, a2, a3 (a0/a1 are `Int Ptr`).
ReadData a0[0]
ReadData a1[0]
If a0[0] = -1 Or a1[0] = -1
	SelectFixtureTable(a2, 0)
	ReadData a0[0]
	ReadData a1[0]
EndIf
If a0[0] > 0 Then a0[0] :+ a3
If a1[0] > 0 Then a1[0] :+ a3
If a0[0] > a2 Then a0[0] :- a2
If a1[0] > a2 Then a1[0] :- a2
Return 0

' TProfile.GetStats
' VA 0x00569912   287 bytes   mode=reloc
' MATCH over the full Ghidra-authoritative length (287/287), every byte, reloc_masked=4.
' Body-only format: statements only, parameters are a0, a1, ...
' SIG (i,i,i):TList  -- a0 = stat level, a1 = team id filter (0 = any), a2 = year filter (0 = any)
' Assumptions:
'   * Self.careerstats (TProfile +0x40) is a TList of TStats_Team; the loop's downcast
'     class table is ClassTable_TStats_Team, confirmed in the annotated decompilation.
'   * 0x005B40BF taken as CreateList from the alias set CreateList|CreateMap|TGNetHost.Create;
'     confirmed by the following TList.AddLast at slot 0x44 (guide 10.8).
'   * TStats_Team fields from object_model.json: statlevel +0x08, teamid +0x0C, year +0x10.
'   * No module Globals used.
' Shape notes (each measured, not assumed):
'   * The dispatch is a Select, not If/Else: the original evaluates the subject once
'     (mov eax,edi) and the Default block ends in a degenerate `EB 00`. If/Else form is
'     283 bytes; Select is 287.
'   * Each filter term is `(x = 0 Or field = x)`, not `x <> 0 And field = x` -- the
'     original bails out of the term with eax=1 (sete/jne), which is an Or, not an And.
Local l:TList = CreateList()
For Local s:TStats_Team = EachIn Self.careerstats
	Select a0
		Case 4
			If s.statlevel = a0 And (a2 = 0 Or s.year = a2) Then l.AddLast(s)
		Default
			If s.statlevel = a0 And (a1 = 0 Or s.teamid = a1) And (a2 = 0 Or s.year = a2) Then l.AddLast(s)
	End Select
Next
Return l

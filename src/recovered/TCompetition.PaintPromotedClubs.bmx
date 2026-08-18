' TCompetition.PaintPromotedClubs
' VA 0x0050DBAF   414 bytes   vtable slot 0xF0   sig (:TTable)i   KIND=Method
' byte-identical vs NSS5.exe (414/414, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=8)
' Work-set class was BLOCKED; nothing about it actually was.
'
' ASSUMPTIONS
'  No module Globals are needed.
'  a0 = the :TTable parameter.  Self = TCompetition.
'  Fields (object_model.json):
'    TCompetition +0x08 id, +0x18 locale, +0x1C level, +0x24 comptype, +0x6C teampool([]:TTeamPool)
'    TTeamPool    +0x08 list(:TList)
'    TTableData   +0x0C teamid
'    TClub        +0x68 leagueid
'  Slots resolved:
'    TTable       0xA8 = SetRowColoursAll($),  0xAC = SetRowColour(i,$)
'    TCompetition 0xD0 = AllFixturesPlayed()
'    TTeamPool    0x5C = SortTableBy(i)
'    TList        0x70 = Count(),  0x8C = ObjectEnumerator()
'    [0x00C59E0C] = TClub class table + 0x60 = TClub.SelectById(i):TClub
'                   -> a DIFFERENT Type, so the `TClub.` prefix is required here
'    0x00C64B80 = TTableData class table -> the inner EachIn loop variable is :TTableData
'  Literals: 0x00C5D680 "FFFFFF", 0x00C7D30C "6666FF", 0x00C725EC "FF0000".
'  SHAPE
'    * The head condition is ONE If-block enclosing both loops (`je` to the epilogue's
'      `mov eax,0`), not an early return.
'    * The outer `For EachIn Self.teampool` is over an ARRAY: the end pointer is computed
'      from [+0x10] (size), and the `cmp [ebp-4],bbNullObject / je` is EachIn's own
'      built-in null skip -- no explicit Null test in source (codegen-patterns 10.6).
'    * `cmp esi,eax / jge` at 0x0050DCEC fixes the operand order as `pos < <count>/2`,
'      with the parameter on the LEFT (codegen-patterns 10.1).
'    * `tp.list` is re-read inside the body (0x0050DCD5) rather than reused from ebx --
'      bcc does no CSE, so the source spells it out twice.
	Method PaintPromotedClubs:Int(a0:TTable)
		a0.SetRowColoursAll("FFFFFF")
		If Self.level = 0 And Self.locale = 0 And (Self.comptype = 0 Or Self.comptype = 4) And Self.AllFixturesPlayed()
			For Local tp:TTeamPool = EachIn Self.teampool
				tp.SortTableBy(4)
				Local pos:Int = 1
				For Local td:TTableData = EachIn tp.list
					If TClub.SelectById(td.teamid).leagueid <> Self.id
						If pos < tp.list.Count() / 2
							a0.SetRowColour(pos, "6666FF")
						Else
							a0.SetRowColour(pos, "FF0000")
						EndIf
					EndIf
					pos = pos + 1
				Next
			Next
		EndIf
	End Method

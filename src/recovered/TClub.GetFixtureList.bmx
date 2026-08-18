' TClub.GetFixtureList
' VA 0x004C18FB   679 bytes   mode=reloc   byte-identical vs NSS5.exe (679/679)
' KIND=Method, SIG (i,i):TList, slot 0x30
' The twin of TNation.GetFixtureList (0x004BF840, 625 bytes): identical body except that
' this one has no opening LogLine, tests `c.level = 0` rather than 1, and adds a second
' guard on the competition's base nation.
' ASSUMPTIONS
'   0x00C6099C -> g_competitions:TList   0x00C59E44 -> g_nation_sortmode:Int (stores 17)
'   0x005B40BF resolved to CreateList (following AddLast at slot 0x44, 10.8).
'   0x00C6632C = TMyDate+0x30 Create(i,i,i):TMyDate; TMyDate slot 0x54 = GetYear()i.
'   Slot 0x88 on the TList = TList.Sort, written `l.Sort()`; bcc materialises both defaults.
'   Field offsets: TCompetition level +0x1C, locale +0x18, based +0x20, teampool +0x6C,
'     lfixturelist +0x60; TTeamPool.list +0x08; TTableData teamid +0x0C, id +0x08;
'     TFixture sdate +0x08, groupno +0x14, hometeam +0x1C, awayteam +0x20;
'     TClub.nationid +0x64, TClub(TBase_Team).id +0x0C.
'   The second guard is `(c.locale = 0 And c.based = Self.nationid) Or c.locale = 1` -- it is
'   a SEPARATE If nested inside the first, not another And on it.
'!Global g_competitions:TList
'!Global g_nation_sortmode:Int
Local l:TList = CreateList()
For Local c:TCompetition = EachIn g_competitions
	If c.level = 0 And (a0 = -1 Or c.locale = a0)
		If (c.locale = 0 And c.based = Self.nationid) Or c.locale = 1
			Local grp:Int = 1
			For Local tp:TTeamPool = EachIn c.teampool
				For Local td:TTableData = EachIn tp.list
					If td.teamid = Self.id
						For Local f:TFixture = EachIn c.lfixturelist
							If a1 = 0 Or TMyDate.Create(f.sdate, 1, 1).GetYear() = a1
								If f.groupno = grp And (f.hometeam = td.id Or f.awayteam = td.id)
									l.AddLast(f)
								EndIf
							EndIf
						Next
					EndIf
				Next
				grp = grp + 1
			Next
		EndIf
	EndIf
Next
g_nation_sortmode = 17
l.Sort()
Return l

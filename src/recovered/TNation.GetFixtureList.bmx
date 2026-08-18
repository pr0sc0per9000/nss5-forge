' TNation.GetFixtureList
' VA 0x004BF840   625 bytes   mode=reloc   byte-identical vs NSS5.exe (625/625)
' KIND=Method, SIG (i,i):TList, slot 0x30
' ASSUMPTIONS
'   0x00C6099C -> g_competitions:TList  (slot 0x8C ObjectEnumerator; same address other
'     recovered bodies already declare TList)
'   0x00C59E44 -> g_nation_sortmode:Int (bare dword store of 17, no refcount traffic -> Int)
'   0x005B40BF resolved to CreateList (the following AddLast at slot 0x44 confirms, 10.8).
'   0x00C6632C = TMyDate+0x30 Create(i,i,i):TMyDate; slot 0x54 on TMyDate = GetYear()i.
'   Slot 0x88 on the TList = TList.Sort -- written `l.Sort()`; bcc materialises both
'     defaults (ascending=1 and CompareObjects at 0x005B3516) at the call site.
'   Field offsets from object_model.json: TCompetition level +0x1C, locale +0x18,
'     teampool +0x6C, lfixturelist +0x60; TTeamPool.list +0x08; TTableData teamid +0x0C,
'     id +0x08; TFixture sdate +0x08, groupno +0x14, hometeam +0x1C, awayteam +0x20;
'     TNation(TBase_Team).id +0x0C.
'   Ghidra's bVar12 cascades are short-circuit Or inside an And -- three of them, and each
'   one is `X And (A Or B)`, not a nested If.
'   `grp` is incremented at the END of the teampool loop body; `For EachIn` supplies its own
'   null-skip so no explicit guard is written (10.6).
'!Global g_competitions:TList
'!Global g_nation_sortmode:Int
LogLine("GetFixtureList:Nation")
Local l:TList = CreateList()
For Local c:TCompetition = EachIn g_competitions
	If c.level = 1 And (a0 = -1 Or c.locale = a0)
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
Next
g_nation_sortmode = 17
l.Sort()
Return l

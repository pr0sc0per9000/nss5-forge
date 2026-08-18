' TTeamPool.SortTableBy
' VA 0x00526911   357 bytes
' byte-identical vs NSS5.exe (357/357, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_teampool_sortby:Int
If a0 = 5
	For Local d:TTableData = EachIn Self.list
		d.randno = Rand(9999, 1)
	Next
ElseIf a0 = 24
	For Local d:TTableData = EachIn Self.list
		d.longlat = TClub.SelectById(d.teamid).stadiumlatitude
	Next
ElseIf a0 = 25
	For Local d:TTableData = EachIn Self.list
		d.longlat = TClub.SelectById(d.teamid).stadiumlongitude
	Next
End If
g_teampool_sortby = a0
Self.list.Sort(1)

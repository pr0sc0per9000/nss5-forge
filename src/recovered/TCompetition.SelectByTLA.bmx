' TCompetition.SelectByTLA
' VA 0x0050a705   118 bytes   vtable slot 0x50   sig ($):TCompetition
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6099c declared :TList. FUN_004a6a30 = _bbStringCompare
' (runtime_helpers.tsv), i.e. the `tla = a0` String comparison at field +0x10.
	Function SelectByTLA:TCompetition(a0:String)
		'!Global g_competitions:TList
		For Local c:TCompetition = EachIn g_competitions
			If c.tla = a0 Then Return c
		Next
		Return Null
	End Function

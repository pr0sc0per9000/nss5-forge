' TClub.SelectListByLeagueId
' VA 0x004C16FA   116 bytes   vtable slot 0x6c   sig (i):TList
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' assumption: module Global at 0x00C59A44 declared :TList (the all-clubs list);
' 0x005B40BF = _brl_linkedlist_CreateList (inferred name, brl_functions_inferred.tsv)
	Function SelectListByLeagueId:TList(a0:Int)
		'!Global g_clubs:TList
		Local l:TList = CreateList()
		For Local c:TClub = EachIn g_clubs
			If c.leagueid = a0 Then l.AddLast(c)
		Next
		Return l
	End Function

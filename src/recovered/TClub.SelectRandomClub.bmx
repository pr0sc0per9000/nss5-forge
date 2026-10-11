' TClub.SelectRandomClub
' VA 0x004c14d2   236 bytes   vtable slot 0x64   sig (i):TClub
' byte-identical vs NSS5.exe (236/236, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C59A44 declared TList (the club list); Global 0x00C59A48 is the
'   Int sort-mode flag TBase_Team.Compare reads.  FUN_005B3516 is
'   _brl_linkedlist_CompareObjects, i.e. TList.Sort's DEFAULT comparator, so the source
'   is a plain Sort(1) with no second argument.
'   The parameter is matched against leagueid (+0x68), NOT nationid (+0x64).
' NAME CHANGED 2026-10-11 (byte-neutral): 0x004C1535 `c705489ac50005000000 mov [0xc59a48],5`
' sets the club sort mode TClub.Compare reads at 0x004C2587 (g_club_sortmode; case 5 sorts
' by randno). g_sortmode is the fixture sort mode, 0x00C59E44.
	Function SelectRandomClub:TClub(a0:Int)
		'!Global g_clubs:TList
		'!Global g_club_sortmode:Int
		For Local c:TClub = EachIn g_clubs
			c.randno = Rand(9999,1)
		Next
		g_club_sortmode = 5
		g_clubs.Sort(1)
		For Local c:TClub = EachIn g_clubs
			If c.leagueid = a0 Then Return c
		Next
		LogLine("No club found!")
		Return Null
	End Function

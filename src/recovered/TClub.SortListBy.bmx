' TClub.SortListBy
' VA 0x004C24E1   151 bytes   vtable slot 0x94   sig (i,i)i
' byte-identical vs NSS5.exe (151/151, original length from Ghidra's inventory)
' Assumptions: module Globals 0x00c59a44 = g_clubs:TList and 0x00c59a48 = g_club_sortby:Int.
' BRL calls relied on: 0x0059F089 = _brl_random_Rand (Rand), 0x005B3516 =
' _brl_linkedlist_CompareObjects (the default comparator TList.Sort passes).
	Function SortListBy(a0:Int, a1:Int)
		'!Global g_clubs:TList
		'!Global g_club_sortby:Int
		g_club_sortby = a0
		If a0 = 5
			For Local c:TClub = EachIn g_clubs
				c.randno = Rand(9999)
			Next
		EndIf
		g_clubs.Sort(a1)
	End Function

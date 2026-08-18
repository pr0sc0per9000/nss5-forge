' TStats_Team.Create
' VA 0x0056eaf2   46 bytes   vtable slot 0x30   sig (i,i,i):TStats_Team
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)

	Function Create:TStats_Team(a0:Int, a1:Int, a2:Int)
		Local s:TStats_Team = New TStats_Team
		s.statlevel = a0
		s.teamid = a1
		s.year = a2
		Return s
	End Function

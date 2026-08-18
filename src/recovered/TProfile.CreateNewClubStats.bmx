' TProfile.CreateNewClubStats
' VA 0x005662af   171 bytes   vtable slot 0x4c   sig (i)i
' byte-identical vs NSS5.exe (171/171, original length from Ghidra's inventory, mode=reloc)
' Assumptions: PTR_FUN_00C6AC3C resolves to TStats_Team class table + 0x30 =
' TStats_Team.Create(i,i,i):TStats_Team. Self.date is :TMyDate so GetYear is slot 0x54;
' Self.careerstats is :TList so slot 0x44 is AddLast. The year is a Local -- inlining
' four GetYear calls would not match.
	Method CreateNewClubStats:Int(a0:Int)
		Local y:Int = Self.date.GetYear()
		Self.careerstats.AddLast(TStats_Team.Create(0,a0,y))
		Self.careerstats.AddLast(TStats_Team.Create(1,a0,y))
		Self.careerstats.AddLast(TStats_Team.Create(2,a0,y))
		Self.careerstats.AddLast(TStats_Team.Create(3,a0,y))
	End Method

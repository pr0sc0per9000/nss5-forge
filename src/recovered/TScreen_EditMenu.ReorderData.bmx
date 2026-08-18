' TScreen_EditMenu.ReorderData
' VA 0x0052826B   32 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' class-table slots: 0x00c59a34=TNation+0x6c, 0x00c59e34=TClub+0x88, 0x00c616c8=TCompetition+0x108
	Function ReorderData:Int()
		TNation.ReorderNations()
		TClub.ReorderClubs()
		TCompetition.ReorderCompetitions()
	End Function

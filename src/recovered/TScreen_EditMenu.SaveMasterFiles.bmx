' TScreen_EditMenu.SaveMasterFiles
' VA 0x005282eb   79 bytes   vtable slot 0x54   sig (i)i
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory)
' Each PTR_FUN resolves to a <Type> + slot = SaveMaster(i,i)i in class_tables.tsv:
' 0x00C60994 TContinent+0x3c, 0x00C59A1C TNation+0x54, 0x00C59E08 TClub+0x5c,
' 0x00C61608 TCompetition+0x48, 0x00C64794 TPromotionPlace+0x40.
	Function SaveMasterFiles:Int(a0:Int)
		TContinent.SaveMaster(0,a0)
		TNation.SaveMaster(0,a0)
		TClub.SaveMaster(0,a0)
		TCompetition.SaveMaster(0,a0)
		TPromotionPlace.SaveMaster(0,a0)
	End Function

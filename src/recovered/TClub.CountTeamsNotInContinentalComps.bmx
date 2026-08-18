' TClub.CountTeamsNotInContinentalComps
' VA 0x004c18d1   42 bytes   vtable slot 0x7c   sig (i)i
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory)
' callees are TClub slots 0x74 / 0x78

	Function CountTeamsNotInContinentalComps:Int(a0:Int)
		Return CountTeamsInDivision(a0) - CountTeamsInContinentalComps(a0)
	End Function

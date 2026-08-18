' TProfile.CreateNewInternationalStats
' VA 0x0056635A   61 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (61/61, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.

	Method CreateNewInternationalStats:Int()
		careerstats.AddLast(TStats_Team.Create(4, nationid, date.GetYear()))
	End Method

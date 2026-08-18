' PropertyName  -- module-level Function (no Type)
' VA 0x005075eb   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Maps a 1..10 property index to its localised display name. The ten keys are
' read out of NSS5.exe as BlitzMax string objects at the pushed addresses, not guessed.
' The callee is the already-verified module Function GetText (0x004C5549), so its E8
' masks by name on both sides.
'
' The trailing Return "" is a real statement, not the implicit end-of-function return:
' the default arm loads the shared empty-string object at 0x005C7D40 and the Select has
' no Default of its own. One of three 237-byte siblings sharing this exact shape
' (0x005075EB / 0x005077C5 / 0x0050799F); a fourth, 0x00508131, does NOT share it.
	Function PropertyName:String(a0:Int)
		Select a0
			Case 1
				Return GetText("property_Apartment")
			Case 2
				Return GetText("property_House")
			Case 3
				Return GetText("property_TownHouse")
			Case 4
				Return GetText("property_Cottage")
			Case 5
				Return GetText("property_Stable")
			Case 6
				Return GetText("property_HolidayVilla")
			Case 7
				Return GetText("property_SkiChalet")
			Case 8
				Return GetText("property_Mansion")
			Case 9
				Return GetText("property_Castle")
			Case 10
				Return GetText("property_PrivateIsland")
		End Select
		Return ""
	End Function

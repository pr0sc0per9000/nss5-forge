' PropertyTooltip  -- module-level Function (no Type)
' VA 0x005076d8   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=21)
'
' NAME IS OURS. Maps a 1..10 property index to its tooltip text, shown on the property
' shop's "buy" button. The ten keys are read out of NSS5.exe as BlitzMax string objects at
' the pushed addresses, not guessed. The callee is the already-verified module Function
' GetText (0x004C5549), so its E8 masks by name on both sides.
'
' NOTE the index-5 key is "tt_Stable", not "property_Stable" like PropertyName's sibling --
' reproduced as found, not tidied (guide 16.8).
'
' The trailing Return "" is a real statement, not the implicit end-of-function return: the
' default arm loads the shared empty-string object at 0x005C7D40 and the Select has no
' Default of its own. Discovered as a sibling of PropertyName/VehicleName/ItemName's
' 237-byte shape (guide 12.2 families), called once each from TScreen_Shop.CreateScreen.
	Function PropertyTooltip:String(a0:Int)
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
				Return GetText("tt_Stable")
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

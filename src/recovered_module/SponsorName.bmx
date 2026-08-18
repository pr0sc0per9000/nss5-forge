' SponsorName  -- module-level Function (no Type)
' VA 0x00508131   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Maps a 1..10 sponsor index to its localised display name. The ten keys are
' read out of NSS5.exe as BlitzMax string objects at the pushed addresses, not guessed.
' The callee is the already-verified module Function GetText (0x004C5549).
'
' SAME SIZE AS ITS THREE SIBLINGS BUT NOT THE SAME SHAPE. PropertyName / VehicleName /
' ItemName (0x005075EB / 0x005077C5 / 0x0050799F) are `Select ... End Select` followed by
' a separate `Return ""`, and the parameter stays in eax. This one loads the empty-string
' object at 0x005C7D40 into eax BEFORE the compare chain and keeps the parameter in edx --
' i.e. a String Local initialised to "" that each arm assigns and a single Return at the
' end. Writing it in the siblings' form is a genuine MISMATCH (31/237, first diff at 4),
' which is the negative control for the distinction.
	Function SponsorName:String(a0:Int)
		Local s:String = ""
		Select a0
			Case 1
				s = GetText("sponsor_Boots")
			Case 2
				s = GetText("sponsor_SportsDrink")
			Case 3
				s = GetText("sponsor_SportsClothing")
			Case 4
				s = GetText("sponsor_CasualClothing")
			Case 5
				s = GetText("sponsor_Food")
			Case 6
				s = GetText("sponsor_Cosmetics")
			Case 7
				s = GetText("sponsor_Watch")
			Case 8
				s = GetText("sponsor_Electronics")
			Case 9
				s = GetText("sponsor_Jewelry")
			Case 10
				s = GetText("sponsor_Car")
		End Select
		Return s
	End Function

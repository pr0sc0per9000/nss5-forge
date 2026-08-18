' VehicleName  -- module-level Function (no Type)
' VA 0x005077c5   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Maps a 1..10 vehicle index to its localised display name. The ten keys are
' read out of NSS5.exe as BlitzMax string objects at the pushed addresses, not guessed.
' The callee is the already-verified module Function GetText (0x004C5549), so its E8
' masks by name on both sides.
'
' The trailing Return "" is a real statement, not the implicit end-of-function return:
' the default arm loads the shared empty-string object at 0x005C7D40 and the Select has
' no Default of its own. One of three 237-byte siblings sharing this exact shape
' (0x005075EB / 0x005077C5 / 0x0050799F); a fourth, 0x00508131, does NOT share it.
	Function VehicleName:String(a0:Int)
		Select a0
			Case 1
				Return GetText("vehicle_Bicycle")
			Case 2
				Return GetText("vehicle_Scooter")
			Case 3
				Return GetText("vehicle_SmallCar")
			Case 4
				Return GetText("vehicle_Motorbike")
			Case 5
				Return GetText("vehicle_SUV")
			Case 6
				Return GetText("vehicle_SailingBoat")
			Case 7
				Return GetText("vehicle_SportsCar")
			Case 8
				Return GetText("vehicle_Helicopter")
			Case 9
				Return GetText("vehicle_Yacht")
			Case 10
				Return GetText("vehicle_PrivateJet")
		End Select
		Return ""
	End Function

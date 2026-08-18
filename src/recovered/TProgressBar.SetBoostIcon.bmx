' TProgressBar.SetBoostIcon
' VA 0x0051ac3d   66 bytes   vtable slot 0x94   sig (:TImage,i)i
' byte-identical vs NSS5.exe (66/66, original length from Ghidra's inventory)

	Method SetBoostIcon:Int(a0:TImage, a1:Int)
		boosticon = a0
		numboost = a1
	End Method

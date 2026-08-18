' TGadget.SetColour
' VA 0x00514ae1   130 bytes   vtable slot 0x6c   sig ($,$)i
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory)
' string constants read out of the .data bbString blobs.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method SetColour:Int(a0:String, a1:String)
		colour = a0
		If colour = "000000" Then colour = "444444"
		txtcolour = a1
	End Method

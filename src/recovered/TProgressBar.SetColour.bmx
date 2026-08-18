' TProgressBar.SetColour
' VA 0x0051ab2a   119 bytes   vtable slot 0x6c   sig ($,$)i
' byte-identical vs NSS5.exe (119/119, original length from Ghidra's inventory)
' "colour" is the inherited TGadget field at +0x30; "fillcolour" is TProgressBar +0x68.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method SetColour:Int(a0:String, a1:String)
		If a0 <> "" Then colour = a0
		If a1 <> "" Then fillcolour = a1
	End Method

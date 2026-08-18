' TCombo.SetColour
' VA 0x00519372   108 bytes   vtable slot 0x6c   sig ($,$)i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' colour/txtcolour are the inherited TGadget fields at 0x30 / 0x34
	Method SetColour:Int(a0:String, a1:String)
		colour = a0
		btn_head.colour = a0
		txtcolour = a1
	End Method

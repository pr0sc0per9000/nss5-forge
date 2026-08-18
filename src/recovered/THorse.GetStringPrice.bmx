' THorse.GetStringPrice
' VA 0x0058ab0c   37 bytes   vtable slot 0x48   sig ()$
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' the literal's text does not affect code bytes; number is the LEFT operand of the concat

	Method GetStringPrice:String()
		Return betprice + "/1"
	End Method

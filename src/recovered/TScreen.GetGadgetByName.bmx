' TScreen.GetGadgetByName
' VA 0x0051265C   126 bytes   vtable slot 0x90   sig ($):TGadget
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' Slot 0x50 on Self is TScreen.GetGadgetList; FUN_004a6a30 is the string-compare runtime helper.

	Method GetGadgetByName:TGadget(a0:String)
		For Local g:TGadget = EachIn GetGadgetList()
			If g.name = a0 Then Return g
		Next
		Return Null
	End Method

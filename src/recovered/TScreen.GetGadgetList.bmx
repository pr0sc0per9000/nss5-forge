' TScreen.GetGadgetList
' VA 0x00510738   217 bytes   vtable slot 0x50   sig ():TList
' byte-identical vs NSS5.exe (217/217, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' FUN_005b40bf = _brl_linkedlist_CreateList; slot 0x78 on TGadget is GetChildren.

	Method GetGadgetList:TList()
		Local l:TList = CreateList()
		For Local g:TGadget = EachIn gadgetlist
			l.AddLast(g)
			For Local c:TGadget = EachIn g.GetChildren()
				l.AddLast(c)
			Next
		Next
		Return l
	End Method

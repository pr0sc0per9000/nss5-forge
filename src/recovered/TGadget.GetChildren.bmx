' TGadget.GetChildren
' VA 0x00514b84   217 bytes   vtable slot 0x78   sig ():TList
' byte-identical vs NSS5.exe (217/217, original length from Ghidra's inventory)
' No assumptions beyond CreateList() (0x005B40BF, brl_functions_inferred.tsv) --
' 'New TList' would be 8 bytes longer.
	Method GetChildren:TList()
		Local l:TList = CreateList()
		For Local g:TGadget = EachIn children
			l.AddLast(g)
			For Local c:TGadget = EachIn g.GetChildren()
				l.AddLast(c)
			Next
		Next
		Return l
	End Method

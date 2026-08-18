' TGadget.Show
' VA 0x00514067   106 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (106/106, original length from Ghidra's inventory)
' Slot 0x78 on Self is TGadget.GetChildren():TList; the EachIn downcast class table
' 0x00c62150 is TGadget's own.
	Method Show:Int()
		hidden = 0
		For Local g:TGadget = EachIn GetChildren()
			g.hidden = 0
		Next
	End Method

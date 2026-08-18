' TGadget.Hide
' VA 0x00513ffd   106 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (106/106, original length from Ghidra's inventory)
' Field [0xf] = +0x3c = hidden. Slot 0x78 = TGadget.GetChildren():TList;
' downcast class table 0x00C62150 is TGadget + 0x00.
	Method Hide:Int()
		hidden = 1
		For Local g:TGadget = EachIn GetChildren()
			g.hidden = 1
		Next
	End Method

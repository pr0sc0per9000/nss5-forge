' TScreen.RemoveGadget
' VA 0x005106E1   87 bytes   vtable slot 0x4c   sig (:TGadget)i
' byte-identical vs NSS5.exe (87/87, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C61CF8 declared :TGadget.
' FindNewActiveGadget() must be called UNQUALIFIED: from inside a Method bcc dispatches the Type's own Function through Self's class table (call [eax+0x64]). Writing TScreen.FindNewActiveGadget() emits a direct call and is 1 byte longer.
' harness mode=reloc.

	Method RemoveGadget:Int(a0:TGadget)
		'!Global g_activegadget:TGadget
		If g_activegadget = a0 Then g_activegadget = Null
		gadgetlist.Remove(a0)
		FindNewActiveGadget()
	End Method

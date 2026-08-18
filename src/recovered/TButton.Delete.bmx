' TButton.Delete
' VA 0x00514F98   68 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (68/68, original length from Ghidra's inventory)
' Body is empty; bcc releases the two :TImage fields (icon @0x68, image @0x60) in reverse order, then chains to TGadget.Delete.
' harness mode=reloc.

	Method Delete:Int()
		' empty -- compiler-generated field release (icon, image) then the TGadget.Delete chain
	End Method

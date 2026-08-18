' TInputBox.Delete
' VA 0x00515610   51 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' Empty body. The 51 bytes are bcc's implicit destructor: release of Field image:TImage
' followed by the chain into TGadget.Delete (TInputBox Extends TGadget).
	Method Delete()

	End Method

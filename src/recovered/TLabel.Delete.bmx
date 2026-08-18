' TLabel.Delete
' VA 0x00519817   85 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (85/85, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' The user body is EMPTY. All 85 bytes are bcc's generated Delete epilogue: release the three
' object fields (icon +104, imgborder +96, image +92) in reverse order, then chain to TGadget.Delete.

	Method Delete:Int()
		' (empty -- the whole body is compiler-generated: release icon/imgborder/image, then Super.Delete)
	End Method

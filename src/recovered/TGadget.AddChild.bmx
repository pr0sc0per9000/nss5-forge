' TGadget.AddChild
' VA 0x00514B63   33 bytes   vtable slot 0x74   sig (:TGadget)i
' byte-identical vs NSS5.exe (33/33, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method AddChild:Int(a0:TGadget)
		children.AddLast(a0)
	End Method

' TGadget.UpdateChildren
' VA 0x00513828   106 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (106/106, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' The early-return form is load-bearing: the nested-If form is 99 bytes, 7 short, because
' the original materialises its own 'mov eax,0; jmp epilogue' for the guard.

	Method UpdateChildren:Int()
		If Not alive Then Return 0
		For Local g:TGadget = EachIn children
			g.Update()
		Next
	End Method

' TMyVector.GetX
' VA 0x004E26D7   15 bytes   vtable slot 0x70   sig ()d
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method GetX:Double()
		Return X
	End Method

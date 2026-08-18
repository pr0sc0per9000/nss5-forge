' TMyVector.GetZ
' VA 0x004E26F5   15 bytes   vtable slot 0x78   sig ()d
' byte-identical vs NSS5.exe
' harness mode=exact, 0 relocation slot(s) masked (absolute addresses differ by construction between probe and NSS5.exe)
' parameter names are the harness placeholders a0/a1/a2; parameter names do not affect codegen.

	Method GetZ:Double()
		Return Z
	End Method

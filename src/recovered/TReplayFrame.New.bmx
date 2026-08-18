' TReplayFrame.New
' VA 0x00504C0F   169 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (169/169, original length from Ghidra's inventory)
' EMPTY body. Every field default is zero except alph at +0x54, which the original
' initialises to 1.0 -- 'Field alph:Float = 1.0' in the Type declaration.
' Recovered via the '!Field harness pragma.
' harness mode=reloc: absolute addresses (class tables, bbNullObject, string and
' array constants) differ by construction between probe and NSS5.exe.
	Method New()
		'!Field alph = 1.0
	End Method

' TKitStrings.Copy
' VA 0x004DC4DA   164 bytes   vtable slot 0x34   sig (:TKitStrings)i
' byte-identical vs NSS5.exe (164/164, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method Copy:Int(a0:TKitStrings)
		style = a0.style
		shirt1 = a0.shirt1
		shirt2 = a0.shirt2
		shorts = a0.shorts
		socks = a0.socks
	End Method

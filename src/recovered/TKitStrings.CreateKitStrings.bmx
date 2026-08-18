' TKitStrings.CreateKitStrings
' VA 0x004DC432   168 bytes   vtable slot 0x30   sig ($,$,$,$,$):TKitStrings
' byte-identical vs NSS5.exe (168/168, original length from Ghidra's inventory)
' Argument order in the original assigns style from the LAST parameter; a0..a3 fill shirt1/shirt2/shorts/socks.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Function CreateKitStrings:TKitStrings(a0:String, a1:String, a2:String, a3:String, a4:String)
		Local k:TKitStrings = New TKitStrings
		k.style = a4
		k.shirt1 = a0
		k.shirt2 = a1
		k.shorts = a2
		k.socks = a3
		Return k
	End Function

' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_MainMenu.ButtonMobile
' VA 0x0051DA05   28 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Global assumed (name ours, type load-bearing): Global g_mobile_url:String

	Function ButtonMobile:Int()
		'!Global g_mobile_url:String
		OpenURL(g_mobile_url)
	End Function

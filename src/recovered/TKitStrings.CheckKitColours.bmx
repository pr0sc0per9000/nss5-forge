' TKitStrings.CheckKitColours
' VA 0x004DC57E   477 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (477/477, original length from Ghidra's inventory)
' helpers learned by the oracle on this function: 0x004A6BF0=_bbStringStartsWith,
' 0x004A7130=_bbStringToInt, 0x004A75B0=_bbStringReplace
' PREDICATE CORRECTED: .StartsWith -> .Contains. extracted/runtime_helpers.tsv named
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row corrected, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Method CheckKitColours:Int()
		If shirt1.Contains("#")
			shirt1 = shirt1.Replace("#", "")
		Else
			shirt1 = ConvertNSS4ColourIndexToHex(Int(shirt1))
		EndIf
		If shirt2.Contains("#")
			shirt2 = shirt2.Replace("#", "")
		Else
			shirt2 = ConvertNSS4ColourIndexToHex(Int(shirt2))
		EndIf
		If shorts.Contains("#")
			shorts = shorts.Replace("#", "")
		Else
			shorts = ConvertNSS4ColourIndexToHex(Int(shorts))
		EndIf
		If socks.Contains("#")
			socks = socks.Replace("#", "")
		Else
			socks = ConvertNSS4ColourIndexToHex(Int(socks))
		EndIf
	End Method

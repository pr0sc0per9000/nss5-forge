' TProfile.GetNewTip
' VA 0x0056900C   151 bytes   vtable slot 0x78   sig ()$
' byte-identical vs NSS5.exe (151/151, original length from Ghidra's inventory, mode=reloc)
' assumptions: FUN_004C5549 = recovered module Function GetText; runtime helpers per
' extracted/runtime_helpers.tsv -- 0x004A7AC0 _bbStringFromInt, 0x004A7C20 _bbStringConcat,
' 0x004A6BF0 _bbStringStartsWith. Locale keys are "CTIP_" + n; a missing key comes back
' starting with "@", which resets the counter. Field tipcount is +0x1C4.
' bcc does no CSE: the GetText("CTIP_" + tipcount) expression really is written twice.
' PREDICATE CORRECTED: .StartsWith -> .Contains. extracted/runtime_helpers.tsv named
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row corrected, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Method GetNewTip:String()
		tipcount = tipcount + 1
		If tipcount > 50
			tipcount = 1
		EndIf
		Local t:String = GetText("CTIP_" + tipcount)
		If t.Contains("@")
			tipcount = 1
			t = GetText("CTIP_" + tipcount)
		EndIf
		Return t
	End Method

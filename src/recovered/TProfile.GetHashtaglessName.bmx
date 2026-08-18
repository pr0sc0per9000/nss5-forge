' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TProfile.GetHashtaglessName
' VA 0x0056d2e4   52 bytes   vtable slot 0x15c   sig ()$
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory)
' 0x004a75b0 is bbStringReplace.

	Method GetHashtaglessName:String()
		Return name.Replace("@", "").Replace("#", "")
	End Method

' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTeamPool.WriteData
' VA 0x0052653D   133 bytes   vtable slot 0x34   sig (:TStream)i
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory)
' The two string literals have addresses masked by mode=reloc, so the byte match alone does not certify their text.
' WriteLine is _brl_stream_WriteLine at 0x005B8307.
' harness mode=reloc.

	Method WriteData:Int(a0:TStream)
		WriteLine(a0, "id~tteamid~tteamname~tteamstrength~tplayed~twon~tdrawn~tlost~tgoalsf~tgoalsa~tpoints")
		For Local t:TTableData = EachIn list
			t.WriteData(a0)
		Next
		WriteLine(a0, "//")
	End Method

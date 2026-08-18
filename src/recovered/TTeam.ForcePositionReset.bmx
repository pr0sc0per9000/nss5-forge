' TTeam.ForcePositionReset
' VA 0x004e0b9f   109 bytes   vtable slot 0x84   sig ()i
' byte-identical vs NSS5.exe (109/109, original length from Ghidra's inventory)
' ASSUMPTIONS: FUN_00505b91 is the recovered module Function LogLine; its literal is this
' function's own name (its address is masked, so the text is not proven).
' The EachIn loop's own null-skip accounts for the decompiler's "if (p != Null)".
' TPlayer slot 0x15c = ResetPosition. harness mode=reloc, 5 addresses masked.
	Method ForcePositionReset:Int()
		LogLine("ForcePositionReset")
		For Local p:TPlayer = EachIn squad
			p.ResetPosition()
		Next
	End Method

' FlushAllInput  -- module-level Function (no Type)
' VA 0x005071c3   34 bytes   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 5 game functions call it. The three callees were identified by source
' order in the BlitzMax module sources against byte-proven neighbours; the match itself
' then confirms them, since a wrong callee would leave the E8 operand unmasked.
' FlushJoy's port_mask parameter defaults to ~0, which is the -1 pushed at the call site.
	Function FlushAllInput:Int()
		FlushKeys
		FlushMouse
		FlushJoy
	End Function

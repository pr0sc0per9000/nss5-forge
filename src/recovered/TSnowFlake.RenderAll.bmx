' TSnowFlake.RenderAll
' VA 0x00505A26   130 bytes
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_snowflakes:TList
SetBlend 4
For Local s:TSnowFlake = EachIn g_snowflakes
	s.Render()
Next
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)

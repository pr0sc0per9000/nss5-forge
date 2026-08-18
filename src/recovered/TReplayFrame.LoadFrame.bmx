' TReplayFrame.LoadFrame
' VA 0x00504DEE   335 bytes
' byte-identical vs NSS5.exe (335/335, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
If a0.Eof() Then Return Null
Local f:TReplayFrame = New TReplayFrame
f.frametime = ReadInt(a0)
f.obtext = ReadLine(a0)
f.obtype = ReadInt(a0)
f.id = ReadInt(a0)
f.selno = ReadInt(a0)
f.clubid = ReadInt(a0)
f.skincol = ReadInt(a0)
f.haircol = ReadInt(a0)
f.bootcol = ReadInt(a0)
f.glovecol = ReadInt(a0)
f.x = ReadFloat(a0)
f.y = ReadFloat(a0)
f.z = ReadFloat(a0)
f.xvel = ReadFloat(a0)
f.yvel = ReadFloat(a0)
f.zvel = ReadFloat(a0)
f.frame = ReadInt(a0)
f.facing = ReadInt(a0)
f.rotation = ReadFloat(a0)
f.alph = ReadFloat(a0)
f.active = ReadInt(a0)
Return f

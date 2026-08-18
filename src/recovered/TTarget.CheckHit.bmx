' TTarget.CheckHit
' VA 0x005845aa   192 bytes
' byte-identical vs NSS5.exe (192/192, original length from Ghidra's inventory, mode=reloc, 8 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Method ()i, vtable slot 0x4c.
' ASSUMPTIONS: the two Globals are TSound (0x00C6DC78) and TChannel (0x00C5B344); only their
' PlaySound argument positions are proven, not their names. Indirect calls resolved as
' TBall classtable+0x44 = GetActiveBall and TPitch classtable+0x6c = YardsToPixels.
'!Global g_target_snd:TSound
'!Global g_target_chan:TChannel
Local b:TBall = TBall.GetActiveBall()
If b And b.z < 1.0 And Dist2D(Self.x, Self.y, b.x, b.y) < TPitch.YardsToPixels(2.0) And Abs(b.zvelocity) > 1
	Self.alive = 0
	PlaySound(g_target_snd, g_target_chan)
EndIf

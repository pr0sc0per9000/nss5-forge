' TBall.SetUpSetPieceBall
' VA 0x004CBB7B   262 bytes
' byte-identical vs NSS5.exe (262/262, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_pitch_hw:Int
'!Global g_pitch_hh:Int
LogLine("SetUpSetPieceBall:" + a0 + ", " + a1 + "   Team:" + a2)
Self.lastkickedby = Null
Self.setpiecex = a0
Self.setpiecey = a1
ClampInt(Varptr Self.setpiecex, -g_pitch_hw, g_pitch_hw)
ClampInt(Varptr Self.setpiecey, -g_pitch_hh, g_pitch_hh)
Self.teaminpossession = a2
Self.ResetPosition(a0, a1, 0)
Self.ResetControllers()

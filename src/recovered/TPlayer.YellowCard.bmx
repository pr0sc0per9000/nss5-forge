' TPlayer.YellowCard
' VA 0x004F5333   314 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_homeTeam:TTeam
'!Global g_homeYellows:Int
'!Global g_awayYellows:Int
'!Global g_msgFont:TBitmapFont
'!Global g_yellowCardImg:TImage
'!Global g_secondYellowImg:TImage
'!Global g_secondYellowTime:Int
' CASE DIRECTION CORRECTED 2026-08-22: 2 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
LogLine("Yellows:" + Self.matchstats.yellows)
If Self.teamid = g_homeTeam.id
	g_homeYellows :+ 1
Else
	g_awayYellows :+ 1
End If
If Self.matchstats.yellows = 0
	Self.AddStat(9, 0, 0, 0, 0)
	TScreenMessage.Create(0, 0, GetText("Yellow Card!").ToUpper(), 2500, g_msgFont, g_yellowCardImg, 2.0, "FFFFFF")
ElseIf Self.selectionno <> 0
	Self.AddStat(10, 0, 0, 0, 0)
	Self.AddStat(9, 0, 0, 0, 0)
	TScreenMessage.Create(0, 0, GetText("Second Yellow!").ToUpper(), g_secondYellowTime, g_msgFont, g_secondYellowImg, 2.0, "FFFFFF")
	Self.selectionno = 50
End If

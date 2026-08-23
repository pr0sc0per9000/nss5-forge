' TPlayer.RedCard
' VA 0x004f546d   163 bytes   vtable slot 0xe0   sig ()i
' byte-identical vs NSS5.exe (163/163, original length from Ghidra's inventory)
' assumes: TTeam Global (globals_final says TKit, but field +8 is TTeam.id); early-return guard; 0x004a7410 = Lower()
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Method RedCard:Int()
		'!Global g_team1:TTeam
		'!Global g_redcards_home:Int
		'!Global g_redcards_away:Int
		'!Global g_msgtime:Int
		'!Global g_font:TBitmapFont
		'!Global g_msgimg:TImage
		If Self.selectionno = 0 Then Return 0
		If Self.teamid = g_team1.id
			g_redcards_home :+ 1
		Else
			g_redcards_away :+ 1
		EndIf
		Self.AddStat(10, 0, 0, 0, 0)
		TScreenMessage.Create(0, 0, GetText("Red Card!").ToUpper(), g_msgtime, g_font, g_msgimg, 2.0, "FFFFFF")
		Self.selectionno = 50
	End Method

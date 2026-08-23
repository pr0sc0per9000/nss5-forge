' TBlackJack.DealersTurn  -- KIND=Function (STATIC method on TBlackJack), slot 0x48, sig ()i
' VA 0x0057704C   542 bytes   (original length from Ghidra's inventory)
' ORACLE: MATCH mode=reloc  542/542  reloc_masked=45
' byte-identical vs NSS5.exe
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_004C5549 = GetText ($)$        FUN_004A7410 = _brl_retro_Lower
'   PTR_FUN_00C6C340 = TBlackJack        classtable + 0x58 -> GetDealerScore(*i,*i)i
'   PTR_FUN_00C6C334 = TBlackJack        classtable + 0x4C -> Hit(:TList)i
'   PTR_FUN_00C6C348 = TBlackJack        classtable + 0x60 -> ShowResult()i
'   PTR_FUN_00C6C158 = TScreen_BlackJack classtable + 0x40 -> UpdateScoreLabels()i
'   PTR_FUN_00C6B264 = TScreenMessage    classtable + 0x30 -> Create(i,i,$,i,:TBitmapFont,:TImage,f,$)
'   Globals (names ours, TYPES load-bearing):
'     0x00C6C17C -> g_bj_dealerturn:Int      (bare `mov dword [g],1`, no refcount traffic)
'     0x00C6C174 -> g_bj_state:Int           0x00C6C178 -> g_bj_result:Int
'     0x00C6C170 -> g_bj_dealercards:TList   (slot 0x70 = TList.Count -- same shape as
'                                             g_bj_cardlist at 0x00C6C16C in CheckPlayerScore;
'                                             globals_final has this row as bare "Object,
'                                             no call-site typing", so TList is inferred from
'                                             the slot, not from a construction site)
'     0x00C6B834 -> g_bj_msgstyle:Int        (TScreenMessage.Create arg 4, an Int)
'     0x00C5B1C8 -> g_font_msg:TBitmapFont   (Create arg 5, forced by the signature)
'     0x00C6EFE4 -> g_screen_w:Int           0x00C6EFE8 -> g_screen_h:Int
'   String literals read out of NSS5.exe BBString headers (harness.read_string):
'     0x00C90E48 "blackjack_Bust"  0x00C90E70 "blackjack_BlackJack"
'     0x00C90EA4 "blackjack_5CardTrick"  0x00C5D680 "FFFFFF"
'
' ARG-COUNT TRAP: Ghidra prints FUN_004C5549 with SIX arguments. The cleanup is
' `add esp,4` -- GetText takes ONE. The other five pushes belong to the following
' TScreenMessage.Create (cleaned with `add esp,0x20`, i.e. 8 arguments).
'
' Note the message y is `g_screen_h / 2 - 100` here (`sub eax,0x64`), where the sibling
' CheckPlayerScore uses `+ 100`. `(D + (D >> 31 & 1)) >> 1` is signed `Int / 2`.
'
' The fourth arm is emitted as `lo > 16 Or hi > 16 -> state = 3` with the Hit() in the
' Else; Ghidra prints the De Morgan dual (`lo < 17 && hi < 17`). Read the setg/0x10.
' CASE DIRECTION CORRECTED 2026-08-22: 3 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function DealersTurn:Int()
		'!Global g_bj_state:Int
		'!Global g_bj_result:Int
		'!Global g_bj_dealerturn:Int
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		'!Global g_bj_msgstyle:Int
		'!Global g_font_msg:TBitmapFont
		'!Global g_bj_dealercards:TList
		g_bj_dealerturn = 1
		Local lo:Int = 0
		Local hi:Int = 0
		TBlackJack.GetDealerScore(Varptr lo, Varptr hi)
		If lo > 21
			g_bj_state = 3
			g_bj_result = 1
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 - 100, GetText("blackjack_Bust").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf hi = 21 And g_bj_dealercards.Count() = 2
			g_bj_state = 3
			g_bj_result = 2
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 - 100, GetText("blackjack_BlackJack").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf g_bj_dealercards.Count() = 5
			g_bj_state = 3
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 - 100, GetText("blackjack_5CardTrick").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf lo > 16 Or hi > 16
			g_bj_state = 3
		Else
			TBlackJack.Hit(g_bj_dealercards)
		EndIf
		TScreen_BlackJack.UpdateScoreLabels()
		If g_bj_state = 3 Then TBlackJack.ShowResult()
		Return 0
	End Function

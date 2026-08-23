' TBlackJack.CheckPlayerScore
' VA 0x00576E46   518 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x44
' ORACLE 518/518 reloc_masked=44, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_004C5549 = GetText ($)$        FUN_004A7410 = _brl_retro_Lower
'   PTR_FUN_00C6C344 = TBlackJack     classtable + 0x5C -> GetPlayerScore(*i,*i)i
'   PTR_FUN_00C6C348 = TBlackJack     classtable + 0x60 -> ShowResult()
'   PTR_FUN_00C6B264 = TScreenMessage classtable + 0x30 -> Create(i,i,$,i,:TBitmapFont,:TImage,f,$)
'   Globals (names ours, TYPES load-bearing):
'     0x00C6C16C -> g_bj_cardlist:TList       (slot 0x70 = TList.Count)
'     0x00C6C174 -> g_bj_state:Int            0x00C6C178 -> g_bj_result:Int
'     0x00C6B834 -> g_bj_msgstyle:Int         (TScreenMessage.Create arg 4, an Int)
'     0x00C5B1C8 -> g_font_msg:TBitmapFont    (Create arg 5, forced by the signature)
'     0x00C6EFE4 -> g_screen_w:Int            0x00C6EFE8 -> g_screen_h:Int
'     0x00C6C020 -> g_bj_gadget1:TButton      0x00C6C024 -> g_bj_gadget2:TButton
'   String literals read out of NSS5.exe BBString headers:
'     0x00C90E48 "blackjack_Bust"  0x00C90E70 "blackjack_BlackJack"
'     0x00C90EA4 "blackjack_5CardTrick"  0x00C5D680 "FFFFFF"
'
' NOT PINNED DOWN BY THE BYTES (and so outside what the MATCH above certifies): the two
' gadget Globals are called through `mov eax,[g] / mov eax,[eax] / call [eax+0x54]`, a
' runtime vtable dispatch with no class-table immediate to fix the type. Slot 0x54 is
' TGadget.Hide, inherited by TPanel/TButton/TLabel alike, so ANY TGadget subtype emits
' these exact bytes. TButton is a guess consistent with the TScreen_BlackJack subsystem.
' Note this is a whole-program hazard per guide 14.1: if another body declares either
' Global as a Type where slot 0x54 differs, the assembled dispatch shifts.
'
' ARG-COUNT TRAP: Ghidra prints FUN_004c5549 with SIX arguments. The cleanup is
' `add esp,4` -- GetText takes ONE. The other five pushes belong to the following
' TScreenMessage.Create (cleaned with `add esp,0x20`, i.e. 8 arguments).
'
' `(int)(D + (D >> 0x1f & 1)) >> 1` is just signed `Int / 2`, not a shift written by hand.
' CASE DIRECTION CORRECTED 2026-08-22: 3 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function CheckPlayerScore:Int()
		'!Global g_bj_state:Int
		'!Global g_bj_result:Int
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		'!Global g_bj_msgstyle:Int
		'!Global g_font_msg:TBitmapFont
		'!Global g_bj_cardlist:TList
		'!Global g_bj_gadget1:TButton
		'!Global g_bj_gadget2:TButton
		Local lo:Int = 0
		Local hi:Int = 0
		TBlackJack.GetPlayerScore(Varptr lo, Varptr hi)
		If lo > 21
			g_bj_state = 3
			g_bj_result = 2
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 + 100, GetText("blackjack_Bust").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf hi = 21 And g_bj_cardlist.Count() = 2
			g_bj_state = 3
			g_bj_result = 1
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 + 100, GetText("blackjack_BlackJack").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf g_bj_cardlist.Count() = 5
			g_bj_state = 2
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2 + 100, GetText("blackjack_5CardTrick").ToUpper(), g_bj_msgstyle, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf lo = 21
			g_bj_state = 2
		EndIf
		If g_bj_state > 1
			g_bj_gadget1.Hide()
			g_bj_gadget2.Hide()
		EndIf
		If g_bj_state = 3 Then TBlackJack.ShowResult()
		Return 0
	End Function

' TScreen_Stable.ButtonSellHorse
' VA 0x00589C6E   243 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x80
' (243/243, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1)
'
' ASSUMPTIONS
'   0x00C6DEE0 g_Object839:TButton                 (globals_final, construction) -- TGadget.alph +0x44
'   0x00C6DEC8 g_screen_stable_tplayer01:TTable    -- slot 0xd8 GetSelectedText(i)$; globals_final
'     says TLabel with a flagged TLabel/TTable conflict, and TScreen_Stable.ButtonBuyHorse
'     already settled it as TTable (slot 0xdc SelectItemByRow exists only on TTable).
'   0x00C6F028 g_contractoffer_tplayer:TProfile    -- slot 0xfc UpdateBank(i)i
'   THorse: slot 0x44 GetValue()i, field owned +0x50 (object_model.json).
'   GetSelectedHorse (class table +0x7c) and SetUpScreen (+0x34) are sibling Functions of
'     TScreen_Stable, so they are written unprefixed.
'   Leading guard is a real early return spelled `< 1.0`: bcc materialises the NEGATED
'     predicate for a float If (setae) and branches with jne -- identical prologue to the
'     already-verified TScreen_MyContract.ButtonRequestLoan.
'   `If Not h` is the 21-byte setne/movzx/cmp/jne form (pattern 10.3).
'   All three string literals read out of NSS5.exe with harness.read_string.
'   NOTE the sell path passes UpdateBank(v) POSITIVE where ButtonBuyHorse passes -v; the
'     original really does push esi unnegated (no `neg`/`fchs` in the stream).
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_Object839:TButton
'!Global g_screen_stable_tplayer01:TTable
'!Global g_contractoffer_tplayer:TProfile
If g_Object839.alph < 1.0 Then Return 0
Local h:THorse = GetSelectedHorse(g_screen_stable_tplayer01.GetSelectedText(0))
If Not h
	TScreen.DoMessage(GetText("CMESSAGE_SELECTHORSE"),0,0)
	Return 0
EndIf
Local v:Int = h.GetValue()
If TScreen.DoMessage(GetText("CMESSAGE_SELLHORSE").Replace("$cash",FormatMoney(v,1)),1,0)
	g_contractoffer_tplayer.UpdateBank(v)
	h.owned = 0
	SetUpScreen(1)
EndIf

' TScreen_Stable.ButtonBuyHorse
' VA 0x0058993B   320 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x74
' (320/320, original length from Ghidra's inventory, reloc_masked=21)
'
' ASSUMPTIONS
'   0x00C6F028 g_contractoffer_tplayer:TProfile (globals_final, 3 construction sites)
'   0x00C6DEDC g_screen_stable_tplayer02:TTable (construction) -- slot 0xd8 GetSelectedText(i)$
'   0x00C6DEC8 g_screen_stable_tplayer01:TTable -- globals_final says TLabel with a flagged
'     TLabel/TTable conflict; slot 0xdc (SelectItemByRow) exists only on TTable, so TTable.
'   THorse.owned is field +0x50 (object_model.json).
'   GetSelectedHorse / SetUpScreen are sibling Functions of TScreen_Stable (class-table
'     0x00C6E284 = +0x7c, 0x00C6E23C = +0x34) so they are written unprefixed.
'   `If Not h` is the 21-byte setne/movzx/cmp/jne form (pattern 10.3), not `If h = Null`.
'   All four string literals read out of NSS5.exe with harness.read_string.
'!Global g_contractoffer_tplayer:TProfile
'!Global g_screen_stable_tplayer01:TTable
'!Global g_screen_stable_tplayer02:TTable
If THorse.CountHorsesOwned() >= g_contractoffer_tplayer.GetStableSize()
	TScreen.DoMessage(GetText("CMESSAGE_STABLE_NOROOM"),0,0)
	Return 0
EndIf
Local h:THorse = GetSelectedHorse(g_screen_stable_tplayer02.GetSelectedText(0))
If Not h
	TScreen.DoMessage(GetText("CMESSAGE_SELECTHORSE"),0,0)
	Return 0
EndIf
Local v:Int = h.GetValue()
If TScreen.DoMessage(GetText("CMESSAGE_BUYHORSE").Replace("$cash",FormatMoney(v,1)),1,0)
	If g_contractoffer_tplayer.UpdateBank(-v)
		h.owned = 1
		SetUpScreen(1)
		g_screen_stable_tplayer01.SelectItemByRow(1)
		g_contractoffer_tplayer.CheckAchievement(82)
	EndIf
EndIf

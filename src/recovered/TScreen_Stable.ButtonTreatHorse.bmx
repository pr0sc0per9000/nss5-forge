' TScreen_Stable.ButtonTreatHorse   (KIND=Function -- static, no Self)
' VA 0x00589D61   339 bytes   class-table slot 0x84   sig ()i
' ORACLE: mode=reloc  matched=339/339  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C6DED0 g_stable_btn_treat:TButton   field +0x44 = TGadget.alph (inherited Float)
'   0x00C6DEC8 g_screen_stable_tplayer01:TTable  slot 0xD8 = GetSelectedText(i)$
'                                          (same call site shape as the banked ButtonBuyHorse)
'   0x00C6F028 g_contractoffer_tplayer:TProfile  slot 0xFC = UpdateBank(i)i
' Class-table static calls resolved:
'   0x00C61CC0 = TScreen+0x94           -> TScreen.DoMessage($,i,i)i
'   0x00C6E284 = TScreen_Stable+0x7C    -> GetSelectedHorse($):THorse  [OWN type => no prefix]
'   0x00C6E23C = TScreen_Stable+0x34    -> SetUpScreen(i)i             [OWN type => no prefix]
' Module Functions: GetText (0x004C5549), FormatMoney (0x0050720B) -- both recovered.
' Float constants read straight out of the exe: 0x00C93C9C = 99.5 (NOT 100.0 -- the two
' other slots 0x00C93CD8 / 0x00C93D14 really are 100.0), 0x00C93CDC = 1000.0.
' Literals read with harness.read_string.
'
' NOTE  x87 comparisons emit the NEGATED setcc plus a jump-if-set past the block:
'       `alph < 1.0` -> setae/jne, `health >= 99.5` -> setb/jne. Read the setcc as the
'       inverse of the source relation (codegen-patterns 10.1 generalised to x87).
' NOTE  `If Not h` is the 21-byte setne/movzx/cmp/jne form (pattern 10.3).
' NOTE  `Local c:Int` is real -- `neg ebx` reuses the same value for UpdateBank(-c).

'!Global g_stable_btn_treat:TButton
'!Global g_screen_stable_tplayer01:TTable
'!Global g_contractoffer_tplayer:TProfile

If g_stable_btn_treat.alph < 1.0 Then Return 0
Local h:THorse = GetSelectedHorse(g_screen_stable_tplayer01.GetSelectedText(0))
If Not h
	TScreen.DoMessage(GetText("CMESSAGE_SELECTHORSE"),0,0)
	Return 0
EndIf
If h.health >= 99.5
	TScreen.DoMessage(GetText("CMESSAGE_HORSEHEALTHY"),0,0)
	Return 0
EndIf
Local c:Int = Int((100.0 - h.health) * 1000.0)
If TScreen.DoMessage(GetText("CMESSAGE_TREATHORSE").Replace("$cash",FormatMoney(c,1)),1,0)
	If g_contractoffer_tplayer.UpdateBank(-c)
		h.health = 100.0
		SetUpScreen(1)
	EndIf
EndIf

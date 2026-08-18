' TScreen_BlackJack.UpdateScoreLabels
' VA 0x00576990   371 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_bjDealerLabel:TLabel
'!Global g_bjPlayerLabel:TLabel
Local lo:Int
Local hi:Int
TBlackJack.GetDealerScore(Varptr lo, Varptr hi)
If hi = 0
	g_bjDealerLabel.SetText(String(lo), "", -1, -1)
Else
	g_bjDealerLabel.SetText(String(lo) + " " + GetText("or") + " " + String(hi), "", -1, -1)
End If
TBlackJack.GetPlayerScore(Varptr lo, Varptr hi)
If hi = 0
	g_bjPlayerLabel.SetText(String(lo), "", -1, -1)
Else
	g_bjPlayerLabel.SetText(String(lo) + " " + GetText("or") + " " + String(hi), "", -1, -1)
End If

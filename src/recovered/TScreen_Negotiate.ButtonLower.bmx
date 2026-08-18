' TScreen_Negotiate.ButtonLower
' VA 0x0057A6BC   150 bytes
' byte-identical vs NSS5.exe (150/150, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_neg_offers:Int
'!Global g_neg_a:Int
'!Global g_neg_b:Int
'!Global g_player_p50:Int
'!Global g_neg_btn1:TButton
'!Global g_neg_btn2:TButton
'!Global g_neg_btn3:TButton
If g_neg_offers > 4 Then Return 0
g_neg_offers = g_neg_offers + 1
g_neg_b = -1
g_neg_a = g_player_p50
g_neg_btn1.alive = 0
g_neg_btn1.SetAlph(0.5)
g_neg_btn2.alive = 0
g_neg_btn2.SetAlph(0.5)
g_neg_btn3.alive = 0
g_neg_btn3.SetAlph(0.5)

' TBlackJack.GetPlayerScore
' VA 0x0057764B   197 bytes
' byte-identical vs NSS5.exe (197/197, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_cards:TList
a0[0] = 0
a1[0] = 0
Local ace:Int = 0
For Local c:TCard = EachIn g_cards
	Local v:Int = c.num
	If v > 10 Then v = 10
	a0[0] = a0[0] + v
	If c.num = 1 Then ace = 1
Next
If ace Then a1[0] = a0[0] + 10
If a1[0] > 21 Then a1[0] = 0

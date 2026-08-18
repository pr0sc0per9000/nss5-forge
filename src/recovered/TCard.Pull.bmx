' TCard.Pull
' VA 0x00577cc9   114 bytes   vtable slot 0x3c   sig ():TCard
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c6c354 declared Int (the TCard.Compare sort key),
' module Global 0x00c6c350 declared TList (the deck).
	Function Pull:TCard()
		'!Global g_card_num:Int
		'!Global g_deck:TList
		g_card_num = 5
		g_deck.Sort()
		Local c:TCard = TCard(g_deck.First())
		Local l:TCard = TCard(g_deck.Last())
		c.randno = l.randno + 1
		Return c
	End Function

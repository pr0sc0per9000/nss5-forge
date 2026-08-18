' TCard.Shuffle
' VA 0x00577c36   147 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' assumptions / Globals declared:
'   0x00c6c350 TList (globals_final g_Object763:Object, untyped; slot 0x8c = ObjectEnumerator
'             and slot 0x88 = TList.Sort fix it)
'   0x00c6c354 Int   (g_card_int01)
' FUN_0059f089 = _brl_random_Rand; Ghidra shows Rand(9999,1) because bcc materialises the
'   maxValue default -- the source is the one-argument Rand(9999).
' FUN_005b3516 = _brl_linkedlist_CompareObjects, i.e. TList.Sort's default comparator, so
'   the call is the argument-less Sort().
' EachIn class table 0x00c6c450 = TCard; puVar3[3] = +0xc = TCard.randno.
	Function Shuffle:Int()
		'!Global g_cards:TList
		'!Global g_card_int01:Int
		For Local c:TCard = EachIn g_cards
			c.randno = Rand(9999)
		Next
		g_card_int01 = 5
		g_cards.Sort()
	End Function

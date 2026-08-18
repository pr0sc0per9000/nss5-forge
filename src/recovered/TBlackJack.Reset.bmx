' TBlackJack.Reset
' VA 0x00576d03   89 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (89/89, original length from Ghidra's inventory)
' ASSUMPTIONS: module Globals 0x00c6c16c / 0x00c6c170 declared TList (the two hands --
' slot 0x34 is TList.Clear), and 0x00c6c174 / 0x00c6c178 / 0x00c6c17c declared Int.
	Function Reset:Int()
		'!Global g_hand1:TList
		'!Global g_hand2:TList
		'!Global g_bj1:Int
		'!Global g_bj2:Int
		'!Global g_bj3:Int
		TCard.Shuffle()
		g_hand1.Clear()
		g_hand2.Clear()
		g_bj1 = 0
		g_bj2 = 0
		g_bj3 = 0
		TScreenMessage.ClearAll(0)
	End Function

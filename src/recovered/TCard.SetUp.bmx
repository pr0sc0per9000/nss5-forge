' TCard.SetUp
' VA 0x00577A3F   287 bytes
' byte-identical vs NSS5.exe (287/287, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_card_img:TImage
'!Global g_card_list:TList
'!Global g_datapath:String
If Not g_card_img
	g_card_img = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/BlackJack/back.png", -1)
	MidHandleImage(g_card_img)
	g_card_list = CreateList()
	Local n:Int = 1
	For Local suit:Int = 1 To 4
		Local s:String = ""
		Select suit
		Case 1
			s = "heart"
		Case 2
			s = "diamond"
		Case 3
			s = "club"
		Case 4
			s = "spade"
		End Select
		For Local v:Int = 1 To 13
			g_card_list.AddLast(CreateCard(v, s))
			n :+ 1
		Next
	Next
EndIf

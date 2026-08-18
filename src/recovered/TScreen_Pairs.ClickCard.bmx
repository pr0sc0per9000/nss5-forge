' TScreen_Pairs.ClickCard
' VA 0x00579256   254 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (254/254, original length from Ghidra's inventory)
' Globals: g_pairs_clicked:Int (0x00c6c82c), g_Object108:Object (0x00c61cf8, downcast to
'          TButton here), g_pair_icons:TList (0x00c6c9e0), g_pairs_int05:Int (0x00c6c834),
'          g_player_int50:Int (0x00c6efd4 -- plain dword copy, so Int not TScreen)
' Two separate early returns, not one compound guard: the original emits
' `cmp [g],0 / jge` then `cmp [g],2 / jne`, both against memory with no sete.
' DisableAll (slot 0x4c) and UpdateFaces (slot 0x44) are this Type's own Functions.
	Function ClickCard:Int()
		'!Global g_pairs_clicked:Int
		'!Global g_Object108:Object
		'!Global g_pair_icons:TList
		'!Global g_pairs_int05:Int
		'!Global g_player_int50:Int
		If g_pairs_clicked < 0 Then Return 0
		If g_pairs_clicked = 2 Then Return 0
		Local b:TButton = TButton(g_Object108)
		For Local ic:TPair_Icon = EachIn g_pair_icons
			If ic.id = Int(b.name.Replace("btn_",""))
				If ic.picked <> 0 Then Return 0
				ic.picked = 1
			EndIf
		Next
		g_pairs_clicked = g_pairs_clicked + 1
		If g_pairs_clicked = 2
			g_pairs_int05 = g_player_int50
			DisableAll()
		EndIf
		UpdateFaces()
	End Function

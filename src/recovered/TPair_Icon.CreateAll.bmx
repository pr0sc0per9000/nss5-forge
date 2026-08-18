' TPair_Icon.CreateAll
' VA 0x005798da   265 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (265/265, original length from Ghidra's inventory)
' Globals: g_pair_icons:TList (0x00c6c9e0), g_path:String (0x00c6e950),
'          g_pair_icon_arr01:TImage[] (0x00c6c9f0)
' Both Null tests are the `If Not x` emission (setne/movzx), and BOTH loops are `To`
' (cmp/jle), not `Until`.  TPair_Icon.New self-registers on g_pair_icons.
	Function CreateAll:Int()
		'!Global g_pair_icons:TList
		'!Global g_pair_icon_arr01:TImage[]
		'!Global g_path:String
		If Not g_pair_icons
			g_pair_icons = CreateList()
		Else
			g_pair_icons.Clear()
		EndIf
		If Not g_pair_icon_arr01[0]
			For Local i:Int = 0 To 4
				g_pair_icon_arr01[i] = LoadImageChecked(g_path + "GameMedia/Images/Casino/Pairs/BG_" + (i + 1) + ".png",-1)
			Next
		EndIf
		For Local i:Int = 0 To 15
			Local ic:TPair_Icon = New TPair_Icon
			ic.id = i
		Next
	End Function

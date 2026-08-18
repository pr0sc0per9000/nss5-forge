' TScreen_TestFixtures.ComboContinent
' VA 0x00539af6   190 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (190/190, original length from Ghidra's inventory)
' Globals: 0x00C66614 :TCombo (nations), 0x00C66610 :TCombo (continents).
' TCombo slots 0x8C ClearItems, 0x90 AddItem($,$,$,i), 0xBC GetSelectedItem.
' TNation.SelectListByContinent is TNation+0x68; TNation.HasLeagues is slot 0x74.
' The two colour literals are string objects at 0x00C7F250 and 0x00C5D680.
	Function ComboContinent:Int()
		'!Global g_tf_combonation:TCombo
		'!Global g_tf_combocontinent:TCombo
		g_tf_combonation.ClearItems()
		For Local n:TNation = EachIn TNation.SelectListByContinent(g_tf_combocontinent.GetSelectedItem())
			If n.HasLeagues()
				g_tf_combonation.AddItem(n.name, "BBBBBB", "FFFFFF", n.id)
			EndIf
		Next
		TScreen_TestFixtures.SetUpScreen()
		Return 0
	End Function

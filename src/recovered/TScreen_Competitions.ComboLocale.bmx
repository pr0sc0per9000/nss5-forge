' TScreen_Competitions.ComboLocale
' VA 0x00530036   483 bytes   vtable slot 0x58   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (483/483, original length from Ghidra's inventory)
' Globals (names ours, addresses from the decompilation):
'   0x00C65578 g_comp_combo1:TCombo    0x00C6557C g_comp_combo2:TCombo   -- same two
'   0x00C65580 g_comp_combo3:TCombo       as TScreen_Competitions.ComboLevel
'   0x00C596F0 g_nations:TList (of TNation)   0x00C6080C g_continents:TList (of TContinent)
' BOTH levels are Select, not If/ElseIf: each pair of Case compares sits back to back
' before either body (10.2).
' The load-bearing quirk is the EMPTY `Case 2` in the inner Select under the outer `Case 2`.
' Written as a bare `If g_comp_combo2.GetSelectedItem() = 1` the body is 469 bytes: the
' original spends 7 bytes on the second compare (`cmp eax,2 / je / jmp` instead of one
' `jne`) and 4 more on the empty arm's `EB 00` plus the Select's own end jump.
' 0x00C656F0 = TScreen_Competitions+0x34 = SetUpScreen, its own Type, so a plain call.
	Function ComboLocale:Int()
		'!Global g_comp_combo1:TCombo
		'!Global g_comp_combo2:TCombo
		'!Global g_comp_combo3:TCombo
		'!Global g_nations:TList
		'!Global g_continents:TList
		g_comp_combo3.ClearItems()
		Select g_comp_combo1.GetSelectedItem()
			Case 1
				Select g_comp_combo2.GetSelectedItem()
					Case 1
						For Local n:TNation = EachIn g_nations
							If n.HasLeagues()
								g_comp_combo3.AddItem(n.name, "BBBBBB", "FFFFFF", n.id)
							EndIf
						Next
					Case 2
						For Local c:TContinent = EachIn g_continents
							g_comp_combo3.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
						Next
				End Select
			Case 2
				Select g_comp_combo2.GetSelectedItem()
					Case 1
						For Local c:TContinent = EachIn g_continents
							g_comp_combo3.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
						Next
					Case 2
				End Select
		End Select
		SetUpScreen()
	End Function

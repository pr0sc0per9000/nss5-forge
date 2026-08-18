' TScreen_Clubs.ComboLocale
' VA 0x0052CA50   309 bytes
' byte-identical vs NSS5.exe (309/309, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_clubs_comboA:TCombo
'!Global g_clubs_comboB:TCombo
'!Global g_nations:TList
'!Global g_continents:TList
LogLine("ComboLocale")
g_clubs_comboB.ClearItems()
Select g_clubs_comboA.GetSelectedItem()
	Case 1
		For Local n:TNation = EachIn g_nations
			g_clubs_comboB.AddItem(n.name, "BBBBBB", "FFFFFF", n.id)
		Next
	Case 2
		For Local c:TContinent = EachIn g_continents
			g_clubs_comboB.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
		Next
End Select
g_clubs_comboB.SelectItem(1)
ComboBased()

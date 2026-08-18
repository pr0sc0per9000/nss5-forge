' TScreen_Continents.SelectLevel  (KIND=Function -- static, a0 is NOT Self)
' VA 0x0054792F   241 bytes   sig (i)i
' byte-identical vs NSS5.exe (241/241, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS; the declared types are load-bearing:
'   0x00C671E0 TCombo  (0x8C ClearItems, 0x90 AddItem)
'   0x00C671CC TTable  (0x9C ClearItems)
'   0x00C671D4/D8 TTable (0x54 Hide, inherited from TGadget)
'   0x00C6080C TList of TContinent
' Ghidra prints the AddItem calls with GetText's argument merged in; the disassembly shows
' GetText takes one argument and TCombo.AddItem($,$,$,i) takes four.
'!Global g_continents_level:Int
'!Global g_continents_combo:TCombo
'!Global g_continents_table1:TTable
'!Global g_continents_table2:TTable
'!Global g_continents_table3:TTable
'!Global g_continents:TList
g_continents_level = a0
g_continents_combo.ClearItems()
g_continents_table1.ClearItems()
g_continents_table3.Hide()
g_continents_table2.Hide()
For Local c:TContinent = EachIn g_continents
	g_continents_combo.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
Next
If g_continents_level = 1 Then g_continents_combo.AddItem(GetText("World"), "BBBBBB", "FFFFFF", 7)

' TTable.CreateTable
' VA 0x00516028   376 bytes
' byte-identical vs NSS5.exe (376/376, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_tableimage:TImage
'!Global g_table_pad:Int
If Not g_tableimage Then CreateTableImage()
Local t:TTable = New TTable
t.name = a0
t.x = a1
t.desx = a1
t.y = a2
t.desy = a2
t.w = 0
t.numdisplayitems = a3
t.ih = a4
t.alive = a5
t.highlightcol = a7
t.alph = a8
t.fntSize = a6
If a4 = 0
	t.SetFontSize(a6)
	t.ih = TextHeight("I") + 4
End If
t.h = a3 * (t.ih + g_table_pad)
If a9 <> 0
	t.h = t.h + (t.ih + g_table_pad)
End If
t.columns = CreateList()
t.items = CreateList()
t.fHit = t.ActivateTable
t.showheadings = a9
t.fRet = a10
Return t

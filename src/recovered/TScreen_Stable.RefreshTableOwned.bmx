' TScreen_Stable.RefreshTableOwned
' VA 0x00589a7b   381 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x78   (reloc_masked=18)
' ASSUMPTIONS
'   '!Global g_stable_table:TTable  -- 0x00C6DEC8. globals_final flags a CONFLICT
'     (TLabel=1; TTable=1). The slots decide it: 0xD4=GetSelectedItem, 0x9C=ClearItems,
'     0x94=AddItem([]$,$,$), 0xDC=SelectItemByRow(i) are all TTable's.
'   '!Global g_horses:TList  -- 0x00C6E294, typed Object by usage. Slot 0x88 = TList.Sort
'     and 0x8C = TList.ObjectEnumerator, so TList (10.7).
'   '!Global g_stable_int26:Int -- 0x00C6E29C, a row-height/limit constant set to 30.
'   THorse fields: name +0x38 $, prize +0x4C i, owned +0x50 i.
'     THorse slots 0x38/0x3C/0x40 = GetStringEnergy/GetStringHealth/GetStringForm.
'   FormatMoney is src/recovered_module/FormatMoney.bmx (0x0050720B).
' SHAPE NOTES
'   * `.Sort(0)` -- the original pushes 0 then _brl_linkedlist_CompareObjects, i.e. the
'     default compareFunc emitted at the call site; add esp,0xc confirms 2 args + Self.
'   * the row is an ARRAY LITERAL, not a New+element stores: bbArrayNew1D(5) followed by
'     five bare `mov [ebx+0x18+n]` with no bounds check is what `[a,b,c,d,e]` emits.
'   * `If Not g_horses Then Return 0` is a genuine early return (3f/10.9); the If-block
'     form is 15 bytes shorter and wrong.
	Function RefreshTableOwned:Int()
		'!Global g_stable_table:TTable
		'!Global g_horses:TList
		'!Global g_stable_int26:Int
		Local sel:Int = g_stable_table.GetSelectedItem()
		If sel < 0
			sel = 0
		EndIf
		g_stable_table.ClearItems()
		If Not g_horses Then Return 0
		g_stable_int26 = 30
		g_horses.Sort(0)
		For Local h:THorse = EachIn g_horses
			If h.owned = 1
				g_stable_table.AddItem([h.name, h.GetStringEnergy(), h.GetStringHealth(), h.GetStringForm(), FormatMoney(h.prize, 1)], "", "")
			EndIf
		Next
		g_stable_table.SelectItemByRow(sel)
	End Function

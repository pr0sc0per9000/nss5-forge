' TScreen_Stable.RefreshTableForSale
' VA 0x005897AF   396 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x70
' ASSUMPTIONS
'   '!Global g_stable_table:TTable   -- 0x00C6DEDC (typed TTable by construction site)
'   '!Global g_horses:TList          -- 0x00C6E294 (ObjectEnumerator at slot 0x8C)
'   '!Global g_stable_maxrows:Int    -- 0x00C6E29C, plain dword store of 30, no refcount
'   TTable slots 0xD4 GetSelectedItem, 0x9C ClearItems, 0x94 AddItem([]$,$,$),
'   0xDC SelectItemByRow(i) (vtable_map.tsv).
'   THorse slots 0x3C GetStringHealth, 0x40 GetStringForm, 0x44 GetValue;
'   fields name $ +0x38, prize i +0x4C, owned i +0x50.
'   0x0050720B is the recovered module Function FormatMoney.
'   Both trailing AddItem arguments are the empty string at 0x005C7D40.
' CODEGEN NOTES
'   `If Not g_horses Then Return 0` is the early-return form (setne/movzx/cmp/jne over a
'   `mov eax,0 / jmp end`) -- guide 10.3.
'   `g_horses.Sort(False)` supplies TList.Sort's default compareFunc at the call site,
'   which is the `push 0x005B3516` (_brl_linkedlist_CompareObjects) before `push 0`.
'   The five row cells are an ARRAY LITERAL, not New String[5] plus assignments.
	Function RefreshTableForSale:Int()
		'!Global g_stable_table:TTable
		'!Global g_horses:TList
		'!Global g_stable_maxrows:Int
		Local sel:Int = g_stable_table.GetSelectedItem()
		If sel < 0 Then sel = 0
		g_stable_table.ClearItems()
		If Not g_horses Then Return 0
		g_stable_maxrows = 30
		g_horses.Sort(False)
		For Local h:THorse = EachIn g_horses
			If h.owned = -1
				g_stable_table.AddItem([h.name, h.GetStringHealth(), h.GetStringForm(), FormatMoney(h.prize, 1), FormatMoney(h.GetValue(), 1)], "", "")
			EndIf
		Next
		g_stable_table.SelectItemByRow(sel)
	End Function

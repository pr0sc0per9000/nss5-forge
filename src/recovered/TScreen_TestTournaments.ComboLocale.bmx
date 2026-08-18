' TScreen_TestTournaments.ComboLocale  -- KIND=Function (static method on the Type), slot 0x3c
' VA 0x00538b36   496 bytes   sig ()i
' byte-identical vs NSS5.exe (496/496, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=28)
'
' ASSUMPTIONS (all Global names are ours; only the declared TYPES are load-bearing)
'  * 0x00C6644C : TCombo  (g_comboLocale)  -- construction-site typed, medium.
'                 Slots used: 0x8c ClearItems, 0x90 AddItem ($,$,$,i).
'  * 0x00C66444 : TCombo  (g_comboA)       -- construction-site typed, medium. Slot 0xbc
'                 GetSelectedItem.
'  * 0x00C66448 : TCombo  (g_comboB)       -- construction-site typed, medium. Slot 0xbc.
'  * 0x00C596F0 : TList   (g_nations)      -- globals_final.tsv says Object/usage/low.
'                 Slot 0x8c (ObjectEnumerator) is used on it, and the loop downcasts to
'                 ClassTable_TNation, so it is a TList of TNation.
'  * 0x00C6080C : TList   (g_continents)   -- same reasoning, downcast to TContinent.
'  * PTR_FUN_00C665E4 = TScreen_TestTournaments classtable + 0x40 = ComboBased ()i --
'    this Type's OWN table, so it is written unqualified (3d).
'  * TNation.HasLeagues is slot 0x74; n.name/n.id are TBase_Team.name (+0x10) and
'    TBase_Team.id (+0x0c), inherited. TContinent.name is +0x0c, .id is +0x08.
'  * String literals 0x00C7F250 = "BBBBBB" and 0x00C5D680 = "FFFFFF" (read from NSS5.exe).
'  * FUN_00505B91 = LogLine, ONE argument, function-entry trace (3g).
'
' CODEGEN NOTES
'  * All three dispatches are SELECT, not If/ElseIf (10.2): each is a run of cmp/je with
'    every target past the last compare, and the subject is evaluated once. As If/ElseIf
'    the body is 501 bytes and the very first dispatch already disagrees.
'  * The inner Select under the outer Case 2 has an EMPTY `Case 2`. It is invisible in the
'    decompilation -- Ghidra folds it away -- but it is worth exactly the 7 bytes the body
'    was short: `cmp eax,2` + `je` (5) for the test plus the case body's trailing
'    `EB 00` (2). The two 2-byte `EB 00` jumps at the tail are the tell.
'  * The `For EachIn` null-skip (cmp esi,bbNullObject / je) is emitted by the loop itself;
'    no explicit Null test is written (10.6).
'!Global g_comboLocale:TCombo
'!Global g_comboA:TCombo
'!Global g_comboB:TCombo
'!Global g_nations:TList
'!Global g_continents:TList
	Function ComboLocale:Int()
		LogLine("ComboLocale")
		g_comboLocale.ClearItems()
		Select g_comboA.GetSelectedItem()
			Case 1
				Select g_comboB.GetSelectedItem()
					Case 1
						For Local n:TNation = EachIn g_nations
							If n.HasLeagues()
								g_comboLocale.AddItem(n.name, "BBBBBB", "FFFFFF", n.id)
							End If
						Next
					Case 2
						For Local c:TContinent = EachIn g_continents
							g_comboLocale.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
						Next
				End Select
			Case 2
				Select g_comboB.GetSelectedItem()
					Case 1
						For Local c:TContinent = EachIn g_continents
							g_comboLocale.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
						Next
					Case 2
				End Select
		End Select
		ComboBased()
	End Function

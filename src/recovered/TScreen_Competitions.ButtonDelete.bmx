' TScreen_Competitions.ButtonDelete
' VA 0x0052fd8a   155 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (155/155, original length from Ghidra's inventory, mode=reloc)
' assumes module Global (name ours, type load-bearing): Global g_sc_table:TTable (0x00C65588)
'   globals_final lists this address as TButton with a CONFLICT (TButton=1;TTable=1); the
'   call is slot 0xD8, which only TTable has (TTable.GetSelectedText(i)$), so TTable it is.
' PTR_FUN_00C6160C = TCompetition class table + 0x4C -> SelectById(i):TCompetition
' PTR_FUN_00C61CC0 = TScreen class table + 0x94 -> TScreen.DoMessage($,i,i)i
' PTR_FUN_00C656F0 = this Type's own class table + 0x34 -> sibling SetUpScreen()
' the middle DoMessage argument is 1, not 0 (first_diff at byte 47 said `push 1`).
' string literals: "CMESSAGE_DELETECOMPETITION" (0x00C83CF4), "$comp" (0x00C83CDC), ":" (0x00C83CCC)
'!Global g_sc_table:TTable

	Function ButtonDelete:Int()
		Local c:TCompetition = TCompetition.SelectById(Int(g_sc_table.GetSelectedText(0)))
		If TScreen.DoMessage(GetText("CMESSAGE_DELETECOMPETITION").Replace("$comp", c.id + ":" + c.name), 1, 0) Then
			c.Destroy()
			SetUpScreen()
		EndIf
	End Function

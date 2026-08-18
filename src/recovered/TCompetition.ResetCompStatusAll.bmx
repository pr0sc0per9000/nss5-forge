' TCompetition.ResetCompStatusAll
' VA 0x0050E2BF   344 bytes   vtable slot 0x100   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (344/344, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C596F0 g_nations:TList and 0x00C6099C g_comps:TList -- both reached at
' slot 0x8C = TList.ObjectEnumerator.
' SortListBy is TCompetition + 0x11C reached through this Type's OWN class table, so it is
' a bare sibling call with no Type prefix.
' The comptype dispatch is a Select WITH a Default: the compares run back to back and the
' Default body follows the last compare directly, with no no-match jmp.
	Function ResetCompStatusAll()
		'!Global g_nations:TList
		'!Global g_comps:TList
		SortListBy(1,1)
		For Local nat:TNation = EachIn g_nations
			Local i:Int = 1
			For Local c:TCompetition = EachIn g_comps
				If c.level = 0 And c.locale = 0 And c.based = nat.id
					Select c.comptype
						Case 4
							c.compstatus = 1
						Case 0
							c.compstatus = i
							If c.townregion <> 1 And c.townregion <> 2
								i = i + 1
							End If
						Default
							c.compstatus = 0
					End Select
				End If
			Next
		Next
	End Function

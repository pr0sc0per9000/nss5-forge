' TScreen_EditCompetition.ButtonDeletePlace
' VA 0x0053225b   407 bytes   vtable slot 0x40   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (407/407, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' NEW MEASUREMENT: the original builds a String (`place + ': ' + comp.name`) and then
' DISCARDS it -- no store, no refcount traffic. A `Local s:String = ...` that is never
' read reproduces this exactly; bcc drops the dead store but still emits the concat.
' Verified by the match, 407/407.
'!Global g_editcomp_table:TTable
'!Global g_editcomp_comp:TCompetition
	Function ButtonDeletePlace:Int()
		Local sel:Int = g_editcomp_table.GetSelectedItem()
		Local i:Int = 1
		For Local pp:TPromotionPlace = EachIn g_editcomp_comp.lpromotionplaces
			If i = sel
				Local s:String = String(pp.place) + ": " + TCompetition.SelectById(pp.promotiontoid).name
				Local c:TCompetition = TCompetition.SelectById(pp.promotiontoid)
				For Local pp2:TPromotionPlace = EachIn c.lplacesthatpromotetome
					If pp2.promotiontoid = pp.promotiontoid And pp2.parentid = pp.parentid And pp2.place = pp.place
						c.lplacesthatpromotetome.Remove(pp2)
					EndIf
				Next
				g_editcomp_comp.lpromotionplaces.Remove(pp)
			EndIf
			i = i + 1
		Next
		TScreen_EditCompetition.SetUpScreen(g_editcomp_comp.id, "")
	End Function

' TScreen_MyContract.ComboNation
' VA 0x00555E51   337 bytes   vtable slot 0x58   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (337/337, mode=reloc, reloc_masked=17)
'
' ASSUMPTIONS (module Global names are ours; declared types are load-bearing):
'   g_mc_combonation   = 0x00C67DA4  TCombo
'   g_mc_combodivision = 0x00C67DA8  TCombo   (field 0x38 = TGadget.alive,
'                                              slot 0x70 = TGadget.SetAlph(f))
'   g_complist         = 0x00C6099C  TList    (globals_final says Object; slot 0x8C
'                                              ObjectEnumerator at the call site)
' The trailing call is this Type's class table + 0x5C -> bare sibling ComboDivision().

	Function ComboNation:Int()
		'!Global g_mc_combonation:TCombo
		'!Global g_mc_combodivision:TCombo
		'!Global g_complist:TList
		LogLine("ComboNation")
		Local sel:Int = g_mc_combonation.GetSelectedItemId()
		g_mc_combodivision.alive = 1
		g_mc_combodivision.SetAlph(1.0)
		If sel = 0
			g_mc_combodivision.alive = 0
			g_mc_combodivision.SetAlph(0.5)
		EndIf
		TCompetition.SortListBy(1,1)
		g_mc_combodivision.ClearItems()
		For Local c:TCompetition = EachIn g_complist
			If c.based = sel And c.comptype = 0 And c.level = 0 And c.duration > 1
				g_mc_combodivision.AddItem(c.labelname,"BBBBBB","FFFFFF",c.id)
			EndIf
		Next
		ComboDivision()
	End Function

' TScreen_TestTournaments.ComboBased  -- KIND=Function (static method on the Type), SLOT=0x40
' VA 0x00538D26   419 bytes   sig ()i
' byte-identical vs NSS5.exe (419/419, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=22)
'
' ASSUMPTIONS
'   * GLOBAL NAMES ARE OURS. Declared types are load-bearing (they pick the vtable slot):
'         0x00C66444  g_combo_level       :TCombo   (globals_final: construction, 1 site)
'         0x00C66448  g_combo_locale      :TCombo
'         0x00C6644C  g_combo_based       :TCombo
'         0x00C66450  g_tt_cmb_comp :TCombo
'           This screen's own competition combo, built by
'           TScreen_TestTournaments.CreateScreen:162 under that name. The
'           g_combo_competition spelling is TScreen_Continents' name for 0x00C671E8,
'           and extracted/global_alias_overrides.tsv:198 merges it onto
'           g_continents_combo, so these four statements drove the CONTINENTS screen's
'           team combo.
'         0x00C6099C  g_competitions      :TList    (globals_final says only "Object";
'                                                    typed TList here because the body
'                                                    calls slot 0x8C ObjectEnumerator on
'                                                    it -- guide 10.7)
'   * TCombo slots resolved from vtable_map.tsv: 0x8C ClearItems(), 0x90 AddItem($,$,$,i),
'     0xBC GetSelectedItem(), 0xC0 GetSelectedItemId().
'   * The three PTR_FUN_* indirect calls are class-table interiors, not Globals (guide 12.1):
'         0x00C59A20 = TNation+0x58  = SelectById(i):TNation
'         0x00C60998 = TContinent+0x40 = SelectById(i):TContinent
'         0x00C616DC = TCompetition+0x11c = SortListBy(i,i)i
'         0x00C665E8 = TScreen_TestTournaments+0x44 = ComboCompetition()  (sibling Function,
'                      so it is written unprefixed in the original's own Type -- both
'                      spellings emit the same call here)
'   * TCompetition field offsets from object_model.json: level 0x1C, locale 0x18,
'     based 0x20, labelname 0x14, id 0x08.  TBase_Team.id 0x0C is what TNation returns.
'
' FORM NOTES (each of these was measured, not assumed)
'   * `Case 2` in the second Select really is EMPTY in the original: its body is the two
'     bytes `EB 00` at 0x00538E21. Dropping it loses 5 bytes.
'   * Both multiway blocks are `Select`, not If/ElseIf -- the original emits every `cmp`
'     back to back at 0x00538DBC..0x00538DCB with all targets past the last compare
'     (guide 10.2). As If/ElseIf the body is 14 bytes short.
'   * The loop filter is three `If ... <> ... Then Continue` statements, not one `And`
'     chain: the original shows the `74 02 EB xx` Continue idiom three times
'     (guide 10.9). As an `And` chain it is 27 bytes long.
'   * The `- 1` on the level sits on the Local's initialiser (`sub eax,1` before the store
'     at 0x00538D5E), not inside the loop.
'   * `If n <> Null` (7-byte `cmp/je`), not `If n` (21-byte setne/movzx form, guide 10.3).
'!Global g_combo_level:TCombo
'!Global g_combo_locale:TCombo
'!Global g_combo_based:TCombo
'!Global g_tt_cmb_comp:TCombo
'!Global g_competitions:TList
	Function ComboBased()
		LogLine("ComboBased")
		g_tt_cmb_comp.ClearItems()
		Local lvl:Int = g_combo_level.GetSelectedItem() - 1
		Local loc:Int = -1
		Local basedid:Int = -1
		Select g_combo_level.GetSelectedItem()
			Case 1
				loc = g_combo_locale.GetSelectedItem() - 1
			Case 2
				loc = g_combo_locale.GetSelectedItem()
		End Select
		Select loc
			Case 0
				Local n:TNation = TNation.SelectById(g_combo_based.GetSelectedItemId())
				If n <> Null Then basedid = n.id
			Case 1
				Local c:TContinent = TContinent.SelectById(g_combo_based.GetSelectedItemId())
				If c <> Null Then basedid = c.id
			Case 2
		End Select
		TCompetition.SortListBy(1, 1)
		For Local comp:TCompetition = EachIn g_competitions
			If lvl <> comp.level Then Continue
			If loc <> comp.locale Then Continue
			If basedid <> comp.based Then Continue
			g_tt_cmb_comp.AddItem(comp.labelname, "BBBBBB", "FFFFFF", comp.id)
		Next
		TScreen_TestTournaments.ComboCompetition()
	End Function

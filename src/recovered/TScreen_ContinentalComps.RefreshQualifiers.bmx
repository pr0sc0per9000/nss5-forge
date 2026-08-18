' TScreen_ContinentalComps.RefreshQualifiers
' VA 0x005340C7   382 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x44
' ORACLE 382/382 reloc_masked=26, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
'
' ASSUMPTIONS / RESOLUTIONS
'  * Globals declared here (names are OURS; the TYPES are load-bearing because they select
'    the vtable slots):
'      g_cc_comp:TCompetition  at 0x00C65A24  (field +0x08 = TCompetition.id)
'      g_cc_table:TTable       at 0x00C65A4C  (slots 0x9C ClearItems, 0x94 AddItem([]$,$,$),
'                                              0xEC CountItems, 0xA0 SetColumnHeading(i,$))
'                              globals_final.tsv guesses TPlayer for this one -- it is WRONG;
'                              the slot set is TTable's.
'      g_clublist:TList        at 0x00C59A44  (slot 0x8C ObjectEnumerator; elements downcast
'                                              to ClassTable_TClub)
'  * Static calls resolved through class_tables/vtable_map:
'      [0x00C59E40] = TClub + 0x94   -> TClub.SortListBy(i,i)
'      [0x00C59A20] = TNation + 0x58 -> TNation.SelectById(i):TNation
'      0x004C5549 = GetText (ONE argument -- Ghidra merges the following pushes into it)
'      0x004A63D0 = _bbArrayNew1D (the String[] literal), 0x004A7AC0 = _bbStringFromInt,
'      0x004A7C20 = _bbStringConcat (three of them => four operands)
'  * Guard is the EARLY-RETURN form (`If Not g Then Return 0`): the block form is 367 bytes,
'    the early return is 382. See guide 3f/10.9.
'  * Field offsets: TClub inherits TBase_Team, so id=+0x0C, name=+0x10; nationid=+0x64 and
'    continentalcompid=+0x6C are TClub's own. The third array cell is TNation.name (+0x10),
'    NOT tla (+0x18) -- that single byte was the last one to diverge.
'  * String literal CONTENT is not byte-observable (all four addresses are masked), so the
'    oracle neither confirms nor refutes the texts below. Recover them with
'    harness.read_string(va) rather than trusting a MATCH for them (guide 13.2).
'!Global g_cc_comp:TCompetition
'!Global g_cc_table:TTable
'!Global g_clublist:TList
	Function RefreshQualifiers()
		If Not g_cc_comp Then Return 0
		g_cc_table.ClearItems()
		TClub.SortListBy(21, 1)
		For Local c:TClub = EachIn g_clublist
			If c.continentalcompid = g_cc_comp.id
				Local n:TNation = TNation.SelectById(c.nationid)
				g_cc_table.AddItem([String(c.id), c.name, n.name], "000000", "FFFFFF")
			End If
		Next
		g_cc_table.SetColumnHeading(1, GetText("Teams") + " (" + String(g_cc_table.CountItems()) + ")")
	End Function

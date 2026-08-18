' TScreen_Competitions.SetUpScreen   (KIND=Function -- static, no Self)
' VA 0x0052FAB3   644 bytes   class-table slot 0x34   sig ()i
' byte-identical vs NSS5.exe (644/644, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=644/644  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C65578 g_comp_combo1:TCombo   0x00C6557C g_comp_combo2:TCombo
'   0x00C65580 g_comp_combo3:TCombo   0x00C65584 g_comp_combo4:TCombo
'     (all four construction-site typed; the same first two are already used by the banked
'      TScreen_Competitions.ComboLevel)
'   0x00C65588 g_comptable:TTable     slots 0x9C ClearItems, 0x94 AddItem([]$,$,$) -- the
'     same correction the banked ButtonEdit records against globals_named.tsv's :TPlayer.
'   0x00C6099C g_complist:TList       slot 0x8C ObjectEnumerator, elements downcast to
'     ClassTable_TCompetition at 0x00C615C0.
' Class-table static calls resolved:
'   0x00C61C88 = TScreen+0x5C      -> SetActive($,$):TScreen
'   0x00C616DC = TCompetition+0x11C-> SortListBy(i,i)i
'   0x00C59A20 = TNation+0x58      -> SelectById(i):TNation
'   0x00C60998 = TContinent+0x40   -> SelectById(i):TContinent
' Fields: TCompetition locale(+0x18) level(+0x1C) based(+0x20) comptype(+0x24);
'   TNation id(+0xC, inherited from TBase_Team); TContinent id(+0x8).
'
' NOTE  Three Selects, not If/ElseIf -- every Case compare sits back to back ahead of any
'       body (pattern 10.2). The EMPTY `Case 2` in the middle Select is real: it emits the
'       lone `EB 00` at 0x0052FBEB, exactly like the banked TScreen_Stable.ButtonRace.
' NOTE  The four filters are `> -1` (cmp -1 / setg), NOT `>= 0` (pattern 10.1).
' NOTE  `ok` is a real Local held in ecx across all four filters; a chain of Continues or
'       a single compound If would not emit the four independent `mov ecx,0` stores.

'!Global g_comp_combo1:TCombo
'!Global g_comp_combo2:TCombo
'!Global g_comp_combo3:TCombo
'!Global g_comp_combo4:TCombo
'!Global g_comptable:TTable
'!Global g_complist:TList

TScreen.SetActive("competitions","")
TCompetition.SortListBy(1,1)
g_comptable.ClearItems()
Local lev:Int = g_comp_combo1.GetSelectedItem() - 1
Local loc:Int = -1
Select lev
	Case 0
		Select g_comp_combo2.GetSelectedItem()
			Case 1
				loc = 0
			Case 2
				loc = 1
		End Select
	Case 1
		Select g_comp_combo2.GetSelectedItem()
			Case 1
				loc = 1
			Case 2
				loc = 2
		End Select
End Select
Local bas:Int = -1
Select loc
	Case 0
		Local n:TNation = TNation.SelectById(g_comp_combo3.GetSelectedItemId())
		If n <> Null Then bas = n.id
	Case 1
		Local c:TContinent = TContinent.SelectById(g_comp_combo3.GetSelectedItemId())
		If c <> Null Then bas = c.id
	Case 2
End Select
Local ct:Int = g_comp_combo4.GetSelectedItem() - 1
For Local cp:TCompetition = EachIn g_complist
	Local ok:Int = 1
	If lev > -1 And cp.level <> lev Then ok = 0
	If loc > -1 And cp.locale <> loc Then ok = 0
	If bas > -1 And cp.based <> bas Then ok = 0
	If ct > -1 And cp.comptype <> ct Then ok = 0
	If ok
		g_comptable.AddItem(cp.GetStringArray(), "", "")
	EndIf
Next

' TScreen_Stats.ComboClub  ()i   slot 0x38   KIND=Function (static, no Self)
' VA 0x0054df94   470 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (470/470, original length from Ghidra's inventory)
' VA 0x0054DF94   length 470   oracle: MATCH mode=reloc 470/470 reloc_masked=29
'
' Assumptions:
'   '!Global g_stats_comboClub:TCombo   0x00C679C8  (globals_final: TCombo, construction/medium)
'   '!Global g_combo_year:TCombo   0x00C679CC  (globals_final: TCombo, construction/medium)
'   '!Global g_stats_comboYearInt:TCombo  0x00C679D8  (globals_final: TCombo, construction/medium)
'   '!Global g_profile:TProfile    0x00C6F028  (globals_final: TProfile, construction/high;
'       corroborated here -- +0x40 is TProfile.careerstats:TList and it is enumerated
'       through slot 0x8c, which is TList.ObjectEnumerator)
'   TCombo slots used: 0x8c ClearItems, 0x90 AddItem($,$,$,i), 0xac SelectItem(i),
'       0xb0 SelectItemById(i), 0xc0 GetSelectedItemId()i
'   PTR_FUN_00C67B04 = classtable TScreen_Stats + 0x3c = TScreen_Stats.UpdateStatTable,
'       i.e. a sibling Function -- written bare, with no Type prefix (guide 3d).
'   String literals read out of NSS5.exe as BlitzMax string objects:
'       0x00C84260 "Year"  0x00C6EF28 " "  0x00C5D680 "FFFFFF"  0x00C7F250 "BBBBBB"
'   FUN_004A7AC0 = _bbStringFromInt (1 arg -- Ghidra merges the FOLLOWING pushes into it),
'   FUN_004A7C20 = _bbStringConcat (2 args), FUN_004C5549 = the module Function GetText.
'   The real AddItem argument list was read off the pushes, not from Ghidra's merged form:
'       AddItem(<text>, "FFFFFF", "BBBBBB", s.year)  -- `add esp,0x14` = self + 4 args.
'
' Shape notes:
'   `s.year > best` is a SEPARATE nested If, not a third And term: it emits `cmp [ebx+0x10],esi
'   / jle` straight into the branch with no setcc/movzx, which an And term would require.
'   Operand order matters (guide 10.1): `s.year > best` gives `39` (mem,reg); `best < s.year`
'   would give `3B`.
Function ComboClub:Int()
	' 0x00C679C8 and 0x00C679D8 are this screen's own two combos, built by
' TScreen_Stats.CreateScreen:145 and :168 as cmb_Clubs and cmb_YearsInt.
' g_combo_club is TScreen_Leagues' name for 0x00C66F3C and g_combo_level is
' TScreen_TestTournaments' name for 0x00C66444, so both spellings put two screens'
' combos on one emitted variable.
	'!Global g_stats_comboClub:TCombo
	'!Global g_combo_year:TCombo
	'!Global g_stats_comboYearInt:TCombo
	'!Global g_profile:TProfile
	Local clubid:Int = g_stats_comboClub.GetSelectedItemId()
	g_combo_year.ClearItems()
	g_stats_comboYearInt.ClearItems()
	Local best:Int = 0
	For Local s:TStats_Team = EachIn g_profile.careerstats
		If s.statlevel = 3 And (s.teamid = clubid Or clubid = 0)
			If s.year > best
				g_combo_year.AddItem(GetText("Year") + " " + s.year, "BBBBBB", "FFFFFF", s.year)
				g_stats_comboYearInt.AddItem(GetText("Year") + " " + s.year, "BBBBBB", "FFFFFF", s.year)
				best = s.year
			EndIf
		EndIf
	Next
	If clubid = 0
		g_combo_year.SelectItem(0)
	Else
		g_combo_year.SelectItemById(best)
	EndIf
	g_stats_comboYearInt.SelectItem(0)
	UpdateStatTable()
End Function

' TScreen_Stats.SetUpScreen  -- KIND=Function (static), slot 0x34, sig ()i
' VA 0x0054DD51   579 bytes
' byte-identical vs NSS5.exe (579/579, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=35)
'
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C6F028 -> g_profile:TProfile   -- globals_final.tsv says TPlayer ("only TPlayer
'        has slots 0x30,0x34,0x3c,0x40"), which guide 11.2 warns is exactly the unsafe
'        uniqueness claim. Every field touched here is a TProfile field: +0x10 date:TMyDate
'        (slot 0x54 = TMyDate.GetYear), +0x40 careerstats:TList, +0x20 clubid,
'        +0x1C8 helppages:Int[].
'      0x00C679B0/0x00C679BC/0x00C679B4 -> TGadget  -- only slots 0x54 Hide / 0x58 Show are
'        used, both TGadget's own, so any subclass emits identical bytes; TGadget is the
'        least-committal choice.
'      0x00C679C8 -> g_stats_comboclub:TCombo -- slots 0x8C ClearItems, 0x90
'        AddItem($,$,$,i), 0xB0 SelectItemById(i) all match TCombo exactly.
'  * Class-table calls: 0x00C61C88 TScreen+0x5C SetActive($,$), 0x00C67B08
'    TScreen_Stats+0x40 UpdateHistoryTable, 0x00C67B00 TScreen_Stats+0x38 ComboClub,
'    0x00C61CE0 TScreen+0xB4 Tutorial, 0x00C59E0C TClub+0x60 SelectById(i).
'    TScreen_Stats' own two are written unprefixed (guide 3d).
'  * 0x005B40BF = CreateList (alias set; the following TList.AddLast at slot 0x44 settles
'    it, guide 10.8). 0x004A7130 = _bbStringToInt, 0x004A7AC0 = _bbStringFromInt.
'  * The year test is `> 1`, not `< 2`: `cmp eax,1 / jle` with the Show arm first
'    (guide 10.1 -- Ghidra prints the inverted form).
'  * Both inner downcasts to 0x005C7D60 are to BBString, i.e. the TList holds Strings.
'  * The `cmp eax,0x5C9C80 / je` right after each EachIn downcast is the loop's OWN
'    null-skip and must not be written (guide 10.6); the one after TClub.SelectById is a
'    real `If c <> Null`.
'  * String literals: 0x00C89360 "stats", 0x00C5D284 "" (pool literal),
'    0x00C7F250 "BBBBBB", 0x00C5D680 "FFFFFF".
'  * helppages[4] is `[eax+0x28]` = BBArray data (+0x18) + 4*4.
	Function SetUpScreen:Int()
		'!Global g_profile:TProfile
		'!Global g_stats_gad1:TGadget
		'!Global g_stats_gad2:TGadget
		'!Global g_stats_gad3:TGadget
		'!Global g_stats_comboclub:TCombo
		TScreen.SetActive("stats", "")
		g_stats_gad1.Hide()
		g_stats_gad2.Show()
		If g_profile.date.GetYear() > 1
			g_stats_gad3.Show()
		Else
			g_stats_gad3.Hide()
		End If
		UpdateHistoryTable()
		Local clubids:TList = CreateList()
		For Local st:TStats_Team = EachIn g_profile.careerstats
			If st.statlevel = 3
				Local found:Int = 1
				For Local s:String = EachIn clubids
					If Int(s) = st.teamid
						found = 0
					End If
				Next
				If found
					clubids.AddLast(String(st.teamid))
				End If
			End If
		Next
		g_stats_comboclub.ClearItems()
		For Local s:String = EachIn clubids
			Local c:TClub = TClub.SelectById(Int(s))
			If c <> Null
				g_stats_comboclub.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
			End If
		Next
		g_stats_comboclub.SelectItemById(g_profile.clubid)
		ComboClub()
		If g_profile.helppages[4] = 0
			TScreen.Tutorial()
			g_profile.helppages[4] = 1
		End If
	End Function

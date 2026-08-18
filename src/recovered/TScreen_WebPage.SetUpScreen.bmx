' TScreen_WebPage.SetUpScreen   (KIND=Function -- static, no Self)
' VA 0x00561066   721 bytes   class-table slot 0x34   sig ($,$)i
' ORACLE: mode=reloc  matched=721/721  reloc_masked=46  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C68900 g_webpage_name:String      full retain/release traffic around the store
'   0x00C68904 g_webpage_headline:String  ditto (globals_final calls both "Int (usage)")
'   0x00C688E8 g_webpage_lbl_headline:TLabel   construction site; slot 0x64 = TGadget.SetText
'   0x00C688EC g_webpage_lbl_comp:TLabel       construction site
'   0x00C688F0 g_webpage_table:TTable          slots 0x94 AddItem, 0x9C ClearItems,
'                                              0xE0 SelectItemByText, field +0x70 selecteditem
'   0x00C6F028 g_profile:TProfile              +0x20 clubid, +0x50 webheadline, +0x1D0 myclub
' Class-table static calls: TScreen+0x5C SetActive, TClub+0x60 SelectById,
'   TCompetition+0x4C SelectById. Module Function LogLine; 0x004A7410 = Lower.
' TCompetition.teampool is []:TTeamPool at +0x6C, so `comp.teampool[0]` is [eax+0x18]
' (BBArray data at +0x18) and the bare truth test `comp.teampool` reads size at +0x10
' (codegen-patterns 11.1). TClub's name fields live in its Super TBase_Team:
'   +0x18 tla, +0x1C labelname, +0x20 labelshortname.
'
' NOTES
'   * `Select comp.comptype` WITH a `Default`: the subject is loaded once, both Case
'     compares are emitted back to back, and the DEFAULT body sits in the fall-through
'     position immediately after them, ahead of the two Case bodies (codegen-patterns 10.2).
'   * The headline test is `a1.Length <> 0` with the a1 arm FIRST -- `cmp dword [ebx+8],0 /
'     je else`, two bytes. Spelling it `= 0` with the arms swapped costs 8 bytes more.
'   * `Local cid:Int = g_profile.clubid` is load-bearing: the original emits
'     `mov eax,[eax+0x20] / push eax` (4 bytes), not the direct `push dword [eax+0x20]`
'     (3 bytes) that the inline form gives. Codegen-patterns 16.5, in the direction where
'     the accumulator route is LONGER.

'!Global g_webpage_name:String
'!Global g_webpage_headline:String
'!Global g_webpage_lbl_headline:TLabel
'!Global g_webpage_lbl_comp:TLabel
'!Global g_webpage_table:TTable
'!Global g_profile:TProfile
g_webpage_name = a0
LogLine("Temp headline: " + a1)
LogLine("Player webheadline: " + g_profile.webheadline)
TScreen.SetActive("webpage", "btn_play")
If a1.Length <> 0
	g_webpage_headline = a1
Else
	g_webpage_headline = g_profile.webheadline
EndIf
g_webpage_lbl_headline.SetText(Lower(g_webpage_headline), "", -1, -1)
Local cid:Int = g_profile.clubid
Local comp:TCompetition = TCompetition.SelectById(TClub.SelectById(cid).GetActualLeagueId())
If comp <> Null And comp.teampool
	g_webpage_lbl_comp.SetText(comp.name, "", -1, -1)
	g_webpage_table.ClearItems()
	Select comp.comptype
		Case 2
			comp.teampool[0].SortTableBy(16)
		Case 3
			comp.teampool[0].SortTableBy(16)
		Default
			comp.teampool[0].SortTableBy(4)
	End Select
	Local i:Int = 1
	For Local td:TTableData = EachIn comp.teampool[0].list
		g_webpage_table.AddItem(td.GetStringArray(i, 1), "", "")
		i = i + 1
	Next
	comp.PaintPromotionPlaces(g_webpage_table)
	g_webpage_table.SelectItemByText(g_profile.myclub.labelshortname, 1)
	If g_webpage_table.selecteditem = -1
		g_webpage_table.SelectItemByText(g_profile.myclub.labelname, 1)
	EndIf
	If g_webpage_table.selecteditem = -1
		g_webpage_table.SelectItemByText(g_profile.myclub.tla, 1)
	EndIf
EndIf

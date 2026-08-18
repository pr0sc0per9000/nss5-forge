' TScreen_WorldMap.ButtonFilm   (KIND=Function -- static, no Self)
' VA 0x0055BA17   235 bytes   class-table slot 0x44   sig ()i
' ORACLE: mode=reloc  matched=235/235  reloc_masked=19  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C68428 g_worldmap_traveltime:Int   bare dword compare, no refcount traffic
'   0x00C6F028 g_profile:TProfile          construction site; slots 0xFC UpdateBank(i)i and
'                                          fields bank(+0x28) items(+0xF0) boughtfilm(+0x184)
'   0x00C683EC g_wm_lbl_money:TLabel       construction site; slot 0x64 = TGadget.SetText($,$,i,i)
' Class-table static calls resolved:
'   0x00C61CC0 = TScreen+0x94          -> TScreen.DoMessage($,i,i)i
'   0x00C68570 = TScreen_WorldMap+0x48 -> UpdateTravelTime()  [OWN type => no prefix]
' Module Functions: GetText (0x004C5549), FormatMoney (0x0050720B) -- both recovered.
' Literals read out of the exe with harness.read_string.
'
' NOTE  The guard is `<= 0` (cmp dword [g],0 / jg), NOT `< 1` (cmp [g],1 / jge).
'       Both are logically identical; only the first reproduces the bytes -- see
'       codegen-patterns 10.1.
' NOTE  items is []i, so the constant index folds to [eax+0x24] = items[3].

'!Global g_worldmap_traveltime:Int
'!Global g_profile:TProfile
'!Global g_wm_lbl_money:TLabel

If g_worldmap_traveltime <= 0
	TScreen.DoMessage(GetText("CMESSAGE_NOTTIRED"), 0, 0)
ElseIf g_profile.items[3] = 0
	TScreen.DoMessage(GetText("CMESSAGE_CANNOTBUYFILM"), 0, 0)
ElseIf g_profile.bank < 500
	TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
Else
	g_profile.UpdateBank(-500)
	g_wm_lbl_money.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
	g_profile.boughtfilm = 1
	TScreen_WorldMap.UpdateTravelTime()
EndIf

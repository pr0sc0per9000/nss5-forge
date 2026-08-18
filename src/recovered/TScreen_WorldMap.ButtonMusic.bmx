' TScreen_WorldMap.ButtonMusic   (KIND=Function -- static, no Self)
' VA 0x0055B92C   235 bytes   class-table slot 0x40   sig ()i
' ORACLE: mode=reloc  matched=235/235  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' Third member of the world-map "buy a distraction" family; ButtonFilm (0x0055BA17) and
' ButtonGame (0x0055B84A) are already banked and supplied the entire segmentation --
' only the item index, the price and the bought-flag field differ (patterns 16.4).
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C68428 g_worldmap_traveltime:Int   bare dword compare, no refcount traffic
'   0x00C6F028 g_profile:TProfile          construction site; slot 0xFC UpdateBank(i)i and
'                                          fields bank(+0x28) items(+0xF0) boughtmusic(+0x17C)
'   0x00C683EC g_wm_lbl_money:TLabel       construction site; slot 0x64 = TGadget.SetText($,$,i,i)
' Class-table static calls resolved:
'   0x00C61CC0 = TScreen+0x94          -> TScreen.DoMessage($,i,i)i
'   0x00C68570 = TScreen_WorldMap+0x48 -> UpdateTravelTime()  [OWN type => no prefix]
' Module Functions: GetText (0x004C5549), FormatMoney (0x0050720B) -- both recovered.
' Literals read out of the exe with harness.read_string.
'
' NOTE  The guard is `<= 0` (cmp dword [g],0 / jg), NOT `< 1` -- see codegen-patterns 10.1.
' NOTE  items is []i, so `+0xF0` then `[eax+0x20]` folds to items[2] (data at +0x18).

'!Global g_worldmap_traveltime:Int
'!Global g_profile:TProfile
'!Global g_wm_lbl_money:TLabel

If g_worldmap_traveltime <= 0
	TScreen.DoMessage(GetText("CMESSAGE_NOTTIRED"), 0, 0)
ElseIf g_profile.items[2] = 0
	TScreen.DoMessage(GetText("CMESSAGE_CANNOTBUYMUSIC"), 0, 0)
ElseIf g_profile.bank < 250
	TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
Else
	g_profile.UpdateBank(-250)
	g_wm_lbl_money.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
	g_profile.boughtmusic = 1
	TScreen_WorldMap.UpdateTravelTime()
EndIf

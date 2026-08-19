' TScreen_WorldMap.ButtonGame
' VA 0x0055B84A   226 bytes   vtable slot 0x3c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (226/226, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C68428 g_screen_worldmap_int01:Int  (tested `<= 0`, i.e. cmp [g],0 / jg)
'   0x00C6F028 g_contractoffer_tplayer:TProfile
'   0x00C683EC :TLabel -- the cash readout on the world map; slot 0x64 is the inherited
'     TGadget.SetText($,$,i,i), which is why the call carries "" , -1, -1
'   TProfile +0x28 bank, +0xF0 items ([]i, tested at element 1), +0x180 boughtgame,
'     slot 0xFC = TProfile.UpdateBank(i)
'   FormatMoney is the recovered module Function, sig (i,i)$ -- the `add esp,8` after it
'     proves only two of the five pushed dwords belong to it.
	Function ButtonGame:Int()
		'!Global g_screen_worldmap_int01:Int
		'!Global g_profile:TProfile
		'!Global g_worldmap_lblcash:TLabel
		If g_screen_worldmap_int01 <= 0
			TScreen.DoMessage(GetText("CMESSAGE_NOTTIRED"), 0, 0)
		ElseIf g_profile.items[1] = 0
			TScreen.DoMessage(GetText("CMESSAGE_CANNOTBUYGAME"), 0, 0)
		ElseIf g_profile.bank < 100
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
		Else
			g_profile.UpdateBank(-100)
			g_worldmap_lblcash.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
			g_profile.boughtgame = 1
			TScreen_WorldMap.UpdateTravelTime()
		End If
	End Function

' ItemTooltip  -- module-level Function (no Type)
' VA 0x00507a8c   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Maps a 1..10 item index to its tooltip text, shown on the item shop's
' "buy" button. The ten keys are read out of NSS5.exe as BlitzMax string objects at the
' pushed addresses, not guessed. The callee is the already-verified module Function GetText
' (0x004C5549), so its E8 masks by name on both sides.
'
' The key naming is not tidy -- indices 1-4 use "tt_" keys (tt_Phone, tt_GamesConsole,
' tt_MusicPlayer, tt_Tablet) while indices 5-10 use "item_" keys (item_TV,
' item_DesignerSuit, item_SilverChain, item_GoldRing, item_Earrings, item_Watch) --
' reproduced as found, not tidied (guide 16.8).
'
' The trailing Return "" is a real statement, not the implicit end-of-function return: the
' default arm loads the shared empty-string object at 0x005C7D40 and the Select has no
' Default of its own. Sibling of PropertyTooltip/VehicleTooltip (same 237-byte shape),
' called once from TScreen_Shop.CreateScreen.
	Function ItemTooltip:String(a0:Int)
		Select a0
			Case 1
				Return GetText("tt_Phone")
			Case 2
				Return GetText("tt_GamesConsole")
			Case 3
				Return GetText("tt_MusicPlayer")
			Case 4
				Return GetText("tt_Tablet")
			Case 5
				Return GetText("item_TV")
			Case 6
				Return GetText("item_DesignerSuit")
			Case 7
				Return GetText("item_SilverChain")
			Case 8
				Return GetText("item_GoldRing")
			Case 9
				Return GetText("item_Earrings")
			Case 10
				Return GetText("item_Watch")
		End Select
		Return ""
	End Function

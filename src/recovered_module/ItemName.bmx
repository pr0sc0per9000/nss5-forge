' ItemName  -- module-level Function (no Type)
' VA 0x0050799f   237 bytes   sig (i)$
' byte-identical vs NSS5.exe (237/237, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Maps a 1..10 item index to its localised display name. The ten keys are
' read out of NSS5.exe as BlitzMax string objects at the pushed addresses, not guessed.
' The callee is the already-verified module Function GetText (0x004C5549), so its E8
' masks by name on both sides.
'
' The trailing Return "" is a real statement, not the implicit end-of-function return:
' the default arm loads the shared empty-string object at 0x005C7D40 and the Select has
' no Default of its own. One of three 237-byte siblings sharing this exact shape
' (0x005075EB / 0x005077C5 / 0x0050799F); a fourth, 0x00508131, does NOT share it.
	Function ItemName:String(a0:Int)
		Select a0
			Case 1
				Return GetText("item_Phone")
			Case 2
				Return GetText("item_GamesConsole")
			Case 3
				Return GetText("item_MusicPlayer")
			Case 4
				Return GetText("item_Tablet")
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

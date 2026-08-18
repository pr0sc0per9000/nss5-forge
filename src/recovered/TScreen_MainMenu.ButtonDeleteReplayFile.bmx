' TScreen_MainMenu.ButtonDeleteReplayFile
' VA 0x0051d8d3   172 bytes   vtable slot 0x?   sig ()i
' byte-identical vs NSS5.exe (172/172, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C639E4 declared TTable (globals_final.tsv, construction-site typed);
'   0x00C6E9A8 is a String Global whose static initialiser is "" -- a user/data path prefix.
'   Ghidra shows THREE bbStringConcat calls, so the DeleteFile argument is built from FOUR
'   pieces; without the leading Global the body is 157 bytes.
'   0x00C6B274 = TScreenMessage class table + 0x40 = ClearAll(i);
'   0x00C61CC0 = TScreen class table + 0x94 = DoMessage($,i,i):i;
'   0x00C63CC8 = TScreen_MainMenu class table + 0x5C = sibling Function UpdateReplayTable().
'   FUN_004C5549 = recovered module Function GetText; FUN_004A75B0 = _bbStringReplace.
'!Global g_mainmenu_replaytable:TTable
'!Global g_userpath:String
	Function ButtonDeleteReplayFile()
		Local f:String = g_mainmenu_replaytable.GetSelectedText(0)
		If f <> ""
			TScreenMessage.ClearAll(1)
			If TScreen.DoMessage(GetText("CMESSAGE_FILECONFIRMDELETE").Replace("$filename", f), 1, 0)
				DeleteFile(g_userpath + "Replays/" + f + ".rep")
			End If
		End If
		UpdateReplayTable()
	End Function

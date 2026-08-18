' TPromotionPlace.SaveMaster
' VA 0x00526150   291 bytes   vtable slot 0x?   sig (i,i)i
' byte-identical vs NSS5.exe (291/291, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C6E950 is a String Global (a data-path prefix, statically "").
'   0x00C61CC0 = TScreen class table + 0x94 = DoMessage($,i,i)i;
'   0x00C616D0 = TCompetition + 0x110 = SortPromotionPlacesAll();
'   0x00C64790 = TPromotionPlace + 0x3C = sibling Function WriteData(:TStream).
'   FUN_005B5A99 = FileType, FUN_005B5578 = StripDir, FUN_005B65FC = WriteFile,
'   FUN_004A75B0 = _bbStringReplace, FUN_004C5549 = module Function GetText.
'   Three shape facts, measured: the first And term is bare `a0` not `a0 <> 0` (2 bytes);
'   the stream test is the `If Not s` emission not `s = Null` (9 bytes); and the failure
'   branch is an EARLY RETURN, not an Else (5 bytes).
'!Global g_datapath:String
	Function SaveMaster(a0:Int, a1:Int)
		Local f:String = g_datapath + "GameMedia/Data/PromotionPlaces.csv"
		If a1 <> 0
			f = g_datapath + "GameMedia/Data/Mobile/PromotionPlaces.txt"
		End If
		If a0 And FileType(f) = 1 And TScreen.DoMessage(GetText("CMESSAGE_OVERWRITEFILE").Replace("$filename", StripDir(f)), 1, 0) = 0
			Return 0
		End If
		Local s:TStream = WriteFile("utf8::" + f)
		If Not s
			TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", StripDir(f)), 0, 0)
			Return 0
		End If
		TCompetition.SortPromotionPlacesAll()
		WriteData(s)
	End Function

' TNation.SaveMaster
' VA 0x004beac8   318 bytes   vtable slot 0x?   sig (i,i)i
' byte-identical vs NSS5.exe (318/318, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C6E950 is a String Global (data-path prefix, statically "").
'   0x00C61CC0 = TScreen class table + 0x94 = DoMessage($,i,i)i;
'   0x00C59A40 / 0x00C59A14 / 0x00C59A18 = TNation + 0x78 / 0x4C / 0x50 = sibling Functions
'   SortListBy(i,i), WriteData(:TStream), WriteDataMobile(:TStream).
'   Same three shape facts as TPromotionPlace.SaveMaster (bare `a0`, `If Not s`, early return).
'   The final branch tests `a1 <> 0` with the MOBILE writer in the then-arm: the original is
'   `cmp edi,0 / je <else>`, so writing `If a1 = 0 / WriteData / Else / WriteDataMobile`
'   is the same 318 bytes but differs at byte 280.
'!Global g_datapath:String
	Function SaveMaster(a0:Int, a1:Int)
		Local f:String = g_datapath + "GameMedia/Data/Nations.csv"
		If a1 <> 0
			f = g_datapath + "GameMedia/Data/Mobile/Nations.txt"
		End If
		If a0 And FileType(f) = 1 And TScreen.DoMessage(GetText("CMESSAGE_OVERWRITEFILE").Replace("$filename", StripDir(f)), 1, 0) = 0
			Return 0
		End If
		Local s:TStream = WriteFile("utf8::" + f)
		If Not s
			TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", StripDir(f)), 0, 0)
			Return 0
		End If
		SortListBy(1, 1)
		If a1 <> 0
			WriteDataMobile(s)
		Else
			WriteData(s)
		End If
	End Function

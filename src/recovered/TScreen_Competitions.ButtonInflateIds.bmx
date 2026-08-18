' TScreen_Competitions.ButtonInflateIds
' VA 0x0052fe94   74 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (74/74, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C6EF50 declared :Int.
' 0x00C61CC0 = TScreen class table + 0x94 = TScreen.DoMessage($,i,i)i.
' 0x00C6166C = TCompetition class table + 0xac = InflateIds()i.
' 0x00C656F0 = TScreen_Competitions class table + 0x34 = SetUpScreen()i.
' 0x004C5549 = recovered module Function GetText; literal text is not load-bearing.
' The guard is an EARLY RETURN, not an enclosing If -- the If form is 67 bytes.
	Function ButtonInflateIds:Int()
		'!Global g_engine_int161:Int
		If g_engine_int161 = 0 Then Return 0
		If TScreen.DoMessage(GetText("CMESSAGE_INFLATEIDS"), 1, 0)
			TCompetition.InflateIds()
			TScreen_Competitions.SetUpScreen()
		EndIf
	End Function

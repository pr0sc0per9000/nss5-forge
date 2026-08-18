' TScreen_Competitions.ButtonCompressIds
' VA 0x0052fede   74 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (74/74, original length from Ghidra's inventory)
' assumptions: Global 0x00c6ef50 declared Int (globals_final: g_engine_int161).
' 0x00c61cc0 = TScreen classtable+0x94 -> TScreen.DoMessage($,i,i)i;
' 0x00c61670 = TCompetition+0xb0 -> TCompetition.CompressIds();
' 0x00c656f0 = this Type's own classtable+0x34 so SetUpScreen() is unqualified.
' 0x00c83d68 = "CMESSAGE_COMPRESSIDS". The guard is an early return (If-block form is 67 bytes).
	Function ButtonCompressIds:Int()
		'!Global g_engine_int161:Int
		If g_engine_int161 = 0 Then Return 0
		If TScreen.DoMessage(GetText("CMESSAGE_COMPRESSIDS"), 1, 0)
			TCompetition.CompressIds()
			SetUpScreen()
		EndIf
	End Function

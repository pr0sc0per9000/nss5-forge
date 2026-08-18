' TContinent.LoadData
' VA 0x00508B7D   285 bytes   vtable slot 0x34
' byte-identical vs NSS5.exe (285/285, original length from Ghidra's inventory, mode=reloc)
'
' g_continents:TList is the Global at 0x00C6080C (slots 0x34 Clear and 0x70 Count are used).
' Same While/Wend shape as TPromotionPlace.LoadData; the "//" terminator is an early
' `Return 0` inside the loop, not an `Exit`.
	Function LoadData:Int(a0:TStream)
		'!Global g_datapath:String
		'!Global g_continents:TList
		If g_continents <> Null Then g_continents.Clear()
		If Not a0 Then a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Continents.csv")
		If Not a0
			Notify("Could not load GameMedia/Data/Continents.csv", 0)
			End
		EndIf
		LogLine("TContinent.LoadData")
		ReadLine(a0)
		While Not Eof(a0)
			Local l:String = ReadLine(a0)
			If l = "//"
				LogLine("Continents:" + String(g_continents.Count()))
				Return 0
			EndIf
			TContinent.CreateContinent(l)
		Wend
		CloseStream(a0)
	End Function

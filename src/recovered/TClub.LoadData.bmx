' TClub.LoadData
' VA 0x004C09F9   285 bytes   vtable slot 0x50   sig (:TStream)i
' byte-identical vs NSS5.exe (285/285, original length from Ghidra's inventory)

'!Global g_clubs:TList
'!Global g_datapath:String
If g_clubs <> Null Then g_clubs.Clear()
If Not a0 Then a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Clubs.csv")
If Not a0
	Notify("Could not load GameMedia/Data/Clubs.csv", 0)
	End
EndIf
LogLine("TClub.LoadData")
ReadLine(a0)
While Not Eof(a0)
	Local l:String = ReadLine(a0)
	If l = "//"
		LogLine("Clubs:" + g_clubs.Count())
		Return 0
	EndIf
	CreateClub(l)
Wend
CloseFile(a0)

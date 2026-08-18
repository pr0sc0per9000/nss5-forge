' TCompetition.LoadData
' VA 0x00509C2D   360 bytes   mode=reloc   byte-identical vs NSS5.exe (360/360)
' KIND=Function (static), SIG (:TStream)i, slot 0x3C
' ASSUMPTIONS
'   0x00C6099C -> g_competitions:TList  (slot 0x34 Clear, 0x70 Count, 0x8C elsewhere)
'   0x00C6E950 -> g_datapath:String     (the data-path prefix Global, as TStadium.LoadData)
'   0x00C61CC0 = TScreen + 0x94 = DoMessage($,i,i)i -- a static call, not Notify.
'   Alias sets resolved by context (3h): 0x005B80B9 = Eof, 0x005B812B = CloseStream,
'   0x005B82EF = ReadLine.
'   `edi` is a real source Local: it is set to 1 BEFORE the null test and cleared inside the
'   ReadFile branch, then selects which CreateCompetition overload argument is passed.
'   String literals read out of .data with harness.read_string.
'!Global g_competitions:TList
'!Global g_datapath:String
If g_competitions <> Null Then g_competitions.Clear()
Local usestream:Int = 1
If Not a0
	a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Competitions.csv")
	usestream = 0
EndIf
If Not a0
	TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", "Competitions.csv"), 0, 0)
	Return 0
EndIf
LogLine("TCompetition.LoadData")
ReadLine(a0)
While Not Eof(a0)
	Local l:String = ReadLine(a0)
	If l = "//"
		LogLine("Competitions:" + g_competitions.Count())
		Return 0
	EndIf
	If usestream = 0
		TCompetition.CreateCompetition(l, Null)
	Else
		TCompetition.CreateCompetition(l, a0)
	EndIf
Wend
CloseStream(a0)

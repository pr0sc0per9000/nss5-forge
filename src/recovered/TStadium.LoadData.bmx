' TStadium.LoadData
' VA 0x00527897   226 bytes   vtable slot 0x34   sig (:TStream)i
' byte-identical vs NSS5.exe (226/226, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C64BC0 is the stadium TList (slot 0x34 = TList.Clear). 0x00C6E950 is a String Global
' (the data-path prefix; its static image value is the empty-string literal at 0x00C5D284).
' String literals read out of .data: "utf8::", "GameMedia/Data/Stadiums.csv",
' "Could not load GameMedia/Data/Stadiums.csv", "//".
' BRL callees: 0x005B65E3 = ReadFile, 0x005B82EF = ReadLine, 0x005B80B9 = Eof,
' 0x005B812B = CloseStream, 0x005B4C68 = Notify, 0x004A4620 = `End`.
' 0x005B80B9 and 0x005B812B are ALIAS SETS; Eof and CloseStream are the members that fit a
' TStream loop (see codegen-patterns 3h).
' 0x00C64D08 = TStadium + 0x30 (CreateStadium($)).
' Two things are load-bearing here:
'   * the stream calls are FREE FUNCTIONS -- `ReadLine(a0)` not `a0.ReadLine()`. The method
'     form emits `mov eax,[ebx]/call [eax+0x8c]` and costs 3 bytes per call.
'   * both stream guards use the object->Int cast form `If Not a0` (setne/movzx/cmp 0), not
'     the fused `If a0 = Null`; the fused form is 6 bytes short each.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_stadiums:TList
'   Global g_datapath:String
	Function LoadData:Int(a0:TStream)
		'!Global g_stadiums:TList
		'!Global g_datapath:String
		If g_stadiums <> Null Then g_stadiums.Clear()
		If Not a0 Then a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Stadiums.csv")
		If Not a0 Then
			Notify("Could not load GameMedia/Data/Stadiums.csv", 0)
			End
		End If
		ReadLine(a0)
		While Not Eof(a0)
			Local line:String = ReadLine(a0)
			If line = "//" Then Return 0
			TStadium.CreateStadium(line)
		Wend
		CloseStream(a0)
	End Function

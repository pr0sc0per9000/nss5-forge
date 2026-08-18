' TPromotionPlace.LoadData
' VA 0x00525F17   219 bytes   vtable slot 0x38
' byte-identical vs NSS5.exe (219/219, original length from Ghidra's inventory, mode=reloc)
'
' g_datapath:String is the Global at 0x00C6E950 (initialised to "").
' Both Null tests are the `If Not x` form (setne/movzx/cmp/jne), not `If x = Null`.
' The loop is `While Not Eof(...) ... Wend` with CloseStream AFTER the Wend; Ghidra
' renders a bottom-tested While by hoisting the tail into the Eof branch.
	Function LoadData:Int(a0:TStream)
		'!Global g_datapath:String
		If Not a0 Then a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/PromotionPlaces.csv")
		If Not a0
			Notify("Could not load GameMedia/Data/PromotionPlaces.csv", 0)
			End
		EndIf
		LogLine("TPromotionPlace.LoadData")
		ReadLine(a0)
		While Not Eof(a0)
			Local l:String = ReadLine(a0)
			If l = "//" Then Return 0
			TPromotionPlace.CreatePromotionPlace(l)
		Wend
		CloseStream(a0)
		TCompetition.SortPromotionPlacesAll()
	End Function

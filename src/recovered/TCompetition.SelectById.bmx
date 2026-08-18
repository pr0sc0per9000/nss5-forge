' TCompetition.SelectById
' VA 0x0050a60f   102 bytes   vtable slot 0x4c   sig (i):TCompetition
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' assumes module global:  Global g_competitions:TList  (0x00c6099c)
' loop downcast class table is TCompetition (0x00c615c0); no Null guard on the list here
' (contrast TContinent.SelectById, which does guard)

	Function SelectById:TCompetition(a0:Int)
		'!Global g_competitions:TList
		For Local c:TCompetition = EachIn g_competitions
			If c.id = a0 Then Return c
		Next
		Return Null
	End Function

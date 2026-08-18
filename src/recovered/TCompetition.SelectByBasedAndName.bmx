' TCompetition.SelectByBasedAndName
' VA 0x0050a675   144 bytes   vtable slot 0x54   sig (i,$):TCompetition
' byte-identical vs NSS5.exe (144/144, original length from Ghidra's inventory)
' assumption: module Global at 0x00c6099c declared as g_comps:TList
	Function SelectByBasedAndName:TCompetition(a0:Int,a1:String)
		'!Global g_comps:TList
		For Local c:TCompetition=EachIn g_comps
			If c.based=a0 And c.name=a1 Then Return c
		Next
		Return Null
	End Function

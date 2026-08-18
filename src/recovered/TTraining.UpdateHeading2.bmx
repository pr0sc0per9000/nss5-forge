' TTraining.UpdateHeading2
' VA 0x00580e8a   196 bytes   vtable slot 0x7c   sig ()i
' byte-identical vs NSS5.exe (196/196, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C6D568 declared :TList (iterated twice with the
' 0x8c/0x30/0x34 TList/TListEnum slot triple). Downcast class tables 0x00C6D770 = TCone
' and 0x00C6DC1C = TTrainingLine, so the two loops walk the same heterogeneous list with
' different element types. Fields are inherited from TTrainingObject: frame +0xc,
' alive +0x18. 0x00C6D53C = TTraining class table + 0x98 = Success()i.
	Function UpdateHeading2:Int()
		'!Global g_trainingobs:TList
		For Local c:TCone = EachIn g_trainingobs
			If c.alive = 0
				c.frame = 1
			EndIf
		Next
		Local n:Int = 0
		For Local l:TTrainingLine = EachIn g_trainingobs
			If l.alive <> 0
				n = n + 1
			EndIf
		Next
		If n = 0
			TTraining.Success()
		EndIf
	End Function

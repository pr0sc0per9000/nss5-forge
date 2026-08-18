' TTrainingObject.UpdateAll
' VA 0x00582d30   121 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' assumes module global:  Global g_Object813:TList  (0x00c6d568, the training-object list;
' the same global TTarget.Clear removes itself from)
' 'If Not (x <> Null) / Else' is load-bearing -- see TMyGfxModes.OnListAlready.
	Function UpdateAll:Int()
		'!Global g_Object813:TList
		If Not (g_Object813 <> Null)
			Return 0
		Else
			For Local o:TTrainingObject = EachIn g_Object813
				o.Update()
			Next
		EndIf
	End Function

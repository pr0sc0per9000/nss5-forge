' TDummy.ResetDummies
' VA 0x00583481   98 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory)
' assumes module global:  Global g_dummies:TList  (0x00c6d568)
' the loop downcast class table is TDummy (0x00c6d898); alive/frame are inherited
' from TTrainingObject at +0x18 / +0x0c

	Function ResetDummies:Int()
		'!Global g_dummies:TList
		For Local d:TDummy = EachIn g_dummies
			d.alive = 1
			d.frame = 0
		Next
	End Function

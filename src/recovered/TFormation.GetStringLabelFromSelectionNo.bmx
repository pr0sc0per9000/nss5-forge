' TFormation.GetStringLabelFromSelectionNo
' VA 0x004D9AAB   232 bytes   vtable slot 0x6c   sig (i)$
' byte-identical vs NSS5.exe (232/232, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_formation_str01:String
' module global assumed: Global g_formation_str02:String
' module global assumed: Global g_formation_str03:String
' module global assumed: Global g_formation_str04:String
' module global assumed: Global g_formation_str05:String
' module global assumed: Global g_formation_str06:String
' module global assumed: Global g_formation_str07:String
' module global assumed: Global g_formation_str08:String
' module global assumed: Global g_formation_str09:String

	Method GetStringLabelFromSelectionNo:String(a0:Int)
		'!Global g_formation_str04:String
		'!Global g_formation_str05:String
		'!Global g_formation_str06:String
		'!Global g_formation_str07:String
		'!Global g_formation_str08:String
		'!Global g_formation_str09:String
		'!Global g_formation_str01:String
		'!Global g_formation_str02:String
		'!Global g_formation_str03:String
		If a0 = 0 Then Return g_formation_str04
		If a0 > 10 Then Return String(a0 + 1)
		Local s:String = ""
		Select GetPosFromSelectionNo(a0)
			Case 1
				s = g_formation_str05
			Case 2
				s = g_formation_str06
			Case 3
				s = g_formation_str07
			Case 4
				s = g_formation_str08
			Case 5
				s = g_formation_str09
		End Select
		Select GetSideFromSelectionNo(a0)
			Case 0
				s :+ g_formation_str01
			Case 1
				s :+ g_formation_str02
			Case 2
				s :+ g_formation_str03
		End Select
		Return s
	End Method

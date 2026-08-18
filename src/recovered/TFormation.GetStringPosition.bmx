' TFormation.GetStringPosition
' VA 0x004D9B93   220 bytes   vtable slot 0x70   sig (i,i)$
' byte-identical vs NSS5.exe (220/220, original length from Ghidra's inventory)
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

	Function GetStringPosition:String(a0:Int, a1:Int)
		'!Global g_formation_str04:String
		'!Global g_formation_str05:String
		'!Global g_formation_str06:String
		'!Global g_formation_str07:String
		'!Global g_formation_str08:String
		'!Global g_formation_str09:String
		'!Global g_formation_str01:String
		'!Global g_formation_str02:String
		'!Global g_formation_str03:String
		Local s:String = ""
		Select a0
			Case 0
				s = g_formation_str04
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
		Select a1
			Case 0
				s :+ " " + g_formation_str01
			Case 1
				s :+ " " + g_formation_str02
			Case 2
				s :+ " " + g_formation_str03
		End Select
		Return s
	End Function

' TStadium.SelectById
' VA 0x00527ad2   130 bytes   vtable slot 0x3c   sig (i):TStadium
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory)
' assumes module global:  Global g_Object280:TList  (0x00c64bc0, the all-stadiums list)
' 'If Not (x <> Null) / Else' is load-bearing -- see TMyGfxModes.OnListAlready.
	Function SelectById:TStadium(a0:Int)
		'!Global g_Object280:TList
		If Not (g_Object280 <> Null)
			Return Null
		Else
			For Local s:TStadium = EachIn g_Object280
				If s.id = a0 Then Return s
			Next
			Return Null
		EndIf
	End Function

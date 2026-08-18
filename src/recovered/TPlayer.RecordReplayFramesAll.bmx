' TPlayer.RecordReplayFramesAll
' VA 0x004fe335   136 bytes   vtable slot 0x200   sig (i)i
' byte-identical vs NSS5.exe (136/136, original length from Ghidra's inventory)
' assumes module global:  Global g_Object79:TList  (0x00c5de10, the all-players list)
' 'If Not (x <> Null) / Else' is load-bearing -- see TMyGfxModes.OnListAlready.
	Function RecordReplayFramesAll:Int(a0:Int)
		'!Global g_Object79:TList
		If Not (g_Object79 <> Null)
			Return 0
		Else
			For Local p:TPlayer = EachIn g_Object79
				p.RecordReplayFrame(a0)
			Next
		EndIf
	End Function

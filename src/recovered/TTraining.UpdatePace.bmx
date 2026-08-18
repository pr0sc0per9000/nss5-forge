' TTraining.UpdatePace
' VA 0x005800C9   766 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (766/766, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only.
' 0x00C6CFC8 / 0x00C6CFCC are TTrainingZone (construction sites); 0x00C6D568 is the TList
' the two EachIn loops walk (class tables 0x00C6DC1C = TTrainingLine, 0x00C6D9A4 = TPole).
' The second ImagesCollide2 is the RIGHT operand of an And and is truth-tested bare
' (no setcc); the first is compared '= 0' as its own If.
'!Global g_Object811:TTrainingZone
'!Global g_Object812:TTrainingZone
'!Global g_Object813:TList
'!Global g_training_int05:Int
'!Global g_player_float02:Float
Local p:TPlayer = TPlayer.GetHumanPlayer()
If p <> Null And g_Object811 <> Null And g_training_int05 = 1 Then
	If ImagesCollide2(p.imgPlayer, Int(p.x), Int(p.y), p.frame, 0, g_player_float02, g_player_float02, g_Object811.img, Int(g_Object811.x), Int(g_Object811.y), 0, 0, g_player_float02 * g_Object811.scl, g_player_float02 * g_Object811.scl) = 0 Then
		g_Object811.alive = 0
		g_Object811 = Null
	EndIf
EndIf
Local n:Int = 0
For Local ln:TTrainingLine = EachIn g_Object813
	If ln.alive Then n = n + 1
Next
If n = 0 Then
	g_Object812.colour = "00FF00"
	If p <> Null And ImagesCollide2(p.imgPlayer, Int(p.x), Int(p.y), p.frame, 0, g_player_float02, g_player_float02, g_Object812.img, Int(g_Object812.x), Int(g_Object812.y), 0, 0, g_player_float02 * g_Object812.scl, g_player_float02 * g_Object812.scl) Then
		For Local po:TPole = EachIn g_Object813
			If po.colour <> "FFFF00" Then
				TTraining.Fail()
				Return 0
			EndIf
		Next
		TTraining.Success()
	EndIf
EndIf

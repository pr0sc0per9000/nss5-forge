' TTraining.UpdateDribbling
' VA 0x005803C7   922 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (922/922, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only.
' Sibling of TTraining.UpdatePace (0x005800C9) -- identical opening zone/collide block and
' TTrainingLine counter, then two more EachIn loops (TPole 0x00C6D9A4, TCone 0x00C6D6xx).
' Two shapes cost bytes and were measured, not assumed:
'   * "If n = 0 Then <rest of function> EndIf" emits a single 6-byte jne -- it is NOT
'     "If n <> 0 Then Return 0" (that form is 6 bytes longer).
'   * the ball test is "If Not b Or b.controlledby <> p". "Not b" materialises the truth
'     value (cmp NullObject / setne / movzx / cmp) and then negates it (sete / movzx /
'     cmp), 9 bytes more than "b <> Null"; and the Fail/Success arms are the other way
'     round from Ghidra's read of it.
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
	For Local co:TCone = EachIn g_Object813
		If co.alive = 0 Then
			TTraining.Fail()
			Return 0
		EndIf
	Next
	Local b:TBall = TBall.GetActiveBall()
	If Not b Or b.controlledby <> p Then
			TTraining.Fail()
			Return 0
		EndIf
		TTraining.Success()
	EndIf
EndIf

' TBall.UpdateAll
' VA 0x004c813d   121 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' assumptions: Global 0x00c5a4c0 declared TList (globals_final has it as g_Object09:Object,
'   init=bbNullObject with no call-site typing; slot 0x8c = TList.ObjectEnumerator fixes it).
'   The EachIn loop variable's class table argument is 0x00c5ae98 = TBall, and slot 0x4c on
'   TBall is Update().
' The guard is `If Not <object>` -- an object under Not materialises through
'   cmp/setne/movzx before the test, which `= Null` (cmp mem,imm32) does not. Measured:
'   `If g <> Null` block form 105 bytes, `If g = Null Then Return 0` 112, `If Not g` 121.
	Function UpdateAll:Int()
		'!Global g_balls:TList
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			b.Update()
		Next
		Return 0
	End Function

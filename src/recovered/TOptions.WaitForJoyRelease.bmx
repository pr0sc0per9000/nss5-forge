' TOptions.WaitForJoyRelease
' VA 0x004e2efb   178 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (178/178, original length from Ghidra's inventory, mode=reloc)
' KIND=Function -- static, no implicit Self.
' assumptions: module Global 0x00c5d1a8 is the joystick port selector :Int;
'              FUN_00505b91 = module Function LogLine, literal 0x00c7602c = "WaitForJoyRelease";
'              FUN_005071c3 = module Function FlushAllInput;
'              FUN_005b4721 = KeyDown, FUN_005b46ee = KeyHit (the latter from
'              brl_functions_inferred.tsv -- the oracle masked it, reloc_masked=8);
'              FUN_00595705 = JoyDown, FUN_00595746 = JoyHit.
'
' The two loop bounds use different forms and it is load-bearing: the key loop is
' `To 255` (cmp esi,0xff / jle) and the joystick loop is `Until 15` (cmp esi,0xf / jl).
' Writing both the same way misses by one byte-pair each time.
	Function WaitForJoyRelease:Int()
		'!Global g_joyport:Int
		LogLine("WaitForJoyRelease")
		Local port:Int = 0
		If g_joyport = 2 Then port = 1
		Local ok:Int
		Repeat
			ok = True
			For Local i:Int = 0 To 255
				If KeyDown(i) Then ok = False
				If KeyHit(i) Then ok = False
			Next
			For Local i:Int = 0 Until 15
				If JoyDown(i, port) Then ok = False
				If JoyHit(i, port) Then ok = False
			Next
		Until ok
		FlushAllInput()
	End Function

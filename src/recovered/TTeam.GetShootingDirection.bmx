' TTeam.GetShootingDirection
' VA 0x004E1914   196 bytes   vtable slot 0x8c   sig ()i
' byte-identical vs NSS5.exe (196/196, original length from Ghidra's inventory)
' g_Object17 must be declared :TTeam - the .id access at +8 and the vtable-free field load depend on it.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_Object17:TTeam
'   Global g_engine_int18:Int

	Method GetShootingDirection:Int()
		'!Global g_Object17:TTeam
		'!Global g_engine_int18:Int
		If g_Object17 And g_Object17.id = id
			Select g_engine_int18
			Case 1
				Return -1
			Case 2
				Return 1
			Case 3
				Return -1
			Case 4
				Return 1
			Case 5
				Return -1
			End Select
		Else
			Select g_engine_int18
			Case 1
				Return 1
			Case 2
				Return -1
			Case 3
				Return 1
			Case 4
				Return -1
			Case 5
				Return -1
			End Select
		EndIf
		Return -1
	End Method

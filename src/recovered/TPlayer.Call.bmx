' TPlayer.Call
' VA 0x004f74c4   100 bytes   vtable slot 0x108   sig ()i
' byte-identical vs NSS5.exe (100/100, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global at 0x00c6efd4 declared :Int (stored into calling), module Global
' at 0x00c6cf90 declared :Int (the in-training flag).
' PTR_FUN_00c6d548 = TTraining + 0xa4 = Call(:TPlayer).
' NOTE the condition sense: `If calling <> 0 / calling = 0 / Else / calling = g_callTime`
' emits the else-first layout (je) the original has; the `= 0` form emits jne and misses.
	Method Call()
		'!Global g_callTime:Int
		'!Global g_inTraining:Int
		If calling <> 0
			calling = 0
		Else
			calling = g_callTime
		EndIf
		calltype = joy.activebutton
		joy.Clear()
		If g_inTraining <> 0 Then TTraining.Call(Self)
	End Method

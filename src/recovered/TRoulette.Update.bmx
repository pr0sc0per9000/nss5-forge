' TRoulette.Update
' VA 0x005756aa   127 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (127/127, original length from Ghidra's inventory)
' globals 0x00c6bbbc / 0x00c6bbc0 typed TRouletteWheel / TRouletteBall from their slot-0x38 signatures; 0x00c6bbc4 is Int.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function Update:Int()
		'!Global g_roulette_wheel:TRouletteWheel
		'!Global g_roulette_ball:TRouletteBall
		'!Global g_roulette_state:Int
		g_roulette_wheel.Update()
		g_roulette_ball.Update(g_roulette_wheel)
		If g_roulette_state = 0 And g_roulette_ball.bStopped = 1 And g_roulette_wheel.fSpeed < 0.2
			GetResult()
		EndIf
	End Function

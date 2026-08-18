' TPlayer.GoalScorer
' VA 0x004FE305   48 bytes   vtable slot 0x1fc   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Globals assumed (names ours, types load-bearing):
'   Global g_state:Int      (0x00C5B1FC)
'   Global g_scorer:TPlayer (0x00C5B248)
' the two guard clauses must use <> -- the = form emits the opposite jump polarity

	Method GoalScorer:Int()
		'!Global g_state:Int
		'!Global g_scorer:TPlayer
		If g_state <> 8 Then Return 0
		If g_scorer <> Self Then Return 0
		Return 1
	End Method

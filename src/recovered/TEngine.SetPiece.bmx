' TEngine.SetPiece
' VA 0x004D35FD   140 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory)
' Select/Case sharing GetStringMatchState skeleton; cases 0,1,10,8,11 have empty bodies.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_player_int01:Int

	Function SetPiece:Int()
		'!Global g_player_int01:Int
		Select g_player_int01
		Case 0
		Case 1
		Case 2
			Return 1
		Case 3
			Return 1
		Case 4
			Return 1
		Case 5
			Return 1
		Case 6
			Return 1
		Case 7
			Return 1
		Case 9
			Return 1
		Case 10
		Case 8
		Case 11
		End Select
		Return 0
	End Function

' TPlayer.PlayerOnFeet
' VA 0x004FC83A   167 bytes   vtable slot 0x1a0   sig ()i
' byte-identical vs NSS5.exe (167/167, original length from Ghidra's inventory)
' currentanim is Int[]; the six compared globals are module-level Int[] animation tables.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_player_arr01:Int[]
'   Global g_player_arr02:Int[]
'   Global g_player_arr08:Int[]
'   Global g_player_arr19:Int[]
'   Global g_player_arr20:Int[]
'   Global g_player_arr21:Int[]

	Method PlayerOnFeet:Int()
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr02:Int[]
		'!Global g_player_arr08:Int[]
		'!Global g_player_arr19:Int[]
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr21:Int[]
		If z > 0 Then Return 0
		If currentanim = g_player_arr01 Then Return 1
		If currentanim = g_player_arr02 Then Return 1
		If currentanim = g_player_arr08 Then Return 1
		If currentanim = g_player_arr19 Then Return 1
		If currentanim = g_player_arr20 Then Return 1
		If currentanim = g_player_arr21 Then Return 1
		Return 0
	End Method

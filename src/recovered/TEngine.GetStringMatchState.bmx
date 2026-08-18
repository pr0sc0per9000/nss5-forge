' TEngine.GetStringMatchState
' VA 0x004D7A8E   165 bytes   vtable slot 0xf4   sig ()$
' byte-identical vs NSS5.exe (165/165, original length from Ghidra's inventory)
' Select/Case in the original source order 0..7,9,10,8,11; literals read out of NSS5.exe .data.
' No Default case - the fallback Return "Error" sits after End Select.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_player_int01:Int

	Function GetStringMatchState:String()
		'!Global g_player_int01:Int
		Select g_player_int01
		Case 0
			Return "Tunnel"
		Case 1
			Return "In Play"
		Case 2
			Return "Centre"
		Case 3
			Return "Throw-In"
		Case 4
			Return "Free Kick"
		Case 5
			Return "Corner"
		Case 6
			Return "Goal Kick"
		Case 7
			Return "Penalty"
		Case 9
			Return "Shoot-Out"
		Case 10
			Return "Shoot-Out Taken"
		Case 8
			Return "Goal!"
		Case 11
			Return "Match Over"
		End Select
		Return "Error"
	End Function

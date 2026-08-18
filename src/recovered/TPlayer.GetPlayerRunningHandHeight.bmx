' TPlayer.GetPlayerRunningHandHeight
' VA 0x004FCDC1   412 bytes   vtable slot 0x1d0   sig (*f)i
' byte-identical vs NSS5.exe (412/412, original length from Ghidra's inventory)
' globals: g_player_arr01/02:Int[] (0x00C5DEAC/0x00C5DEB0) - the Stand and Run frame lists;
'          g_player_float02:Float (0x00C5DE44)
' a0 is the (*f) out-parameter; the harness declares it Float Ptr, so the body writes a0[0].
' The original source may well have been 'Var' - identical codegen either way.
' float constants 32/32/37/35/33/35/37/33 read from 0x00C7A57C..0x00C7A598
' module globals this body declares:
'   Global g_player_arr01:Int[]
'   Global g_player_arr02:Int[]
'   Global g_player_float02:Float
	Method GetPlayerRunningHandHeight:Int(a0:Float Ptr)
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr02:Int[]
		'!Global g_player_float02:Float
		Local n:Int = 0
		For Local f:Int = EachIn g_player_arr01
			If imageframenumber = f
				n = f
				Exit
			EndIf
			If imageframenumber = f + 64
				n = f
				Exit
			EndIf
			If imageframenumber = f + 128
				n = f
				Exit
			EndIf
		Next
		If n = 0
			For Local f:Int = EachIn g_player_arr02
				If imageframenumber = f
					n = f
					Exit
				EndIf
				If imageframenumber = f + 64
					n = f
					Exit
				EndIf
				If imageframenumber = f + 128
					n = f
					Exit
				EndIf
			Next
		EndIf
		Select n
			Case 0
				a0[0] = 32.0 * g_player_float02
			Case 1
				a0[0] = 32.0 * g_player_float02
			Case 2
				a0[0] = 37.0 * g_player_float02
			Case 3
				a0[0] = 35.0 * g_player_float02
			Case 4
				a0[0] = 33.0 * g_player_float02
			Case 5
				a0[0] = 35.0 * g_player_float02
			Case 6
				a0[0] = 37.0 * g_player_float02
			Case 7
				a0[0] = 33.0 * g_player_float02
		End Select
	End Method

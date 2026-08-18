' TPlayer.DoCollision
' VA 0x004F4BB3   428 bytes   vtable slot 0xd4   sig (:TPlayer,:TPlayer)i
' byte-identical vs NSS5.exe (428/428, original length from Ghidra's inventory)
' global: g_player_int34:Int (0x00C5DE74) - the collision radius, converted to Float
' 'push' must be its own local: writing 'd = d - dist' reuses d's slot and is 2 bytes short.
' module globals this body declares:
'   Global g_player_int34:Int
	Function DoCollision:Int(a0:TPlayer, a1:TPlayer)
		'!Global g_player_int34:Int
		Local d:Float = g_player_int34
		Local dist:Float = Sqr((a0.x - a1.x) ^ 2 + (a0.y - a1.y) ^ 2)
		If dist < d
			Local ang:Float = ATan2(a0.y - a1.y, a0.x - a1.x)
			Local push:Float = d - dist
			a0.x = a0.x + push * Cos(ang)
			a0.y = a0.y + push * Sin(ang)
			a1.x = a1.x + push * Cos(ang + 180.0)
			a1.y = a1.y + push * Sin(ang + 180.0)
		EndIf
	End Function

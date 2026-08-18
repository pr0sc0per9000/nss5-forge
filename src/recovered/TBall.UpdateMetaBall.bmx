' TBall.UpdateMetaBall
' VA 0x004C8DCE   610 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (610/610, original length from Ghidra's inventory)
' globals: g_ball_float01/02/03:Float (0x00C5A4CC/D0/D4), g_player_int33:Int (0x00C5DE70)
' literals 1.1 / 0.6 / 3.0 are 4-byte Float constants at 0x00C72640/44/48
' Operand order is load-bearing: 'Cos(ldir) * lv' (not 'lv * Cos(ldir)') - putting lv first
' forces it to be spilled to a qword temp across the call, +10 bytes per accumulate.
' 'If Not controlledby' (not 'If controlledby = Null') - the Not form materialises the
' object-to-bool via cmp/setne/movzx, which is what the original does; '= Null' emits a
' direct cmp/jne and is 10 bytes short at each of the two sites.
' VERIFIED WITH ONE HARNESS FIX: helper_map.load_table() labels 0x004A1F10 '_bbSin' and
' 0x004A1F00 '_bbCos', but 0x004A1F10 ends in D9 FF (fcos) and 0x004A1F00 in D9 FE (fsin) -
' the labels are swapped. Because compare() breaks out of call-masking whenever both sides
' are named and the names disagree, the (stronger) byte-identity proof never ran. Dropping
' those two table entries lets _same_callee prove the targets by bytes: MATCH, 610/610.
' module globals this body declares:
'   Global g_ball_float01:Float
'   Global g_ball_float02:Float
'   Global g_ball_float03:Float
'   Global g_player_int33:Int
	Method UpdateMetaBall:Int()
		'!Global g_ball_float02:Float
		'!Global g_ball_float03:Float
		'!Global g_player_int33:Int
		'!Global g_ball_float01:Float
		metax = x
		metay = y
		jumpx = 0
		jumpy = 0
		If controlledby <> Null
			metax = controlledby.metax
			metay = controlledby.metay
			Return 0
		EndIf
		Local lz:Float = z
		Local lv:Float = velocity
		Local lzv:Float = zvelocity
		Local ldir:Float = direction
		If z > 0.0
			Repeat
				lv = lv * g_ball_float02
				metax = metax + Cos(ldir) * lv
				metay = metay + Sin(ldir) * lv
				lzv = lzv - g_ball_float03
				lz = lz + lzv
				If Not controlledby
					ldir = ldir + curlamount
				EndIf
				If lzv < 0.0
					If lz > g_player_int33 * 1.1
						jumpx = metax
						jumpy = metay
					EndIf
					If lz > g_player_int33 * 0.6
						divex = metax
						divey = metay
					EndIf
				EndIf
			Until lz <= 0.0 Or lv <= 0.0
		Else
			Repeat
				lv = lv * g_ball_float01
				metax = metax + Cos(ldir) * lv
				metay = metay + Sin(ldir) * lv
				If Not controlledby
					ldir = ldir + curlamount
				EndIf
			Until lv <= 3.0
		EndIf
	End Method

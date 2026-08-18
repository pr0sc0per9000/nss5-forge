' TBall.CheckAdHoardings
' VA 0x004CAA8F   524 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, slot 0x78
' ASSUMPTIONS
'  * Globals (names are ours; codegen depends only on the declared types):
'      0x00C6CF90 g_training_int03:Int    0x00C5D634 g_player_int16:Int
'      0x00C5D638 g_player_int17:Int      0x00C5D660 g_pitch_int12:Int
'      0x00C5A4D8 g_ball_float04:Float    0x00C5A51C g_ball_sound:TSound
'      0x00C5A510 g_ball_channel:TChannel
'    The two audio Globals are `Object` with no call-site typing in globals_final.tsv;
'    TSound/TChannel come from BRL's PlaySound(sound:TSound, channel:TChannel) and the
'    push order (0x00C5A51C pushed second = argument 0).
'  * FUN_00505E20 is the recovered module Function GetInterceptPoint (src/recovered_module).
'    Its TInterceptPoint result is read at +0x18 = `intercept`.
'  * FUN_004A7FE0 = Abs(Double), FUN_004A1F90 = ATan2. Both are unnamed in full_table();
'    the body nevertheless matches byte-for-byte, so their E8 operands agree.
'  * The opening is an EARLY RETURN (cmp/je body/mov eax,0/jmp end), not an If-block:
'    as an If-block the body comes out 6 bytes short (guide 3f).
'  * `c` and `s` are real Float Locals. Only the LAST one stays on the x87 stack
'    (guide 10.5) -- `c` spills to [ebp-4], which is the 6 bytes of fstp/fld that
'    separate 518 from 524. Folding either back into the ATan2 call loses them.
'  * `Abs(x) > n` compiles to `setbe` plus an INVERTED branch, so a setbe whose
'    cmp/jne skips the then-block still reads as `>` in source.
	'!Global g_training_int03:Int
	'!Global g_player_int16:Int
	'!Global g_player_int17:Int
	'!Global g_pitch_int12:Int
	'!Global g_ball_float04:Float
	'!Global g_ball_sound:TSound
	'!Global g_ball_channel:TChannel
	If g_training_int03 <> 0 Then Return 0
	Local a:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -g_player_int16, -g_pitch_int12, g_player_int16, -g_pitch_int12)
	Local b:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -g_player_int16, g_pitch_int12, g_player_int16, g_pitch_int12)
	If (a.intercept Or b.intercept) And Self.z <= 12.0
		PlaySound(g_ball_sound, g_ball_channel)
		Self.x = Self.oldx
		Self.y = Self.oldy
		Self.velocity = Self.velocity * g_ball_float04
		Local c:Float = Cos(Self.direction)
		Local s:Float = -Sin(Self.direction)
		Self.direction = ATan2(s, c)
	EndIf
	If g_training_int03 = 0
		If Abs(Self.x) > g_player_int16 + 200
			Self.alph = Self.alph - 0.05
		ElseIf Abs(Self.y) > g_player_int17 + 200
			Self.alph = Self.alph - 0.05
		EndIf
	EndIf

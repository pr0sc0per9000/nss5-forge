' TBall.UpdateAnimation
' VA 0x004C9030   370 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (370/370, original length from Ghidra's inventory)
' ASSUMPTION: two module Globals --
'   g_ball_minspeed:Float @ 0x00C7264C  (read with 'fld dword ptr', so Float; it
'                                        is NOT in globals_named.tsv, name invented)
'   g_player_int50:Int    @ 0x00C6EFD4  (name from globals_named.tsv; it behaves
'                                        as the millisecond clock)
' NESTED Ifs, not 'If a And b'. The float guard compiles to 'setbe / cmp eax,0 /
' jne' in the original; the And form makes bcc emit the positive 'seta' and the
' function builds 7 bytes long.
' Cos() is the first helper called (0x004A1F10) and Sin() the second (0x004A1F00).
' 0x004A1F10 ends D9 FF (fcos) and 0x004A1F00 ends D9 FE (fsin), disassembled straight
' out of NSS5.exe. extracted/runtime_helpers.tsv must not have _bbSin/_bbCos swapped:
' with the table right, the swapped spelling scores 354/370 and this one 370/370.
' vx drives frames 6..11 and vy frames 0..5.
' ':+ 1' / ':- 1' are required -- they emit 'add/sub dword ptr [ebx+0xa0],1'
' whereas 'frame = frame + 1' would load, add and store.
	Method UpdateAnimation:Int()
		' g_ball_minspeed's original data-section value is 0.1 (0x00C7264C).
		' Never stored to anywhere in the corpus -- see codegen-patterns 21.1.
		'!Global g_ball_minspeed:Float = 0.1
		'!Global g_player_int50:Int
		hideball = 0
		If KeeperImageHolding() Then hideball = 1
		If velocity > g_ball_minspeed
			If g_player_int50 > lastframetime + 50
				lastframetime = g_player_int50
				Local vx:Float = Cos(direction)
				Local vy:Float = Sin(direction)
				If Abs(vx) > Abs(vy)
					If vx > 0 Then frame :+ 1 Else frame :- 1
					If frame > 11 Then frame = 6
					If frame < 6 Then frame = 11
				Else
					If vy > 0 Then frame :+ 1 Else frame :- 1
					If frame > 5 Then frame = 0
					If frame < 0 Then frame = 5
				EndIf
			EndIf
		EndIf
	End Method

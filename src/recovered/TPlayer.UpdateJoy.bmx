' TPlayer.UpdateJoy
' VA 0x004F19AA   433 bytes   vtable slot 0x88   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (433/433, mode=reloc, reloc_masked=17)
'
' ASSUMPTIONS (module Global names are ours; declared types are load-bearing):
'   g_player_int02 = 0x00C5B200  Int
'   g_player_int01 = 0x00C5B1FC  Int   (type_source='verified')
'   g_activeball   = 0x00C5DEA4  TBall (codegen-patterns 11.2)
'   g_player_int50 = 0x00C6EFD4  Int   (globals_final says TScreen with a flagged
'                                       conflict; used as a bare dword compare, and
'                                       codegen-patterns 10.7 already ruled this address
'                                       family Int)
'   the two float constants are .rdata at 0x00C7974C = 0.0 and 0x00C79750 = -1.0
'
' CODEGEN NOTES (three separate measurements, each worth a length):
'  1. `Self.controller` is loaded ONCE and compared twice back to back -> Select, not
'     If/ElseIf (codegen-patterns 10.2). If/ElseIf gives 434.
'  2. The kickbuttonhits test is a NESTED If, not a fifth And term. As a fifth term bcc
'     materialises it (setcc/movzx/cmp, +9 bytes -> 442); nested it branches directly.
'  3. Operand order: the original is `cmp dword [g],eax / jle`, i.e. the Global on the
'     LEFT (`g > x`). `x < g` emits `cmp eax,[g] / jge` -- same length, different bytes
'     (codegen-patterns 10.1).

	Method UpdateJoy:Int()
		'!Global g_player_int02:Int
		'!Global g_player_int01:Int
		'!Global g_activeball:TBall
		'!Global g_player_int50:Int
		Select Self.controller
			Case 1
				If g_player_int02 = 0
					Local dir:Float = 0.0
					If g_player_int01 = 3 And g_activeball <> Null And g_activeball.setpiecetaker = Self
						dir = -1.0
					Else
						If TEngine.SetPiece() And g_activeball <> Null And g_activeball.setpiecetaker = Self
							dir = Self.GetShootingDirection()
							If g_player_int01 = 5 Then dir = -dir
						EndIf
					EndIf
					Self.joy.Update(Self.GetHumanNumber(),Self.GetMouseDirection(),Int(dir))
					Self.CheckJoyAngle()
					If g_activeball <> Null And g_activeball.controlledby <> Self And Self.joy.kickbuttonhits And Self.joy.kickbuttondown
						If g_player_int50 > Self.joy.kickbuttonhits + 250
							Self.joy.kickbuttonhits = 0
						EndIf
					EndIf
				EndIf
			Case 0
				Self.UpdateJoyAI()
		End Select
	End Method

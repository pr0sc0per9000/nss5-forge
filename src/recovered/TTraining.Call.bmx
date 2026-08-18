' TTraining.Call
' VA 0x00581EA1   908 bytes   class-table slot 0xA4   sig (:TPlayer)i   KIND=Function (static)
' byte-identical vs NSS5.exe (908/908, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=32)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C6CF90 Int  g_training_int03   (training-drill state machine selector)
'    0x00C6CFFC Int  g_training_int22   (calls-remaining counter, decremented at the end)
'    0x00C6CFD8 Int  g_training_int13   (SetUpSetPiece arg)
'    0x00C6CFDC Int  g_training_int14   (SetUpSetPiece arg)
'    0x00C5D1AC Int  g_player_int14     (joypad-control flag)
'  Fields: TPlayer .calling +0x114, .x/.y +0x4C/+0x50, .metax/.metay +0x84/+0x88,
'    .joy:TJoy +0x158 (TJoy.activebutton +0x24), .id +0x10.
'  Slots resolved: TEngine+0x70 = SetUpSetPiece(i,i,i,i)i, TPitch+0x6C = YardsToPixels(f)f,
'    TPitch+0x7C = ValidateOnPitch(*f,*f)i (Float Ptr params -- see TPitch.ValidateOnPitch.bmx),
'    TBall+0x38 = CreateBall(i,i,i):TBall, TBall+0x68 = Kick(:TPlayer,f,f,i,i)i.
'  Module Functions: Abs (_bbFloatAbs, 0x004A7FE0 per runtime_helpers), AngleTo (0x0050639D),
'    Dist2D (0x00505DA2, already in src/recovered_module), LogLine.
'  Literals read from NSS5.exe's data section: 0x00C929FC=0.15, 0x00C92A00=40.0 (compare),
'    0x00C92A04=40.0 (store -- same value, different address), 0x00C92A08=0.25. The float
'    literal 30.0 (0x41F00000) pushed for YardsToPixels() is a raw immediate, not a data
'    reference, and decodes directly from the instruction bytes.
' SHAPE NOTES (each measured)
'  * The `g_training_int03` dispatch is a SELECT (10 `cmp/je` back to back, section 10.2), with
'    no Default -- the fallback (physics/kick code) is the code physically AFTER `End Select`,
'    reached by every case that does not explicitly `Return`.
'  * Cases 1..6 have byte-IDENTICAL bodies (`a0.calling = 0 ; Return 0`) but the original
'    duplicates the three-instruction body SIX TIMES at six different addresses rather than
'    sharing one via a comma-separated `Case 1,2,3,4,5,6` -- reproduced as six separate `Case`
'    blocks per law 3 (do not improve/collapse what the original duplicated).
'  * Cases 7, 8 and 9 are likewise three SEPARATE `Case` blocks with the identical one-line body
'    `If g_training_int22 = 0 Then Return 0` -- when int22 <> 0 each case falls out of the
'    Select (no more statements) straight into the shared physics code after End Select.
'  * `dist:Float` (the raw `Dist2D` result) is read TWICE -- once for the 0.15 multiply, once
'    (conditionally) for the 0.25 multiply -- with a long, FPU-touching If cascade in between
'    that nets zero net effect on the x87 stack depth (each cascade's own `fld`/`fucompp` pair
'    is self-contained), so `dist` survives the whole cascade in an x87 register with no
'    intervening spill: a single `Local dist:Float = Dist2D(...)` referenced twice reproduces
'    this exactly, with no manual "keep on stack" trick needed.
'  * The joypad override is itself a nested SELECT on `a0.joy.activebutton` (Case 1/3/2, in
'    that non-ascending order -- reproduced as written), guarded by a compound
'    `g_player_int14 = 1 And g_training_int03 <> 7 And g_training_int03 <> 8`.
'  * `TPitch.ValidateOnPitch` takes `Float Ptr` params (not implicit `Var`); callers pass
'    `Varptr mx`/`Varptr my` explicitly (confirmed against the already-recovered callee).
	'!Global g_training_int03:Int
	'!Global g_training_int22:Int
	'!Global g_training_int13:Int
	'!Global g_training_int14:Int
	'!Global g_player_int14:Int
	Function Call:Int(a0:TPlayer)
		Select g_training_int03
			Case 1
				a0.calling = 0
				Return 0
			Case 2
				a0.calling = 0
				Return 0
			Case 3
				a0.calling = 0
				Return 0
			Case 4
				a0.calling = 0
				Return 0
			Case 5
				a0.calling = 0
				Return 0
			Case 6
				a0.calling = 0
				Return 0
			Case 7
				If g_training_int22 = 0 Then Return 0
			Case 8
				If g_training_int22 = 0 Then Return 0
			Case 9
				If g_training_int22 = 0 Then Return 0
			Case 10
				TEngine.SetUpSetPiece(4, 1, g_training_int13, g_training_int14)
				Return 0
		End Select
		Local ax:Float = Abs(a0.x)
		Local ballx:Int = Int(ax + TPitch.YardsToPixels(30.0))
		Local bally:Int = Int(a0.y)
		If a0.x < 0 Then ballx = -ballx
		Local mx:Float = a0.metax
		Local my:Float = a0.metay
		TPitch.ValidateOnPitch(Varptr mx, Varptr my)
		Local ball:TBall = TBall.CreateBall(ballx, bally, 0)
		Local angle:Int = Int(AngleTo(Float(ballx), Float(bally), mx, my))
		Local dist:Float = Dist2D(Float(ballx), Float(bally), mx, my)
		Local power:Float = dist * 0.15
		Local kicktype:Int = 3
		If (g_training_int03 = 7 Or g_training_int03 = 8) And power < 40.0
			power = 40.0
		EndIf
		If g_training_int03 = 9 Or g_training_int03 = 10
			kicktype = 1
		EndIf
		If g_player_int14 = 1 And g_training_int03 <> 7 And g_training_int03 <> 8
			Select a0.joy.activebutton
				Case 1
					kicktype = 2
				Case 3
					kicktype = 3
				Case 2
					kicktype = 1
			End Select
		EndIf
		If kicktype = 1
			power = dist * 0.25
		EndIf
		LogLine("kicktype:" + kicktype)
		ball.Kick(a0, Float(angle), power, kicktype, a0.id)
		g_training_int22 = g_training_int22 - 1
		Return 0
	End Function

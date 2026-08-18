' TTraining.SetUpTraining_Tackling
' VA 0x0057F595   1952 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (1952/1952, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only. MATCHED on the first attempt using the already-solved
' siblings TTraining.SetUpTraining_Shooting (same Global block, same LogLine/GetText/ClampInt
' shape, same "int06 default before Select" placement) and TTraining.SetUpTraining_Dribbling
' (source for the g_training_int19/int17/int22 names and the TCone.Create tail loop).
'
' SHAPE NOTES (byte-observable, confirmed against the raw disassembly, not just Ghidra's C)
'  * The 20-way Select on g_training_int04 is emitted in SOURCE order {1,2,3,5,7,9,11,13,
'    15,17,19,4,6,8,10,12,14,16,18,20} -- NOT numeric, and NOT the odd-then-even split seen
'    in SetUpTraining_Shooting. Level 2 sits with the 11-Case "trial-drill" group; the other
'    nine even levels (4,6,...,20) form the second group. Confirmed by the back-to-back
'    cmp/je chain at 0x0057F6E5 which is in exactly that order (pattern 10.2: Select, not
'    If/ElseIf; no Default arm -- falls straight to the tail `jmp 0x57FC2C`).
'  * The first 11 Cases (1,2,3,5,7,9,11,13,15,17,19) all set g_trainingstate = 5 and reload
'    g_training_int10 = GetText("CTRAINING_TACKLING2"); the other nine (4,6,...,20) touch
'    neither -- they set int17/int22 instead. This is the reverse role-split from Shooting's
'    odd/even Cases, and Cases 4 and 6 write IDENTICAL constants (int06=60, int17=4) --
'    reproduced as-is (law 3), not merged.
'  * g_training_int19 (the tail-loop's upper bound) is only assigned inside the first 11
'    Cases; the other nine leave it untouched, so on those levels the tail For-loop runs
'    with whatever g_training_int19 already held. That is the original's behaviour, not a
'    reconstruction gap -- nothing in this function initialises it beforehand.
'  * Tail loop: `Local a:Int = Rand(190, 360)` per iteration, then two independent
'    Cos/Sin-times-YardsToPixels products -- unlike SetUpTraining_Dribbling's cx/cy, there is
'    no `x +`/`y +` base offset added; x and y are the raw trig products. Float literals at
'    0xC928DC/E0/E4/E8 read back as 10.0/1.5/10.0/1.5 (harness.read_string's numeric sibling:
'    read via va2off + struct.unpack), giving `TPitch.YardsToPixels(10.0 + i*1.5)` for both
'    axes. `TCone.Create(x, y, 2)` -- confirmed by class-table arithmetic: TCone's table VA
'    0x00C6D770 + slot 0x48 = 0x00C6D7B8, the address the tail loop calls indirectly.
'  * `TPitch.YardsToPixels` is likewise a class-table-slot call, not a helper: TPitch's table
'    VA 0x00C5D92C + slot 0x6C = 0x00C5D998, matching the `call dword ptr [0xC5D998]` sites.
'    Both are class-table slot calls (oracle mask 3) so their exact call-site bytes are not
'    independently significant; the semantics were confirmed from the class-table arithmetic.
'  * `FUN_004C5549(key, sep, valueStr)`-shaped 3-arg GetText calls in Ghidra's decompile are
'    an artefact of eager argument pre-pushing for a chained `+` expression: the disassembly
'    shows GetText's OWN call only ever pops 4 bytes (one argument); the other two pushed
'    values are consumed by the two later `_bbStringConcat` (0x004A7C20) calls. Source is the
'    plain `GetText("Level") + " " + g_training_int04` already used in the two sibling files.
'  * Ends with g_training_int11 = 0 and g_training_int12 = 0 (unconditional resets, not
'    tied to the tail loop) then the implicit `Return 0` epilogue.
'
' Globals (all bare-dword Int/String access unless noted; names shared with the sibling
' SetUpTraining_Shooting/_Dribbling files where the addresses coincide):
'   0x00C6F028 g_profile:TProfile (field 0xB0 = tackling, 0x78 = contractwage)
'   0x00C6CF90 g_trainingstate (same Global as SetUpTraining_Shooting/ClearUpTraining)
'   0x00C6CF94 int04   0x00C6CF9C int06   0x00C6CFA4 int08$   0x00C6CFA8 int09$
'   0x00C6CFAC int10$  0x00C6CFB8 g_traininglabel1:TLabel (slot 0x64 SetText, inherited)
'   0x00C6CFD0 int11   0x00C6CFD4 int12   0x00C6CFE8 int17   0x00C6CFF0 int19
'   0x00C6CFFC int22
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TCone+0x48=Create(i,i,i)i,
'   TLabel+0x64=SetText (inherited).
	Function SetUpTraining_Tackling:Int()
		'!Global g_profile:TProfile
		'!Global g_trainingstate:Int
		'!Global g_training_int04:Int
		'!Global g_training_int06:Int
		'!Global g_training_int08:String
		'!Global g_training_int09:String
		'!Global g_training_int10:String
		'!Global g_traininglabel1:TLabel
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int17:Int
		'!Global g_training_int19:Int
		'!Global g_training_int22:Int
		LogLine("SetUpTraining_Tackling")
		g_training_int04 = g_profile.tackling * 2 + 10
		g_training_int04 :/ 10
		ClampInt(Varptr g_training_int04, 1, 20)
		g_training_int08 = GetText("Tackling Training")
		g_training_int09 = GetText("Level") + " " + g_training_int04
		g_training_int10 = GetText("CTRAINING_TACKLING1")
		If g_training_int04 = 1 And g_profile.contractwage = 0
			g_traininglabel1.SetText(GetText("CMESSAGE_TRIALTACKLING"), "", -1, -1)
		EndIf
		g_training_int06 = 60
		Select g_training_int04
			Case 1
				g_training_int06 = 60
				g_training_int19 = 1
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 2
				g_training_int06 = 50
				g_training_int19 = 2
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 3
				g_training_int06 = 40
				g_training_int19 = 3
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 5
				g_training_int06 = 30
				g_training_int19 = 4
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 7
				g_training_int06 = 28
				g_training_int19 = 5
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 9
				g_training_int06 = 26
				g_training_int19 = 6
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 11
				g_training_int06 = 24
				g_training_int19 = 7
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 13
				g_training_int06 = 22
				g_training_int19 = 8
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 15
				g_training_int06 = 20
				g_training_int19 = 9
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 17
				g_training_int06 = 18
				g_training_int19 = 10
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 19
				g_training_int06 = 16
				g_training_int19 = 12
				g_trainingstate = 5
				g_training_int10 = GetText("CTRAINING_TACKLING2")
			Case 4
				g_training_int06 = 60
				g_training_int17 = 4
				g_training_int22 = 1
			Case 6
				g_training_int06 = 60
				g_training_int17 = 4
				g_training_int22 = 1
			Case 8
				g_training_int06 = 60
				g_training_int17 = 5
				g_training_int22 = 1
			Case 10
				g_training_int06 = 55
				g_training_int17 = 6
				g_training_int22 = 1
			Case 12
				g_training_int06 = 50
				g_training_int17 = 7
				g_training_int22 = 1
			Case 14
				g_training_int06 = 45
				g_training_int17 = 8
				g_training_int22 = 1
			Case 16
				g_training_int06 = 40
				g_training_int17 = 9
				g_training_int22 = 1
			Case 18
				g_training_int06 = 35
				g_training_int17 = 10
				g_training_int22 = 1
			Case 20
				g_training_int06 = 30
				g_training_int17 = 11
				g_training_int22 = 1
		End Select
		For Local i:Int = 1 To g_training_int19
			Local a:Int = Rand(190, 360)
			Local x:Int = Int(Cos(a) * TPitch.YardsToPixels(10.0 + i * 1.5))
			Local y:Int = Int(Sin(a) * TPitch.YardsToPixels(10.0 + i * 1.5))
			TCone.Create(x, y, 2)
		Next
		g_training_int11 = 0
		g_training_int12 = 0
	End Function

' TTraining.SetUpTraining_Shooting
' VA 0x0057E0C5   2556 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (2556/2556, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only. MATCHED on the first attempt using the already-solved
' twin TTraining.SetUpTraining_Dribbling (same shape: Select on the level Global, no Default)
' plus TTraining.ClearUpTraining for the g_traininglabel1..4 / g_trainingstate naming.
'
' SHAPE NOTES (byte-observable)
'  * The 20-way Select on g_training_int04 is emitted in the SOURCE's Case order, which is
'    NOT numeric: all ten ODD levels (1,3,5,7,9,11,13,15,17,19) first, then all ten EVEN
'    levels (2,4,6,8,10,12,14,16,18,20) -- confirmed by the `cmp/je` chain at 0x0057E2A8,
'    which is back-to-back in exactly that order (pattern: Select, not If/ElseIf -- 10.2).
'    Reproducing the SOURCE Case order (not the numeric one) is load-bearing for the byte
'    count; a naive numeric 1..20 ordering does not match.
'  * Even-level Cases carry four extra fields (int23/int16/int15 plus a GetText re-fetch of
'    g_training_int10 and g_trainingstate=10) that the odd levels do not touch.
'  * A second, smaller `Select g_trainingstate` (Case 9 / Case 10, no Default) sits at the
'    very end of the function with nothing after it -- End Select is immediately followed by
'    the implicit `Return 0` epilogue (`mov eax,0 / jmp +0`).
'  * Ghidra's decompile hoists `iVar6 = g_player_int16` / `iVar7 = g_player_int17` before the
'    `if (g_training_int03 == 9)` test, but the actual instructions for both only exist
'    INSIDE Case 9 -- ghidra is not evidence for statement placement (10.1). Both become
'    Locals declared inside Case 9 because each is read from a register (no reload) after an
'    intervening call.
'  * `g_training_int12 = Int(-g_player_int17 + TPitch.YardsToPixels(g_training_int18 + 5))`
'    evaluates the plain Int global left-to-right (fild/fstp to a Float spill slot) BEFORE
'    the call on the right, because the call needs the x87 stack -- same shape as section 6's
'    float-Local note, just for a temporary rather than a declared Local.
'  * `ResetTraining()` is unqualified: its class-table slot is TTraining's own (this function
'    is itself a TTraining Function), matching the "sibling Function, no Type. prefix" rule
'    (codegen-patterns.md 3d).
'
' Globals (all bare-dword Int/String access unless noted):
'   0x00C6F028 g_profile:TProfile (same Global as SetUpTraining_Dribbling; field 0xA8=shooting,
'     0x78=contractwage)          0x00C6CF90 g_trainingstate (same Global as ClearUpTraining)
'   0x00C6CF94 int04   0x00C6CF9C int06   0x00C6CFA4 int08$   0x00C6CFA8 int09$
'   0x00C6CFAC int10$  0x00C6CFB8 g_traininglabel1:TLabel (slot 0x64 SetText, inherited)
'   0x00C6CFC4 g_traininglabel4:TLabel (same slot)         0x00C6CFD0 int11   0x00C6CFD4 int12
'   0x00C6CFE0 int15   0x00C6CFE4 int16   0x00C6CFE8 int17  0x00C6CFEC int18
'   0x00C6CFF8 int21   0x00C6CFFC int22   0x00C6D000 int23
'   0x00C5D1AC g_player_int14 (Int)   0x00C5D634 g_player_int16 (Int)   0x00C5D638 g_player_int17 (Int)
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TTrainingLine+0x48=Create(i,i,i,i,$),
'   TDummy+0x48=Create(i,i)i, TTraining+0xB4=ResetTraining()i (this Type, unqualified).
	Function SetUpTraining_Shooting:Int()
		'!Global g_profile:TProfile
		'!Global g_trainingstate:Int
		'!Global g_training_int04:Int
		'!Global g_training_int06:Int
		'!Global g_training_int08:String
		'!Global g_training_int09:String
		'!Global g_training_int10:String
		'!Global g_traininglabel1:TLabel
		'!Global g_traininglabel4:TLabel
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int15:Int
		'!Global g_training_int16:Int
		'!Global g_training_int17:Int
		'!Global g_training_int18:Int
		'!Global g_training_int21:Int
		'!Global g_training_int22:Int
		'!Global g_training_int23:Int
		'!Global g_player_int14:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		LogLine("SetUpTraining_Shooting")
		g_training_int04 = g_profile.shooting * 2 + 10
		g_training_int04 :/ 10
		ClampInt(Varptr g_training_int04, 1, 20)
		g_training_int08 = GetText("Shooting Training")
		g_training_int09 = GetText("Level") + " " + g_training_int04
		g_training_int10 = GetText("CTRAINING_SHOOTING1")
		If g_training_int04 = 1 And g_profile.contractwage = 0
			g_traininglabel1.SetText(GetText("CMESSAGE_TRIALSHOOTINGSIMPLE"), "", -1, -1)
			If g_player_int14 = 1
				g_traininglabel1.SetText(GetText("CMESSAGE_TRIALSHOOTINGADVANCED"), "", -1, -1)
			EndIf
			g_traininglabel4.SetText(GetText("CMESSAGE_TRIALGOALS"), "", -1, -1)
		EndIf
		g_training_int06 = 60
		g_training_int11 = 0
		g_training_int12 = Int(TPitch.YardsToPixels(-45.0))
		g_training_int22 = -1
		g_training_int18 = 0
		Select g_training_int04
			Case 1
				g_training_int06 = 60
				g_training_int18 = 6
				g_training_int21 = 1
				g_training_int17 = 0
			Case 3
				g_training_int06 = 55
				g_training_int18 = 8
				g_training_int21 = 1
				g_training_int17 = 1
			Case 5
				g_training_int06 = 50
				g_training_int18 = 10
				g_training_int21 = 2
				g_training_int17 = 1
			Case 7
				g_training_int06 = 45
				g_training_int18 = 12
				g_training_int21 = 2
				g_training_int17 = 1
			Case 9
				g_training_int06 = 50
				g_training_int18 = 14
				g_training_int21 = 2
				g_training_int17 = 3
			Case 11
				g_training_int06 = 60
				g_training_int18 = 16
				g_training_int21 = 3
				g_training_int17 = 3
			Case 13
				g_training_int06 = 55
				g_training_int18 = 18
				g_training_int21 = 3
				g_training_int17 = 3
			Case 15
				g_training_int06 = 50
				g_training_int18 = 20
				g_training_int21 = 3
				g_training_int17 = 3
			Case 17
				g_training_int06 = 45
				g_training_int18 = 22
				g_training_int21 = 3
				g_training_int17 = 3
			Case 19
				g_training_int06 = 40
				g_training_int18 = 24
				g_training_int21 = 3
				g_training_int17 = 3
			Case 2
				g_training_int06 = 60
				g_training_int21 = 1
				g_training_int23 = 1
				g_training_int16 = 10
				g_training_int15 = 20
				g_training_int17 = 0
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 4
				g_training_int06 = 60
				g_training_int21 = 1
				g_training_int23 = 2
				g_training_int16 = 15
				g_training_int15 = 22
				g_training_int17 = 0
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 6
				g_training_int06 = 60
				g_training_int21 = 1
				g_training_int23 = 3
				g_training_int16 = 20
				g_training_int15 = 24
				g_training_int17 = 0
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 8
				g_training_int06 = 60
				g_training_int21 = 2
				g_training_int23 = 3
				g_training_int16 = 25
				g_training_int15 = 26
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 10
				g_training_int06 = 60
				g_training_int21 = 2
				g_training_int23 = 4
				g_training_int16 = 30
				g_training_int15 = 28
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 12
				g_training_int06 = 60
				g_training_int21 = 3
				g_training_int23 = 4
				g_training_int16 = 35
				g_training_int15 = 30
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 14
				g_training_int06 = 60
				g_training_int21 = 3
				g_training_int23 = 4
				g_training_int16 = 40
				g_training_int15 = 32
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 16
				g_training_int06 = 60
				g_training_int21 = 3
				g_training_int23 = 5
				g_training_int16 = 45
				g_training_int15 = 34
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 18
				g_training_int06 = 60
				g_training_int21 = 3
				g_training_int23 = 5
				g_training_int16 = 50
				g_training_int15 = 36
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
			Case 20
				g_training_int06 = 60
				g_training_int21 = 3
				g_training_int23 = 5
				g_training_int16 = 50
				g_training_int15 = 38
				g_training_int17 = 1
				g_training_int10 = GetText("CTRAINING_SHOOTING2")
				g_trainingstate = 10
		End Select
		g_training_int12 = Int(-g_player_int17 + TPitch.YardsToPixels(g_training_int18 + 5))
		Select g_trainingstate
			Case 9
				Local x:Int = g_player_int16
				Local y:Int = Int(g_player_int17 - TPitch.YardsToPixels(g_training_int18))
				If g_training_int18 > 0
					TTrainingLine.Create(x, -y, -x, -y, "FF0000")
				EndIf
			Case 10
				For Local i:Int = 1 To g_training_int23
					TDummy.Create(0, 0)
				Next
				ResetTraining()
		End Select
	End Function

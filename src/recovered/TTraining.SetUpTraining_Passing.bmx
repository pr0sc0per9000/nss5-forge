' TTraining.SetUpTraining_Passing
' VA 0x0057D94E   1911 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (1911/1911, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=129). Re-verified under NSS5_NO_LEARN=1.
'
' SHAPE NOTES (byte-observable)
'  * Same family as the already-banked twins TTraining.SetUpTraining_Dribbling and
'    TTraining.SetUpTraining_Shooting: a 20-way Select on the level Global (g_training_int04),
'    no Default, in NUMERIC Case order (1..20) this time -- confirmed by the back-to-back
'    cmp/je chain at 0x0057DAD9, which increments 1,2,3,...,20 (unlike Shooting's odd-then-
'    even order).
'  * `g_training_int04 = g_profile.passing * 2 + 10` then `:/ 10` are TWO statements (store
'    before idiv, reload after) -- same as Dribbling/Shooting.
'  * `Local spread:Float` is declared bare and assigned `spread = 0.0` as a SEPARATE statement:
'    writing `Local spread:Float = 0.0` gets the initialiser elided by bcc (16.3's "Local
'    x:Float = 0.0 emits nothing" rule) and produces a body 4 bytes short. The original's
'    `fld [0xc92380] / fstp [ebp-0x34]` proves the store is really there.
'  * The one non-obvious statement, easy to miss by analogy with the OTHER two twins: after
'    copying int13/int14 into int11/int12, the original does a THIRD YardsToPixels call the
'    twins don't have -- `rad = Int(TPitch.YardsToPixels(rad))` -- exactly mirroring
'    Dribbling's `gap = Int(TPitch.YardsToPixels(gap))`. Omitting it undershoots by 41 bytes
'    (one call + its Int-cast + argument marshalling), fully accounted by localise_diff.
'  * `g_training_int13 = 0` / `g_training_int14 = Int(TPitch.YardsToPixels(-10.0))` are set,
'    then IMMEDIATELY copied into `g_training_int11` / `g_training_int12` as two further
'    statements -- four separate Global stores where a tidied version would use two. Verified
'    against four distinct fixed addresses in the disassembly (0xc6cfd8/dc/d0/d4); reproduced
'    verbatim per the "do not tidy" rule (16.8).
'  * The two `.SetText(GetText(...), "", -1, -1)` calls on `g_traininglabel1` and
'    `g_traininglabel2` reproduce the established push-order tell (GetText consumes only its
'    own pushed literal; the three leftover pushed values -1,-1,"" become the trailing
'    arguments of the following virtual call through slot 0x64) -- same as Shooting.
'  * Inside the loop, `a` (the base angle, `Rand(140,1)+200`) is read FOUR times: once each
'    for `Cos(a)`/`Sin(a)` (first cone) and again inline as `a + spread` for `Cos(a+spread)`/
'    `Sin(a+spread)` (second cone) -- `a+spread` is recomputed twice, never stored to a
'    separate Local, matching the disassembly's two independent `fild a / fadd [spread]`
'    sequences.
'  * Every `Int(intGlobal + Cos(a)*rad)` expression evaluates the Int global FIRST (stashed to
'    an anonymous Float spill slot) because the call on the right needs the x87 stack --
'    same left-to-right-with-a-call-on-the-right shape as Shooting's notes.
'
' Globals (all bare-dword Int/String/object access unless noted):
'   0x00C6F028 g_profile:TProfile (.passing=+0xAC, .contractwage=+0x78)
'   0x00C6CF94 int04   0x00C6CF9C int06   0x00C6CFA4 int08$   0x00C6CFA8 int09$
'   0x00C6CFAC int10$  0x00C6CFB8 g_traininglabel1:TLabel (slot 0x64 SetText, inherited)
'   0x00C6CFBC g_traininglabel2:TLabel (same slot)
'   0x00C6CFD0 int11   0x00C6CFD4 int12   0x00C6CFD8 int13 (new)   0x00C6CFDC int14 (new,
'     fills the gap between established int12=0xD4 and int15=0xE0)
'   0x00C6CFF0 int19 (loop bound, established by Dribbling)
'   0x00C6CFFC int22 (established by Shooting)
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TCone+0x48=Create(i,i,i)i (same Type
'   as Dribbling's cone calls), TTrainingLine+0x48=Create(i,i,i,i,$):TTrainingLine.
' Literals (read with harness.read_string, all confirmed): "SetUpTraining_Passing",
'   "Passing Training", "Level", " ", "CTRAINING_PASSING1", "CMESSAGE_TRIALPASSING",
'   "CMESSAGE_TRIALBALLS", "0000FF". Empty-string arguments use the corpus-wide established
'   empty-BBString constant 0x00C5D284.
	Function SetUpTraining_Passing:Int()
		'!Global g_profile:TProfile
		'!Global g_training_int04:Int
		'!Global g_training_int06:Int
		'!Global g_training_int08:String
		'!Global g_training_int09:String
		'!Global g_training_int10:String
		'!Global g_traininglabel1:TLabel
		'!Global g_traininglabel2:TLabel
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int13:Int
		'!Global g_training_int14:Int
		'!Global g_training_int19:Int
		'!Global g_training_int22:Int
		LogLine("SetUpTraining_Passing")
		g_training_int04 = g_profile.passing * 2 + 10
		g_training_int04 :/ 10
		ClampInt(Varptr g_training_int04, 1, 20)
		g_training_int08 = GetText("Passing Training")
		g_training_int09 = GetText("Level") + " " + g_training_int04
		g_training_int10 = GetText("CTRAINING_PASSING1")
		If g_training_int04 = 1 And g_profile.contractwage = 0
			g_traininglabel1.SetText(GetText("CMESSAGE_TRIALPASSING"), "", -1, -1)
			g_traininglabel2.SetText(GetText("CMESSAGE_TRIALBALLS"), "", -1, -1)
		EndIf
		Local rad:Int = 0
		Local spread:Float
		spread = 0.0
		g_training_int06 = -1
		Select g_training_int04
			Case 1
				g_training_int22 = 10
				g_training_int19 = 1
				rad = 10
				spread = 25.0
			Case 2
				g_training_int22 = 10
				g_training_int19 = 2
				rad = 10
				spread = 24.0
			Case 3
				g_training_int22 = 10
				g_training_int19 = 2
				rad = 10
				spread = 23.0
			Case 4
				g_training_int22 = 10
				g_training_int19 = 3
				rad = 10
				spread = 22.0
			Case 5
				g_training_int22 = 10
				g_training_int19 = 3
				rad = 10
				spread = 21.0
			Case 6
				g_training_int22 = 20
				g_training_int19 = 4
				rad = 10
				spread = 20.0
			Case 7
				g_training_int22 = 20
				g_training_int19 = 4
				rad = 10
				spread = 19.0
			Case 8
				g_training_int22 = 20
				g_training_int19 = 5
				rad = 10
				spread = 18.0
			Case 9
				g_training_int22 = 20
				g_training_int19 = 5
				rad = 10
				spread = 17.0
			Case 10
				g_training_int22 = 20
				g_training_int19 = 6
				rad = 10
				spread = 16.0
			Case 11
				g_training_int22 = 20
				g_training_int19 = 6
				rad = 11
				spread = 15.0
			Case 12
				g_training_int22 = 20
				g_training_int19 = 7
				rad = 11
				spread = 14.0
			Case 13
				g_training_int22 = 19
				g_training_int19 = 7
				rad = 11
				spread = 13.0
			Case 14
				g_training_int22 = 18
				g_training_int19 = 8
				rad = 11
				spread = 12.0
			Case 15
				g_training_int22 = 17
				g_training_int19 = 8
				rad = 11
				spread = 11.0
			Case 16
				g_training_int22 = 16
				g_training_int19 = 9
				rad = 12
				spread = 10.0
			Case 17
				g_training_int22 = 15
				g_training_int19 = 9
				rad = 12
				spread = 9.0
			Case 18
				g_training_int22 = 14
				g_training_int19 = 10
				rad = 12
				spread = 8.0
			Case 19
				g_training_int22 = 13
				g_training_int19 = 10
				rad = 12
				spread = 7.0
			Case 20
				g_training_int22 = 12
				g_training_int19 = 10
				rad = 12
				spread = 6.0
		End Select
		g_training_int13 = 0
		g_training_int14 = Int(TPitch.YardsToPixels(-10.0))
		g_training_int11 = g_training_int13
		g_training_int12 = g_training_int14
		rad = Int(TPitch.YardsToPixels(rad))
		For Local i:Int = 1 To g_training_int19
			Local a:Int = Rand(140, 1) + 200
			Local x:Int = Int(g_training_int11 + Cos(a) * rad)
			Local y:Int = Int(g_training_int12 + Sin(a) * rad)
			TCone.Create(x, y, 1)
			Local x2:Int = Int(g_training_int11 + Cos(a + spread) * rad)
			Local y2:Int = Int(g_training_int12 + Sin(a + spread) * rad)
			TCone.Create(x2, y2, 1)
			TTrainingLine.Create(x, y, x2, y2, "0000FF")
			rad :+ 25
		Next
	End Function

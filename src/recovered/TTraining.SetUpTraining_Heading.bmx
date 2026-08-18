' TTraining.SetUpTraining_Heading
' VA 0x0057EAC1   1799 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (1799/1799, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=142). Re-verified MATCH under NSS5_NO_LEARN=1 (no self-fulfilling masking).
' MATCHED on the first attempt using the already-solved twins TTraining.SetUpTraining_Shooting
' and TTraining.SetUpTraining_Dribbling for the g_training_int* / g_profile / g_traininglabel1
' naming, plus the "single line vs cone loop" split from Shooting's Case 9/10 tail Select.
'
' SHAPE NOTES (byte-observable)
'  * `g_training_int04 = g_profile.heading / 10 + 1` is ONE expression, not the two-statement
'    `*2+10` then `:/10` idiom Dribbling/Shooting use -- no intermediate store to int04 exists
'    between the `idiv` and the `add eax,1` in the disassembly.
'  * The 10-way `Select g_training_int04` is emitted in plain NUMERIC Case order (1..10) --
'    UNLIKE Shooting, which uses odd-then-even source order (its own note 12.2/10.2). Confirmed
'    by the `cmp/je` chain at 0x0057EC77, back to back 1,2,3,...,10 with a trailing `jmp` past
'    the last compare (no Default -- pattern 10.2).
'  * `Local dist:Float` is declared bare and set with a SEPARATE `dist = 0.0` statement (not a
'    `Local dist:Float = 0.0` initializer) -- the original still emits a real `fld 0.0 / fstp
'    [ebp-0x38]` immediately before the Select, which the elision rule of 16.3/21.1 would
'    otherwise have dropped. Same shape as the still-open TTeam.UpdatePlayerDestinations note;
'    here it happens to also be length- and byte-exact.
'  * Only the four ODD "cone course" cases (3,5,7,9) touch `dist`, and each sets a different
'    constant (6.5, 6.0, 5.5, 5.0 yards) read directly out of `data` (0x00C92688, 0x00C926BC,
'    0x00C926C0, 0x00C926C4) -- not guessed. Those same four cases are the only ones that set
'    `g_training_int03 = 8`; the other six leave it untouched, i.e. they assume the caller
'    already left it at 7 (TTraining.Call's dispatcher, per its own file's notes).
'  * The trailing `Select g_training_int03 / Case 7 / Case 8` (no Default) is the same shape as
'    Shooting's closing `Select g_trainingstate` (Case 9/10) -- single `TTrainingLine.Create`
'    line for the "aim at target" mode (7) vs a `For` loop of paired `TCone.Create` +
'    `TTrainingLine.Create` for the "cone course" mode (8).
'  * Case 8's loop places each pair of cones at an ABSOLUTE random offset from the pitch origin
'    (`Int(TPitch.YardsToPixels(Rand(-25,25)))`, `Int(TPitch.YardsToPixels(Rand(-45,-20)))`),
'    unlike Dribbling's cone loop, which offsets from a running `x`/`gap`. The second cone of
'    the pair is placed by angle: `Local a:Int = Rand(180,1) + 180` -- the `+180` on top of the
'    `Rand` result is genuinely part of this function (confirmed against the raw disassembly,
'    `add eax,0xb4` right after the `call Rand`); Dribbling's twin statement has no such offset.
'    ORIGINAL BUG/QUIRK preserved as written, not "fixed": Cos(a)/Sin(a) are evaluated on the
'    literal `Rand(180,1)+180` result, i.e. an angle in [181,360], not normalised to [0,180].
'  * The single-line branch (Case 7) computes `x`/`y` as `Local`s ONLY inside the
'    `g_training_int04 > 1 And g_training_int18 > 0` guard, matching Shooting's Case 9 body
'    almost verbatim (`TTrainingLine.Create(x, -y, -x, -y, "FF0000")`), but with the extra
'    `int04 > 1` half of the And that Shooting's twin does not have.
'  * `g_traininglabel1` (0x00C6CFB8, the same TLabel Global Shooting/Dribbling use) has its
'    `.SetText` called TWICE HERE on the SAME label (simple message, then advanced message if
'    `g_player_int14 = 1`) -- Shooting instead spreads simple/advanced/goals across TWO
'    different labels. Read from this function's own code, not copied from the twin.
'  * `g_training_int10`'s PRE-Select value is `GetText("CTRAINING_HEADING2")`, not "...HEADING1"
'    -- there is no "...HEADING1" string referenced anywhere in this function. Read directly
'    via `harness.read_string(0x00C925C8)`.
'
' Globals (all bare-dword Int/String access unless noted; every address already used by an
' already-recovered TTraining sibling carries the SAME name here for consistency):
'   0x00C6F028 g_profile:TProfile (field 0xB4="heading", field 0x78="contractwage")
'   0x00C6CF90 g_training_int03   0x00C6CF94 int04   0x00C6CF9C int06
'   0x00C6CFA4 int08$  0x00C6CFA8 int09$  0x00C6CFAC int10$
'   0x00C6CFB8 g_traininglabel1:TLabel (slot 0x64 SetText, inherited from TGadget)
'   0x00C6CFD0 int11   0x00C6CFD4 int12   0x00C6CFE8 int17   0x00C6CFEC int18
'   0x00C6CFF0 int19   0x00C6CFF8 int21   0x00C6CFFC int22
'   0x00C5D1AC g_player_int14 (Int)   0x00C5D634 g_player_int16 (Int)   0x00C5D638 g_player_int17 (Int)
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TTrainingLine+0x48=Create(i,i,i,i,$):TTrainingLine,
'   TCone+0x48=Create(i,i,i)i, TGadget+0x64=SetText($,$,i,i)i (via g_traininglabel1, a TLabel).
' Literals confirmed with harness.read_string()/direct float read, not guessed:
'   "SetUpTraining_Heading" "Heading Training" "Level" " " "CTRAINING_HEADING2"
'   "CMESSAGE_TRIALHEADINGSIMPLE" "CMESSAGE_TRIALHEADINGADVANCED" "CTRAINING_HEADING3"
'   "FF0000" "00FFFF" ; floats -45.0, 6.5, 6.0, 5.5, 5.0.
	Function SetUpTraining_Heading:Int()
		'!Global g_profile:TProfile
		'!Global g_training_int03:Int
		'!Global g_training_int04:Int
		'!Global g_training_int06:Int
		'!Global g_training_int08:String
		'!Global g_training_int09:String
		'!Global g_training_int10:String
		'!Global g_traininglabel1:TLabel
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int17:Int
		'!Global g_training_int18:Int
		'!Global g_training_int19:Int
		'!Global g_training_int21:Int
		'!Global g_training_int22:Int
		'!Global g_player_int14:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		LogLine("SetUpTraining_Heading")
		g_training_int04 = g_profile.heading / 10 + 1
		ClampInt(Varptr g_training_int04, 1, 10)
		g_training_int08 = GetText("Heading Training")
		g_training_int09 = GetText("Level") + " " + g_training_int04
		g_training_int10 = GetText("CTRAINING_HEADING2")
		If g_training_int04 = 1 And g_profile.contractwage = 0
			g_traininglabel1.SetText(GetText("CMESSAGE_TRIALHEADINGSIMPLE"), "", -1, -1)
			If g_player_int14 = 1
				g_traininglabel1.SetText(GetText("CMESSAGE_TRIALHEADINGADVANCED"), "", -1, -1)
			EndIf
		EndIf
		g_training_int06 = 60
		g_training_int11 = 0
		g_training_int12 = Int(TPitch.YardsToPixels(-45.0))
		g_training_int22 = -1
		Local dist:Float
		dist = 0.0
		Select g_training_int04
			Case 1
				g_training_int06 = 60
				g_training_int18 = 6
				g_training_int21 = 1
				g_training_int17 = 0
			Case 2
				g_training_int06 = 50
				g_training_int18 = 12
				g_training_int21 = 1
				g_training_int17 = 0
			Case 3
				g_training_int06 = 60
				g_training_int22 = -1
				g_training_int19 = 2
				dist = 6.5
				g_training_int10 = GetText("CTRAINING_HEADING3")
				g_training_int03 = 8
			Case 4
				g_training_int06 = 40
				g_training_int18 = 18
				g_training_int21 = 3
				g_training_int17 = 0
			Case 5
				g_training_int06 = 50
				g_training_int22 = -1
				g_training_int19 = 3
				dist = 6.0
				g_training_int10 = GetText("CTRAINING_HEADING3")
				g_training_int03 = 8
			Case 6
				g_training_int06 = 50
				g_training_int18 = 6
				g_training_int21 = 1
				g_training_int17 = 1
			Case 7
				g_training_int06 = 40
				g_training_int22 = -1
				g_training_int19 = 4
				dist = 5.5
				g_training_int10 = GetText("CTRAINING_HEADING3")
				g_training_int03 = 8
			Case 8
				g_training_int06 = 40
				g_training_int18 = 6
				g_training_int21 = 3
				g_training_int17 = 1
			Case 9
				g_training_int06 = 30
				g_training_int22 = -1
				g_training_int19 = 5
				dist = 5.0
				g_training_int10 = GetText("CTRAINING_HEADING3")
				g_training_int03 = 8
			Case 10
				g_training_int06 = 30
				g_training_int18 = 10
				g_training_int21 = 3
				g_training_int17 = 1
		End Select
		g_training_int12 = Int(-g_player_int17 + TPitch.YardsToPixels(g_training_int18 + 5))
		Select g_training_int03
			Case 7
				If g_training_int04 > 1 And g_training_int18 > 0
					Local x:Int = g_player_int16
					Local y:Int = Int(g_player_int17 - TPitch.YardsToPixels(g_training_int18))
					TTrainingLine.Create(x, -y, -x, -y, "FF0000")
				EndIf
			Case 8
				For Local i:Int = 1 To g_training_int19
					Local x:Int = Int(TPitch.YardsToPixels(Rand(-25, 25)))
					Local y:Int = Int(TPitch.YardsToPixels(Rand(-45, -20)))
					TCone.Create(x, y, 1)
					Local a:Int = Rand(180, 1) + 180
					Local cx:Int = Int(x + Cos(a) * TPitch.YardsToPixels(dist))
					Local cy:Int = Int(y + Sin(a) * TPitch.YardsToPixels(dist))
					TCone.Create(cx, cy, 1)
					TTrainingLine.Create(x, y, cx, cy, "00FFFF")
				Next
		End Select
	End Function

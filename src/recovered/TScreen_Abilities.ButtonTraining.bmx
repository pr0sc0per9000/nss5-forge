' TScreen_Abilities.ButtonTraining  -- KIND=Function (static method on the Type), slot 0x38
' VA 0x0053f4e0   448 bytes   sig ()i
' byte-identical vs NSS5.exe (448/448, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=36)
'
' ASSUMPTIONS
'  * Global 0x00C61CF8 declared TGadget, named g_activeGadget (name is ours).
'    globals_final.tsv has it as Object/usage/low. It is the engine's "active gadget"
'    cell: TGadget.GetActiveGadgetName, TScreen.FindNewActiveGadget, TCombo.Activate and
'    TButton.Draw all read it. Field +0x44 is TGadget.alph (Float), which is what this
'    body tests.
'  * Global 0x00C6F028 declared TProfile, named g_profile (name is ours). Typed
'    'construction/high' in globals_final.tsv; fields +0x16c = TProfile.injury (Int) and
'    +0x15c = TProfile.energy (Float) line up exactly, which corroborates it.
'  * PTR_FUN_00C621CC = TGadget classtable + 0x7c = TGadget.GetActiveGadgetName ()$.
'  * PTR_FUN_00C6D4D4 = TTraining classtable + 0x30 = TTraining.SetUpTraining (i)i.
'  * PTR_FUN_00C61CC0 = TScreen classtable + 0x94 = TScreen.DoMessage ($,i,i)i.
'    TScreen_Abilities extends Object(runtime), NOT TScreen, so the call needs the
'    explicit TScreen. prefix.
'  * PTR_FUN_00C66B78 = TScreen_Abilities classtable + 0x34 = SetUpScreen ()i -- this
'    Type's OWN table, so it is written unqualified (3d).
'  * FUN_004C5549 = GetText, ONE argument. Ghidra merges DoMessage's two trailing zero
'    pushes into it and prints GetText(&str,0,0).
'  * FUN_004A6A30 = _bbStringCompare (runtime_helpers.tsv, 332 witnesses).
'  * The seven name tests are a SELECT, not an If/ElseIf chain (10.2): every
'    _bbStringCompare/je pair sits back to back with all targets past the last compare.
'  * The float constant at 0x00C86D94 is 0x41A00000 = 20.0.
'
' CODEGEN NOTE -- FLOAT COMPARISON BRANCH POLARITY.
' The original computes `setae` for BOTH float tests and then skips the then-block with
' `jne`. That is bcc emitting the COMPLEMENT of the source relation and complementing the
' jump: source `a < b` lowers to fld a / fld b / fxch / fucompp / setae / jne-skip. Do not
' read the setcc as the source relation for floats -- `>=` here would be the wrong body.
' (The first fld is the LEFT operand; the fxch restores that order before fucompp.)
'!Global g_activeGadget:TGadget
'!Global g_profile:TProfile
	Function ButtonTraining:Int()
		If g_activeGadget.alph < 1.0
			If g_profile.injury > 0
				TScreen.DoMessage(GetText("CMESSAGE_NOTRAININGINJURY"), 0, 0)
				Return 0
			ElseIf g_profile.energy < 20.0
				TScreen.DoMessage(GetText("CMESSAGE_NOTRAININGTIRED"), 0, 0)
				Return 0
			Else
				TScreen.DoMessage(GetText("CMESSAGE_NOTRAININGMAX"), 0, 0)
				Return 0
			End If
		End If
		Select TGadget.GetActiveGadgetName()
			Case "btn_Pace"
				TTraining.SetUpTraining(1)
			Case "btn_Dribbling"
				TTraining.SetUpTraining(2)
			Case "btn_Tackling"
				TTraining.SetUpTraining(4)
			Case "btn_Passing"
				TTraining.SetUpTraining(6)
			Case "btn_Heading"
				TTraining.SetUpTraining(7)
			Case "btn_Shooting"
				TTraining.SetUpTraining(9)
			Case "btn_Flair"
				TTraining.SetUpTraining(3)
		End Select
		SetUpScreen()
	End Function

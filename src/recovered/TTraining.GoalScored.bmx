' TTraining.GoalScored
' VA        0x005823D6   slot 0xAC   KIND=Function (static)   SIG=(:TBall)i
' ORACLE    MATCH mode=reloc  407/407 bytes  reloc_masked=14
'
' MODULE GLOBALS DECLARED (names are ours; the declared TYPE is load-bearing)
'   0x00C6CFF8 g_train_goalsleft:Int   (table: Int/usage)   decremented with `sub [mem],1`
'   0x00C6CF90 g_train_mode:Int        (table: Int/usage)   the Select subject
'   0x00C5D638 g_train_goalline:Int    (table: Int/usage)   negated as an Int, then fild
'   0x00C6CFEC g_train_targetyards:Int (table: Int/usage)   fild'd into the (f) parameter
'   0x00C6CF78 g_snd_goal:TSound       table says Object/low -- typed TSound because it is
'                                      argument 1 of brl.audio PlaySound
'   0x00C6CF80 g_snd_miss:TSound       same, the else-branch sound
'   0x00C5B348 g_sndchannel:TChannel   argument 2 of PlaySound
'   All four Ints are bare `mov`s with no refcount traffic (guide 11.2), so Int is right.
'
' CALL TARGETS RESOLVED
'   0x0059B25E              -> brl.audio PlaySound (brl_functions.tsv)
'   call [0x00C5D998]       -> TPitch+0x6C = TPitch.YardsToPixels(f)f -- a class-table
'                              interior, NOT a Global (globals_final marks it
'                              type_source=classtable-slot).
'   call [0x00C6D558]       -> TTraining+0xB4 = ResetTraining()i. That is THIS Type's own
'                              class table, so per guide 3d it is written as a bare sibling
'                              call `ResetTraining()`, with no `TTraining.` prefix.
'
' FIELD OFFSETS
'   TBall   +0x1C y:Float   +0x68 lastkicktype:Int   +0x74 lastkickedby:TPlayer
'   TPlayer +0x08 newstar:Int   +0x98 kicky:Int
'
' SOURCE-FORM NOTES
'   * The dispatch is a SELECT, not If/ElseIf: eleven `cmp ecx,<n>/je` back to back at
'     0x00582425-0x0058245B with every target past the LAST compare, then `jmp` for the
'     no-match path (guide 10.2). There is no Default -- Case 10 has an EMPTY body, which
'     is why it emits a bare `EB 00`.
'   * Cases 1-6 and 8 each get their OWN 10-byte body (`mov eax,0 / jmp epilogue`), so they
'     are seven separate `Case` clauses each containing `Return 0`, not one `Case 1,2,...`
'     clause. A combined clause would emit a single shared body.
'   * `ok` is an Int Local that bcc keeps in EAX across the whole Select.
'   * Cases 7 and 9 are `If <cmp> Then ok = 0` guards, and the relational spelling is
'     byte-observable (guide 10.1): case 7 is `< 4` (cmp [edx+0x68],4 / jge over) and
'     case 9 is `> 3` (cmp [edx+0x68],3 / jle over) -- NOT `<= 3` / `>= 4`.
'   * The final comparison is Float because TPitch.YardsToPixels returns Float; the x87
'     temps at [ebp-4]/[ebp-8] are compiler spills, not source Locals. Evaluation order in
'     the original is kicky first, then -goalline, then YardsToPixels, which is
'     `lhs > rhs` with the parameter-derived side on the left (guide 10.1).
'   * The whole thing is an If-BLOCK, not an early return: the outer test's false path
'     lands on the function's own trailing `mov eax,0`.

Function GoalScored(a0:TBall)
	'!Global g_train_goalsleft:Int
	'!Global g_train_mode:Int
	'!Global g_train_goalline:Int
	'!Global g_train_targetyards:Int
	'!Global g_snd_goal:TSound
	'!Global g_snd_miss:TSound
	'!Global g_sndchannel:TChannel
	If a0.y < 0.0 And g_train_goalsleft > 0 And a0.lastkickedby <> Null Then
		Local ok:Int = 1
		Select g_train_mode
			Case 1
				Return 0
			Case 2
				Return 0
			Case 3
				Return 0
			Case 4
				Return 0
			Case 5
				Return 0
			Case 6
				Return 0
			Case 7
				If a0.lastkicktype < 4 Then ok = 0
			Case 8
				Return 0
			Case 9
				If a0.lastkicktype > 3 Then ok = 0
			Case 10
		End Select
		If ok And a0.lastkickedby.newstar And a0.lastkickedby.kicky > -g_train_goalline + TPitch.YardsToPixels(g_train_targetyards) Then
			g_train_goalsleft :- 1
			PlaySound(g_snd_goal, g_sndchannel)
			ResetTraining()
		Else
			PlaySound(g_snd_miss, g_sndchannel)
		End If
	End If
End Function

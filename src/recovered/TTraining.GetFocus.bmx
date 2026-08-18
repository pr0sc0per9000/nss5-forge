' TTraining.GetFocus  (:TPlayer,*f,*f)i   slot 0xa8   KIND=Function (static, no Self)
' VA 0x0058222D   length 425   oracle: MATCH mode=reloc 425/425 reloc_masked=15
'
' Assumptions:
'   '!Global g_matchstate:Int      0x00C5B1FC  (globals_final: Int, type_source=verified)
'   '!Global g_trainingfocus:Int   0x00C6CF90  (globals_final: Int, usage/medium; bare dword
'                                   loads with no refcount traffic confirm Int)
'   '!Global g_pitchtopy:Int       0x00C5D638  (globals_final: Int, usage/medium; `mov eax,[g]
'                                   / neg eax / fild` confirms a signed Int, not a Float)
'   TPitch.YardsToPixels (f)f is class-table TPitch + slot 0x6c = PTR_FUN_00C5D998.
'   TBall.GetActiveBall ():TBall is class-table TBall + slot 0x44 = PTR_FUN_00C5AEDC.
'   The 0.75 multiplier in Case 3 is the .rdata float at 0x00C92A2C, read out of NSS5.exe
'   (0x3F400000).  NOTE: that operand is an absolute data address and is therefore MASKED
'   by the oracle, so the match does not by itself prove the constant's VALUE -- only that
'   a single .rdata float is loaded there.  The value comes from reading the exe.
'
' Shape notes:
'   The 12-compare is an EARLY RETURN (cmp/jne/mov eax,0/jmp epilogue), not an If block.
'   The 11 compares run back-to-back with every target past the last one, so this is a
'   Select (guide 10.2), not If/ElseIf.  Case 0 is present and EMPTY -- it jumps straight
'   to the end-of-select label.  There is no Default and no statement after End Select.
Function GetFocus:Int(a0:TPlayer, a1:Float Ptr, a2:Float Ptr)
	'!Global g_matchstate:Int
	'!Global g_trainingfocus:Int
	'!Global g_pitchtopy:Int
	a1[0] = a0.x
	a2[0] = a0.y
	If g_matchstate = 12 Then Return 0
	Select g_trainingfocus
	Case 0
	Case 1
		a1[0] = a0.x
		a2[0] = a0.y
	Case 2
		a1[0] = a0.x
		a2[0] = a0.y
	Case 3
		a1[0] = 0
		a2[0] = -g_pitchtopy * 0.75
	Case 4
		a1[0] = a0.x
		a2[0] = a0.y
	Case 5
		a1[0] = a0.x
		a2[0] = a0.y - TPitch.YardsToPixels(5.0)
	Case 6
		a1[0] = a0.x
		a2[0] = a0.y - TPitch.YardsToPixels(30.0)
	Case 7
		If TBall.GetActiveBall() <> Null
			a1[0] = 0
			a2[0] = -g_pitchtopy
		EndIf
	Case 8
		a1[0] = a0.x
		a2[0] = a0.y
	Case 9
		If TBall.GetActiveBall() <> Null
			a1[0] = 0
			a2[0] = -g_pitchtopy
		EndIf
	Case 10
		If TBall.GetActiveBall() <> Null
			a1[0] = 0
			a2[0] = -g_pitchtopy
		EndIf
	End Select
End Function

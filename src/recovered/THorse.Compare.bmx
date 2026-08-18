' THorse.Compare
' VA 0x0058b55b   957 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (957/957, original length from Ghidra's inventory, mode=reloc)
' Assumption: module global at 0x00c6e29c declared as Int, named g_screen_stable_int26
' after extracted/globals_named.tsv. The dispatch is a Select on that global (bcc loads
' the global once into eax then emits a cmp/je chain -- an If/ElseIf chain re-reads it).
' Float comparisons put the downcast argument on the LEFT of the operator: that is the
' operand bcc pushes onto the x87 stack first, so 'THorse(a0).x > x' and 'x < THorse(a0).x'
' are NOT the same bytes.
' Case 30 uses Float locals: the original converts both Int GetValue() results with
' fild/fstp and compares on the FPU.
'
' Verified from scratch with the '!Global pragma below -> MATCH
' 957/957, reloc_masked=40. A BUILD_FAIL without them is a harness limitation
' (it cannot bind a Global from prose alone), not a body defect.
	Method Compare:Int(a0:Object)
		'!Global g_screen_stable_int26:Int
		Select g_screen_stable_int26
			Case 1
				If THorse(a0).id < id Then Return 1
				If THorse(a0).id > id Then Return -1
			Case 31
				If THorse(a0).racenum < racenum Then Return 1
				If THorse(a0).racenum > racenum Then Return -1
			Case 5
				If THorse(a0).randno < randno Then Return 1
				If THorse(a0).randno > randno Then Return -1
			Case 7
				If THorse(a0).x > x Then Return 1
				If THorse(a0).x < x Then Return -1
			Case 29
				Local pos1:Int = THorse(a0).raceposition
				Local pos2:Int = raceposition
				If pos1 = 0 Then pos1 = 99
				If pos2 = 0 Then pos2 = 99
				If pos1 < pos2 Then Return 1
				If pos1 > pos2 Then Return -1
				If THorse(a0).x > x Then Return 1
				If THorse(a0).x < x Then Return -1
			Case 11
				If THorse(a0).strength < strength Then Return 1
				If THorse(a0).strength > strength Then Return -1
				If THorse(a0).name < name Then Return 1
				If THorse(a0).name > name Then Return -1
			Case 30
				Local val1:Float = THorse(a0).GetValue()
				Local val2:Float = GetValue()
				If val1 < val2 Then Return 1
				If val1 > val2 Then Return -1
				If THorse(a0).strength < strength Then Return 1
				If THorse(a0).strength > strength Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method

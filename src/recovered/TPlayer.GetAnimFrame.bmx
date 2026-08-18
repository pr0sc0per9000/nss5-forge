' TPlayer.GetAnimFrame
' VA 0x004FC12E   135 bytes   vtable slot 0x194   sig (i)i
' byte-identical vs NSS5.exe (135/135, mode=exact, original length from Ghidra's inventory)
' no assumptions -- no Globals, no indirect calls.
' KEY FINDING: the guard is `If Not currentanim`, NOT `If currentanim.length = 0`.
'   `Not <array>` emits `cmp [arr+0x10],0`  (BBArray.size)
'   `.length`     emits `cmp [arr+0x14],0`  (BBArray.scales[0])
'   Both are semantically the same test here, but only the first reproduces the byte.
'   `Len(arr)` is the same as `.length`; `arr = Null` is a pointer compare (126/135).
' The `a0 <> 0` / `f = -1` pair is NESTED Ifs, not `And` -- `And` emits setne/movzx/cmp
' per operand and comes out 21 bytes long.
' Parameter names are not recoverable from the binary; a0 as emitted by the harness.
	Method GetAnimFrame:Int(a0:Int)
		If Not currentanim Then Return -1
		Local f:Int = currentanim[frame]
		If a0 <> 0
			If f = -1 Then f = currentanim[frame-1]
		End If
		Select facing
			Case 0
			Case 1
			Case 2
				If f <> -1 Then f = f + 64
			Case 3
				If f <> -1 Then f = f + 128
		End Select
		Return f
	End Method

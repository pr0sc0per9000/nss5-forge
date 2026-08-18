' TBall.RecordReplayFrame
' VA 0x004cbf3c   242 bytes   vtable slot 0xac   sig (i)i
' byte-identical vs NSS5.exe (242/242, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C5B2B4 and 0x00C6F02C declared Int (integer idiv in the loop test).
'   TList slots 0x44 AddLast, 0x48 First, 0x50 RemoveFirst.
'   The guard is an EARLY RETURN in the `If Not x` emission (setne/movzx/cmp/jne then
'   mov eax,0 / jmp epilogue); the enclosing-If form is 224 bytes.
'   The loop test's operand order is load-bearing: the original computes First() FIRST and
'   compares `cmp [ebx+8], ecx / jl`, so frametime must be on the LEFT. With the operands
'   swapped the body is 240 bytes (see codegen-patterns 10.1).
'!Global g_replay_maxtime:Int
'!Global g_replay_div:Int
	Method RecordReplayFrame(a0:Int)
		If Not Self.replayframes Then Return 0
		Local f:TReplayFrame = New TReplayFrame
		f.frametime = a0
		f.id = Self.id
		f.obtext = Self.colour
		f.obtype = 1
		f.x = Self.x
		f.y = Self.y
		f.z = Self.z
		f.frame = Self.frame
		f.alph = Self.alph
		f.active = Self.active
		Self.replayframes.AddLast(f)
		While TReplayFrame(Self.replayframes.First()).frametime < a0 - g_replay_maxtime / g_replay_div
			Self.replayframes.RemoveFirst()
		Wend
	End Method

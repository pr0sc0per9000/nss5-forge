' TTeam.ResetCornerFormation
' VA 0x004DDFB2   240 bytes   vtable slot 0x60
' byte-identical vs NSS5.exe (240/240, original length from Ghidra's inventory, mode=reloc)
'
' g_goalline:Int is the Global at 0x00C5D638, read at 0x004DE016
' `a138d6c500 mov eax, dword ptr [0xc5d638]`; this body never touches 0x00C5D674.
' g_pitch_int17 is TPitch.DrawBosses' and TPlayer.DoAnimCelebrate's name for 0x00C5D674,
' the dugout y, which nothing writes under that spelling, so the corner formation's base
' y was 0 (the halfway line) instead of the goal line.
' `Local n:Int = Rand(4,5)` then `For i = 1 To n` is load-bearing: writing the Rand call
' inline in the To-expression puts `mov esi,1` BEFORE the call and diffs at byte 24.
	Method ResetCornerFormation:Int()
		'!Global g_goalline:Int
		Self.cornerformation.Clear()
		Local n:Int = Rand(4,5)
		For Local i:Int = 1 To n
			Local v:TMyVector = New TMyVector
			v.X = TPitch.YardsToPixels(Rand(-12,12))
			v.Y = g_goalline - TPitch.YardsToPixels(Rand(8,18))
			v.Y = v.Y * Self.GetShootingDirection()
			Self.cornerformation.AddLast(v)
		Next
	End Method

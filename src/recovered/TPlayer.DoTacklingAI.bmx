' TPlayer.DoTacklingAI
' VA 0x004F2CA9   302 bytes   vtable slot 0xA4   sig ()i   KIND=Method
' ORACLE: mode=reloc  matched=302/302  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C5DEA4 g_ball:TBall   (globals_final says TPlayer; codegen-patterns 11.2 corrects it
'                              to TBall, and +0x70 controlledby:TPlayer is TBall's field)
'   0x00C6EFD4 g_player_int50:Int  (bare dword copy, no refcount traffic)
' Class-table static calls resolved:
'   0x00C5D998 = TPitch+0x6C -> YardsToPixels(f)f
'   0x00C5D988 = TPitch+0x5C -> InsidePenaltyBox(i,i,i)i
' Self slots: 0x174 = GetMyTeam, 0x160 = GetShootingDirection.
' AngleDiff is the recovered module Function at 0x00506049, sig (f,f,i)f.
' Fields from object_model.json: TPlayer x(+0x4C) y(+0x50) speed(+0x74) direction(+0x78)
'   distancetoball(+0xD0) joy(+0x158):TJoy; TJoy kickbuttondown(+0x1C) kickbuttonhits(+0x20);
'   TTeam controller(+0x18) newstarselno(+0x3C).
'
' NOTE  `2.5` is the Float immediate 0x40200000 pushed straight to YardsToPixels.
' NOTE  x87 setcc reads as the source relation here (the operand order is what fxch fixes):
'       setb -> `dist < YardsToPixels(..)`, seta -> `ang > lim` and `speed > 1.0`.
' NOTE  The trailing `Return 0` inside the innermost block is REAL -- without it the body is
'       exactly 7 bytes short, i.e. one `mov eax,0 / jmp epilogue` pair (295 vs 302).

'!Global g_ball:TBall
'!Global g_player_int50:Int

Local t:TTeam = Self.GetMyTeam()
If (t.controller = 0 Or t.newstarselno > 0) And Self.distancetoball < TPitch.YardsToPixels(2.5)
	Local ang:Float = AngleDiff(g_ball.controlledby.direction, Self.direction, 1)
	Local lim:Int = 115
	If TPitch.InsidePenaltyBox(Int(Self.x), Int(Self.y), -Self.GetShootingDirection()) Then lim = 155
	If ang > lim And Self.speed > 1.0
		Self.joy.kickbuttonhits = g_player_int50
		Self.joy.kickbuttondown = 0
		Return 0
	EndIf
EndIf

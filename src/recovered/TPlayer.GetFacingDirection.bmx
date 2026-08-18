' TPlayer.GetFacingDirection
' VA 0x004FAF81   575 bytes   vtable slot 0x16C   sig (f)i   KIND=Method
' byte-identical vs NSS5.exe (575/575, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=21)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C5B1FC Int    g_player_int01 (globals_final type_source='verified', high)
'    0x00C5DEB0 Int[]  g_anim_run     (globals_final says Object[]; it is compared for
'                                      IDENTITY against TPlayer.currentanim, which is
'                                      []i, so Int[] is the consistent element type)
'    0x00C5DEA4 TBall  g_ball         (globals_final type_source='verified', high --
'                                      the earlier TPlayer guess is flagged unsound)
'  Fields: TPlayer +0x50 y(f), +0xBC selectionno(i), +0x130 currentanim([]i);
'          TBall +0x1C y(f).
'  Slots: TPlayer 0x160 = GetShootingDirection()i.
'  Helpers: 0x00506184 = WrapAngle (module Function, `Float Var`; called with
'    `lea eax,[ebp-4]` on a LOCAL COPY of the parameter, which is why the source needs
'    `Local ang:Float = a0` -- passing the parameter directly would not create the slot).
'    0x004A7FE0 is a 3-instruction `fld qword [esp+4] / fabs / ret` = Abs.
'  Float constants (read from .rdata): 305.0, 45.0, 45.0, 135.0, 135.0, 215.0.
'  SHAPE (measured, cost 18 bytes on the first attempt):
'    The GetShootingDirection test is a SEPARATE NESTED `If`, not the sixth term of the
'    And chain.  As a sixth conjunct bcc materialises it (`cmp eax,-1 / sete / movzx /
'    cmp eax,0 / je`, 14 bytes); the original tests it directly (`cmp eax,-1 / jne`,
'    5 bytes).  Both nested-If exits land on the same `Return 3` / `Return 2`, which is
'    exactly what the two identical jump targets in the original show.
'    The head guard is an Or short-circuit early return, and each range test reads its
'    setcc literally: `seta` = `>`, `setbe` = `<=`.
	'!Global g_player_int01:Int
	'!Global g_anim_run:Int[]
	'!Global g_ball:TBall
	Method GetFacingDirection:Int(a0:Float)
		Local ang:Float = a0
		WrapAngle(ang)
		If ang > 305.0 Or ang <= 45.0 Then Return 1
		If ang > 45.0 And ang <= 135.0
			If Self.selectionno = 0 And g_player_int01 = 1 And Self.currentanim = g_anim_run And g_ball <> Null And Abs(g_ball.y) < Abs(Self.y)
				If Self.GetShootingDirection() = -1 Then Return 2
			EndIf
			Return 3
		EndIf
		If ang > 135.0 And ang <= 215.0 Then Return 0
		If Self.selectionno = 0 And g_player_int01 = 1 And Self.currentanim = g_anim_run And g_ball <> Null And Abs(g_ball.y) < Abs(Self.y)
			If Self.GetShootingDirection() = 1 Then Return 3
		EndIf
		Return 2
	End Method

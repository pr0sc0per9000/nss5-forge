' TPlayer.InterceptBall -- NOT VERIFIED (revised by a
' later pass that read the FULL original disassembly at VA 0x004F9201 instead of only the
' Ghidra C, via scripts/bytematch.py's disasm_original(0x004f9201, 696)).
' VA 0x004F9201   696 bytes   vtable slot 0x124   sig (:TBall)i
' Previous score: 307/686 (44.8%), first diff at byte 5 (the `sub esp,N` immediate --
' i.e. the whole local-variable/stack-slot layout was off, not a late statement).
'
' RESOLVED, from the raw disassembly (not just the Ghidra pseudo-C):
'   TBall fields: velocity+84 jumpx+56 jumpy+60 direction+92 x+24 y+28
'   TPlayer fields used: x+76 y+80 xvel+100 yvel+104 desx+124 desy+128
'   TMyVector fields X/Y/Z are PUBLIC (+8/+16/+24).
'   TMyVector.Sub/.Add/.Mul all MUTATE Self in place and return Self (confirmed again by
'     reading TMyVector.Sub/.Add/.Mul's own byte-identical bodies in src/recovered/).
'   AngleTo(x1,y1,x2,y2):Float is the free Function form (0x0050639d); AngleDiff(a0,a1,a2)
'     is src/recovered_module/AngleDiff.bmx, called as AngleDiff(ang2, ang1, 1).
'   Outer guard is `a0.velocity < 2.0` (small/reset block as Then, big block as Else) --
'     re-derived directly from the fxch/fucompp/setae/jne sequence at the very top and it
'     matches what was already here; unchanged.
'   `a0.jumpx <> 0.0` guard direction likewise re-derived and unchanged.
'   Constant 0x00C7A040 (double) = 0.949999988079071, a Float literal 0.95 promoted.
'   Constant 0x00C7A03C (float) = 2.0.  Global 0x00C7A048 (double) g_player_double15=90.0.
'   Every leaf has its own explicit `Return 0`; unchanged.
'
' WHAT WAS ACTUALLY WRONG (found by walking the real instruction stream end to end):
'   1. vx/vy were declared Double. The original stores them with `fstp DWORD ptr`
'      (D9 opcode), i.e. Float, not `fstp QWORD` (DD). Sibling TBall.UpdateAnimation.bmx
'      uses the exact same idiom (`Local vx:Float = Cos(direction)`), confirming Float is
'      how this project spells it. Fixed: vx, vy are now Float.
'   2. There is NO separate `speed` Local. The original computes
'      `dist = ballPos.Sub(playerPos).GetLength()` (Sub's return value chained straight
'      into GetLength(), never spilled -- exactly like Normalize.bmx's
'      `Local d:Double = 1.0 / GetLength()` idiom, just chained), then
'      `t = dist / relVel.GetLength()` with relVel.GetLength() evaluated directly as the
'      divisor. relVel itself DOES get its own slot (ebp-0x28) because its Sub() call
'      happens before dist's Sub()+GetLength() chain and must survive across it -- but
'      there is no persisted "relPos" and no persisted "speed"; removing the extra Local
'      is exactly the missing/extra 8-byte stack slot that made `sub esp` 0x34 instead of
'      the original's 0x2C.
'   3. The tail (SetX/SetY/Mul/Add) operates on ballPos (ebp-4) and ballVel (register
'      edi) -- the ORIGINAL un-subtracted vectors -- not on relPos/relVel. Concretely:
'      after computing dist and t only from the subtracted lengths, the code resets
'      ballPos back to (a0.x,a0.y) and ballVel back to (vx,vy) via SetX/SetY (undoing
'      Sub's in-place mutation) and only THEN does `ballPos.Add(ballVel.Mul(adjT))`.
'      This looks redundant (SetX/SetY restore the exact values ballPos/ballVel were
'      Created with) but it is what the bytes show: ballPos's slot (-4) and ballVel's
'      register (edi) are reloaded directly for every one of these calls, and relPos
'      never gets a memory slot in the whole function (it lives only in eax for the one
'      instruction between its Sub() and its chained GetLength()) -- there is nothing
'      left to call SetX on. This is being preserved as a probable original bug/quirk,
'      per the "preserve original behaviour" rule, not fixed.
'   Net effect of 1-3: the reconstructed stack layout now lands on exactly the same 9
'   slots the disassembly uses (ebp-4, -0xc, -0x14, -0x18, -0x1c, -0x20, -0x24, -0x28,
'   -0x2c), with -0x2c as the deepest -> frame size 0x2C, matching the original exactly.
'
' Chained method calls like `ballPos.Sub(playerPos).GetLength()` are an established idiom
' in this project (e.g. TCompetition.GetNoofTeamsInRound.bmx's
' `TCompetition.SelectById(pp.parentid).GetNoofTeamsInRound()`, TLocale.SetUp.bmx's
' `ReadLine(a1).Replace(";", ",").Trim()`), so this is not a novel construct for bcc here.

	Method InterceptBall:Int(a0:TBall)
		'!Global g_player_double15:Double
		If a0.velocity < 2.0
			desx = a0.x
			desy = a0.y
			Return 0
		Else
			If a0.jumpx <> 0.0
				desx = a0.jumpx
				desy = a0.jumpy
				Return 0
			Else
				Local vx:Float = Cos(a0.direction) * a0.velocity
				Local vy:Float = Sin(a0.direction) * a0.velocity
				Local ballPos:TMyVector = TMyVector.Create(a0.x, a0.y, 0)
				Local ballVel:TMyVector = TMyVector.Create(vx, vy, 0)
				Local playerPos:TMyVector = TMyVector.Create(Self.x, Self.y, 0)
				Local playerVel:TMyVector = TMyVector.Create(Self.xvel, Self.yvel, 0)
				Local relVel:TMyVector = ballVel.Sub(playerVel)
				Local dist:Double = ballPos.Sub(playerPos).GetLength()
				Local t:Double = dist / relVel.GetLength()
				Local adjT:Double = t
				adjT :* 0.95
				ballPos.SetX(a0.x)
				ballPos.SetY(a0.y)
				ballVel.SetX(vx)
				ballVel.SetY(vy)
				Local landing:TMyVector = ballPos.Add(ballVel.Mul(adjT))
				desx = landing.GetX()
				desy = landing.GetY()
				Local ang1:Float = AngleTo(Self.x, Self.y, a0.x, a0.y)
				Local ang2:Float = AngleTo(Self.x, Self.y, desx, desy)
				If AngleDiff(ang2, ang1, 1) > g_player_double15
					desx = a0.x
					desy = a0.y
					Return 0
				EndIf
				Return 0
			EndIf
		EndIf
	End Method

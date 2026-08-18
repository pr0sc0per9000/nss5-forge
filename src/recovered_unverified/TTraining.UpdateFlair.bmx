' TTraining.UpdateFlair -- NOT VERIFIED. KIND=Function (static), slot 0x68, sig ()i
' VA 0x00580761   898 bytes (Ghidra-authoritative)
' PRIOR RESULT: ours = 896 bytes, delta -2, 10.8% byte agreement
' -- length was close but the byte-agreement was low because several comparisons
' and one whole control-flow region used the wrong shape. Reworked by disassembling BOTH
' sides (capstone, not just Ghidra's C) and diffing instruction-by-instruction.
' Fixes below, each confirmed
' against the actual x87/branch bytes, not just the decompiled C text:
'
'  1. OUTER GUARD + flag1 fused into ONE compound And condition (was: nested
'     `If ball.kicktime > 0` wrapping a separately-declared `Local flag1`). The original's
'     `ball.kicktime>0` test uses the SAME materialised-boolean shape
'     (mov/cmp/setg/movzx/cmp/je) as the old flag1 test, and the two tests share their
'     final `cmp eax,0` check -- textbook short-circuit `And` codegen (eval A, if false
'     jump past B straight into the shared false-check with A's 0 already in eax; else
'     eval B, fall into the same shared check). Confirmed against the verified sibling
'     `TBall.CheckLongShotRating.bmx`, whose header documents exactly this pattern
'     ("three tests are ONE short-circuit And chain... the falsy exit simply leaves that 0
'     in eax"). New shape:
'       `If ball.kicktime > 0 And g_time > ball.kicktime + 1000 ... EndIf`
'  2. `flag2 = (ball.controlledby = human)` replaced with
'     `If ball.controlledby = human Then flag2 = True`. The original stores via a bare
'     `cmp/jne/mov [flag2],1` (flag2 already False, so the "no" branch just leaves it
'     alone) -- NOT a `cmp/sete/movzx/mov` full materialise-then-assign, which is what a
'     direct `flag2 = (cond)` expression assignment compiles to. Same total length either
'     way (18 bytes) but different opcodes, so it silently failed to match before.
'  3. `If 0.0 < ball.y Then flag2 = True` -> `If ball.y > 0.0 Then flag2 = True`. Ghidra
'     prints `0.0 < y` regardless of source order (guide 10.1); the real push order is
'     `fld ball.y` THEN `fldz` THEN `fxch` -- ball.y is evaluated (and pushed) FIRST, which
'     only happens when it is the left-hand operand as written.
'  4. Pole-max loop: `If maxDist < d Then maxDist = d` -> `If d > maxDist Then maxDist = d`.
'     Same operand-order issue as #3: the original needs an `fxch`/`fucom`/`fxch`/`fstp`
'     dance to bring the freshly-called Dist2D result back to the top of the x87 stack
'     before comparing, which only happens when Dist2D's result (evaluated first, via the
'     call) is the LEFT operand. Reversing the operand order reproduces this exactly --
'     the previous header's theory that this was an unresolvable "spill vs no-spill"
'     x87-allocation mystery was a mis-read; it was a plain comparison-direction bug
'     (guide 10.1), and no change to whether `d` gets a memory slot was needed at all.
'  5. `Local ballDist:Float = Dist2D(...)` / `If maxDist + 20.0 < ballDist Then flag2=True`
'     -> `If ballDist > maxDist + 20.0 Then flag2 = True`. Same left-operand rule as #4:
'     ballDist (the call result, evaluated first) must be the side that gets `fxch`'d back
'     to the top, which only happens when it is written first.
'  6. The `flag3` / `ballDist2` block never existed as separate Locals in the original --
'     it is the RHS of a SECOND And-fusion with `lineAlive <> 0`, exactly like #1:
'     `If lineAlive <> 0 And Dist2D(human.x,human.y,ball.x,ball.y) > minDist + 100.0
'          Then flag2 = True`
'     `lineAlive<>0` false leaves 0 in eax and falls straight into the shared "skip store"
'     check, so Dist2D is only ever called when lineAlive<>0 (one call site, matching the
'     original's single `call 0x505da2` here). No `flag3`/`ballDist2` Locals needed.
'  7. Final block rewritten to drop the `redFound:Int` flag + `Exit` entirely:
'       `For Local pole:TPole = EachIn g_Object813
'            If pole.colour = "FF0000" Then Return 0
'        Next`
'     matches the verified sibling `TBall.GetActiveBall.bmx`'s
'     `For Local b:TBall = EachIn g_balls : If b.active Then Return b : Next` idiom
'     exactly -- the original's do-while breaks straight to the function's `mov eax,0 /
'     jmp <epilogue>` on a match, with NO flag and no further work, confirmed
'     instruction-for-instruction against the disassembly (only embedded addresses
'     differ). The alive-count loop and `TTraining.Success()` call that follow are NOT
'     gated by an `If Not redFound` any more -- they are simply the code that runs when
'     the search loop falls through unmatched, which is what "no separate flag" naturally
'     produces.
'
' STILL TRUE FROM BEFORE (unchanged, already correct):
'  * `If g_training_int22 = -1 Then g_training_int22=0; Fail(); Return 0` is an early
'    return (guide 10.9).
'  * `ball = TBall.GetActiveBall()`, `human = TPlayer.GetHumanPlayer()` -- both called
'    unconditionally before `If ball <> Null`.
'  * Two EachIn loops over `g_Object813:TList` filtered by declared Local type
'    (`TPole` classtable 0x00C6D9A4, `TTrainingLine` classtable 0x00C6DC1C).
'  * `TEngine.SetUpSetPiece(4, 1, g_training_int13, g_training_int14)` guarded by
'    `If flag2`.
'
' Globals used (names ours, TYPES load-bearing):
'   0x00C6CFFC g_training_int22:Int   0x00C6EFD4 g_time:Int (same address as TTraining.Update)
'   0x00C6D568 g_Object813:TList (globals_final.tsv wrongly says bare Object, low conf --
'     the refcount-free `+0x8C ObjectEnumerator` traffic at every call site proves TList,
'     guide 10.7)
'   0x00C6CFD8 g_training_int13:Int, 0x00C6CFDC g_training_int14:Int (SetUpSetPiece args,
'     same Globals TTraining.Call already established)
' Float literal constants read directly from the image (NOT Globals): 0.0, 20.0, 0.0, 100.0
' at 0x00C92910/14/18/1C.
' Module Function reused: Dist2D (src/recovered_module/Dist2D.bmx, already verified).
' Fields: TBall.kicktime +0x64, TBall.controlledby +0x70, TBall.x/y +0x18/0x1C,
'   TPlayer.x/y +0x4C/0x50, TTrainingObject.x/y/alive +0x10/0x14/0x18 (inherited by
'   TPole and TTrainingLine), TPole.colour +0x24, TTrainingLine.alive (inherited).
	Function UpdateFlair:Int()
		'!Global g_training_int22:Int
		'!Global g_time:Int
		'!Global g_Object813:TList
		'!Global g_training_int13:Int
		'!Global g_training_int14:Int
		If g_training_int22 = -1
			g_training_int22 = 0
			TTraining.Fail()
			Return 0
		EndIf
		Local ball:TBall = TBall.GetActiveBall()
		Local human:TPlayer = TPlayer.GetHumanPlayer()
		If ball <> Null
			Local flag2:Int = False
			If ball.kicktime > 0 And g_time > ball.kicktime + 1000
				If ball.controlledby = human Then flag2 = True
				If ball.kicktime + 4500 < g_time Then flag2 = True
			EndIf
			If ball.y > 0.0 Then flag2 = True
			Local maxDist:Float = 0.0
			For Local p:TPole = EachIn g_Object813
				Local d:Float = Dist2D(human.x, human.y, p.x, p.y)
				If d > maxDist Then maxDist = d
			Next
			Local ballDist:Float = Dist2D(human.x, human.y, ball.x, ball.y)
			If ballDist > maxDist + 20.0 Then flag2 = True
			Local minDist:Float = 0.0
			Local lineAlive:Int = 0
			For Local l:TTrainingLine = EachIn g_Object813
				Local d2:Float = Dist2D(human.x, human.y, l.x, l.y)
				If minDist = 0.0 Or d2 < minDist
					minDist = d2
					lineAlive = l.alive
				EndIf
			Next
			If lineAlive <> 0 And Dist2D(human.x, human.y, ball.x, ball.y) > minDist + 100.0
				flag2 = True
			EndIf
			If flag2 Then TEngine.SetUpSetPiece(4, 1, g_training_int13, g_training_int14)
		EndIf
		For Local pole:TPole = EachIn g_Object813
			If pole.colour = "FF0000" Then Return 0
		Next
		Local n:Int = 0
		For Local l2:TTrainingLine = EachIn g_Object813
			If l2.alive <> 0 Then n :+ 1
		Next
		If n = 0 Then TTraining.Success()
		Return 0
	End Function

' TTraining.UpdateFlair
' VA 0x00580761   898 bytes   vtable slot 0x68   sig ():Int
' byte-identical vs NSS5.exe (898/898, mode=reloc, reloc_masked=38)
' KIND=Function (static). Wrapper format (Function ... End Function).
'
' Oracle: harness.try_method under NSS5_NO_LEARN=1, MATCH 898/898, body passed body-only.
' Negative controls, both discriminating: changing the 4500 literal to 4501 reports
'   MISMATCH 782/898 first_diff=+157; rewriting `If ballDist > maxDist + 20.0` as
'   `If maxDist + 20.0 < ballDist` reports MISMATCH 350/898 first_diff=+40 at length 896.
' WHAT THE ORACLE DOES NOT COVER HERE: the Float literals (0.0, 20.0, 100.0 at
'   0x00C92910/14/18/1C) live in a constant pool reached through a relocated address, so
'   changing 100.0 to 101.0 still reports 898/898. Their VALUES are read from the image,
'   not proven by this comparison. Do not treat them as verified.
'
' Shape findings, each confirmed against the x87/branch bytes rather than Ghidra's C:
'  1. The outer guard is ONE short-circuit `And`, not a nested If with a separate flag:
'     `If ball.kicktime > 0 And g_time > ball.kicktime + 1000`. Both tests use the
'     materialised-boolean shape (mov/cmp/setg/movzx/cmp/je) and SHARE their final
'     `cmp eax,0` -- the falsy exit just leaves A's 0 in eax and jumps into the shared
'     check. Same pattern as the verified TBall.CheckLongShotRating.
'  2. `If ball.controlledby = human Then flag2 = True`, not `flag2 = (ball.controlledby =
'     human)`. The original stores via bare cmp/jne/mov [flag2],1, not
'     cmp/sete/movzx/mov. Identical length (18 B), different opcodes.
'  3/4/5. Comparison operand order is load-bearing and Ghidra hides it (guide 10.1): it
'     prints `0.0 < y` whatever the source said. The side evaluated FIRST is pushed first,
'     so it must be written first: `ball.y > 0.0`, `d > maxDist`, `ballDist > maxDist +
'     20.0`. For the two Dist2D results this is what produces the fxch/fucom/fxch/fstp
'     dance that brings the call result back to the x87 top. An earlier header called this
'     an unresolvable spill-vs-no-spill allocation tie; it was not -- it was plain
'     comparison direction.
'  6. The lineAlive test is a SECOND And-fusion, with no flag3/ballDist2 Locals:
'     `If lineAlive <> 0 And Dist2D(human.x,human.y,ball.x,ball.y) > minDist + 100.0`.
'     Dist2D is only called when lineAlive<>0, matching the original's single call site.
'  7. The red-pole search has no flag and no Exit -- it returns straight out of the loop
'     (`If pole.colour = "FF0000" Then Return 0`), the TBall.GetActiveBall idiom. The
'     alive-count loop and TTraining.Success() that follow are not gated by an
'     `If Not redFound`; they are simply what runs when the search falls through.
'
' Globals: 0x00C6CFFC g_training_int22:Int, 0x00C6EFD4 g_time:Int, 0x00C6D568
'   g_Object813:TList (globals_final.tsv says bare Object at low confidence; the
'   refcount-free +0x8C ObjectEnumerator traffic at every call site proves TList, guide
'   10.7), 0x00C6CFD8 g_training_int13:Int, 0x00C6CFDC g_training_int14:Int.
' Module Function reused: Dist2D (src/recovered_module/Dist2D.bmx, verified).
' Fields: TBall.kicktime +0x64, TBall.controlledby +0x70, TBall.x/y +0x18/0x1C,
'   TPlayer.x/y +0x4C/0x50, TTrainingObject.x/y/alive +0x10/0x14/0x18 (inherited by TPole
'   and TTrainingLine), TPole.colour +0x24.
'
' NOTE ON RUNNING THE ORACLE ON THIS FILE: scripts/harness.py's CLI does NOT strip the
' `Function ... End Function` wrapper that src/recovered/ uses for KIND=Function bodies --
' it reports our_len=14 (the empty stub) for any wrapper-form file, including bodies that
' are already verified byte-identical (reproduced on src/recovered/TBall.GetActiveBall.bmx).
' Pass the statements body-only, or go through scripts/reverify.py, which calls body_of().
'
' STALE SCORE RECORD (not fixable from here): status/score/TTraining.UpdateFlair.txt in the main tree still
'   reads "539/898 (60.0%), ours 907, delta +9" for a body version that no longer exists. status/ is gitignored
'   regenerated output ("Nothing here is authored"), and scripts/reverify.py --pending -- the
'   only thing that writes it -- scores src/recovered_pending and src/recovered_unverified
'   only, so it will not refresh a record for a body that has been promoted to
'   src/recovered. That contradicting record was one half of the defect here: commit
'   122bd86's bulk pass injected a bare "byte-identical" marker above the VA line while line
'   1 still said NOT VERIFIED, and progress.py accepted a marker anywhere in the first 40
'   lines with no negative test. Delete the stale record by hand, or ignore it -- the oracle
'   run named at the top of this header is the authority.
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
				If g_time > ball.kicktime + 4500 Then flag2 = True
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
			If lineAlive And Dist2D(human.x, human.y, ball.x, ball.y) > minDist + 100.0
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

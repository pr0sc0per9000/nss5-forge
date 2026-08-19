' TBall.CheckAfterTouch
' VA 0x004C9C35   1175 bytes (Ghidra-authoritative)   vtable slot 0x6c   sig ()i
' byte-identical vs NSS5.exe
'
' FIXED this pass (was 4.1% byte agreement / delta +14 / wrong from byte 5 onward,
' i.e. everything after the prologue was misaligned). Re-verified MATCH, mode=reloc,
' 1175/1175 via harness.try_method. Root causes, in the order they were found:
'
'  1. STACK FRAME. `sub esp,0x1c` (7 dword slots) in the original vs our `sub esp,0x14`
'     (5 slots) -- two locals short (guide 16.3/22: read `sub esp,N` first; slot count is
'     spill order, not something you can add by declaring more Locals blind). The two
'     missing slots turned out to be spill destinations for the `distancetogoal_opp`
'     Int->Float coercions ahead of the two `TPitch.YardsToPixels` calls (see #4) -- they
'     only appear once those calls are written in the operand order that forces the spill.
'
'  2. OUTER GUARD is an early-return guard clause, not an enclosing `If...Then...EndIf`:
'     `If ingoal Or lastkicktype > 3 Then Return 0`, body unindented below it (same idiom
'     as TBall.CheckAdHoardings.bmx, guide 10.9/3f). Two sub-findings inside this one line:
'       * `ingoal` must be a BARE truthy test, not `ingoal <> 0` -- the explicit `<> 0`
'         forces bcc to materialise the comparison (`sete`/`movzx`) before branching; the
'         bare Int test compiles straight to `cmp/jne` with no materialisation, matching
'         the original exactly.
'       * `lastkicktype > 3` (not `<= 3`, negated) since the guard fires on the NEGATED
'         condition of the wrapping If.
'
'  3. THE passtoid/lastkickedby/kicktime/g_ball_float14 CASCADE is ONE flat 4-term `And`
'     used directly as the `If b ... Else ... EndIf` condition, not four separate
'     `Local=False / If guard Then x=test` statements. bcc compiles a flat `And` chain by
'     reusing a single register end-to-end (each term overwrites it via its own `setcc`
'     only when the preceding terms already passed) -- writing it as separate Locals
'     produces extra `mov edx,0`/register-shuffle bytes that aren't there in the original.
'     Same idiom, once collapsed to one `If A And B And C And D` line, also fixed the
'     `g_player_int50 > kicktime + 50` operand order (g_player_int50 must be the LEFT
'     operand -- it loads into a register first in the original; written the other way
'     round bcc compares directly against the memory operand instead, 6 bytes shorter).
'
'  4. TWO-STEP BOOL ACCUMULATORS still need the `Local x = cond1 / If x Then x = cond2`
'     idiom (TPlayer.ShootAI's `ok`, guide 10.9) even when `cond1` is itself an
'     independent test rather than a self-reference -- `Local d:Int = False / If
'     lastkickedby.controller = 0 Then d = (...)` compiles to an unmaterialised direct
'     branch (`cmp mem,0/jne`) that is NOT what the original does; storing `cond1`
'     straight into the freshly-declared Local (`Local d:Int = (lastkickedby.controller =
'     0)`) forces the same `sete/movzx` materialisation the original has. Applies to `d`/
'     `e`/`g`/`h` here. Also: `TPitch.YardsToPixels(18.0) <= lastkickedby.distancetogoal_opp`
'     is the sole condition of an If/Else with two genuinely different bodies, so it needed
'     the branch-swap rule (guide §21) -- negate to `distancetogoal_opp <
'     YardsToPixels(18.0)` AND swap which branch is Then vs Else, not just flip the
'     comparison spelling (flipping alone made the delta worse).
'
'  5. `Select g_engine_int20 Mod 5` (guide 10.2), not `If f=0 ... ElseIf f=1 ...`. The
'     tell is the disassembly: FIVE back-to-back `cmp edx,N`/`je` tests (0,1,2,3,4) before
'     any case body, including an explicit empty `Case 4` (mod 5 can yield 4, and Ghidra's
'     C silently drops the no-op case). If/ElseIf interleaves test-then-body and never
'     reproduces that shape.
'
'  6. OPERAND ORDER on several commutative comparisons/adds (guide 10.1/23.4) -- in each
'     case the variable/field loads FIRST and the literal constant or `Self` field loads
'     second, even where the source reads more naturally the other way:
'     `local_8 >= 315.0` (not `315.0 <= local_8`), `local_8 >= 135.0`, `local_8 >= 190.0`,
'     `local_8 >= 10.0`, `curlamount > -local_1c` (not `-local_1c < curlamount`),
'     `curlamount > local_18` / `curlamount + local_18 * 0.25` (not `local_18 * 0.25 +
'     curlamount`), `zvelocity + local_18 * 2.0` (not `local_18 * 2.0 + zvelocity`),
'     `local_14 > 0.5` (not `0.5 < local_14`).
'
' Fields/globals: TBall/TPlayer/TJoy offsets from src/generated/types_skeleton.bmx;
' g_ball_float14/15/16/19/20, g_engine_int20, g_player_int50 from the SYM table --
' unchanged from the previous pass, all confirmed correct.
	Method CheckAfterTouch:Int()
		'!Global g_ball_float14:Float
		'!Global g_ball_float15:Float
		'!Global g_ball_float16:Float
		'!Global g_ball_float19:Float
		'!Global g_ball_float20:Float
		'!Global g_engine_int20:Int
		'!Global g_player_int50:Int

		If ingoal Or lastkicktype > 3 Then Return 0
		Local local_18:Float = g_ball_float15
		Local local_1c:Float = g_ball_float16
		If lastkickedby <> Null Then
			local_18 = (g_ball_float15 / 10.0) * lastkickedby.flair
			local_1c = (g_ball_float16 / 10.0) * lastkickedby.flair
		EndIf
		If passtoid = 0 And lastkickedby <> Null And g_player_int50 > kicktime + 50 And Float(g_player_int50) < Float(kicktime) + g_ball_float14
			Local local_8:Float = lastkickedby.joy.direction - direction
			Local local_14:Float = lastkickedby.joy.force
			Local d:Int = (lastkickedby.controller = 0)
			If d Then d = (lastkickmatchstate <> 7)
			Local e:Int = d
			If e Then e = (lastkickmatchstate <> 9)
			If e Then
				If lastkickedby.distancetogoal_opp < TPitch.YardsToPixels(18.0) Then
					local_14 = g_ball_float19
				Else
					If TPitch.InsideCrossZone(Int(lastkickedby.x), Int(lastkickedby.y), 0) <> 0 Then
						local_14 = local_14 * 0.25
					Else
						local_14 = local_14 * 0.75
					EndIf
				EndIf
				If lastkickedby.selectionno = 0 Then
					local_8 = Float((g_engine_int20 Mod 11 - 5) * 5 + 180)
					local_14 = 1.0
				Else
					Select g_engine_int20 Mod 5
					Case 0
						local_14 = g_ball_float20
					Case 1
						If lastkickedby.distancetogoal_opp > TPitch.YardsToPixels(40.0) Then
							local_8 = local_8 + 180.0
						EndIf
					Case 2
						local_8 = local_8 + 90.0
					Case 3
						local_8 = local_8 - 90.0
					Case 4
					End Select
				EndIf
			EndIf
			If local_14 > 0.5 Then
				WrapAngle(local_8)
				If local_8 >= 315.0 Or local_8 <= 45.0 Then
					zvelocity = zvelocity - local_18 * 2.0
				EndIf
				If local_8 >= 135.0 And local_8 <= 225.0 Then
					zvelocity = zvelocity + local_18 * 2.0
					velocity = velocity + local_18
				EndIf
				Local g:Int = (local_8 >= 190.0 And local_8 <= 350.0)
				If g Then g = (curlamount > -local_1c)
				If g Then curlamount = curlamount - local_18
				Local h:Int = (local_8 >= 10.0 And local_8 <= 170.0)
				If h Then h = (curlamount < local_1c)
				If h Then curlamount = curlamount + local_18
			EndIf
		Else
			If curlamount > local_18 Then curlamount = curlamount - local_18 * 0.25
			If curlamount < local_18 Then curlamount = curlamount + local_18 * 0.25
		EndIf
		Return 0
	End Method

' ============ localise_diff.py reports CLEAN, 2008/2008, delta 0 ================
' VA 0x004ca0cc   2008 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (2008/2008, original length from Ghidra's inventory)
' TBall.CheckGoals -- VA 0x004CA0CC, 2008 bytes (Ghidra-authoritative), KIND=Method
' SIG=()i SLOT=0x70. Self=[ebp+8].
'
' ORACLE STATE as of THIS pass (scripts/localise_diff.py TBall.CheckGoals <thisfile> --max-gaps 25):
'   orig 2008 bytes, ours 2008 bytes, delta +0, 0 gaps, 0 subs -> "CLEAN -- byte-identical
'   modulo the oracle's masks". (Note: status/score/TBall.CheckGoals.txt in the repo still
'   shows an 84.4%/first-diff-at-byte-28 report -- that file is a snapshot of the last shared
'   src/assembled/ build and is STALE relative to this pass's edit; scripts/assemble.py was
'   deliberately NOT run here (rule 1, shared state). Trust localise_diff.py's direct probe of
'   THIS file, re-run above, over the stale status/score/ report.)
'
' ============================================================================================
' THIS PASS'S FIX -- the last remaining span (an earlier pass's "WHAT IS STILL WRONG": 2 gaps + 2
' subs, delta +8, all inside ORIGINAL offset ~1786..1848, the `g_player_int01`/`Self.z < f4`
' block at the very end of the function):
'
'   ROOT CAUSE was NOT a jump-size-selection artifact or an isolated sense-flip on `Self.z <
'   f4` (both of which the prior pass chased and correctly gave up on) -- it was STRUCTURE.
'   The prior pass had this as THREE NESTED `If`s:
'     If Self.active And Self.ingoal = 0
'       If g_player_int01 = 1 Or g_player_int01 = 10
'         If Self.z < f4
'           <body>
'         EndIf
'       EndIf
'     EndIf
'   but the decompile (bVar7/bVar8 chain, lines 167-190 of the .c) is ONE flat compound
'   condition with a parenthesised `Or` sub-clause, exactly the shape already established as
'   house style by src/recovered/TBall.Kick.bmx:125 (`If a0.newstar And g_player_int01 = 1
'   And g_training_int03 = 0 And (a3 = 2 Or a3 = 3) And Rand(5) = 1`, verified byte-identical)
'   and src/recovered/TBall.CanSeePlayer.bmx:46. Rewritten as:
'     If Self.active And Self.ingoal = 0 And (g_player_int01 = 1 Or g_player_int01 = 10) And
'        Self.z < f4
'       <body, unchanged>
'     EndIf
'   Nested `If`s make each level's failure-jump target "skip past everything down to my own
'   EndIf" -- which, since these three EndIfs are all adjacent with nothing after the
'   innermost body, means all three failure jumps converge on the SAME address (confirmed:
'   ours had GAP1, GAP2 and SUB2 all jumping to the identical target 0x51af20, essentially the
'   function's end). A flat `And`/`Or` chain instead short-circuits STEP BY STEP -- each failed
'   term jumps to the NEXT test point, a few bytes ahead -- which is what the original's SHORT
'   (`74`/`75`, rel8) jumps to nearby offsets actually show. Restructuring to the flat form
'   fixed the jump ENCODING (rel8 vs rel32, the two `+4` gaps) as a side effect of fixing the
'   jump TARGETS, and also fixed the `Self.z < f4` sense (SUB1 `setb`/SUB2 `je`, both were
'   showing an inverted sense under the nested-If reading) because as the chain's LAST term it
'   now compiles via the standard flat-AND materialised-guard pattern (fcompare/setb/movzx/
'   cmp/je) instead of a solo-`If`-with-no-Else pattern. All 4 findings (2 gaps + 2 subs) were
'   one root cause, not four.
'
' WHAT IS SOLID -- reuse without re-deriving (all still confirmed):
'   * TBall fields (object_model.json, byte offsets): active(12,i) x(24,f) y(28,f) z(32,f)
'     oldx(36,f) oldy(40,f) oldz(44,f) ingoal(80,i) velocity(84,f) zvelocity(88,f)
'     controlledby(112,:TPlayer).
'   * FUN_00505e20 is the ALREADY-VERIFIED module Function GetInterceptPoint
'     (src/recovered_module/GetInterceptPoint.bmx, byte-identical). Its TInterceptPoint
'     result fields (also already verified): intercept_CD +0x14, intercept +0x18.
'   * TBall.HitPost(f)i is slot 0x7c=124; TBall.HitNet(i)i is slot 0x80=128 (both `virt
'     vtable` calls in the decompile, confirmed against vtable_map.tsv).
'   * The two `call dword ptr [0xc5bab4]` sites are a DEVIRTUALISED Function call:
'     `TEngine.GoalScored(Self)` -- object_model.json has it as `kind:Function,
'     sig:(:TBall)i, offset:132` (0x84 hex). Self (the ball, ebx) is the SOLE pushed
'     argument; there is no receiver object.
'   * FUN_004A7FE0 = Abs(Double) (used for `Abs(Self.y)`).
'   * Globals: g_ball_int02:Int(0xC5A4C8) g_ball_float04:Float(0xC5A4D8)
'     g_player_int01:Int(0xC5B1FC) g_player_int17:Int(0xC5D638) g_player_int18:Int(0xC5D63C)
'     g_pitch_int08:Int(0xC5D640) g_pitch_int09:Int(0xC5D644) g_pitch_int10:Int(0xC5D648).
'   * Float .rdata literals, ALL separate slots (no CSE): 0xC72790=2.0, 0xC72794/0xC72798=1.0,
'     0xC7279C..0xC727B8=1.0 nine more times -- write a bare `1.0` literal at each site.
'   * THE POST-COLLISION CALL GROUPING (lines ~26-42 below) is CONFIRMED CORRECT, zero gaps
'     across 0x004CA161..0x004CA399: low-z (`Self.z < f4 - f5*2.0`) fires FOUR narrow-post
'     `GetInterceptPoint`/`HitPost` calls with the real `intercept_CD`; mid-z (`Self.z < f4`)
'     fires only TWO wide-goal calls with a flat `0.5` literal; z>=f4 fires nothing.
'   * The Y-branch-swap for the goal-net `HitNet` cascade (lines ~76-90): write
'     `If y<0 Then <neg> ElseIf y>0 Then <pos> EndIf` (matches physical layout), confirmed
'     zero-gap.
'
' NEXT PASS: this body is byte-CLEAN per localise_diff.py (2008/2008, delta 0, 0 gaps, 0
'   subs) as of this pass -- nothing further to chase here. Re-run
'   `scripts/localise_diff.py TBall.CheckGoals src/recovered_unverified/TBall.CheckGoals.bmx
'   --max-gaps 10` to reconfirm before promoting; if it still says CLEAN this body is ready
'   to move to src/recovered/ (not done in this pass -- rule 1, only this file was touched).

'!Global g_ball_int02:Int
'!Global g_ball_float04:Float
'!Global g_player_int01:Int
'!Global g_player_int17:Int
'!Global g_player_int18:Int
'!Global g_pitch_int08:Int
'!Global g_pitch_int09:Int
'!Global g_pitch_int10:Int

		If Self.ingoal And Abs(Self.y) < g_player_int17
			Self.ingoal = 0
		EndIf
		Local f1:Float = Float(g_player_int17)
		Local f2:Float = f1 + Float(g_pitch_int10 + 2)
		Local f3:Float = Float(g_player_int18)
		Local f4:Float = Float(g_pitch_int09)
		Local f5:Float = Float(g_pitch_int08)
		Local ip:TInterceptPoint
		If Self.z < f4 - f5 * 2.0
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3 - f5, -f1, -f3 + f5, -f1)
			If ip.intercept <> 0 Then Self.HitPost(ip.intercept_CD)
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, f3 - f5, -f1, f3 + f5, -f1)
			If ip.intercept <> 0 Then Self.HitPost(ip.intercept_CD)
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3 - f5, f1, -f3 + f5, f1)
			If ip.intercept <> 0 Then Self.HitPost(1.0 - ip.intercept_CD)
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, f3 - f5, f1, f3 + f5, f1)
			If ip.intercept <> 0 Then Self.HitPost(1.0 - ip.intercept_CD)
		Else
			If Self.z < f4
				ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3 - f5, -f1, f3 + f5, -f1)
				If ip.intercept <> 0 Then Self.HitPost(0.5)
				ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3 - f5, f1, f3 + f5, f1)
				If ip.intercept <> 0 Then Self.HitPost(0.5)
			EndIf
		EndIf
		f1 = f1 + Float(g_ball_int02)
		If Not Self.controlledby
			If Self.ingoal And Self.z > f4 And Self.oldz < f4 And Self.x > -f3 - 1.0 And Self.x < f3 + 1.0
				If (Self.y < -f1 And Self.y > -f2 - 1.0) Or (Self.y > f1 And Self.y < f2 + 1.0)
					Self.z = Self.oldz
					Self.zvelocity = -Self.zvelocity * g_ball_float04
				EndIf
			ElseIf Self.z < f4
				If Self.oldz > f4 And Self.x > -f3 - 1.0 And Self.x < f3 + 1.0
					If (Self.y < -f1 And Self.y > -f2 - 1.0) Or (Self.y > f1 And Self.y < f2 + 1.0)
						Self.z = Self.oldz
						Self.zvelocity = -Self.zvelocity * g_ball_float04
						If Self.velocity < 1.0 Then Self.velocity = 1.0
					EndIf
				EndIf
				If Self.y < 0.0
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, -f2, f3, -f2)
					If ip.intercept <> 0 Then Self.HitNet(0)
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, -f1, -f3, -f2)
					If ip.intercept <> 0 Then Self.HitNet(1)
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, f3, -f1, f3, -f2)
					If ip.intercept <> 0 Then Self.HitNet(1)
				ElseIf Self.y > 0.0
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, f2, f3, f2)
					If ip.intercept <> 0 Then Self.HitNet(0)
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, f1, -f3, f2)
					If ip.intercept <> 0 Then Self.HitNet(1)
					ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, f3, f1, f3, f2)
					If ip.intercept <> 0 Then Self.HitNet(1)
				EndIf
			EndIf
		EndIf
		If Self.active And Self.ingoal = 0 And (g_player_int01 = 1 Or g_player_int01 = 10) And Self.z < f4
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, -f1, f3, -f1)
			If ip.intercept <> 0
				TEngine.GoalScored(Self)
				Self.ingoal = 1
			EndIf
			ip = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -f3, f1, f3, f1)
			If ip.intercept <> 0
				TEngine.GoalScored(Self)
				Self.ingoal = 1
			EndIf
		EndIf
		Return 0

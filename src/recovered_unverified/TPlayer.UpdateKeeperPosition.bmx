' TPlayer.UpdateKeeperPosition
' VA 0x004F2EED   1701 bytes   class-table slot 0xB4   sig ()i   KIND=Method
' Body-only format: statements only (no Method/End Method wrapper); Self is implicit.
'
' WHAT IT DOES. Picks Self.desx/desy (the keeper's target position) for the current
' match state. State 9/10 (goal kick / corner-ish dead ball) parks the keeper on the
' byline, shifted toward the near post if his own team has the ball. State 1 (open
' play) is the big branch: if he is not already holding the ball, he shadows the ball
' along an arc in front of goal (closer in when the ball is loose and reachable, or
' aimed at the ball's controller's short-term predicted spot when it is not), calling
' Self.InterceptBall() when a through-ball/breakaway threat is judged too dangerous to
' shadow; if he is holding the ball but caught it recently he freezes in place; if he
' has been holding it a while he does an idle side-to-side wobble keyed off the match
' tick. Any other match state (celebrations, etc.) just parks him on the goal line.
'
' ASSUMPTIONS -- module Global NAMES are the already-established ones for these
' addresses (checked with scripts/explain_global.py); DECLARED TYPES are load-bearing.
'   0x00C5B1FC g_matchstate:Int        match state (1 = open play, 9/10 = dead ball
'                                       near goal, others = e.g. celebration). Same
'                                       address already used as g_matchstate in
'                                       TPlayer.DoKeeperDiveAI (the sibling keeper-AI
'                                       method) and as g_player_int01 elsewhere.
'   0x00C5D638 g_goalline:Int          pitch half-length / goal-line depth. Same
'                                       address, same `* -Self.GetShootingDirection()`
'                                       idiom, as TPlayer.GetCoveringLocation's `gy` and
'                                       TPlayer.UpdateFundamentals' g_player_int17.
'   0x00C5DEA4 g_ball:TBall            the match ball (globals_final: verified). Fields
'                                       used: x/y/z +0x18/0x1C/0x20, jumpx/jumpy
'                                       +0x38/0x3C (TPlayer.UpdateFundamentals),
'                                       velocity +0x54, teaminpossession +0x60,
'                                       controlledby +0x70 (TPlayer.CheckBallContact).
'   0x00C5D64C g_penboxside:Int        penalty-box half-width; TPitch.SetUp's own
'                                       construction site reads it from Engine.ini key
'                                       "penboxside".
'   0x00C6EFD4 g_matchclock:Int        the millisecond match clock (same address as
'                                       g_player_int50 / g_matchtime elsewhere); named
'                                       to match the sibling TPlayer.DoKeeperDiveAI.
'   0x00C5D63C g_goal_halfw:Int        goal-mouth half-width (TPlayer.DoKeeperDiveAI:
'                                       "goal mouth spans [-(g+20), g+20] on the byline").
'   0x00C5DE70 g_player_int33:Int      ball/player height unit; dive-height threshold,
'                                       dominant name across the corpus (10 bodies incl.
'                                       TPlayer.CheckBallContact, TPlayer.UpdateFundamentals).
'   0x00C6CF90 g_tr_mode:Int           in-training flag (TPlayer.CheckBallContact's name
'                                       for this address).
'   0x00C5D658 g_player_int19:Int      a byline-depth constant, same `* GetShootingDirection()`
'                                       idiom as TPlayer.ShootAI/TapKick and the same
'                                       "desy = +/-g_player_int19" idiom as
'                                       TPlayer.GetMatchOverPosition.
'   0x00C5B210 g_engine_int20:Int      the tick counter already read `Mod 3` for a
'                                       3-way random pick in TPlayer.DoCelebrations
'                                       ("Select g_engine_int20 Mod 3 / Case 0/1/2") --
'                                       the exact idiom reused here.
'   0x00C797C0 g_player_double10:Double = 100.0   first body to touch this address;
'                                       genuine 8-byte `fld qword` constant (verified by
'                                       reading NSS5.exe's .rdata directly: both this and
'                                       the next slot hold exactly 100.0), not a Float
'                                       literal -- globals_final.tsv already types it
'                                       Double from the qword access width.
'   0x00C797C8 g_player_double11:Double = 100.0   same as above, second slot.
' `0.5` (0x00C797D0) and `3.0` (0x00C797D4) are plain 4-byte Float literals read
' straight out of NSS5.exe's .rdata (confirmed: interpreting those two dwords as
' doubles gives garbage, as floats gives exact 0.5 and 3.0) -- not Globals, so they are
' written as literals below, the same treatment CheckBallContact/DoKeeperDiveAI give
' their own per-function float pools.
'
' Fields (object_model.json, TPlayer): x +0x4C, y +0x50, desx +0x7C, desy +0x80,
'   teamid +0x14, keepercatchtime +0x90, distancetoball +0xD0, direction +0x78,
'   distancetogoal_opp +0xE8.
' Self-methods (TPlayer, object_model.json / class-table slots): KeeperHoldingBall
'   ()i +0x1C0, GetShootingDirection ()i +0x160, InterceptBall(:TBall)i +0x124.
' piVar4 = g_ball.controlledby is itself a TPlayer (per TPlayer.CheckBallContact);
'   its CleanThrough ()i is class-table slot +0xE4 (object_model.json).
' Static/class-table calls: TPitch.IsOnPitch(i,i)i (+0x58), TPitch.InsidePenaltyBox
'   (i,i,i)i (+0x5C), TPitch.YardsToPixels(f)f (+0x6C) -- all three already named and
'   pinned NOT-A-GLOBAL class-table-interior slots (globals_final.tsv).
' Module Functions (src/recovered_module/): Dist2D (0x00505DA2), GetInterceptPoint
'   (0x00505E20, returns TInterceptPoint; field `.intercept` +0x18).
' Runtime builtins: ATan2 (0x004A1F90), Cos (0x004A1F10, `_bbCos`), Sin (0x004A1F00,
'   `_bbSin`), Int() (0x005B9690, `_bbFloatToInt`) -- named from TPlayer.GetCoveringLocation
'   / extracted/runtime_helpers.tsv, same as every other trig call site in the corpus.
' &DAT_005c9c80 is the Object-Null sentinel (the usual `<>&DAT_005c9c80` / `==&DAT_005c9c80`
'   pattern seen everywhere else in the corpus for `<> Null` / `= Null`).
'
' STRUCTURE NOTES (preserved, not tidied)
'   * The idle-wobble Mod-3 test is a genuinely redundant nested pair in the original:
'     `If wobble > 1` wrapping `If wobble > 2` -- the inner test is always false once the
'     outer is false (a value under 2 is never over 2), so its Then arm is dead code.
'     Reproduced as-is (preserve-by-default): a genuine original oddity, not a
'     transcription error. `wobble` is `g_engine_int20 Mod 3`, computed once into its own
'     Local and reused by both tests -- writing the `Mod 3` expression out twice instead
'     costs a second `cdq`/`idiv` pair the original does not pay (confirmed against
'     0x004F2FED: a single `idiv`, `mov eax,edx`, then two `cmp eax,N` against that same
'     value). The exact relational spelling matters too: both comparisons compile as
'     `cmp;jle` jumping *into* the Else arm on failure with the Then arm inline, which only
'     comes out of `wobble > 1` / `wobble > 2` (not the equivalent `< 2` / `< 3`) -- bcc
'     encodes the *written* comparison directly rather than picking whichever spelling is
'     shorter, so an equivalent-but-differently-spelled condition changes the branch bytes
'     even though the arithmetic result is identical (docs/reference/codegen-patterns.md
'     11.3, "match the setcc and its immediate, not the meaning").
'   * `iVar7`/`fVar12` are reused by Ghidra for unrelated values across this body
'     (a TInterceptPoint pointer, then a scratch Int, then a scratch Float); the BASIC
'     below uses one Local per distinct concept instead, which is source-equivalent.
'   * The `ball.x - 0.0` term in the ATan2 call, and the `0.0 +` in both `desx = ... +
'     dist*Cos(ang)` lines, read from the exact same stack slot in the original
'     (`[ebp-0x5c]`) as a plain Int local seeded to 0 -- a `goalx` counterpart to `goaly`,
'     not a bare Float literal (a literal 0.0 elsewhere in this same body compiles to a
'     one-byte `fldz`, not this int-then-fild roundtrip). Tried reproducing that literally
'     as a named `Local goalx:Int = 0` reused at all three sites: it does reproduce the
'     int-then-fild shape at each site, but it also grows our frame by another 72 bytes
'     (0x94 -> 0xdc) instead of shrinking it, so it was left as the plain `0`/`0.0`
'     literals below -- worth revisiting once the frame-size root cause immediately below
'     is understood, since guessing at one spill in isolation while the allocator's overall
'     behaviour is still unexplained moved the total further from MATCH, not closer.
'
' UNRESOLVED CODEGEN GAP (byte diff, first_diff=byte 3 -- the prologue itself)
'   `sub esp` differs at the very first instruction: original `83 EC 60` (96-byte frame,
'   8-bit imm), ours `81 EC 94 00 00 00` (148-byte frame, 32-bit imm) -- 52 bytes / ~13
'   slots more than the original, and both still push all 3 callee-saved regs (`53 56 57`
'   identical in both), so the gap is pure stack-resident spill, not register count.
'   Disassembling our own compiled probe directly (not just localise_diff's alignment,
'   which mis-syncs across this block once the byte drift below accumulates and reports
'   phantom "moved" code that is not actually reordered) confirms every statement, branch
'   and call site in the "not holding ball" block lands in the same order as the original,
'   including the CleanThrough/GetInterceptPoint section that localise_diff's alignment
'   reports as an insert-here/delete-there pair. That pair is downstream noise from the
'   frame being bigger, not a second bug: the ~13 extra slots push several later
'   same-purpose scratch offsets (e.g. the original's `[ebp-0x54]` for `ip`) past the
'   signed-disp8 range into disp32 encodings, and each such crossing costs 3-4 bytes on
'   every read of that slot, which is most of the small +1..+12 byte gaps in the report.
'   Two concrete, register-visible differences are now pinned down:
'     - `Self` sits in esi in the original, edi in ours (`8B 75 08` vs `8B 7D 08`); `ctrl`
'       (`g_ball.controlledby`) sits in ebx in the original, esi in ours. Both are real,
'       corpus-attested colour effects (see TPlayer.DoKeeperDiveAI's note on `ip`/`goaly`
'       swapping esi/ebx) -- physical colour identity is not staticaly predictable
'       (docs/reference/codegen-patterns.md 18.2), so this is reported, not chased further.
'     - The register story is not just a colour swap, though: in the original, `ctrl`
'       (not-holding-ball branch) and the idle-wobble block's `gy`-adjustment temp share
'       ebx, because their live ranges never overlap (KeeperHoldingBall() true vs false are
'       mutually exclusive) and the allocator coalesces them onto one colour. Our build
'       does NOT make that coalescing: `ctrl` gets its own colour (esi) and the idle-wobble
'       temp keeps ebx separately, which leaves only edi free for the fourth same-tier
'       candidate -- `goaly`, referenced across the whole not-holding-ball branch -- and it
'       loses out and spills to `[ebp-0x88]` instead (confirmed by disassembling our probe
'       directly). That is the actual mechanism behind the frame gap: not a missing/wrong
'       statement, and not simply "the wrong Local count", but our build using one more
'       distinct register colour than the original for values whose live ranges do not
'       objectively require it. Nudging this from source (declaration order, an explicit
'       vs. implicit `= 0` initialiser on `ct`, moving `goalx` in or out) was tried several
'       ways in this pass without shifting the coalescing outcome; per
'       scripts/local_alloc_stats.py's own docstring this is the class of question that
'       needs a synthetic probe against the real bcc/FASM toolchain
'       (tools/blitzmax-legacy-src/bin/) to isolate the ctrl/gy coalescing decision, not
'       further static guessing.
'!Global g_matchstate:Int
'!Global g_goalline:Int
'!Global g_ball:TBall
'!Global g_penboxside:Int
'!Global g_matchclock:Int
'!Global g_goal_halfw:Int
'!Global g_player_int33:Int
'!Global g_tr_mode:Int
'!Global g_player_int19:Int
'!Global g_engine_int20:Int
'!Global g_player_double10:Double = 100.0
'!Global g_player_double11:Double = 100.0
If g_matchstate = 9 Or g_matchstate = 10
	Self.desx = 0
	Self.desy = -(g_goalline - 5)
	If g_ball.teaminpossession = Self.teamid
		Self.desx = -g_penboxside
	EndIf
ElseIf g_matchstate <> 1
	Self.desx = 0
	Self.desy = g_goalline * -Self.GetShootingDirection()
Else
	If Self.KeeperHoldingBall() <> 0
		If g_matchclock < Self.keepercatchtime + 750
			Self.desx = Self.x
			Self.desy = Self.y
		Else
			Self.desx = 0
			Local gy:Int = g_player_int19
			Local wobble:Int = g_engine_int20 Mod 3
			If wobble > 1
				gy = Int(gy - TPitch.YardsToPixels(1.0))
			Else
				If wobble > 2
					gy = Int(gy - TPitch.YardsToPixels(2.5))
				Else
					gy = Int(gy + TPitch.YardsToPixels(1.5))
				EndIf
			EndIf
			Self.desy = gy * -Self.GetShootingDirection()
		EndIf
	Else
		Local goaly:Int = g_goalline * -Self.GetShootingDirection()
		Self.desx = 0
		Self.desy = goaly
		If g_ball <> Null
			If TPitch.IsOnPitch(Int(g_ball.x), Int(g_ball.y))
				Local ang:Float = ATan2(g_ball.y - goaly, g_ball.x - 0.0)
				Local yds:Int = 6
				If g_tr_mode Then yds = 3
				Local dist:Float = TPitch.YardsToPixels(yds)
				Self.desx = 0.0 + dist * Cos(ang)
				Self.desy = goaly + dist * Sin(ang)
				Local ctrl:TPlayer = g_ball.controlledby
				If ctrl <> Null
					If g_tr_mode = 0
						Local ip:TInterceptPoint = GetInterceptPoint(-10 - g_goal_halfw, goaly, g_goal_halfw + 10, goaly, ctrl.x, ctrl.y, ctrl.x + g_player_double11 * Cos(ctrl.direction), ctrl.y + g_player_double10 * Sin(ctrl.direction))
						Local ct:Int = 0
						If ctrl.teamid <> Self.teamid And ctrl.distancetogoal_opp < TPitch.YardsToPixels(30.0)
							ct = ctrl.CleanThrough()
						EndIf
						If ct <> 0
							If ip.intercept Or ctrl.distancetogoal_opp < TPitch.YardsToPixels(12.0)
								Self.InterceptBall(g_ball)
							Else
								Local dd:Float = ctrl.distancetogoal_opp * 0.5
								Self.desx = 0.0 + dd * Cos(ang)
								Self.desy = goaly + dd * Sin(ang)
							EndIf
						EndIf
					EndIf
				Else
					If TPitch.InsidePenaltyBox(Int(g_ball.x), Int(g_ball.y), -Self.GetShootingDirection())
						If g_ball.jumpx <> 0.0 And 3.0 < g_ball.velocity And Float(g_player_int33 Shl 1) < g_ball.z And Dist2D(Self.x, Self.y, g_ball.jumpx, g_ball.jumpy) < TPitch.YardsToPixels(10.0)
							Self.InterceptBall(g_ball)
						Else
							If Self.distancetoball < TPitch.YardsToPixels(6.0)
								Self.InterceptBall(g_ball)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndIf

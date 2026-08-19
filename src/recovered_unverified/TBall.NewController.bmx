' TBall.NewController  -- KIND=Method, SIG=(:TPlayer)i, slot 0x84
' VA 0x004CAF26   1576 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe
' Body-only format: statements only, parameter is a0:TPlayer.
'
' Called whenever a new player (a0) gains control of the ball: re-scores whoever last
' had it, stamps receive position, fires the free-kick trap for a player who heads/lobs
' the ball straight back to himself, tracks assists for a clean pass between team-mates
' (with a "Cross"/"Pass"/"Long Pass" floating-text callout for a newstar passer), and
' finally rolls the dice on a crowd-popularity chant when a home-team newstar picks the
' ball up in open play.
'
' ASSUMPTIONS -- fields, all object_model.json, offset/4 = the decompiled dword index:
'   TBall (Self): x@0x18(idx6) y@0x1c(idx7) teaminpossession@0x60(idx0x18)
'     lastkicktype@0x68(0x1a) lastkickmatchstate@0x6c(0x1b) controlledby:TPlayer@0x70(0x1c)
'     lastkickedby:TPlayer@0x74(0x1d) lasttouchedby:TPlayer@0x78(0x1e)
'     assistedby:TPlayer@0x7c(0x1f) backpass@0x88(0x22) slidekick@0x8c(0x23)
'     posthit@0x90(0x24) passtoid@0x9c(0x27).
'   TPlayer (a0 / lastkickedby / humanplayer): newstar@8(idx2) teamid@0x14(idx5)
'     initials$@0x20(idx8) x@0x4c(idx0x13) y@0x50(idx0x14) selectionno@0xbc(idx0x2f)
'     keepercatchtime@0x90(idx0x24) receivex@0x9c(idx0x27) receivey@0xa0(idx0x28)
'     kickx@0x94(idx0x25) kicky@0x98(idx0x26) distancetogoal_opp@0xe8 distancetogoal_own@0xec
'     calling@0x114(idx0x45).
'   TFixture.level Int @0x3c. TTeam.id Int @8. TProfile.relationfans Int @0x10c.
'
' ASSUMPTIONS -- module Globals (names ours where noted; addresses verified against the
' decompilation, types/names cross-checked with explain_global.py):
'   g_awayteam:TTeam (0x00C5B21C), g_hometeam:TTeam (0x00C5B218) -- established corpus-wide
'     (TBall.Kick, TBall.Render, TPlayer.CheckOffside).
'   g_player_int01:Int (0x00C5B1FC) -- match state, 1 = open play.
'   g_training_int03:Int (0x00C6CF90).
'   g_player_int50:Int (0x00C6EFD4) -- current match-clock stamp, "verified" in
'     globals_corrections (TBall.Kick already stamps kicktime/tiredness with it).
'   g_fixture:TFixture (0x00C5B22C) -- CERTAIN, 15 bodies.
'   g_engine_int20:Int (0x00C5B210) -- CERTAIN, 14 bodies.
'   g_profile:TProfile (0x00C6F028) -- the career save (TBall.Kick already established).
'   g_trainingline_chan:TChannel (0x00C5B348) -- this address has 8 different established
'     aliases across the corpus (it is one of several shared mixer channels); this is the
'     CERTAIN-tier one per explain_global.py and is used here unqualified by the semantic
'     mismatch -- same slot, whichever body first named it did so from a training context.
'   g_ball_int06:Int (0x00C728CC) -- OURS, first body to touch this address. Timestamp of
'     the last "fan chant" commentary line, gated against g_player_int50 with a 5000ms
'     cooldown exactly the way TBall.Kick's g_ball_double01 gates the on-target angle.
'   g_ball_soundfanlow:TSound (0x00C5B370), g_ball_soundfanhigh:TSound (0x00C5B374) --
'     OURS, first body to touch these addresses. Two TSound Globals selected by
'     g_profile.relationfans (<20 / >99) when the chant fires; names are our best-guess
'     label for "fans don't rate him yet" vs "fans love him", not independently confirmed.
'
' RUNTIME/BRL calls resolved by address (matching already-recovered sibling bodies):
'   0x00505B91 LogLine, 0x004A7C20 bbStringConcat, 0x005B9690 _bbFloatToInt i.e. Int(x)
'     (TCone.CheckKnockOver), 0x004C5549 GetText (recovered_module, ($)$ -- every extra
'     operand Ghidra folds into a GetText call site belongs to the FOLLOWING call),
'     0x004A7410 _brl_retro_Lower (TPlayer.BlockTackle), 0x0059F089 Rand.
'   [0x00C5FAB0] TPlayer classtable+0x164 = GetHumanPlayer():TPlayer (TPlayer.CheckOffside,
'     TCone.CheckKnockOver). [0x00C5D998] TPitch+0x6c = YardsToPixels(f)f. [0x00C5BAA0]
'     TEngine+0x70 = SetUpSetPiece(i,i,i,i)i (TBall.CheckSideLines et al). [0x00C5BAB0]
'     TEngine+0x80 = ResetClubLastChange()i, no-arg (TBall.Kick). [0x00C6AFC0] TParticle
'     classtable+0x38 = StarShower(i,i,$,$) (TPlayer.BlockTackle). TBall's own class table:
'     0xa4 = Crossing(f)i, 0xcc = CheckForPlayerRatings(:TPlayer)i, 0xf0 (on TPlayer) =
'     CheckHoldingKick()i, 0x174 (on TPlayer) = GetMyTeam():TTeam.
'   AngleTo(f,f,f,f)f (VA 0x0050639d) and Dist2D(f,f,f,f)f (VA 0x00505da2) are the two
'     already-recovered module Functions in src/recovered_module/ -- bearing/distance from
'     the kick origin to the receiving player.
'   String literals read with harness.read_string(): 0x00C72840 "NewController:", 0x00C72868
'     "0000FF", 0x00C72880 "Cross", 0x00C728B8 "Pass", 0x00C72898 "Long Pass".
'
' SHAPE NOTES:
'   * The `&DAT_005c9c80` sentinel is bbNullObject, i.e. Null, exactly as established
'     project-wide (TScreen_*.CreateScreen.bmx headers). Every plain field-to-object
'     assignment below (Self.controlledby = a0, Self.assistedby = Self.lastkickedby, etc.)
'     compiles to the observed inc-new/dec-old/free-if-zero/store sequence automatically;
'     no manual refcounting is written.
'   * Ghidra MERGES argument lists repeatedly here (guide's trap #2): the two chained
'     `_bbFloatToInt` calls feeding SetUpSetPiece's 3rd/4th ints, and the GetText/Lower/
'     Int/Int chain feeding StarShower's 4 args, are each really ONE call with the earlier
'     computed values carried through as decoration on the intermediate calls -- confirmed
'     against TPlayer.BlockTackle's identical shape for the StarShower chain.
'   * `Self.lastkickedby.kickx` / `.kicky` are read into Locals ONCE and reused across the
'     AngleTo and Dist2D calls (iVar8/iVar3 in the decompilation) -- bcc does no CSE, so a
'     field referenced twice in source would show as two loads; showing one load used twice
'     means the source cached it in a Local.
'   * REVISED (byte-oracle pass): every short-circuit boolean that is tested immediately
'     by the very next statement -- with nothing in between that could touch EAX -- is
'     written as an inline `And`/`Or` compound condition, NOT a named flag Local. Verified
'     against the actual disassembly at 0x004caf26: none of these had a spilled slot or an
'     explicit initialising store (`sub esp,0x10` reserves exactly 4 dwords: ang, dist,
'     wasCrossing, and the compiler's own int->float scratch temp -- nothing for hp,
'     diffTeam, ownSit, teammate, clean, farEnough, bigCross, forward, ns, doChant or
'     isHome). A `Local x:Int = False` statement, if the source actually had one, forces
'     the compiler to emit that initialising store regardless of whether the following
'     conditional reassignment makes it redundant -- exactly the trap TBall.Kick's header
'     documents ("+5 bytes / two sites") for its own tired/unhappy gate. The clean
'     ABSENCE of that store here, at every one of these ten sites, is the same signature:
'     none of them were named Locals in the original. Collapsed to:
'       hp<>Null And a0.teamid<>hp.teamid                         (was diffTeam)
'       lastkickedby=a0 And g_player_int01=1 And (matchstate=5 Or =4 Or =3)   (was ownSit)
'       lastkickedby<>a0 And lastkickedby.teamid=a0.teamid         (was teammate)
'       lasttouchedby=lastkickedby Or lasttouchedby=a0             (was clean, still its
'         own nested If -- it must NOT merge into the teammate And-chain, since a false
'         `clean` does nothing while a false `teammate` runs the backpass/assistedby=Null
'         Else; the disasm confirms these are two separate exits)
'       posthit=0 And YardsToPixels(1.0)<dist                      (was farEnough)
'       wasCrossing<>0 And YardsToPixels(20.0)<dist And distancetogoal_opp<distancetogoal_own
'         (was bigCross + forward; both false-paths converge on the same Pass/LongPass
'         Else, confirmed by the disasm jumping to the identical merge point either way)
'       g_fixture.level=0 And a0.newstar And g_training_int03=0 And g_player_int01=1 And
'       2<g_engine_int20 And g_ball_int06+5000<g_player_int50 And Rand(3,1)=1 And
'       a0.GetMyTeam()=g_hometeam                                   (was ns + doChant +
'         isHome chained through three separate Ifs)
'     `side`, `kx`, `ky`, `ang`, `dist`, `wasCrossing`, `hp` remain real Locals: each one's
'     value survives across an intervening CALL (Int()/AngleTo/Dist2D/AddStat/etc.), which
'     the disasm shows spilled to a callee-saved register (ebx/esi) or, once those are
'     exhausted, a real stack slot -- exactly the `t`/`p` pattern in TBall.CheckSideLines.
'   * REVISED AGAIN (bytematch pass): the outer Null test at 0x4caf26+0x12A is a SOLO
'     relational If/Else with two genuinely different bodies (the whole ownSit/teammate/
'     crossing block vs the single `assistedby=Null` store), so the solo-relational
'     negation-swap rule (codegen-patterns.md #21) applies: original tests
'     `Self.lastkickedby <> Null` (NOT `= Null`) with the big block as Then (inline,
'     fallthrough) and `Self.assistedby = Null` as Else (out-of-line, reached by a forward
'     `je`, sharing the same tail code the teammate-false path also jumps into). Writing it
'     as `= Null / Else` compiles a `jne`-and-inline-Then shape the disasm does not have.
'   * The three `YardsToPixels(x) <> dist`-shaped float compares all read `dist` on the
'     LEFT in the original, not the call: `dist > YardsToPixels(1.0)`, `dist >
'     YardsToPixels(20.0)`, and (per the solo-If negation rule again, since the Pass/
'     LongPass If has two distinct bodies) `dist > YardsToPixels(25.0) Then <Long Pass>
'     Else <Pass>`. Writing the call on the left (`YardsToPixels(x) < dist`) still computes
'     the same boolean but costs a spurious `fxch st(1)` + flipped setcc (`setb` for `seta`)
'     on the first two, and the wrong `seta`/branch pairing on the third -- confirmed by
'     direct disassembly diff against the probe exe, not inferred.
'   * `wasCrossing` is tested bare (`wasCrossing And ...`), not `wasCrossing <> 0 And ...`:
'     the explicit `<>0` spelling costs an extra `setne al / movzx eax,al / cmp eax,0`
'     the original does not have (`cmp eax,0 / je` directly on the raw Int, same idiom as
'     the plain-Int Global guards in TWeather.SetWeatherTimes).
'   * The final gate's two Global comparisons are Global-on-the-left, matching how they are
'     loaded first in the disasm: `g_engine_int20 > 2` (not `2 < g_engine_int20`) and
'     `g_player_int50 > g_ball_int06 + 5000` (not `g_ball_int06 + 5000 < g_player_int50`) --
'     same operand-order-is-byte-observable rule as codegen-patterns.md #10.1.
'!Global g_awayteam:TTeam
'!Global g_hometeam:TTeam
'!Global g_player_int01:Int
'!Global g_training_int03:Int
'!Global g_player_int50:Int
'!Global g_fixture:TFixture
'!Global g_engine_int20:Int
'!Global g_profile:TProfile
'!Global g_trainingline_chan:TChannel
'!Global g_ball_int06:Int
'!Global g_ball_soundfanlow:TSound
'!Global g_ball_soundfanhigh:TSound
	LogLine("NewController:" + a0.initials)
	Self.CheckForPlayerRatings(a0)
	Local hp:TPlayer = TPlayer.GetHumanPlayer()
	If hp <> Null And a0.teamid <> hp.teamid Then hp.calling = 0
	Local wasCrossing:Int = Self.Crossing(0)
	a0.calling = 0
	Self.controlledby = a0
	Self.controlledby.CheckHoldingKick()
	If Self.controlledby.selectionno = 0 Then Self.controlledby.keepercatchtime = g_player_int50
	Self.controlledby.receivex = Int(a0.x)
	Self.controlledby.receivey = Int(a0.y)
	Self.teaminpossession = a0.teamid
	Self.slidekick = 0
	Self.posthit = 0
	If Self.lastkickedby <> Null
		If Self.lastkickedby = a0 And g_player_int01 = 1 And (Self.lastkickmatchstate = 5 Or Self.lastkickmatchstate = 4 Or Self.lastkickmatchstate = 3)
			Local side:Int = 2
			If g_awayteam.id = a0.teamid Then side = 1
			TEngine.SetUpSetPiece(4, side, Int(Self.x), Int(Self.y))
			Return 0
		EndIf
		Self.assistedby = Self.lastkickedby
		If Self.lastkickedby <> a0 And Self.lastkickedby.teamid = a0.teamid
			If Self.lasttouchedby = Self.lastkickedby Or Self.lasttouchedby = a0
				Local kx:Int = Self.lastkickedby.kickx
				Local ky:Int = Self.lastkickedby.kicky
				Local ang:Float = AngleTo(kx, ky, a0.x, a0.y)
				Local dist:Float = Dist2D(kx, ky, a0.x, a0.y)
				If Self.posthit = 0 And dist > TPitch.YardsToPixels(1.0)
					Self.lastkickedby.AddStat(3, ang, dist, kx, ky)
					If Self.lastkickedby.newstar
						If wasCrossing And dist > TPitch.YardsToPixels(20.0) And Self.lastkickedby.distancetogoal_opp < Self.lastkickedby.distancetogoal_own
							TParticle.StarShower(Int(Self.lastkickedby.x), Int(Self.lastkickedby.y), Lower(GetText("Cross")), "0000FF")
						Else
							If dist > TPitch.YardsToPixels(25.0)
								TParticle.StarShower(Int(Self.lastkickedby.x), Int(Self.lastkickedby.y), Lower(GetText("Long Pass")), "0000FF")
							Else
								TParticle.StarShower(Int(Self.lastkickedby.x), Int(Self.lastkickedby.y), Lower(GetText("Pass")), "0000FF")
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			Self.backpass = 0
			Self.assistedby = Null
		EndIf
	Else
		Self.assistedby = Null
	EndIf
	Self.lastkickedby = a0
	Self.lasttouchedby = a0
	Self.passtoid = 0
	TEngine.ResetClubLastChange()
	If g_fixture.level = 0 And a0.newstar And g_training_int03 = 0 And g_player_int01 = 1 And g_engine_int20 > 2 And g_player_int50 > g_ball_int06 + 5000 And Rand(3, 1) = 1 And a0.GetMyTeam() = g_hometeam
		g_ball_int06 = g_player_int50
		If g_profile.relationfans < 20
			PlaySound(g_ball_soundfanlow, g_trainingline_chan)
		ElseIf g_profile.relationfans > 99
			PlaySound(g_ball_soundfanhigh, g_trainingline_chan)
		EndIf
	EndIf
	Return 0

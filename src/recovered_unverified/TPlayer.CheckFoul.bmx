' TPlayer.CheckFoul
' byte-identical vs NSS5.exe
' VA 0x004F4D5F   1492 bytes   vtable slot 0xD8   sig (:TPlayer)i   KIND=Method
' Body-only format: statements only; parameter is a0:TPlayer, the "victim"/ball carrier
' being challenged -- Self is the tackler, per CheckFoul(tackler, victim) semantics
' documented in docs/game/match/fouls-and-cards.md (HIGH confidence, checked 2026-08-15).
' Written from extracted/decomp/TPlayer.CheckFoul@004f4d5f.c and its annotated
' twin (extracted/decomp_annotated/), cross-checked against that doc and against
' extracted/object_model.json for every field offset used below.
'
' REFINEMENT PASS 2 (byte-diff-guided, first diff still at byte 5 -- the prologue's
'   `sub esp,0x08` vs the original's `sub esp,0x0C`, a missing 4-byte local slot):
'   Disassembling the original directly (Ghidra's C had already thrown this bit away)
'   showed the "genuine save" 2.5-yard check spills Self.distancetoball to a temp stack
'   slot (`fld [ebx+0xd0]; fstp [ebp-8]`) BEFORE calling YardsToPixels(2.5), then reloads
'   and compares with `seta` -- the exact same field-first/call-second/spill-and-reload
'   shape the 10-yard check above it already uses (and which this file already had
'   right). This file had that one comparison backwards -- `YardsToPixels(2.5) <
'   Self.distancetoball`, call evaluated first -- which needs no spill slot at all (hence
'   the missing local) and compiles several bytes shorter besides. Flipped to
'   `Self.distancetoball > TPitch.YardsToPixels(2.5)` to put distancetoball back on the
'   left/first-evaluated side, matching the original's load-spill-call-reload-compare
'   sequence and its `seta` (strictly-greater) test exactly.
'
' REFINEMENT PASS 1 (byte-diff-guided, score was 5.7%, first diff at byte 5):
'   The prologue itself disagreed -- `sub esp,0x08` here vs the original's `sub esp,0x0C`
'   -- and right after it the outer `g_player_int01 = 1` compare jumped the WRONG way: a
'   far JNZ around a huge inline "then" (this file's old shape: nested If/Else with a
'   shared `ret` Local, `ret = 0` in the Else), vs the original's short JZ *into* the huge
'   block with a tiny 10-byte inline "else" (`mov eax,0` + `jmp` to the epilogue). That
'   10-byte shape is exactly what an unelaborated guard clause compiles to
'   (`If cond Then Return 0`, no Else, the rest of the function just continues past it) --
'   confirmed against TPlayer.CheckKeeperSave, TPlayer.CleanThrough and
'   TPlayer.DoKeeperDiveAI, all byte-identical and all using nothing but stacked
'   `If ... Then Return N` guards for exactly this shape (DoKeeperDiveAI alone opens with
'   seven of them in a row). Rewritten below:
'     * both outer gates (match state, training) and the ball.controlledby / distance /
'       lastkickedby checks are now guard clauses instead of a nested If/Else with a
'       shared `ret` Local -- every exit is a direct `Return`, so `ret` and the trailing
'       `Return ret` are gone entirely (this also explains the frame-size gap: the shared
'       `ret` Local needs no slot).
'     * the KeeperHoldingBall() split is now a guard too: the keeper-holding branch (with
'       its own Return) comes first, and the real (huge) foul-check logic is the
'       fall-through -- "the rest of the function" stays unindented rather than being
'       wrapped as the Else of a same-sized If, matching the idiom above.
'     * the two SetUpSetPiece call sites (main foul path, slide-on-keeper path) now share
'       one `n` Local instead of two (`n`/`n2`) -- the decompile reuses the same `uVar2`
'       slot for both, which only happens if the source did too; DoKeeperDiveAI's `ip`
'       (declared once inside a Select-Default, again later at a different scope) is the
'       same reuse-across-disjoint-blocks idiom, confirmed compiling fine in this dialect.
'   Left UNCHANGED (kept as ordinary If/Else, not converted to guards): the "made a save"
'   three-way check, the clean-through/from-behind card logic, and the slide-on-keeper
'   And-chain's Else. All three have branches of comparable size on both sides -- no clear
'   small-guard/large-body asymmetry the way the outer gates have -- and turning either
'   side into a guard would mean De Morgan-negating a 3-term And chain with no byte
'   evidence this deep in the body to check it against. Not worth the risk of silently
'   reordering a short-circuit comparison.
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C5B1FC g_player_int01:Int -- match state (must be 1, normal live play).
'   0x00C6CF90 g_training_int03:Int -- training-mode gate (must be 0).
'   0x00C5DEA4 g_ball:TBall -- the match ball. Same address/name TPlayer.SlideBall uses
'     when it calls Self.CheckFoul(g_ball.controlledby), and the same address/name
'     TPlayer.CheckKeeperSave (a direct sibling in the same doc pass) already uses.
'     Fields read: controlledby +0x70, lastkickedby +0x74, lasttouchedby +0x78.
'   0x00C5DEBC g_player_arr05:Int[] -- the slide-tackle animation array; same address as
'     TPlayer.PlayerSliding's "currentanim = g_player_arr05" test (and TPlayer.DoAnimSlide's
'     g_player_anim_slide, an unmerged synonym at the same slot).
'   0x00C5B21C g_awayteam:TTeam -- field +8 = id (object_model.json). Decides which side
'     the free kick is credited to. (0x00C5B218, the neighbouring home-team slot used by
'     TPlayer.RedCard/YellowCard/CheckOffside as g_hometeam/g_team1, is NOT touched here.)
'   0x00C6F028 g_contractoffer_tplayer:TProfile -- the human player's profile (established
'     name across 20+ recovered bodies). Fields used: energy +0x15C (Float),
'     takenpainkillers +0x174 (Int).
'   0x00C5DE8C g_player_float16:Float -- the injury-roll chance denominator, persisted
'     across matches (only ever multiplied here, never reset).
'   0x00C5B348 g_Object46:TChannel -- same address TPlayer.CheckKeeperSave and
'     TEngine.SetUpSetPiece already use for PlaySound's channel argument.
'   0x00C5B36C g_object52:TSound -- PlaySound's sound argument. UNRESOLVED elsewhere in
'     the unify tables (explain_global reports zero names at this address); it sits four
'     bytes before CheckKeeperSave's g_Object51:TSound (0x00C5B368), so it is almost
'     certainly a sibling TSound slot (a whistle/reaction cue), but which one is a guess.
'   TPlayer slots: 0x1C0 KeeperHoldingBall()i (on a0), 0x1E0 DoAnimFall()i (on a0),
'     0x160 GetShootingDirection()i (on Self), 0xE4 CleanThrough()i (on a0),
'     0xDC YellowCard()i, 0xE0 RedCard()i, 0x228 AddStat(i,f,f,f,f)i.
'   TStats_Match slot 0x3C = CountStat(i)i, field +0xC = yellows (object_model.json).
'   TPitch class-table: 0x5C InsidePenaltyBox(i,i,i)i, 0x6C YardsToPixels(f)f.
'   TEngine class-table: 0x70 SetUpSetPiece(i,i,i,i)i, 0xD4 DoYourSubstitutionOff(i)i.
'   TProfile slot 0x114 = DoInjury()i.
'   AngleDiff(f,f,i)f = module Function at 0x00506049 (the from-behind test; result
'     compared against 60.0, read out of the .rdata dword at 0x00C79AF0/0x00C79A28).
'   AngleTo(f,f,f,f) at 0x0050639D is called immediately afterwards on the two players'
'     positions and its Float result is discarded (fstp st(0) in the original -- invisible
'     in Ghidra's C, documented as a load-bearing quirk in fouls-and-cards.md). Kept here
'     as a bare statement call for exactly that reason.
'   Numeric literals read from .rdata and cross-checked against fouls-and-cards.md:
'     10.0 yards (max tackle-to-ball distance), 2.5 yards (keeper "genuine save"
'     distance), 60.0 degrees ("from behind" threshold, used twice), energy tiers at
'     30/40/50/60/70 with multipliers 0.5/0.6/0.7/0.8/0.9 (70+ = no multiplier at all).
'   Rand(1, Int(g_player_float16)) -- the "roll 1 in N" idiom (matches
'     simulated-results.md); argument order derived from cdecl push order the same way
'     TPlayer.CheckOffside's SetUpSetPiece(4, n, x, y) call was derived.
'
' KNOWN GAP: fouls-and-cards.md documents a dead conditional immediately before the
'   energy-tier calculation -- the code tests the human player's shinpads field
'   (TProfile+0x178) against zero and then does nothing with the result at all (the
'   branch target is the fall-through instruction). That test produces no visible effect
'   on control flow, so Ghidra's decompiler drops it from the C entirely -- it is not in
'   extracted/decomp/ or extracted/decomp_annotated/, and no raw disassembly was re-run
'   for this pass to recover its exact position/form. It is NOT reproduced below; the
'   compiled body may still fall a handful of bytes short of 1492 for this reason.
'
'!Global g_player_int01:Int
'!Global g_training_int03:Int
'!Global g_ball:TBall
'!Global g_player_arr05:Int[]
'!Global g_awayteam:TTeam
'!Global g_profile:TProfile
'!Global g_player_float16:Float
'!Global g_Object46:TChannel
'!Global g_object52:TSound
If g_player_int01 <> 1 Then Return 0
If g_training_int03 <> 0 Then Return 0
If a0.KeeperHoldingBall() <> 0
	If Self.currentanim = g_player_arr05 And TPitch.InsidePenaltyBox(Int(Self.x), Int(Self.y), Self.GetShootingDirection()) And g_ball.lasttouchedby <> Self
		LogLine("Foul: Slide on keeper!")
		Self.YellowCard()
	Else
		LogLine("Don't block tackle keeper.")
		Return 0
	End If
	a0.DoAnimFall()
	If g_training_int03 = 0 Then PlaySound(g_object52, g_Object46)
	Local n:Int = 2
	If g_awayteam.id = Self.teamid Then n = 1
	TEngine.SetUpSetPiece(4, n, a0.x, a0.y)
	Return 1
End If
a0.DoAnimFall()
If g_ball <> Null And g_ball.controlledby <> Null And g_ball.controlledby <> a0 Then Return 0
If Self.distancetoball > TPitch.YardsToPixels(10.0)
	LogLine("No Foul: Too far from ball")
	Return 0
End If
If g_ball.lastkickedby = Self
	LogLine("No Foul: Got ball")
	Return 0
End If
Local ang:Float = AngleDiff(Self.direction, a0.direction, 1)
AngleTo(Self.x, Self.y, a0.x, a0.y)
If Self.selectionno = 0
	If Self.distancetoball > TPitch.YardsToPixels(2.5) And g_ball.lasttouchedby <> Self And g_ball.lastkickedby = a0
		Self.AddStat(11, 0, 0, 0, 0)
	Else
		LogLine("No Foul: Made save")
		Return 0
	End If
Else
	If a0.CleanThrough() <> 0
		If ang < 60.0
			LogLine("Red card: Clean through and from behind")
			Self.RedCard()
		Else
			LogLine("Yellow card: Clean through but not from behind")
			Self.YellowCard()
		End If
	Else
		If ang < 60.0
			LogLine("Yellow card: From behind")
			Self.YellowCard()
		Else
			If Self.matchstats.CountStat(11) = Self.matchstats.yellows + 5
				LogLine("Yellow card: Too many fouls")
				Self.YellowCard()
			Else
				Self.AddStat(11, 0, 0, 0, 0)
			End If
		End If
	End If
End If
If g_training_int03 = 0 Then PlaySound(g_object52, g_Object46)
Local n:Int = 2
If g_awayteam.id = Self.teamid Then n = 1
TEngine.SetUpSetPiece(4, n, a0.x, a0.y)
If g_profile.shinpads = 0
End If
If g_profile.energy < 30.0 Or g_profile.takenpainkillers
	g_player_float16 = g_player_float16 * 0.5
Else
	If g_profile.energy < 40.0
		g_player_float16 = g_player_float16 * 0.6
	Else
		If g_profile.energy < 50.0
			g_player_float16 = g_player_float16 * 0.7
		Else
			If g_profile.energy < 60.0
				g_player_float16 = g_player_float16 * 0.8
			Else
				If g_profile.energy < 70.0
					g_player_float16 = g_player_float16 * 0.9
				End If
			End If
		End If
	End If
End If
If a0.newstar And Rand(Int(g_player_float16), 1) = 1
	TEngine.DoYourSubstitutionOff(1)
	g_profile.DoInjury()
End If
Return 1

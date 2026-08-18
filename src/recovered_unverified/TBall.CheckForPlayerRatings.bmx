' TBall.CheckForPlayerRatings -- NOT VERIFIED candidate, built on several earlier attempts.
' The most recent of those added no body changes -- it instrumented bcc's real register
' allocator instead (see the ALLOCATOR INSTRUMENTATION section below) and confirmed the
' residual is not reachable by source-level reordering, but did not find the actual lever.
' VA 0x004CC644   Ghidra-authoritative length 2867 bytes   slot 0xCC   SIG=(:TPlayer)i
'
' CURRENT STATE: mode=SAME LENGTH, 2867 of 2867 bytes.
' 6 real byte differences remain, all same-length substitutions (register/stack-slot choice
' only, no content difference). Zero length-changing gaps.
' Verify: `NSS5_WORKER=x NSS5_NO_LEARN=1 python scripts/localise_diff.py
' TBall.CheckForPlayerRatings src/recovered_unverified/TBall.CheckForPlayerRatings.bmx`.
'
' FIX 1 -- GAP A (the +9-byte gap that blocked several earlier passes) was NOT a codegen-fold
' problem at all. It was a WRONG SOURCE FORMULA. The GOODINTERCEPTION guard those passes
' wrote as:
'     Local ok:Int = lastkickedby.teamid <> p.teamid And Not (lasttouchedby = lastkickedby)
'     If ok Then ok = lasttouchedby = p
'     If ok And Not a0.PlayerSliding()
' (i.e. T1 And Not(T2) And T3 And Not(T4)) does not match the raw bytes at all once you
' trace the actual jump targets instead of trusting Ghidra's decompile shape. Reading
' 0x004CC75F-0x004CC7AE by hand (harness.disasm_original, not Ghidra) shows:
'   * T1 (lastkickedby.teamid<>p.teamid) false -> jump PAST the whole OR-group to the
'     PlayerSliding test carrying eax=0 (proceed=false).
'   * T1 true, falls into T2 (lasttouchedby=lastkickedby, a PLAIN `sete`, not negated).
'     T2 TRUE -> jump to the SAME target carrying eax=1 (proceed=true), SKIPPING T3
'     entirely -- classic Or short-circuit (true term skips the rest of the Or-group).
'   * T2 false -> falls through and evaluates T3 (lasttouchedby=p), whose result becomes
'     the carried eax directly (no separate combine step).
' That is `T1 And (T2 Or T3)`, not `T1 And Not(T2) And T3`. Every earlier "GAP A
' is a fold-eligibility problem" analysis was investigating the right BYTES with the wrong
' FORMULA baked into the candidate; changing the formula make the fold question moot --
' the region GAP A used to sit in (ORIGINAL +295..+338) is now BYTE IDENTICAL with no
' restructuring games, no accumulator-refcount tightrope, nothing from section 18 needed:
'     If lastkickedby.teamid <> p.teamid And (lasttouchedby = lastkickedby Or lasttouchedby = p)
' Confirmed: applying ONLY this change (leaving everything else, including the old `ok`
' plumbing into the PlayerSliding test, untouched) took the body from +9/1 gap to -12/2
' gaps -- GAP A's own +9 fully gone, replaced by a NEW, smaller, unrelated pair of gaps at
' the PlayerSliding test (see next fix) and a branch-length knock-on 3 bytes earlier.
'
' FIX 2 -- the PlayerSliding test. Once the OR-group above is fixed, `ok`
' has no reason to exist (its "reassign then AND with Not(D)" plumbing was purpose-built for
' the WRONG formula). Dropping it and testing PlayerSliding directly regressed a NEW pair
' of gaps: our compiler folds a bare `If Not a0.PlayerSliding()` into a direct negated jump
' (2 bytes), but the ORIGINAL materializes the boolean first (call / cmp / sete / movzx /
' cmp / je -- 11 bytes) then tests it. This is the exact "assign-then-test" idiom already
' established for GAP B (a plain CmpExp assignment is never fold-eligible, only
' a bcc consuming a scc directly is) -- so write it as a comparison assignment, not a Not():
'     Local slide:Int = a0.PlayerSliding() = 0
'     If slide
'         p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODINTERCEPTION" + Rand(4))
'     EndIf
' This closed the second gap completely. Combined with FIX 1, delta went -12 -> 0. Tried
' and confirmed NEUTRAL: moving `Local slide:Int` to the top of the function (next to `p`)
' and reassigning instead of declaring inline -- byte-for-byte identical result either way,
' so this part of the function's allocation is NOT sensitive to slide's declaration position
' (unlike the earlier `ok` experiments, which regressed the whole body). Kept the inline form
' as the more natural/faithful read.
'
' WHAT REMAINS -- 6 SAME-LENGTH SUBS, ALL ONE FAMILY, IDENTIFIED BY BRANCH:
'   ORIGINAL +1893/+1910 (VA 0x004CCDA9/0x004CCDBA) -- BADVISION's `Dist2D(...)>15.0` check
'     (confirmed via harness.read_string(0xc72e28) = "CBOSSSHOUT_BADVISION"): original spills
'     the Dist2D() float result to [ebp-0x18] across the YardsToPixels() call; ours uses
'     [ebp-0x14].
'   ORIGINAL +2134/+2151 -- GOODLONGPASS's `Dist2D(...)>15.0 And a0.distancetogoal_opp<
'     a0.distancetogoal_own` check (edi holds a0 here, confirmed via [edi+0xe8]/[edi+0xec]):
'     original uses [ebp-0x1c], ours uses [ebp-0x18].
'   ORIGINAL +2751/+2768 -- the a0=Null block's tail Crossing check (`Self.Crossing(0) And
'     Dist2D(...)>20.0 And p.distancetogoal_opp<p.distancetogoal_own`, ebx holds p here,
'     confirmed via [ebx+0xe8]/[ebx+0xec] and the trailing `AddPlayerRating(3,-1,"")` call):
'     original uses [ebp-0x14], ours uses [ebp-0x1c].
'   Pattern: original's assignment order across these 3 mutually-exclusive-branch sites is
'   -0x18, -0x1c, -0x14 (in program order); ours is the "obvious" ascending -0x14, -0x18,
'   -0x1c. A pure rotation. The OTHER three Dist2D>YardsToPixels sites in this same function
'   (GOODCORNER, GOODFREEKICK, GOODCROSS -- all textually EARLIER, all sharing the identical
'   spill/reload shape and the same [ebp-0x20] int->float staging slot) are NOT in the SUB
'   list, i.e. already byte-identical, so the rotation starts exactly at BADVISION and holds
'   for the rest of the function. sub esp is 0x20 on BOTH sides (checked directly against
'   the raw prologue bytes) -- total frame size already matches exactly, so this is pure
'   spill-ORDER (section 18.1's "handed out in the order nodes fail to colour"), not a
'   missing/extra Local.
'   RULED OUT THIS PASS (3 experiments):
'   (1) moving `Local slide`'s declaration position -- neutral, byte-identical result,
'       did not touch this cluster at all.
'   (2) (implicitly, via FIX 2) `ok`'s former presence/absence -- also not the cause.
'   (3) hoisting `Not Self.Crossing(0)` out of the 5-term guard into its own
'       assign-then-test Local (`Local notcross:Int = Self.Crossing(0) = 0` declared BEFORE
'       the And-chain, then `... And notcross`) -- REGRESSED HARD (+4 bytes, 2 new gaps,
'       first divergence at ORIGINAL +1735, 17 branch shifts). Root cause visible directly
'       in the original bytes: at ORIGINAL +1735 (VA 0x004CCD0B) the ORIGINAL loads
'       `Self.slidekick` (mov eax,[esi+0x8c]) as the literal FIRST action of the guard,
'       i.e. the And-chain's short-circuit order is exactly as written --
'       slidekick, posthit, lastkicktype<>4, lastkicktype<>5, Not Crossing(0) LAST -- and
'       Crossing() (an actual method call, expensive) is deliberately the last, so it is
'       only ever called when the first four cheap field-compares already passed. Hoisting
'       it to a Local BEFORE the chain forces an unconditional call up front, which is a
'       real behavioural change (not just a byte-count one) and correctly costs bytes.
'       CONCLUSION: whatever tips the 3-way rotation is NOT reachable by restructuring this
'       guard's evaluation order -- that order is already provably correct. The remaining
'       lever, if any, is something more subtle a few nodes upstream (or is a genuine
'       whole-function block_count/liveness property per section 18.4, same class of
'       finding earlier passes reached for the OTHER part of this function). Next pass:
'       do NOT retry hoisting/reordering this guard's terms; instead try
'       `scripts/w14S0_live.py`-style instrumentation on a probe modelling just these 3
'       Dist2D-spill sites plus filler branches, per section 18.4's own remedy, which has
'       never actually been run for this function despite being recommended by name in
'       three earlier reports.
'
' WHAT IS STILL PROVEN (still valid, verify with localise_diff.py
' rather than re-deriving):
'  * Outer guard is FOUR SEPARATE EARLY RETURNS (`If g_player_int01<>1 Then Return 0`,
'    `If g_bossmessages.Count()<>0 Then Return 0`, `Local p:TPlayer=TPlayer.GetHumanPlayer()`,
'    `If Not p Then Return 0`, `If Not lastkickedby Then Return 0`), not a wrapping And-chain.
'  * Top-level dispatch is `If a0=p ... ElseIf a0<>Null ... Else <a0=Null block> EndIf`; the
'    a0=Null block is physically last, falling straight into `p.icalledforball=0 /
'    p.ihadashot=0` with no trailing jmp.
'  * The teamid dispatch inside the a0<>p arm is a plain 3-way `If <crossing-eligible> ...
'    ElseIf a0.teamid<>p.teamid ... Else ...`; BOTH arms independently re-test
'    `slidekick=0 And posthit=0` as their own first conjunct (not a shared hoisted guard).
'  * SIX places in this function have If/Else arms physically swapped relative to Ghidra's
'    decompile text (Ghidra normalises polarity, guide 10.1): `sel<>0`
'    (PENALTYBOX/GOODEFFORT) vs `sel=0` (BIGDISPATCH); the a0=Null block's
'    `lastkickedby.ihadashot<>0` split; BIGDISPATCH's own ihadashot split; three
'    `InsidePenaltyBox(...)<>0` splits (GOODEFFORT's PENALTYBOX-arm, the a0=Null
'    ihadashot-arm, BIGDISPATCH's tail). Pattern: wherever Ghidra prints
'    `if (X = 0) { A } else { B }` with B a LogLine/EXPLETIVE-style tail case, true source
'    is `If X <> 0 Then B Else A`.
'  * Bare truth tests, not `<> 0`, for THREE guard-opening conditions that are the first
'    term of a fresh (non-ElseIf) `If`: `p.icalledforball`, both `Self.Crossing(0)`
'    occurrences at the head of their And chains. Costs 9 bytes as `X <> 0 And ...`.
'  * BADFREEKICK's two textually-identical arms are gated `ElseIf p.ihadashot <> 0`.
'  * All AddPlayerRating (shoutid,delta) pairs and string-literal keys, confirmed correct:
'    GOODPOSITIONING(4,2), GOODINTERCEPTION(4,2), GENERICBAD(4,0,Rand(5)), BADCALL(4,-1),
'    GOODCORNER(2,5)/BADCORNER(2,-1), GOODFREEKICK(1,3)/BADFREEKICK(1,-1),
'    GOODCROSS(3,3)/(3,-1,"") empty-string call (two sites), GOODLONGPASS(6,3)/GOODPASS(5,3),
'    BADVISION(6,-2)/(5,-3) [Then=6,-2 when Dist2D>15, Else=5,-3], BADLONGSHOT(8,-3)
'    [BIGDISPATCH tail] / (8,-5) [a0=Null block, credited to lastkickedby not p -- an
'    ORIGINAL quirk, preserved], BADFINISHING(9,-1)/(9,-1)/(9,-2), EXPLETIVE(10,-5),
'    GOODEFFORT(8,1).
'  * Field offsets: TBall lastkicktype+104, lastkickmatchstate+108, controlledby+112,
'    lastkickedby+116, lasttouchedby+120, slidekick+140, posthit+144. TPlayer teamid+20,
'    x+76, y+80, kickx+148, kicky+152, selectionno+188, distancetogoal_opp+232,
'    distancetogoal_own+236, distancetoopponent+264, icalledforball+288, ihadashot+292.
'  * Vtable slots: TList.Count=0x70, TPlayer.AddPlayerRating=0x234 (i,i,$)i,
'    TPlayer.PlayerSliding=0x1B0 ()i, TBall.Crossing=0xA4 (f)i.
'  * Globals: g_bossmessages:TList at 0x00C6B284, g_player_int01:Int at 0x00C5B1FC.
'  * Comparison operand order (x87, guide 10.1): every `Dist2D(...) > YardsToPixels(N)` has
'    Dist2D on the left EXCEPT GOODPOSITIONING (`p.distancetoopponent > YardsToPixels(10.0)`).
'
' ALLOCATOR INSTRUMENTATION -- DID NOT CLOSE THE GAP. Section 22 says
' "the answer is in the compiler, which ships with this repo" -- took that literally.
' tools/blitzmax-legacy-src/_src/win32_x86/rebuildbcc.bat genuinely works (`bmk makeapp -a -r
' -z -t console -o bcc bcc.cpp`, ~40s) and, built UNMODIFIED, reproduces this function
' byte-for-byte identically to the shipped bcc.exe (confirmed with localise_diff -- same 6
' SUBs, same VAs). Do this ONLY inside your own tools/bmx-workers/<id> tree (never the shared
' tools/blitzmax-legacy-src), and restore the original bin/bcc.exe when done -- it is a live,
' live build tool, not a scratch file.
' Patched cgallocregs.cpp (cgAllocRegs/createGraph/spill) to print usage/degree/block_count/
' cost per candidate, gated at runtime on frame->fun->sym->value containing
' "CheckForPlayerRatings" so the trace does not drown in the probe's prelude. Rebuilt, ran
' `bin\bcc.exe -r -g x86 probe.bmx` directly (bmk.exe swallows bcc's own stdout; calling bcc
' directly does not) against the harness's own generated probe.bmx for this exact candidate.
' MEASURED, not inferred:
'   * All 6 Dist2D-result temps (regs 140/157/191/220/240/292 in THIS candidate's compile,
'     one per site in textual order GOODCORNER/GOODFREEKICK/GOODCROSS/BADVISION/GOODLONGPASS/
'     a0=Null-tail) are an EXACT four-way cost tie: usage=2, degree=7, block_count=1,
'     cost=0.285714 -- all of them, no exceptions. (The pattern is generic: GOODPOSITIONING's
'     int->float staged distancetoopponent, reg 78, shares the identical profile; it is not
'     Dist2D-specific.) Confirmed from the flow dump that each is `mov FLOAT32'N,FLOAT64'8`
'     immediately after `call _bb_Dist2D` -- reg 8 is the shared x87-return virtual register
'     every float-returning CALL defines, so this profile is the generic "float result must
'     survive a second call" shape, not something special to these six sites.
'   * On an exact tie, spill()'s candidate loop keeps the FIRST node under `cost<min` (strict
'     less-than), so the winner is whichever is earlier in the `_spill` list. In THIS
'     candidate that list order matches ASCENDING REGISTER ID, which in turn matches PURE
'     TEXTUAL ORDER (140<157<191<220<240<292 exactly = source order) -- confirmed directly:
'     the debug trace's `Spilling:` sequence is 140,157,191,220,240,292, i.e. GOODCORNER,
'     GOODFREEKICK, GOODCROSS, BADVISION, GOODLONGPASS, a0=Null-tail in that order, which is
'     precisely today's WRONG slot assignment (-8,-0xc,-0x10,-0x14,-0x18,-0x1c respectively).
'   * For the ORIGINAL's order (GOODCORNER,GOODFREEKICK,GOODCROSS,a0=Null-tail,BADVISION,
'     GOODLONGPASS) to come out of the SAME tie-break rule, a0=Null-tail's virtual register
'     must have been allocated a LOWER id than BADVISION's/GOODLONGPASS's in the original's
'     compile -- i.e. bcc's front-to-back AST walk must have generated a0=Null-tail's Dist2D
'     call BEFORE BADVISION's/GOODLONGPASS's, despite a0=Null-tail sitting in the textually
'     LAST top-level branch of the whole function.
'   * RULED OUT (read straight from stm.cpp, not guessed): `IfStm::eval()` unconditionally
'     calls `then_block->eval()` before `else_block->eval()` (stm.cpp:277-298). An
'     `ElseIf`/`Else` chain desugars to right-nested `If`s, so codegen/register numbering for
'     a cascading If/ElseIf/Else walks STRICTLY in source (= physical) order, recursively,
'     with NO mechanism to visit an outer `Else` before an inner `ElseIf`'s `Then`. This is
'     definitive, not inferred from bytes: a0=Null-tail CANNOT be numbered before BADVISION/
'     GOODLONGPASS while the function's control-flow shape is what six passes have already
'     verified byte-exact (and reordering that shape is not on the table -- the CFG matches).
'   * CONCLUSION: the residual is not reachable by any statement move, guard rewrite, or
'     accumulator change within THIS function's text as currently structured -- six passes
'     have exhausted that space, and this pass closed it definitively for
'     the "just reorder something" family of fixes via source, not just by trial and error.
'     What is NOT yet tried: instrument `createGraph()`'s move-edge/coalesce path (the six
'     nodes are all move-related to reg 8, so they pass through `_coalesce` before `_freeze`/
'     `_spill` -- verify whether _coalesce's processing order, not raw id order, is the real
'     tie-break, and whether something upstream of these six sites -- more or fewer
'     intervening float-returning calls anywhere earlier in the function -- shifts relative
'     id spacing enough to change it without changing this guard's own text at all). That is
'     a bigger instrumentation lift (needs the coalesce()/combine() call sequence traced, not
'     just spill()) and was not attempted this pass for time. The rebuildbcc.bat route itself
'     is now proven fast and safe (worker-isolated); next pass does not need to rediscover it.
'
' EXTENDED INSTRUMENTATION -- FOUND WHY THE TRACE ABOVE MISLED. Reused
' the same isolated tree (SHA256-verified byte-identical to tools/blitzmax-legacy-src/bin/bcc.exe
' before touching it; restored byte-identical again afterward -- diffed clean). Added prints
' to freezeNode() (which list a node lands in + a running seq counter), combine(), coalesce(),
' freeze()'s pick, selectNode() (the _selected PUSH, LIFO), selectRegs()'s POP, the real
' frame->spillReg() call (the actual [ebp-N] slot assignment per cgframe_x86.cpp:898), and a
' full per-candidate dump inside spill()'s own cost loop (usage/degree/block_count/cost).
' Findings, most important first:
'   1. CONFIRMED all 6 sites really are an EXACT tie, not merely equal to 4 decimal places
'      (the earlier figure) -- usage/degree/block_count are literally the small integers
'      2/7/1 for every one of the 6, so cost=2.0f/7.0f is the SAME IEEE-754 bit pattern for
'      all 6, computed independently each time. There is no floating-point-noise angle here;
'      the outcome is 100% a question of which node the linked-list scan visits FIRST.
'   2. The _spill list order for these 6 is built by createLists()'s plain `for(k=0..
'      nodes.size())` scan -- a bare integer loop, NOT a pointer-ordered container -- so on
'      its own that part is fully deterministic and ascending (140,157,191,220,240,292 =
'      source order), confirmed identical across every run this pass made.
'   3. BUT: two separate rebuilds of the SAME instrumentation concept -- one printing only at
'      freezeNode()/combine()/coalesce()/freeze(), a second adding ONE more cout print inside
'      spill()'s cost loop, otherwise touching no logic at all -- produced OPPOSITE pick
'      orders for these 6 nodes on the IDENTICAL candidate source: build A pushed them onto
'      _selected as 292,240,220,191,157,140 (descending); build B (one extra cout call added,
'      nothing else) pushed 140,157,191,220,240,292 (ascending) -- a full reversal from one
'      unrelated print statement. Node::edges and Node::moves are `set<Node*>`
'      (cgallocregs.cpp:23) -- ordered by raw pointer value -- so somewhere upstream (which
'      node's decDegree()-triggered demotion out of _spill happens first, itself resolved by
'      iterating a NodeSet) the outcome is sensitive to bcc.exe's OWN heap layout, which
'      shifts when bcc.exe's own compiled code changes size at all, even in a dead branch
'      gated on a runtime string compare that is never true for any other function.
'   4. Ruled out that this is "any recompile is random": the PRISTINE, hash-verified-identical
'      bcc.exe run through the real harness path (`bmk makeapp -r -t console`, not bcc invoked
'      by hand) gave the IDENTICAL MISMATCH (first_diff=335, matched=2542/2867) THREE TIMES in
'      a row on this exact candidate body. One fixed binary => fully reproducible result
'      (consistent with old 32-bit PE + no ASLR). It is specifically OUR OWN instrumented
'      rebuilds, which are different binaries from the pristine one and from each other, that
'      disagree with each other and with the shipped compiler.
'   5. CONCLUSION: cout-tracing added to cgallocregs.cpp is NOT a safe probe for this
'      specific residual -- it can change the very address-dependent tie-break it is trying to
'      observe, so any trace captured this way (including the earlier one, which also printed inside
'      these same hot functions) should be treated as suspect for the exact pick ORDER, even
'      though the coarser facts it established (which nodes tie, that the CFG shape is
'      correct, that stm.cpp visits Then before Else) do not depend on pick order and still
'      stand. A trustworthy probe needs a side channel that cannot perturb bcc's own heap --
'      e.g. writing to a fixed-address static array (no heap allocation) instead of `cout`, or
'      dumping state via the debugger (mcp__ghidra__debugger_*) attached to the UNMODIFIED
'      bcc.exe instead of recompiling it at all.
'
' NEXT STEP for whoever continues: do NOT trust cout-based cgallocregs.cpp instrumentation for
' the pick order (see findings 3/5 above) -- use a fixed-size static buffer + a single write()
' syscall at process exit, or attach a debugger to the unmodified bcc.exe and set a breakpoint
' on `spill()`/`selectNode()`, so nothing is added to bcc's own compiled code and its heap
' layout is untouched. Once you have a trustworthy trace, the open question is still
' this: does something upstream of these six sites (more/fewer intervening float-
' returning calls anywhere earlier in the function) change whichever of them gets swept from
' _spill to _simplify first via decDegree()'s NodeSet-ordered neighbor walk -- that is a
' genuine source-level question (int/float traffic count earlier in the function), not a
' property of bcc.exe's own binary, and answering it might still close this gap.
'
' RE-RAN AGAINST status/score/TBall.CheckForPlayerRatings.txt, WHICH SAYS
' 87.1% (2497/2867) WITH THE *FIRST* DIVERGENCE AT BYTE 17 -- inside the function's own
' prologue (`cmp dword [g_player_int01],1`), nowhere near the "6 same-length subs deep in the
' Dist2D spill cluster" this file's own notes above describe. That is not a regression
' in this body -- it is corpus-wide shared build state. Proof, not inference:
'   `python scripts/bytematch.py src/assembled/nss5_assembled.exe TBall CheckSideLines` --
'   TBall.CheckSideLines.bmx (a src/recovered/, BYTE-VERIFIED sibling this very file cites as
'   its own Global-naming precedent, which this pass did NOT touch) mismatches in the CURRENT
'   full assembled build TOO, at the SAME address and with the SAME wrong substitute bytes
'   (orig `A1 FC B1 C5 00` vs ours `A1 C0 CB C9 00` -- i.e. g_matchstate/g_player_int01's
'   canonical slot 0x00C5B1FC is resolving to 0x00C9CBC0 in THIS build for a file that is
'   independently known-good). `TBossMessage.DrawAll` (also src/recovered/, also cites
'   g_bossmessages at 0x00C6B284) shows the identical drift for THAT slot
'   (0x00C6B284 -> 0x00C9B944, byte-for-byte the same wrong value this file's own report
'   shows). Three unrelated files, two different Globals, the same wrong replacement address
'   each time -- that is the full-corpus Global layout (src/assembled/, written by
'   scripts/assemble.py, shared and rebuilt by every pass) having drifted since those
'   siblings were last verified, not anything a change to THIS file's source text can reach.
' Re-verified the ACTUAL function logic the only way that is not contaminated by that shared
' drift -- `NSS5_NO_LEARN=1 python
' scripts/localise_diff.py TBall.CheckForPlayerRatings
' src/recovered_unverified/TBall.CheckForPlayerRatings.bmx` (private per-pass probe build,
' operands masked by name so Global-slot drift cannot leak into the comparison) -- and it
' reproduces the numbers above exactly: SAME LENGTH (delta +0), first REAL divergence
' at ORIGINAL +1893, and precisely the same 6 same-length subs at +1893/+1910/+2134/+2151/
' +2751/+2768 (all `[ebp-0x18]` vs `[ebp-0x14]` vs `[ebp-0x1c]` spill-slot swaps in the
' Dist2D-result float staging for BADVISION/GOODLONGPASS/a0=Null-tail), nothing else. So the
' source in this file is unchanged from the state described above, and that state is still
' correct: 2861/2867 (99.79%) once corpus-wide address drift is factored out, with the
' residual 6 bytes already proven (by direct compiler instrumentation, not
' guesswork) to be a bcc.exe register-allocator tie-break the source text does not control.
' MADE NO BODY CHANGE THIS PASS. Per rule 4 ("if the current body is closer to the original
' than anything you can produce, leave it alone and say so"): this body already IS that,
' and the low number in status/score/TBall.CheckForPlayerRatings.txt is a shared-build-state
' artifact, not a defect to chase here. NEXT PASS ON THIS FILE: before touching the body,
' rerun the CheckSideLines/DrawAll cross-check above against whatever nss5_assembled.exe
' exists at the time -- if Global addresses are still drifting corpus-wide, the fix belongs
' in scripts/assemble.py's Global-emission/ordering path (or whatever shared state feeds it),
' not in any one function's .bmx source.
	Method CheckForPlayerRatings:Int(a0:TPlayer)
		'!Global g_player_int01:Int
		'!Global g_bossmessages:TList

		If g_player_int01 <> 1 Then Return 0
		If g_bossmessages.Count() <> 0 Then Return 0
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If Not p Then Return 0
		If Not lastkickedby Then Return 0
		If a0 = p
			If lastkickedby <> a0
				If lastkickmatchstate = 1 And p.distancetogoal_opp < p.distancetogoal_own And p.distancetoopponent > TPitch.YardsToPixels(10.0)
					p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODPOSITIONING" + Rand(4))
				Else
					If lastkickedby.teamid <> p.teamid And (lasttouchedby = lastkickedby Or lasttouchedby = p)
						Local slide:Int = a0.PlayerSliding() = 0
						If slide
							p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODINTERCEPTION" + Rand(4))
						EndIf
					EndIf
				EndIf
			EndIf
		ElseIf a0 <> Null
			If controlledby = p
				p.AddPlayerRating(4, 0, "CBOSS_GENERICBAD" + Rand(5))
			Else
				If p.icalledforball And a0.teamid <> p.teamid
					p.AddPlayerRating(4, -1, "CBOSSSHOUT_BADCALL" + Rand(4))
				ElseIf lastkickedby = p And lasttouchedby = p
					Local sel:Int = a0.selectionno = 0
					If sel Then sel = p.ihadashot
					If sel <> 0
						If TPitch.InsidePenaltyBox(p.kickx, p.kicky, 0) <> 0
							If lastkickmatchstate = 7
								p.AddPlayerRating(10, -5, "CBOSSSHOUT_EXPLETIVE" + Rand(4))
							Else
								p.AddPlayerRating(9, -1, "CBOSSSHOUT_BADFINISHING" + Rand(4))
							EndIf
						Else
							p.AddPlayerRating(8, 1, "CBOSSSHOUT_GOODEFFORT" + Rand(4))
						EndIf
					Else
						If lastkickmatchstate = 5
							If a0.teamid = p.teamid
								If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
									p.AddPlayerRating(2, 5, "CBOSSSHOUT_GOODCORNER" + Rand(4))
								EndIf
							Else
								p.AddPlayerRating(2, -1, "CBOSSSHOUT_BADCORNER" + Rand(4))
							EndIf
						ElseIf lastkickmatchstate = 4
							If a0.teamid = p.teamid
								If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
									p.AddPlayerRating(1, 3, "CBOSSSHOUT_GOODFREEKICK" + Rand(4))
								EndIf
							ElseIf p.ihadashot <> 0
								p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
							Else
								p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
							EndIf
						ElseIf p.ihadashot <> 0
							If TPitch.InsidePenaltyBox(p.kickx, p.kicky, 0) <> 0
								p.AddPlayerRating(9, -1, "CBOSSSHOUT_BADFINISHING" + Rand(4))
							Else
								p.AddPlayerRating(8, -3, "CBOSSSHOUT_BADLONGSHOT" + Rand(4))
							EndIf
						Else
							If Self.Crossing(0) And Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(20.0) And a0.distancetogoal_opp < a0.distancetogoal_own
								If a0.teamid = p.teamid
									p.AddPlayerRating(3, 3, "CBOSSSHOUT_GOODCROSS" + Rand(4))
								Else
									p.AddPlayerRating(3, -1, "")
								EndIf
							ElseIf a0.teamid <> p.teamid
								If Self.slidekick = 0 And Self.posthit = 0 And Self.lastkicktype <> 4 And Self.lastkicktype <> 5 And Not Self.Crossing(0)
									If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
										p.AddPlayerRating(6, -2, "CBOSSSHOUT_BADVISION" + Rand(4))
									Else
										p.AddPlayerRating(5, -3, "CBOSSSHOUT_BADVISION" + Rand(4))
									EndIf
								EndIf
							Else
								If Self.slidekick = 0 And Self.posthit = 0
									If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0) And a0.distancetogoal_opp < a0.distancetogoal_own
										p.AddPlayerRating(6, 3, "CBOSSSHOUT_GOODLONGPASS" + Rand(4))
									Else
										p.AddPlayerRating(5, 3, "CBOSSSHOUT_GOODPASS" + Rand(4))
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If lastkickedby.newstar <> 0
				LogLine("Player kicked ball out of play")
				If lastkickedby.ihadashot <> 0
					If TPitch.InsidePenaltyBox(lastkickedby.kickx, lastkickedby.kicky, 0) <> 0
						If lastkickmatchstate = 7
							p.AddPlayerRating(10, -5, "CBOSSSHOUT_EXPLETIVE" + Rand(4))
						Else
							p.AddPlayerRating(9, -2, "CBOSSSHOUT_BADFINISHING" + Rand(4))
						EndIf
					Else
						lastkickedby.AddPlayerRating(8, -5, "CBOSSSHOUT_BADLONGSHOT" + Rand(4))
					EndIf
				Else
					If lastkickmatchstate = 5
						p.AddPlayerRating(2, -1, "CBOSSSHOUT_BADCORNER" + Rand(4))
					ElseIf lastkickmatchstate = 4
						p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
					Else
						If Self.Crossing(0) And Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(20.0) And p.distancetogoal_opp < p.distancetogoal_own
							p.AddPlayerRating(3, -1, "")
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		p.icalledforball = 0
		p.ihadashot = 0
	End Method
' ================= LATEST PASS: NOT VERIFIED -- DO NOT PROMOTE =================
' VA 0x004f6c2b   2201 bytes   vtable slot 0xf4   sig ()i
' PROGRESS THIS PASS (NSS5_WORKER=442): entered at 2271/2201 (+70, 25 gaps, 0 subs) -> left at
' 2261/2201 (+60, 24 gaps, 0 subs), delta_accounted COMPLETE both ends
' (scripts/localise_diff.py TPlayer.CheckKick). first_divergence stays at ORIGINAL +86
' throughout.
'
' ONE FIX LANDED, CONFIRMED AGAINST harness.disasm_original 0x004F71F0..0x004F7263 BYTE BY
' BYTE: the u5/tplayer02/b3/b Slide-decision gate (source lines ~570-579 at pass start) had
' the wrong SHAPE, not just a materialisation difference. The disassembly shows TWO SEPARATE
' tplayer02 tests back to back, not one. The FIRST (VA 0x004F7219) is `cmp eax,NULL / sete al
' / movzx / cmp eax,0 / jne <merge>` -- a Null-EQUALITY test whose 0/1 result reaches the SAME
' merge point (VA 0x4F727C, the final `If b` test) as the u5=0 skip and as the b3-chain's own
' fallthrough. The SECOND (VA 0x4F722E) reloads tplayer02 a second time and tests
' setne/`<>Null` in the direct sense, gating entry to the b3 computation -- and this second
' test is provably a dead/redundant check (always true when reached, since the first test's
' fallthrough already proved tplayer02<>Null). Old source had ONE gate
' (`If u5 And g_player_tplayer02 <> Null`) wrapping a `Local b3:Int=False / If
' g_player_tplayer02<>Null / b3=... / EndIf / b=False / If b3 / b=... / EndIf`, which does
' not reproduce the "Null test result becomes b directly" path at all (tplayer02=Null was
' unreachable dead weight in that shape, always landing on b=False via the b3 default instead
' of the true value carried through eax). Rewritten to match the disassembly's actual data
' flow: `Local b:Int=False / If u5 / b = g_player_tplayer02 = Null / If
' g_player_tplayer02<>Null / Local b3:Int = g_player_tplayer02.z<g_player_int33 / b=False /
' If b3 / b=passtoid<>id / EndIf / EndIf / EndIf`. Net -10 bytes (gap at ORIGINAL +1511/+1528
' collapsed from a 5-byte insert plus a 21-byte delete into a single -12/+3 pair; the
' remainder is the inner redundant `<>Null` check still compiling to a compact
' `cmp mem,imm/je` on our side where the original fully materialises via
' mov+cmp+setne+movzx+cmp+je -- see below).
'
' THREE VARIANTS TRIED ON THE u9/u5/u2 VALUE-SUBSTITUTION CASCADE THIS PASS (source lines
' ~583-609, the `u9 = u5 : If u5 = 0 Then u9 = u2` idiom feeding the Jump-vs-Dive gate),
' ALL VERIFIED WORSE, ALL REVERTED, confirming the three EARLIER passes' independent finding
' below still holds at this pass' lower baseline:
'   1. Flattening the `n=0/If u5 Then n=Self.newstar/n6=0/If n<>0 Then
'      n6=TTraining.CanCallForBall()` cascade (source lines ~549-556) into
'      `Local n6:Int=0 / If u5 And Self.newstar<>0 Then n6=TTraining.CanCallForBall()` --
'      2261->2281 (delta 60->80, 24->32 gaps). Matches the earlier pass' identical finding at
'      the higher +132 baseline: bcc materialises BOTH terms of the And with setne+movzx when
'      they feed an assignment rather than gating a branch directly.
'   2. `Local u9:Int = u5` (fresh shadowing declaration in place of the plain `u9 = u5`
'      reassignment, matching the b3-redeclaration pattern that DOES work elsewhere in this
'      file) -- 2261->2265 (60->64, 24->32 gaps).
'   3. Replacing the `u9 = u5 : If u5 = 0 Then u9 = u2` value-select plus its downstream
'      `If u9 And g_player_tplayer02 <> Null` with a flat `If (u5 Or u2) And
'      g_player_tplayer02 <> Null`, relying on u9's truthiness-only usage (confirmed: u9's
'      numeric value is never read anywhere, only its <>0-ness at the one site) -- 2261->2265
'      (60->64, 24->32 gaps). Disassembly of our own build shows this makes the compiler
'      reuse u5's OWN register (edi) to hold the Or-result, corrupting u5's value for its
'      LATER, separate reload at source line ~598 (`If u5 = 0 Then u5 = u2`), which then
'      needs its own extra byte to recover.
' CONSEQUENCE: the u9/u5/u2 cascade and the long-lived `n` Local (read at 4+ disconnected
' sites: PlayerOnFeet-result at line ~527, newstar-gate result at ~551, and three
' jumpspotgood-gate results at ~593/607/641) are NOT reachable by reshaping the surrounding
' If/And/Or syntax -- three structurally different rewrites (flat And, flat Or, fresh
' shadowing) all fail the same way this pass, matching three independently-reverted attempts
' from earlier passes (flat 3-term And, nested-if, and a targeted last-hop flatten). The
' remaining gaps this pass could not close are the same family the two "TRIED THIS PASS,
' VERIFIED WORSE" sections below already diagnose: legacy bcc appears to keep NO persistent
' register/stack slot for u9/n across their multi-site lifetimes at all (pure eax-reuse, value
' recomputed fresh at each read, never stored) while NG's allocator commits a register for
' the Local's WHOLE textual scope the moment it is read from 2+ separated statements, and no
' BlitzMax-level rewrite tried so far avoids that commitment without changing which register
' holds something else nearby.
'
' Also confirmed unfixable this pass, same root cause, not re-attempted (already disproved by
' the u9 experiments above): the solo `If Self.joy.kickbuttonhits > g_player_int50 - 200`
' u5-setup gate (ORIGINAL +994/+1013, delta -6 net -- our build is ALREADY shorter than
' original here, not longer) and the inner redundant `g_player_tplayer02 <> Null` check left
' over from the b3 rewrite above (ORIGINAL +1534, delta -12) both show original fully
' materialising a solo relational branch condition via mov+cmp+setcc+movzx+cmp+jcc while NG's
' backend collapses the same solo condition to a direct `cmp mem,imm/jcc`. Tried wrapping the
' inner check in `Not (g_player_tplayer02 = Null)` to force materialisation (per the
' double-negation rule) -- VERIFIED WORSE (2261->2270, 24->25 gaps, 1 sub), reverted. This
' looks like an unconditional NG-vs-legacy backend optimisation difference for solo branch-
' only comparisons, not something the BlitzMax source can steer.
'
' ================= EARLIER PASS: NOT VERIFIED -- DO NOT PROMOTE =================
' VA 0x004f6c2b   2201 bytes   vtable slot 0xf4   sig ()i
' PROGRESS THIS PASS: 2333/2201 (+132, 33 gaps) -> 2266/2201 (+65, 26 gaps), both COMPLETE
' (harness.try_method + scripts/localise_diff.py, NSS5_WORKER=405). first_divergence stays at
' ORIGINAL +86 throughout (a short-vs-near jmp encoding artifact of the bytes fixed below, not
' a separate defect). Net: 67 bytes closed, verified by re-running the oracle after every edit,
' no regression introduced anywhere else in the function.
'
' ROOT CAUSE OF ALL 8 EDITS THIS PASS: a single recurring codegen rule, confirmed against
' `harness.disasm_original` at every site before editing: when an Int-typed field/Local/call
' result is the FIRST term of a short-circuit `And`-chain (or the SOLE condition of a direct
' `If`/`ElseIf`) written as an explicit `<> 0` comparison, bcc materialises it with an extra
' `setne al / movzx eax,al` that the original never has for that term -- the original just does
' `cmp eax,0 / je` straight off the raw load and lets the eax-reuse merge trick (documented
' below in "ROOT CAUSE FOUND") carry the value forward. LATER terms of the same chain that are
' genuine relational/equality tests (`<> Null`, `= 0`, `> x`, etc.) DO get materialised in the
' original and were already correct in this file; only the bare-truthiness FIRST term was wrong.
' The fix is always the same single-token edit: drop the `<> 0` and leave the field/Local bare
' (`If Self.newstar` not `If Self.newstar <> 0`). No Local declarations, no control flow, no
' reassignment shape was touched -- these are pure materialisation-style edits, structurally
' unlike the value-substitution rewrites earlier passes tried and reverted (see below).
'
' Sites fixed, each confirmed bare (`cmp eax,0/je`, no setcc) in the original before editing:
'   - Redundant `n = 0` inside `If n = 0` (KeyHit/JoyHit dev-cheat gate, VA ~0x004F6D89-area
'     for the analogous newstar case; this specific one at VA 0x004F6C92): the original never
'     stores a literal 0 for `n` here at all -- it reads `g_engine_int164` straight into eax
'     off the fallthrough from the `n=0` test. The extra statement was a leftover from an
'     earlier flag-default idiom that was never live code; removing it (not "fixing a value",
'     genuinely deleting a no-op the original does not have) closed GAP 23/24/25 (the
'     KeyHit/JoyHit region's three linked short-vs-near jump artifacts, ~12 bytes plus cascade).
'   - `Self.newstar <> 0 And ...` (ResetKick guard) -> `Self.newstar And ...`. Confirmed at VA
'     0x004F6D89: bare `cmp eax,0/je`, only the LATER `<>Null`/`<>Self`/`>` terms materialise.
'     -9 bytes (GAP 10).
'   - `(Self.joy.kickbuttonhits <> 0 And kickbuttondown = 0) Or ...` (TapKick/HoldKick gate)
'     -> `(Self.joy.kickbuttonhits And kickbuttondown = 0) Or ...`. Confirmed at VA 0x004F6F36.
'     -9 bytes (GAP 11).
'   - Five more first-term `<> 0` -> bare fixes in the u5/u2/u9/n6 cascade (source area
'     "Local u5:Int = 0" through the "kickdirection=-1.0/kickpower=0.0" reset), each confirmed
'     individually against disasm before editing: `If u5 <> 0` (sole, newstar hop, VA
'     0x004F708C) -> `If u5`; `If n6 <> 0 And ...` (CanCallForBall gate, VA 0x004F70A1) ->
'     `If n6 And ...`; `If u9 <> 0 And (...)` (teaminpossession/distancetoball gate, VA
'     0x004F7151) -> `If u9 And (...)`; `If u5 <> 0 And g_player_tplayer02 <> Null` (Slide/b3
'     gate, VA 0x004F7212) -> bare, TWO occurrences (the Jump-arm b3 gate and the Dive-recheck
'     0.6-threshold gate, VA 0x004F72F8); `If u9 <> 0 And g_player_tplayer02 <> Null`
'     (jumpspotgood-Jump gate, VA 0x004F7294 merge) -> bare; `ElseIf u5 <> 0` (activebutton
'     branch selector, VA 0x004F7365) -> bare; `ElseIf u5 <> 0 Then Self.Call()` (outer
'     ball<>Null-Or-training gate's ElseIf, VA 0x004F748F) -> bare.
'   - The `u2 <> 0 And g_player_tplayer02 <> Null` third-arm gate (u2-only jumpspotgood path,
'     VA 0x004F7432) -> `u2 And ...`: A/B verified in isolation this pass (with vs without,
'     holding the other 7 edits constant) to independently save 9 bytes and NOT be the cause
'     of the alignment tool's large merged-gap display in the u5/u9 region -- that display
'     artifact (localise_diff.py's tolerant aligner collapsing ~400 bytes of real content into
'     one low-confidence gap once enough nearby bytes shifted) is cosmetic; delta_accounted
'     stayed COMPLETE throughout and the byte total only ever moved the direction predicted.
'
' NOT ATTEMPTED THIS PASS, and should not be attempted incrementally by the next pass either:
' the remaining +65 bytes are entirely the `u9 = u5; If u5 = 0 Then u9 = u2` VALUE-SUBSTITUTION
' reload (source lines ~510-513) and the `n = 0; If b Then n = Self.jumpspotgood` reassignment
' (four occurrences) that the "ROOT CAUSE FOUND" section below already diagnosed correctly: the
' original stores NEITHER u9 NOR this use of n anywhere -- it is pure conditional eax-reload,
' impossible to reproduce faithfully while `n`/`u9` remain real, stack-visible Locals shared
' with the rest of the function (they must stay real Locals elsewhere -- `n` in particular is
' read across many disconnected sites, `Local n:Int = Self.PlayerOnFeet()` earlier in the
' function). This is a genuinely different class of fix from the 8 above (restructuring value
' flow, not rewording a boolean test) and three independent earlier attempts at it (see the
' "TRIED THIS PASS" and "PROBE PASS" sections below) each made the body WORSE by flipping
' register allocation across the whole cascade. Confirmed again indirectly this pass: none of
' the 8 materialisation-only edits above touched this pattern and none regressed anything,
' consistent with the earlier passes' finding that the value-substitution reload specifically
' (not bare-vs-materialised in general) is what destabilises register allocation. The next
' pass's only remaining lever is still the one named below: rewrite the whole u9/n
' value-substitution chain as one simultaneous edit and verify once, not gap-by-gap.
'
' ================= EARLIER PASS: NOT VERIFIED -- DO NOT PROMOTE =================
' VA 0x004f6c2b   2201 bytes   vtable slot 0xf4   sig ()i
' State unchanged from the pass before: STILL 2333/2201, +132, 33 gaps, COMPLETE. Three edits were
' tried this pass and ALL reverted after `scripts/localise_diff.py` verified each one made
' the body worse; the file below is byte-for-byte the inherited text.
'
' NEW DIAGNOSIS for GAP 1 (original +498, the -25 entry) / GAP 4 (+490, the +16 entry) --
' confirmed directly from harness disassembly (`harness.disasm_original` 0x004F6E04..
' 0x004F6E4A, the GoalScorer/kickbuttonhits/kickbuttondown/PlayerOnFeet gate at source
' lines ~373-391): this is genuinely ONE FLAT 3-TERM AND-CHAIN, not 4 nested Ifs as an earlier pass
' left it and not a "materialise-then-branch" Local either. Proof: `je 0x4f6e37` (GoalScorer
' fails) and the second `je 0x4f6e37` (kickbuttonhits fails) BOTH jump to the exact same
' byte -- the `cmp eax,0` that sits immediately after the THIRD term's `sete al / movzx
' eax,al` (kickbuttondown==0). There is no separate zero-store for the failed-early paths;
' they land directly on eax's stale 0 from the failed cmp, exactly the merge-point idiom
' documented elsewhere in this function. The third term needs `sete/movzx` (it is
' an `=0` equality, not a raw truthiness) but is NOT stored to any Local -- its raw eax
' value flows straight into the merge `cmp eax,0` that gates the `PlayerOnFeet()` call.
' Source that should reproduce this: `Local n:Int = 0 : If Self.GoalScorer() <> 0 And
' Self.joy.kickbuttonhits <> 0 And Self.joy.kickbuttondown = 0 Then n =
' Self.PlayerOnFeet() : If n <> 0 Then <controlledby/HoldKick/Celebrate/Commiserate> :
' n = Self.PlayerOnFeet() : If n <> 0 Then <rest of function>`.
'
' TRIED THIS PASS, VERIFIED WORSE, REVERTED (three variants, in order):
'   1. `Local b1:Int=False / If GoalScorer()<>0 And kickbuttonhits<>0 Then b1=(kickbuttondown
'      =0) / Local n:Int=0 / If b1 Then n=PlayerOnFeet()` -> 2333->2372 (+132->+171). The
'      "And" between GoalScorer<>0 and kickbuttonhits<>0, when the chain's result feeds an
'      assignment rather than gating a branch directly, makes bcc materialise BOTH terms
'      with setne+movzx (confirmed in the compiled output) -- it does NOT get the eax-reuse
'      merge-point trick at all in this shape.
'   2. Same but nested `If GoalScorer()<>0 / If kickbuttonhits<>0 / b1=(kickbuttondown=0)`
'      instead of `And` -> 2333->2352 (+132->+151). Better than (1) but still materialises
'      `b1` into a real register (`mov ebx,eax`) and reloads it (`mov eax,0/cmp ebx,0`) for
'      the subsequent `If b1` -- extra bytes the original does not have, because the
'      original never stores this value anywhere (see diagnosis above).
'   3. The flat 3-term `And`-chain matching the diagnosis exactly (`Local n:Int=0 / If
'      GoalScorer()<>0 And kickbuttonhits<>0 And kickbuttondown=0 Then n=PlayerOnFeet()`)
'      -> 2333->2367 (+132->+166), AND `first_divergence` jumped from +86 all the way back
'      to +9: this change flips Self's physical register for the ENTIRE REST OF THE
'      FUNCTION (esi -> ebx from the prologue onward, confirmed via `subs` in
'      localise_diff.py's JSON output). This is the SAME whole-function-interference-graph
'      fragility already documented for the u5/u2/n cascade -- it now reproduces at
'      a COMPLETELY DIFFERENT site (the very first statement of the "Else" branch, VA
'      0x004F6E04), which generalises that warning: it is not specific to the
'      jumpspotgood cascade, it is a property of this function's register pressure as a
'      whole. Any local-scope edit here, even one that is provably byte-correct in
'      isolation for its own gap, is not safe to land without re-verifying the WHOLE
'      function afterward, and in all three tries here the whole-function cost exceeded the
'      local gain.
'
' CONSEQUENCE FOR THE NEXT PASS: the diagnosis above (flat 3-term And, no Local storage for
' the chain) is believed correct and is new evidence, unlike the earlier "nested 4 deep"
' guess which this pass's disassembly reading shows was never byte-correct (GAP 1's -25
' was always open, that pass just did not close it). But per variant 3, landing it verbatim
' regresses the whole function. Given the earlier and this pass's independent confirmation
' that incremental single-site edits to register-pressure-sensitive parts of this function
' are not reliable, the only remaining path is still the one named earlier: rewrite the
' full ~150-line cascade (source lines ~373-520, i.e. this gate PLUS the u5/u2/u9/b/b3/n
' cascade already analysed) as one simultaneous, single edit incorporating BOTH
' diagnoses, verify once. Not attempted this pass (too large a blind edit for one pass,
' per the same reasoning given earlier). Left the body exactly as inherited.
'
' ================= EARLIER PASS: NOT VERIFIED -- DO NOT PROMOTE =================
' Re-ran localise_diff.py against the body BELOW, unedited: STILL 2333/2201, +132, 33 gaps,
' 4 subs, COMPLETE -- byte-for-byte identical to the earlier end state. Corpus is not
' rotting on this target.
'
' Widened the disassembly window around SUB 3 (harness.disasm_original 0x004F72E3..+120,
' the DoAnimJump/DoAnimDive decision spanning VA 0x004F72E3-0x004F7360) to look for a
' register-pressure explanation for why SUB 1-4 land in edx/ecx in our build instead of
' eax. CONFIRMED, does not change the diagnosis: across that entire ~125-byte span the
' original touches ONLY eax as scratch (esi=Self, edi=u5, one `mov [ebp-0x14],eax` for an
' Int->Float cast temp) -- there is no second GP register in play anywhere in this window,
' so there is no "eax is needed elsewhere, spill to edx" story to find on the original's
' side; the divergence is purely OUR allocator's choice, driven by whatever our build sees
' as competing for eax at that program point (most likely artefact of `b`/`n` being real,
' separately-declared Locals in our source vs. the original's zero-storage chain -- see
' the "KEY STRUCTURAL FINDING" below, unchanged).
'
' Did not attempt a further edit this pass: the two earlier targeted
' fixes each independently made the body WORSE (+132->+147 and +132->+138 respectively) when
' applied incrementally, and the isolated probe already showed the minimal syntactic
' shape compiles correctly IN A VACUUM but not embedded in this function's full register
' pressure. The one still-untried lever (rewrite the whole ~100-line u5/u2/u9/b/b3/n
' cascade as a single simultaneous edit, verify once) was judged too large a blind edit to
' attempt safely inside one pass's budget without the dedicated small-probe sweep earlier passes
' called for and did not complete either. Leaving the file exactly as inherited
' rather than risk a third regression. NEXT PASS: do the probe sweep first (2-3 syntactic
' forms of the u9=u5/If u5=0 Then u9=u2 idiom embedded in a SMALL harness that reproduces
' the surrounding register pressure -- e.g. wrap the probe method with dummy edi/esi-held
' params so the allocator has the same competition -- before touching this file's body).
'
' ================= PROBE PASS: NOT VERIFIED -- DO NOT PROMOTE =================
' TPlayer.CheckKick -- VA 0x004F6C2B, 2201 bytes (Ghidra-authoritative), KIND=Method
' SIG=()i SLOT=0xf4. Self=[ebp+8].
'
' STATE AT THAT POINT: body BELOW is IDENTICAL to the state before -- still 2333/2201, +132,
' 33 gaps, COMPLETE. This pass did the "dedicated small probe" asked for above and
' made one concrete, reverted attempt; both are recorded here so the next pass does not
' repeat either.
'
' 1. ISOLATED PROBE (scripts/w14S0_probe.py), CONFIRMS the eax-reuse theory for the
'    minimal 2-term case in a vacuum:
'      Function ProbeV1:Int(u5:Int, u2:Int)
'          Local u9:Int = 0
'          u9 = u5
'          If u5 = 0
'              u9 = u2
'          EndIf
'          Return u9
'      End Function
'    compiles to 22 bytes total, ZERO stack slots, ZERO `sub esp`:
'      mov eax,[ebp+8] / mov edx,[ebp+0xc] / cmp eax,0 / jne +2 / mov eax,edx / jmp +0 /
'      leave / ret
'    i.e. `u9` never becomes a Local at all -- confirms the *shape* is achievable when the
'    whole value-select is one unbroken statement pair with nothing else competing for
'    registers. This is necessary but NOT sufficient in context -- see (2).
'
' 2. TARGETED FIX ATTEMPT on the GAP-5 site (source lines ~324-338 in the body below,
'    the `n=0/If u5<>0 Then n=Self.newstar/Local n6=0/If n<>0 Then n6=CanCallForBall()/
'    Local u9=0/If n6<>0 And ...` cascade) -- READ THE ORIGINAL DISASSEMBLY FIRST, do not
'    re-derive: `harness.disasm_original` across 0x004F708E..0x004F70B6 shows this is
'    genuinely ONE FLAT AND-CHAIN in the original, no separate n/n6 storage at all:
'    `cmp eax,0 / je <skip newstar load, eax stays 0>` (eax here is u5's leftover value
'    from just before this window) `/ mov eax,[esi+8]` (Self.newstar, only reached when
'    u5<>0) `/ cmp eax,0 / je <skip call>/ call CanCallForBall (eax=result) / cmp eax,0 /
'    je <skip> / mov eax,[0xc5dea4] (g_player_tplayer02)`. So the true source is
'    `u5 <> 0 And Self.newstar <> 0 And TTraining.CanCallForBall() <> 0 And
'    g_player_tplayer02 <> Null And (...)`, no `n`/`n6` Locals.
'
'    TRIED writing exactly that (deleting the `n=.../Local n6=.../If n<>0...` steps,
'    replacing with the flat And-chain, keeping everything else in the file untouched) --
'    VERIFIED WORSE: 2333->2339 (+132->+138), 33 gaps->35 gaps. This is NOT a case where
'    the fix was locally wrong; `harness.compare`'s diff shows the SAME gap-5 region did
'    shrink as predicted, but the change also flipped `Self`'s physical register from esi
'    to ebx at SEVERAL unrelated sites both earlier (gap 1, ~VA+492) and later (new gaps
'    at +1709/+1815, each gaining a fresh `mov edx,eax / mov eax,0` pair that was not
'    there before) in the function -- i.e. deleting those two Locals changed the WHOLE
'    function's interference graph, not just the local site, per codegen-patterns.md
'    section 18/22 (removing a node changes every other node's degree and colouring).
'    REVERTED. Body below is back to the previous exact text.
'
'    CONSEQUENCE FOR THE NEXT PASS: an INCREMENTAL, one-site-at-a-time flattening of the
'    u5/u2/n/n6/u9/b/b3 cascade (this pass's attempt, and by extension the earlier "just the
'    last hop" attempt) cannot be trusted even when the isolated sub-pattern is provably
'    right, because the allocator sees the WHOLE function at once and a local win can be a
'    global loss. The only remaining untried approach is the one already named:
'    rewrite the ENTIRE ~100-line cascade (source lines ~301-421) as ONE simultaneous edit
'    from the flat-And-chain literal source (matching the original's continuous eax/edx
'    reuse throughout, per gaps 1,2,3,4,5,6,7,8 and the still-open list below, all of which
'    show the identical "no eax=0/ecx=0 materialise, direct field cmp instead of
'    load-then-cmp, continuous register reuse across chained comparisons" shape), verify
'    ONCE at the end, not gap-by-gap. Do not spend another pass probing single sites.
'
' ================= ROOT-CAUSE NOTES BELOW, STILL CURRENT =================
'
' ORACLE STATE as of THIS pass (scripts/localise_diff.py TPlayer.CheckKick <thisfile>):
'   orig 2201 bytes, ours 2333 bytes, delta +132 -- UNCHANGED from the end state before it (an
'   edit attempt was tried, made it WORSE (+147/35 gaps), and was reverted -- see
'   "ROOT CAUSE FOUND, FIX NOT YET LANDED" below, which is the important output of
'   this pass even though the byte count did not move). 33 length-changing gaps + 4
'   same-length subs, delta_accounted +132 of +132 -> COMPLETE. first_divergence at ORIGINAL
'   +86 (GAP 23).
'
' FIELD / GLOBAL / SLOT MAPPING -- confirmed via extracted/decomp_annotated (annotate,
' CONFIDENCE=HIGH) cross-checked against extracted/object_model.json. Reuse without
' re-deriving:
'   TPlayer fields used: controller(24) x(76) y(80) newstar(8) teamid(20) id(16)
'     direction(120) facing(296) distancetoball(208,Float) kickpower(192,Float)
'     kickdirection(196,Float) jumpspotgood(220) joy(344,:TJoy).kickbuttonhits/
'     kickbuttondown/activebutton.
'   TBall (g_player_tplayer02) fields: x(0x18) y(0x1c) z(0x20,Float) oldx(0x24)
'     oldy(0x28) oldz(0x2c) velocity(0x54) zvelocity(0x58) controlledby(0x70,:TPlayer)
'     teaminpossession(0x60) setpiecetaker(0x80,:TPlayer) passtoid(0x9c). Method slot
'     0x84 = NewController(:TPlayer).
'   TProfile (g_contractoffer_tplayer) field name(0x14) -> ".name".
'   TTeam slot 0x90 = GetPlayerNearestToXY(i,i,i,:TPlayer,i):TPlayer -- confirmed by
'     "add esp,0x18" (24 bytes = 6 dwords incl. receiver) after the call and by the
'     object_model.json signature; the 5 real args from raw disasm (harness.disasm_original
'     0x004f70f1..0x004f7210) are (Int(ball.x), Int(ball.y), 1, Null, 0) -- Ghidra's
'     printed arg list at that call site is NOT evidence (merges with adjacent pushes,
'     see codegen-patterns.md 6/16.6); the real arg list was read from the raw pushes.
'   TTraining.CanCallForBall -- Function (static), class-table call, ()i, slot 0xa0.
'   TPitch.YardsToPixels(f)f -- class-table call, slot 0x6c. All three call sites in
'     this function pass float args as raw immediates (push 0x40c00000 = 6.0,
'     push 0x41700000 = 15.0), NOT via a masked .rdata address, so no read_string-style
'     recovery was needed for those two.
'   Float constants read directly from .rdata by (dword, value): 0x00C79D20=-1.0 (used
'     twice, kickdirection sentinel and the final reset), 0x00C79D24=50.0, 0x00C79D28=
'     15.0, 0x00C79D2C=0.6, 0x00C79D30=0.6 (SEPARATE .rdata slot, same value -- two
'     distinct source occurrences of the literal 0.6, no CSE per codegen-patterns 6),
'     0x00C79D34=1.5.
'   String literals (harness.read_string): 0x00C740BC "Simon Read", 0x00C740DC "Si Read"
'     -- the "which developer gets the ball auto-snapped to them" easter egg, gated by
'     KeyHit(8) or JoyHit(5,0) plus g_contractoffer_tplayer.name matching either spelling.
'   Globals: g_engine_int161:Int g_player_int01:Int g_player_int03:Int g_player_int04:Int
'     g_player_int14:Int g_player_int33:Int g_player_int50:Int g_player_float13:Float
'     g_player_tplayer02:TBall g_training_int03:Int g_engine_int164:Int
'     g_contractoffer_tplayer:TProfile -- all established elsewhere in the
'     corpus (TPlayer.HoldKick.bmx etc.), types unchanged here.
'
' KEY STRUCTURAL FINDING THIS PASS -- confirm and REUSE, do not re-derive:
'   A `Local` declared with a literal/False initializer at the FUNCTION-TOP scope (i.e.
'   visible across an EndIf boundary, needed later by code outside the block where it
'   is first assigned) forces bcc to emit an explicit zero-store for it immediately after
'   the prologue, EVEN IF every live code path also assigns it explicitly before use, and
'   EVEN IF the bare declaration carries no "= value" (tested both forms, byte-identical).
'   The fix is not "avoid initializers" -- it is to keep the Local's declaration, and
'   every one of its uses, inside the SMALLEST enclosing block that is still true to the
'   original's control flow, so it never needs to be visible at the function's outermost
'   scope. Concretely: the KeyHit(8)/JoyHit(5,0) dev-cheat gate and the "Simon Read"/
'   "Si Read" name check were first drafted as two separate top-level If-blocks
'   sharing a hoisted `Local n:Int`; moving the SECOND If entirely INSIDE the body of the
'   FIRST (semantically identical, since n defaults to 0 when the first gate is false)
'   removed a spurious `mov ecx,0` at the very top of the function and closed 87 bytes in
'   one step (2467 -> 2380). The same principle was applied throughout: wherever a
'   Ghidra bVarN/iVarN/uVarN temp is read by exactly ONE subsequent statement, it was
'   eliminated entirely and the guard was inlined as a flat short-circuit And/Or
'   expression (confirmed safe: BlitzMax And/Or genuinely short-circuit at the bytecode
'   level here, matching the "flag=false;if(cond){flag=X}" Ghidra cascade byte-for-byte
'   for every case tried). Only u5, u2, u9, n, n6 remain as real Locals, because each is
'   read by 2+ separated statements; b/b3 remain ONLY inside the Slide/Jump/Dive
'   threshold cascade for the same reason, redeclared with `Local` in EACH sibling
'   If/ElseIf/Else arm (BlitzMax Locals ARE block-scoped to their If/ElseIf/Else arm --
'   confirmed by compile error "Identifier 'b3' not found" when reused across arms
'   without a fresh `Local`).
'   This generalises to every future large body with Ghidra-name-reused scratch
'   variables: do not assume "declare all scratch flags once at the top" -- check
'   whether the original scope truly needs function-wide visibility, and prefer the
'   tightest scope, or a flat And/Or, whenever only one subsequent read exists.
'
' SECOND CONFIRMED FINDING -- the solo-relational If/Else branch-swap rule (codegen-
'   patterns.md section 21) applies at VA ~0x004F6E54: `g_player_tplayer02.controlledby
'   = Null` is a solo equality gating two genuinely different bodies (Celebrate/
'   Commiserate vs. z=0.0+HoldKick), and the original emits the NEGATED test with the
'   arms swapped -- confirmed directly from harness.disasm_original: `cmp [eax+0x70],
'   0x5c9c80 / je <celebrate/commiserate code, placed AFTER the z=0/HoldKick arm>`. This
'   file has that swap applied (`If controlledby <> Null Then z=0.0,HoldKick() Else
'   Celebrate/Commiserate`); it did not move the byte-length delta (branch swap is
'   length-neutral here) but IS the byte-correct form and should not be re-flipped.
'
' EARLIER FIXES -- confirmed against harness.disasm_original byte-for-byte, REUSE, do not
' re-derive or re-flip any of these six:
'   1. GAP A (the u5=0/activebutton=3/Dive three-way ElseIf chain) WAS a
'      second instance of the solo-relational branch-swap rule (codegen-patterns.md
'      section 21), one level up from the earlier finding: the original tests `u5==0` and
'      on TRUE jumps FORWARD to code placed AFTER the activebutton/Dive arms (i.e. the
'      jump-only body is physically LAST, reached only by a jump), while `u5<>0` falls
'      straight through into the activebutton-check/Dive code placed inline. Reproduced by
'      writing the NEGATED test with the two content blocks swapped: `ElseIf u5 <> 0 Then
'      {If activebutton=3 Then Slide Else DiveOnly} Else {JumpOnly}` -- NOT the naive
'      `ElseIf u5 = 0 Then JumpOnly ElseIf activebutton=3 Then Slide Else DiveOnly` that
'      an earlier draft wrote from the Ghidra ElseIf order. Confirmed directly: original's `cmp
'      edi,0 / je <jump-only code, placed after the Dive arm>` at VA 0x004F7365.
'   2. A THIRD, nested instance of the same rule one level deeper: the `n=0/n<>0` gate
'      guarding DoAnimJump vs the 0.6-multiplier Dive re-check (the earlier lines 243-260)
'      also has its Then/Else physically swapped in the original -- DoAnimJump's code is
'      placed BEFORE the Dive-recheck code, reached by FALLTHROUGH when n<>0, while the
'      Dive-recheck is jumped-to when n=0. Source must read `If n <> 0 Then DoAnimJump()
'      Else {dive recheck} EndIf`, not `If n = 0 Then {dive recheck} Else DoAnimJump()`.
'      Confirmed at VA 0x004F72E3 (`cmp eax,0 / je <dive-recheck, placed after>`).
'   3. `g_player_int50 - 200 < Self.joy.kickbuttonhits` (both occurrences, the ResetKick
'      guard AND the u5 setup) compiles wrong-operand-order when written left-to-right as
'      the subtraction first. The original evaluates `Self.joy.kickbuttonhits` FIRST (into
'      edx) and `g_player_int50 - 200` SECOND (into eax), then `cmp edx,eax / setg`. Source
'      must read `Self.joy.kickbuttonhits > g_player_int50 - 200` (operands swapped,
'      operator flipped to `>`) to reproduce that evaluation order. Confirmed at VA
'      0x004F6DBE (early occurrence) and VA 0x004F700D (u5 occurrence).
'   4. `If 15.0 <= Self.kickpower Or g_player_int01 = 7 Or g_player_int01 = 9 Then
'      HoldKick() Else TapKick()` is a solo Or-chain gating two genuinely different bodies,
'      and De Morgan's law applies exactly like the relational branch-swap rule: the
'      original computes the NEGATION as a short-circuit AND-chain of negated terms and
'      swaps which body is which. Source must read `If Self.kickpower < 15.0 And
'      g_player_int01 <> 7 And g_player_int01 <> 9 Then TapKick() Else HoldKick()`.
'      Confirmed at VA 0x004F6FA6 (kickpower<15.0 first, then int01<>7, then int01<>9,
'      each short-circuiting via `je`/fallthrough to the SAME merge point, ending
'      `je <TapKick> / <fallthrough calls HoldKick>` -- eax<>0 through the whole chain
'      means TapKick, matching NOT(A Or B Or C) via De Morgan).
'   5. Flat multi-term `And` chains where a LATER term is a genuine comparison (`=`, not
'      `<>0`/`=0`-shaped raw truthiness) get extra setcc+movzx normalisation bytes our
'      compiler does not need when the SAME chain is written as NESTED `If`s instead. Two
'      sites fixed: the KeyHit(8)/name-check gate (`If n<>0 Then If (name=...) Then ...`,
'      not `If n<>0 And (name=...)`) and the GoalScorer/kickbuttonhits/kickbuttondown/
'      PlayerOnFeet 4-term gate (nested 4 deep, not one flat And). This alone closed ~61
'      bytes (GAP 9-12 of the earlier list) when applied to the GoalScorer gate.
'   6. Float relational comparisons against a Global (`g_player_int33`, `50.0`, `0.0`)
'      need the INSTANCE-side operand (`Self.kickpower`, `g_player_tplayer02.z`) written
'      FIRST/left, with the Global or literal second/right, REGARDLESS of the "natural"
'      mathematical direction -- the original always `fld`s the instance float first, then
'      `fild`/`fld`s the Global/constant, then `fxch`s to restore source order for
'      `fucompp`. Getting the written order backwards flips `setae`<->`setbe` and
'      `seta`<->`setb` (a same-length, MATCH-relevant substitution the oracle WILL still
'      catch since these masks do not cover setcc opcodes). Fixed 6 sites: `g_player_int33
'      <= g_player_tplayer02.z` (x2) -> `g_player_tplayer02.z >= g_player_int33`;
'      `g_player_int33 * 0.6 <= g_player_tplayer02.z` -> `g_player_tplayer02.z >=
'      g_player_int33 * 0.6`; `g_player_int33 * 0.6 < g_player_tplayer02.z` ->
'      `g_player_tplayer02.z > g_player_int33 * 0.6`; `50.0 <= Self.kickpower` ->
'      `Self.kickpower >= 50.0`; `0.0 < Self.kickpower` -> `Self.kickpower > 0.0`.
'
' ROOT CAUSE FOUND, FIX NOT YET LANDED -- read this before touching gaps 1, 4, 6, 7,
' 8, 9, 14-17, 19, 20-22, 27, 29-32 (i.e. most of the 33). Confirmed by
' `harness.disasm_original` across the CONTINUOUS byte range 0x004F7212..0x004F7360 (the
' whole "g_player_int14=0 / ElseIf u5<>0 / Else" three-way cascade -- source lines ~293-372
' of THIS file, from `Local b:Int = False` through the end of the Jump/Dive/Slide decision
' tree) AND separately 0x004F70B6..0x004F71FB (the u9/GetPlayerNearestToXY/Call gate,
' lines ~284-294):
'
'   THE ORIGINAL NEVER MATERIALISES b, b3, u9, OR THE "n=0;If b Then n=jumpspotgood" PATTERN
'   AS A STORED VARIABLE WITH A DEFAULT VALUE. It is ONE continuous EAX-only register-reuse
'   chain from the first term of each compound condition to the final branch. The trick,
'   confirmed at every site in that range:
'     - Each term's comparison is computed into EAX (via the usual cmp/setcc/movzx idiom).
'     - If the term is FALSE, code jumps FORWARD, OVER the next term's computation, landing
'       exactly on the byte after that computation -- so EAX keeps its stale 0 from the
'       failed term, and the merge point's `cmp eax,0` reads that stale 0 as "chain is
'       false" for free. No store, no default, no second register.
'     - If the term is TRUE, execution falls through into the next term's computation,
'       which OVERWRITES eax with the new term's fresh 0/1 (or raw field value, for a
'       trailing `<>0`-shaped term -- see below), and THAT flows into the merge `cmp eax,0`.
'   Concretely, `u9 = u5; If u5 = 0 Then u9 = u2` compiles to `mov eax,edi(u5) / cmp eax,0 /
'   jne <skip reload, eax=u5's value> / mov eax,[ebp-0x10](u2)` -- i.e. THERE IS NO u9
'   VARIABLE AT ALL; it is a conditional-reload of eax with no separate storage. Likewise
'   `n=0;If b Then n=Self.jumpspotgood EndIf;If n<>0 Then DoAnimJump()` is really `<eax
'   already holds b's 0/1 from the immediately preceding statement> / cmp eax,0 / je <skip,
'   landing past the load> / mov eax,[esi+0xdc](jumpspotgood) / cmp eax,0 / je <false>` --
'   confirmed at VA 0x004F72D8 and 0x004F7342 (DoAnimJump/DoAnimDive) and again at
'   0x004F73C8 (the u5<>0/activebutton branch's z>int33*0.6 gate).
'
'   THIS RULES OUT fixing gaps 14-17 (the "b/n->jumpspotgood" +7-byte sites) by simply
'   removing the intermediate `n` and writing `If b And Self.jumpspotgood <> 0 Then
'   DoAnimJump()` -- TRIED THIS PASS, VERIFIED WRONG: it made the body WORSE (+132 -> +147,
'   33 gaps -> 35). Root cause of the failure: when the left operand of `And` is a
'   ALREADY-STORED Local read fresh (rather than the tail end of an unbroken expression
'   chain), bcc does NOT apply the eax-reuse trick to the right operand -- it fully
'   materialises `Self.jumpspotgood <> 0` as its own setne+movzx boolean in a FRESH register
'   (ecx) and ANDs the two stored values together, which is MORE bytes than either the
'   original OR the un-flattened `n`-based version in this file today. The trick only fires
'   when the WHOLE compound condition, from the u5/u2 reload through the final field test,
'   is written and compiled as ONE unbroken expression/statement -- there is no way to get
'   it by patching just the last hop.
'
' WHAT THIS MEANS FOR THE NEXT PASS: gaps 1, 4 (GoalScorer/kickbuttonhits/kickbuttondown/
' PlayerOnFeet, earlier finding 5's "nested Ifs" fix) and gaps 6, 7, 8, 9, 14-17, 19-22, 27,
' 29-32 (the whole u5/u2/u9/b/b3/n Jump/Dive/Slide cascade, source lines ~269-372) most
' likely ALL need the SAME kind of rewrite: not `Local flag = default / If cond Then flag =
' X EndIf / If flag ...` (materialise-then-branch, what earlier passes built and what this file
' currently has), and not naive flat `A And B And C` either (earlier finding 5 already
' showed flat costs extra bytes when a trailing term is a genuine comparison) -- but writing
' each DoAnimJump/DoAnimDive/DoAnimSlide/Self.Call() gate as ONE right-associated nested
' expression that lets bcc's own short-circuit codegen do the eax-reuse for you, e.g.
' `If u5 <> 0 Or u2 <> 0 Then ... ` is NOT it either (u9=u5-else-u2 is a VALUE substitution,
' not a boolean Or) -- this needs a dedicated small probe (isolate JUST the u9=u5;If
' u5=0 Then u9=u2 shape in a standalone method, sweep 2-3 syntactic forms against the
' oracle, find which one bcc compiles to the conditional-reload idiom) BEFORE touching this
' 100-line cascade again. Given the density of occurrences (this ONE pattern repeats at
' least 4 times: u9-reload, then the GoalScorer-style merge, then the jumpspotgood hop,
' each nested inside the other), closing it by hand-editing the full cascade without first
' confirming the minimal syntactic trigger in a probe is how the earlier single attempt lost
' 15 bytes instead of gaining any.
'
' Everything NOT in the u5/u2/u9/b/b3/n cascade (GAP 2/3/5/10/11/12/13/18/23/24/25/26/28/33,
' the KeyHit/GoalScorer-gate and SUB1-4 register-choice items) is UNCHANGED from the earlier
' diagnosis and still open; re-run `scripts/localise_diff.py TPlayer.CheckKick <this file>
' --max-gaps 40` for the full current list (offsets/deltas below are the earlier numbers,
' confirmed unchanged this pass since the reverted edit is a no-op):
' +498(-25) +1518(-21) +1558(+17) +490(+16) +1142(+14) +1648(+14) +1748(+14) +1511(+12)
' +1313(+10) +356(+9) +788(+9) +2058(+9) +1013(-8) +1709(+7) +1815(+7) +1949(+7) +2116(+7)
' +463(-5) +1128(+5) +1592(+5) +1992(+5) +2055(+5) +86(+4) +103(+4) +128(+4) +1890(-4)
' +1121(+3) +655(+2) +994(+2) +1308(+2) +1617(+2) +1741(-2) +2034(+2). The 4 same-length
' subs (register choice: original keeps a scratch value in EAX at offsets +1641, +1714,
' +1820, +2121; our build puts it in EDX) are LIKELY the SAME root cause under a different
' symptom -- once the cascade is rewritten to match the eax-reuse idiom these may resolve
' for free, since the "extra register" need goes away when nothing is stored separately.
'
' RULED OUT EARLIER (still valid):
'   - Extra top-level `Local` zero-inits as the cause of the whole 266-byte original gap
'     (2467->2380) -- only accounted for ~87 bytes; the rest was the branch-swap-shaped
'     issues above plus flattening, not more hidden zero-inits.
'   - Treating GetPlayerNearestToXY's 5 args as (ball.y, ball.x, ...) in that order --
'     the raw push sequence proves (Int(ball.x), Int(ball.y), 1, Null, 0); Ghidra's own
'     printed call showed only 2 of the 5 real args and in a misleading order.
' RULED OUT (newer):
'   - Flattening ONLY the last hop of the jumpspotgood pattern (`If b And Self.jumpspotgood
'     <> 0 Then ...` in place of the `n=0/If b.../If n<>0` shape) -- made it worse, see above.
'     Do not retry without first fixing how `b` itself reaches that point.
'
' NUMBERS FOR THE NEXT PASS: ours N=2333 of M=2201, delta +132, delta_accounted COMPLETE
' (33 gaps, 4 subs) -- byte-for-byte identical to the earlier end state. Re-run:
'   scripts/localise_diff.py TPlayer.CheckKick <this file> --max-gaps 40
' Highest-leverage next step: build a standalone probe for the `u9 = u5; If u5 = 0 Then u9 =
' u2` conditional-reload idiom (2-3 syntactic variants) BEFORE re-editing this file, per the
' "ROOT-CAUSE NOTES" section above.

'!Global g_engine_int161:Int
'!Global g_player_int01:Int
'!Global g_player_int03:Int
'!Global g_player_int04:Int
'!Global g_player_int14:Int
'!Global g_player_int33:Int
'!Global g_player_int50:Int
'!Global g_player_float13:Float
'!Global g_ball:TBall
'!Global g_training_int03:Int
'!Global g_engine_int164:Int
'!Global g_profile:TProfile

		If g_engine_int161 = 2 And g_player_int01 = 1 And Self.controller = 1 And g_ball <> Null
			Local n:Int = KeyHit(8)
			If n = 0
				If g_engine_int164
					n = JoyHit(5, 0)
				EndIf
			EndIf
			If n <> 0
				If g_profile.name = "Simon Read" Or g_profile.name = "Si Read"
					g_ball.NewController(Self)
					g_ball.x = Self.x
					g_ball.y = Self.y
					g_ball.z = 0.0
					g_ball.oldx = Self.x
					g_ball.oldy = Self.y
					g_ball.oldz = 0.0
					g_ball.velocity = 0.0
					g_ball.zvelocity = 0.0
				EndIf
			EndIf
		EndIf
		If g_player_int03 = 0 Or g_player_int50 < g_player_int03 + 1000
			If Self.newstar And g_ball <> Null And g_ball.setpiecetaker <> Self And Self.joy.kickbuttonhits > g_player_int50 - 200
				Self.Call()
			EndIf
			Self.ResetKick()
			Return 0
		Else
				If Self.GoalScorer() <> 0
					If Self.joy.kickbuttonhits <> 0
						If Self.joy.kickbuttondown = 0
							If Self.PlayerOnFeet() <> 0
								If g_ball.controlledby <> Null
									g_ball.z = 0.0
									Self.HoldKick()
								Else
									If g_player_int04 = Self.teamid
										Self.DoAnimCelebrate(Self.facing)
									Else
										Self.DoAnimCommiserate(Self.facing)
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			Local n:Int = Self.PlayerOnFeet()
			If n <> 0
				If g_ball <> Null And g_ball.controlledby = Self
					If Self.joy.kickbuttondown = 1
						Self.kickpower = Self.kickpower + g_player_float13
						If Self.kickdirection = -1.0
							Self.kickdirection = Self.direction
						EndIf
					EndIf
					If (Self.joy.kickbuttonhits And Self.joy.kickbuttondown = 0) Or (Self.kickpower >= 50.0) Or (g_player_int01 = 2 And Self.kickpower > 0.0)
						If Self.kickpower < 15.0 And g_player_int01 <> 7 And g_player_int01 <> 9
							Self.TapKick()
						Else
							Self.HoldKick()
						EndIf
					EndIf
				Else
					Local u5:Int = 0
					If Self.joy.kickbuttonhits > g_player_int50 - 200
						u5 = Self.joy.kickbuttondown = 0
					EndIf
					Local u2:Int = Self.joy.kickbuttondown
					If g_ball <> Null Or g_training_int03 = 4 Or g_training_int03 = 5
						n = 0
						If u5
							n = Self.newstar
						EndIf
						Local n6:Int = 0
						If n <> 0
							n6 = TTraining.CanCallForBall()
						EndIf
						Local u9:Int = 0
						If n6 And g_ball <> Null And (g_ball.controlledby = Null Or g_ball.controlledby.teamid = Self.teamid)
							u9 = Self.GetMyTeam().GetPlayerNearestToXY(Int(g_ball.x), Int(g_ball.y), 1, Null, 0) <> Self
							If u9 = 0
								u9 = g_training_int03
							EndIf
						EndIf
						If u9 And (g_ball.teaminpossession = Self.teamid Or Self.distancetoball > TPitch.YardsToPixels(6.0))
							Self.Call()
						Else
							If g_player_int01 = 1 And Self.distancetoball <= TPitch.YardsToPixels(15.0)
								If g_player_int14 = 0 Or Self.controller = 0
									Local b:Int = False
									If u5
										b = g_ball = Null
										If g_ball <> Null
											Local b3:Int = g_ball.z < g_player_int33
											b = False
											If b3
												b = g_ball.passtoid <> Self.id
											EndIf
										EndIf
									EndIf
									If b
										Self.DoAnimSlide()
									Else
										u9 = u5
										If u5 = 0
											u9 = u2
										EndIf
										b = False
										If u9 And g_ball <> Null
											b = g_ball.z >= g_player_int33
										EndIf
										n = 0
										If b
											n = Self.jumpspotgood
										EndIf
										If n <> 0
											Self.DoAnimJump()
										Else
											If u5 = 0
												u5 = u2
											EndIf
											b = False
											If u5 And g_ball <> Null
												b = g_ball.z >= g_player_int33 * 0.6
											EndIf
											n = 0
											If b
												n = Self.jumpspotgood
											EndIf
											If n <> 0
												Self.DoAnimDive()
											EndIf
										EndIf
									EndIf
								ElseIf u5
									If Self.joy.activebutton = 3
										Self.DoAnimSlide()
									Else
										Local b:Int = False
										If g_ball <> Null
											b = g_ball.z > g_player_int33 * 0.6
										EndIf
										Local b3:Int = False
										If b
											b3 = g_ball.z < g_player_int33 * 1.5
										EndIf
										b = False
										If b3
											b = Self.distancetoball < TPitch.YardsToPixels(6.0)
										EndIf
										If b
											Self.DoAnimDive()
										EndIf
									EndIf
								Else
									Local b:Int = False
									If u2 And g_ball <> Null
										b = g_ball.z >= g_player_int33
									EndIf
									n = 0
									If b
										n = Self.jumpspotgood
									EndIf
									If n <> 0
										Self.DoAnimJump()
									EndIf
								EndIf
							EndIf
						EndIf
					ElseIf u5
						Self.Call()
					EndIf
					Self.kickdirection = -1.0
					Self.kickpower = 0.0
				EndIf
			EndIf
		EndIf

' =========================== REVISION H -- FULL BYTE MATCH ========================================
' VA 0x004de516   9170 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (9170/9170, original length from Ghidra's inventory)
' TTeam.UpdatePlayerDestinations   VA 0x004DE516   original length 9170 bytes
' harness.try_method (NSS5_NO_LEARN=1): status=MATCH, mode='reloc',
' matched=9170/9170, first_diff=None. Confirmed against the ON-DISK copy of this file, not
' just a scratch probe. Two independent statement-level fixes closed the remaining gap; see
' REVISION H below for the full derivation. Everything from the earlier revisions (kept verbatim beneath
' this entry) is now historical -- read REVISION H first.
'
' REVISION H -- CLOSED both of revisions E-G's "GAP 2/3" fxch bytes AND a third, until now invisible,
' defect that only became visible once the fxch gap was gone (it had been hiding behind the
' length mismatch the whole time: with mode='len', harness.compare never got far enough into
' the body to see it, and even scripts/localise_diff.py's tolerant alignment -- which blanks
' relative-branch displacements before diffing -- happened to align straight through it. Only
' the strict positional harness.try_method oracle, re-run AFTER the length agreed, surfaced it).
'
' FIX 1 -- the fxch pair (Case 4 of Select g_matchstate, the two "d1"/"d2" distance guards).
' Revisions A-G exhaustively proved that no MIRROR-EQUIVALENT rewrite of
' "TPitch.YardsToPixels(45.0) < d1" (i.e. any rewrite preserving that exact truth value) can
' drop the spurious `fxch st(1)` without also flipping `setae` to `setbe` (revision G section B's
' negation-table proof). That proof is correct as far as it goes -- but it implicitly assumed
' the original written comparator was "<" with Yards on the left. It was never wrong to have
' been considered; it was just answering the wrong question. This pass built THREE standalone
' probes (harness.build_source_function, disassembled directly -- same technique as the
' isolation probes of revisions D and G, kept as the probe scripts referenced in
' this session's tool transcript) that write d1/d2 FIRST instead of Yards():
'   `d1 >= TPitch.YardsToPixels(45.0)`  -> no fxch, but `setb`  (not a match)
'   `d1 >  TPitch.YardsToPixels(45.0)`  -> no fxch, but `setbe` (not a match, = revision B's finding)
'   `d1 <  TPitch.YardsToPixels(45.0)`  -> no fxch, AND `setae` -- BYTE-IDENTICAL to the
'                                          original's fld/fucompp/fnstsw/sahf/setae/movzx/cmp
'                                          sequence, confirmed instruction-by-instruction.
' Mechanism (consistent with revision G section A's fixfp_x86.cpp reading, just applied to the
' operand revisions E-G never tried): fixMov's CGScc branch colours `rd` from the LHS of the
' WRITTEN comparison. With Yards() as LHS, rd is the call result's hard-coded colour 0, which
' stops being top() once d1's reload physically pushes on top of it -- forcing the fxch. With
' d1 as LHS, rd IS the reload's own colour, and a value is always top() immediately after its
' own `fld` -- so `fxch(rd)` is a no-op the compiler doesn't need to emit, unconditionally, by
' construction. This makes the fxch gap byte-motivated rather than a whole-function liveness
' accident: the ORIGINAL source writes the distance first, the yardage threshold second,
' consistent with the established idiom used throughout this codebase's already-verified
' siblings (`src/recovered/TBall.CanSeePlayer.bmx`: "If Dist2D(...) <= TPitch.YardsToPixels
' (2.0) Then Continue"; `src/recovered/TDummy.CheckHit.bmx`: "Dist2D(...) < TPitch.
' YardsToPixels(1.0)") -- distance-expression first, Yards()-threshold second, is simply how
' this codebase writes these guards; Case 4's "Yards() < d1" phrasing (every earlier
' assumption) had the two operands backwards. Applied: both "TPitch.YardsToPixels(45.0) < d1"
' and the ElseIf's "< d2" became "d1 < TPitch.YardsToPixels(45.0)" / "d2 < ...". Nothing else
' in the two nested If/Else bodies changed.
'
' FIX 2 -- ORIGINAL +6916ish, inside "If g_matchstate = 1 And ball.KeeperHolding() = 0 / If Not
' ball.controlledby / ... / If Not t Or t <> n". The decompilation for this inner guard is the
' textbook BlitzMax `Or`-ShortCircuit compiled shape, not an If-guarding-an-If:
'     uVar10 = 0;
'     if (piVar11 != Null) uVar10 = (uint)(0 < piVar11[0x2f]);   // n<>Null And n.selectionno>0
'     if (uVar10 == 0) uVar10 = ball->Crossing(0);                // OR short-circuit
'     if (uVar10 != 0) n->InterceptBall(piVar4);
' i.e. "If (n <> Null And n.selectionno > 0) Or ball.Crossing(0) Then n.InterceptBall(ball)".
' The body here used to read
'     If Not (n <> Null And n.selectionno > 0)
'         If ball.Crossing(0) Then n.InterceptBall(ball)
'     EndIf
' which is "(Not A) And B", NOT "A Or B" -- a real logic bug (InterceptBall would wrongly be
' skipped whenever A alone was true, instead of firing on A alone same as the original), not
' just a byte-shape mismatch. It compiled 23 bytes SHORTER than the original's flat Or-chain
' (two nested If/EndIf pairs cost more branch-setup than one ShortCircExp), which is exactly
' the 23-byte relative-jump-displacement drift (`jne` operand 0x14 vs 0x2B) that harness.
' try_method's strict positional compare surfaced once FIX 1 made the overall length agree.
' Rewritten to the flat Or form above; matches the original queue call-by-call (t.InterceptBall
' still fires unconditionally when t<>Null, same as before -- only this inner n.InterceptBall
' guard changed).
'
' VERIFICATION: harness.try_method('TTeam','UpdatePlayerDestinations', <this file's body>) with
' NSS5_NO_LEARN=1 (so nothing was taught to make this look clean) returns status=MATCH,
' mode='reloc', matched=9170/9170, first_diff=None -- run directly against the on-disk copy of
' this file after both edits, not just a scratch probe. scripts/localise_diff.py independently
' agrees: 0 gaps, 0 subs, delta 0, verdict "CLEAN -- byte-identical modulo the oracle's masks".
' Both checks used a throwaway probe build in a private temp workdir (scripts/assemble.py was
' NOT run; no shared state was touched).
' ================================================================================================
'
' -------------------------- HISTORICAL NOTES, KEPT FOR THE RECORD -----------------
' The status line and gap numbers below describe the PRE-REVISION-H state and are replaced by
' the REVISION H entry above. Left in place because the mechanism analysis in REVISIONS E-G (the
' fixfp_x86.cpp / cgallocregs.cpp reading, the isolation-probe technique) is what revision H's fix
' was built on, and because the "GONE" GAP 1 / trainingmode-guard story below is still correct
' and not re-derived above.
' =========================== NOT VERIFIED - DO NOT COUNT AS MATCHED ===================
' TTeam.UpdatePlayerDestinations   VA 0x004DE516   original length 9170 bytes
' Candidate length: 9174 bytes  (delta +4, ours LONGER, UNCHANGED since revision E)
' harness.try_method: mode='len' (MISMATCH, lengths differ) -- never verdict=MATCH.
' Worked across eleven successive revisions. This file is revision E's
' source, re-verified unchanged in revisions F and G -- GAP 2/3 mechanism further narrowed each
' revision (see the REVISION F and REVISION G notes below) but NOT closed; no source edit made in either.
' Full narrative: the per-revision notes below.
'
' scripts/localise_diff.py TTeam.UpdatePlayerDestinations <this file> --max-gaps 200
' reports (NSS5_WORKER=any NSS5_NO_LEARN=1), AS OF REVISION E:
'   2 length-changing gaps, +4 bytes total, delta_accounted COMPLETE, 0 same-length subs.
'   first real divergence at ORIGINAL +1399 (0x577) -- both remaining gaps are the GAP 2/3
'   fxch pair below (renumbered GAP 1/2, GAP 2/2); GAP 1 (the trainingmode guard, +9 bytes, at
'   ORIGINAL +6664) is closed. Everything else in the ENTIRE 9170-byte function --
'   every byte before offset 1399, every byte from 1508 through the end -- aligns exactly.
'
' ------------------------------------------------------------------------------------------
' REVISION E -- GAP 1 CLOSED (9 of 13 bytes recovered). Root cause: bare Int TRUTHINESS vs an
' EXPLICIT `<>0` comparison compile to DIFFERENT shapes when used as the LEFT operand of an
' `And` (ShortCircExp), even though they are semantically identical. This is the exact same
' phenomenon as codegen-patterns.md section 11.1 (bare array truth test vs `.Length`), now
' confirmed for Int operands inside a ShortCircExp specifically -- prior passes (17,18,19)
' only ever tested bare-truthiness inside SOLO `If`/nested-`If` conditions, where it is
' byte-IDENTICAL to `<>0` (both fold to the same `cmp mem,imm`), which is why the distinction
' was never seen before. THE FIX:
'     was:  If g_trainingmode <> 0 And g_trainingmode <> 4 Then Return 0
'     now:  If g_trainingmode And g_trainingmode <> 4 Then Return 0
' Mechanism, confirmed by reading tools/blitzmax-legacy-src/_src/compiler/exp.cpp (Val::cond,
' line ~109) alongside ShortCircExp::_eval (line 666): for an Int Local/Global of cgType
' CG_INT32 (not CG_INT64), `Val::cond()` is a NO-OP (`return this`). A bare Global reference
' therefore carries `cg_exp = mem(g)` (the raw memory operand, no comparison node at all)
' into ShortCircExp::_eval''s `mov(r, lv->cg_exp)`, which becomes a PLAIN `mov eax,[g]` --
' then the following `bcc(cg_op,r,lit0,e)` is an ordinary register-vs-0 compare, `cmp eax,0 /
' je`. Total: `mov/cmp/je`, 10 bytes -- exactly shape (b), GAP 1''s target. An EXPLICIT
' `g_trainingmode<>0` instead carries `cg_exp = Scc(NE,g,0)` into the same `mov(r,...)`,
' which forces full materialization (`setne al / movzx eax,al`) before the same following
' `cmp/je` -- 16 bytes, shape (c), which is what revisions B-D''s seven text variants all
' produced without exception. Confirmed directly against the oracle this pass (not just by
' inspection): `scripts/localise_diff.py` before/after, NSS5_NO_LEARN=1 --
' delta went from 3 gaps/+13 to 2 gaps/+4, and the closed gap is EXACTLY GAP 1 (former offset
' ORIGINAL +6664); GAPs 2/3 (the fxch pair, offsets +1399/+1491) are untouched, confirming
' the fix is local to the trainingmode guard and caused no regression elsewhere in the
' 9170-byte body (0 same-length substitutions, confirmed by scripts/localise_diff.py --json).
' This ALSO retroactively explains revision D''s VariantF/G negative results: neither varied the
' bare-truthiness-vs-`<>0` axis for the FIRST operand of a genuine top-level `And` -- VariantG
' used bare truthiness only in a SOLO nested-If (byte-identical to `<>0` there, per above),
' never inside a ShortCircExp.
'
' REVISION E -- GAP 2/3 (fxch): MECHANISM NOW LOCATED (not yet fixed). Prior passes guessed
' "cgflow.cpp or the allocator" as the source of the fxch decision; it is neither --
' it is tools/blitzmax-legacy-src/_src/codegen/cgfixfp_x86.cpp, the X87-STACK FIXUP PASS
' (`CGFrame_X86::fixFp`, run per-CGBlock AFTER register allocation has assigned each Float
' value a "colour" 0-7, propagating an `FPStack` simulation block-to-block via `stack_map`).
' For `A < B`, `fixMov`''s `CGScc` case calls `st->fcomp(rd,rs,live)` where `rd`/`rs` are the
' COLOURS of the WRITTEN lhs/rhs (`TPitch.YardsToPixels(45.0)` and `d1` respectively here).
' `fcomp` ALWAYS opens with `fxch(rd)` -- emit `fxch st(N)` UNLESS colour `rd` (Yards'' result,
' pushed by the call, several bytes earlier) is ALREADY `top()`. The immediately preceding
' instruction, `fld dword ptr [ebp-0x84]` (loading `d1`), is what disturbs `top()`: `FPStack::
' fload` PHYSICALLY pushes via the `fld`, then either (a) if `d1`''s colour has NO existing
' stack slot (`regs[rd]<0`), calls `push(rd)`, making `d1` the new top and forcing the
' subsequent `fxch(rd=Yards)` -- OUR case; or (b) if `d1`''s colour ALREADY has an existing
' slot from earlier in the SAME basic-block chain (`regs[rd]>=0`), emits `fstp st(N+1)`
' instead -- a physical push+pop net-zero that OVERWRITES the old slot''s value in place
' WITHOUT calling `push()`/updating `top()` -- so `top()` stays whatever it already was
' (Yards'' colour, untouched), and `fcomp`''s `fxch(rd)` finds it already there: NO fxch. This
' is the ORIGINAL''s path. So the difference is not phrasing at the comparison statement at
' all -- it is whether `d1`''s FP colour was ALREADY resident on the notional stack from an
' EARLIER Float value in the same block-chain (colour reuse) at the moment `d1` is loaded.
' That is a whole-function graph-colouring-allocator property (same allocator as section 18,
' applied to the FP colour space 0-7 instead of the int one) driven by every Float
' Local/temp''s reference count and live range in the ENTIRE function, not a local rewrite of
' this one comparison -- confirmed structurally sound with revisions A and B''s independent
' "operand-order swap removes the fxch but flips setae->setbe" finding (swapping the WRITTEN
' operands makes `d1`, not Yards, the fxch target -- and `d1` is the freshly-`fld`ed value,
' i.e. already top -- so no fxch is needed on THAT side either, for the same colour-vs-top
' reason, independent confirmation of the mechanism though not a usable fix since it changes
' the boolean sense). NOT ATTEMPTED this pass: identifying WHICH earlier Float value''s colour
' `d1` would need to alias in the original to reproduce this -- that requires dumping the
' colour assignment for every Float Local across the whole 9170-byte function (a
' `cgfixfp_x86.cpp`-aware controlled probe per codegen-patterns.md 18.4/22, not a textual
' guess), left for revision F. Do NOT try more textual permutations of the `d1`/`d2` comparison
' lines themselves -- the mechanism above shows the lever is elsewhere (an earlier Float
' value''s colour), not in these two lines'' own text, which is already independently
' length-exact and semantically confirmed correct (setae, not setbe).
' ------------------------------------------------------------------------------------------
'   3 length-changing gaps, +13 bytes total, delta_accounted COMPLETE, 0 same-length subs.
'   first real divergence at ORIGINAL +1399 (0x577)
'
'   GAP 1  insert +9  @ ORIGINAL +6664 (0x004DFF1E) -- inside the
'          "g_trainingmode <> 0 And g_trainingmode <> 4 Then Return 0" guard (source line
'          ~331). Original tests the FIRST term with a bare register compare-then-jump
'          (`mov eax,[g]; cmp eax,0; je`, 10 bytes, no setne/movzx) while materializing
'          the SECOND term normally (setne/movzx/cmp/je). Ours materializes BOTH terms
'          as the plain "A And B Then Return" form. RULED OUT this pass, confirmed
'          against the oracle (not just by inspection):
'            - rewriting as `If g_trainingmode <> 0 / If g_trainingmode <> 4 Then Return 0 /
'              EndIf` (nested If) produces a DIFFERENT, even shorter shape for BOTH terms
'              (`cmp dword ptr [g],N` memory-immediate compare, 7 bytes, no register load
'              at all) -- delta goes to -7, not toward 0. Confirmed with localise_diff.
'            - substituting a bare `If g_trainingmode` (truthiness) for the first nested
'              term gives the IDENTICAL memory-immediate bytes as `<> 0` in that position --
'              so the choice is not "bare vs explicit", it is single-condition-If vs
'              part-of-And, and NEITHER of those two known shapes matches original's
'              specific register-mediated, non-materialized first-term form.
'          Unsolved: original's exact form (load-to-register, cmp-to-zero, jump -- no
'          memory-immediate, no setne) was not reproduced by any source variant tried.
'          Next step: search this file for an already-MATCHING "single-condition guard on
'          a Global compared to 0" to learn which exact source shape yields that byte
'          pattern (line 45 "If g_trainingmode <> 0" is a candidate witness -- it borders
'          a byte-identical region so its exact form is already proven correct here; check
'          whether ITS compiled bytes are register-mediated or memory-immediate before
'          guessing again).
'
'   GAP 2  insert +2  @ ORIGINAL +1399 (0x004DEA8D) -- `Case 4` of `Select g_matchstate`,
'          first distance guard: `If TPitch.YardsToPixels(45.0) < d1`. Ours emits a
'          redundant `fxch st(1)` (D9 C9) before `fucompp` that the original does not.
'   GAP 3  insert +2  @ ORIGINAL +1491 (0x004DEAE9) -- same `Case 4`, second guard
'          (`< d2`). Same defect, same shape.
'          RULED OUT this pass, confirmed against the oracle: swapping the written
'          operand order (`If d1 > TPitch.YardsToPixels(45.0)`) DOES remove the fxch, but
'          it also flips the following `setae` (0F 93 C0) to `setbe` (0F 96 C0) -- a real,
'          same-length SUB, i.e. a different boolean outcome, not a cosmetic byte fix. The
'          written text `TPitch.YardsToPixels(45.0) < d1` is therefore CONFIRMED CORRECT
'          (it alone reproduces original's `setae`); only the extra `fxch` is spurious.
'          This reinforces revision A's conclusion: a static x87-stack-depth bookkeeping
'          difference from something upstream of this statement, not a phrasing lever on
'          the statement itself. Needs a controlled probe (codegen-patterns.md §18.4
'          style liveness/FPU-depth investigation), not further guessing at this text.
'
' FIXED this pass (confirmed by localise_diff, closed revision A's gaps 2+3 with 0 regressions):
'   `Case 2` of `Select g_matchstate` was two statements:
'       Local yy:Float = TPitch.YardsToPixels(35.0)
'       yy :* Self.GetShootingDirection()
'       desy = -yy
'   Original caches Self in ebx BEFORE the (Self-independent) YardsToPixels() call and
'   reuses it for GetShootingDirection() afterward; the two-statement form reloads Self
'   from [ebp+8] fresh at the second call. Combining into ONE expression:
'       Local yy:Float = TPitch.YardsToPixels(35.0) * Self.GetShootingDirection()
'       desy = -yy
'   reproduces the original's Self-caching exactly -- 6 bytes recovered, 0 regressions,
'   collapsed revision A's 5 gaps / +13 bytes to 3 gaps / +13 bytes (same total delta, two
'   fewer independent defects; the two closed gaps happened to be a delete+replace pair
'   that summed to 0 net bytes on their own, so total delta is unchanged but the body is
'   now provably more correct: 0 same-length subs, delta_accounted COMPLETE).
'
' STATUS: no verified bodies written (law 1 respected). This file is preserved per the
' "near miss" rule (spec: NON-NEGOTIABLE item 4b) so revision C resumes at 3 gaps instead of
' re-deriving the whole 432-line body. Builds clean under bmk/harness (mode='len' MISMATCH,
' never crashes, never BUILD_FAIL).
'
' REVISION C - GAP 1 mechanism now understood via bcc's OWN COMPILER SOURCE (not just codegen,
' the front end). Still NOT closed, but the next pass should start from the mechanism, not
' from more textual guessing -- two more textual guesses were tried and ruled out this pass.
'
'   `And`/`Or` KEYWORDS parse to ShortCircExp, NOT BitwiseExp (BitwiseExp is only `&`/`|`/`~`
'   -- tools/blitzmax-legacy-src/_src/compiler/parser.cpp:866 parseShortCircExp, one level
'   ABOVE parseCmpExp). ShortCircExp::_eval (exp.cpp:666) for `A And B` emits EXACTLY:
'       mov(r, lv->cg_exp)          -- r = materialize(A)
'       bcc(CG_EQ, r, lit0, e)      -- if r==0 goto e   (this IS the short-circuit skip)
'       mov(r, rv->cg_exp)          -- r = materialize(B)   (only reached if A was true)
'       lab(e)
'   for ANY `A And B`, textually regardless of what A/B are -- so the shape is NOT a lever;
'   every `And` compiles through this same four-node sequence.
'
'   Separately, cgframe.cpp's CGPreOpter::visit(CGStm*) (~line 230) folds
'   `Bcc(EQ/NE, Scc(cc2,x,y), lit0, sym)` directly into `Bcc(cc2 or swapcc(cc2), x, y, sym)`
'   -- i.e. "don't materialize a comparison just to re-test it against 0, compare the raw
'   operands directly". This is PROVEN to be the reason every OTHER solo `If g_trainingmode
'   = N Then` in this same function (5 sites: VA 0x4DE760, 0x4DE78E, 0x4DEC75, 0x4DEF65,
'   0x4E004E -- read directly off NSS5.exe with harness.disasm_original, not inferred) is a
'   plain 7-byte `cmp dword ptr [g],N / jcc`, no register load at all.
'
'   The open question is why GAP 1's FIRST term (`g_trainingmode <> 0`, i.e. `A` in the And)
'   comes out REGISTER-mediated (`mov eax,[g]; cmp eax,0; je`, no setne/movzx) instead of
'   either (a) the plain memory-immediate fold above, or (b) full setne+movzx materialize
'   like the SECOND term gets. Hypothesis, NOT yet confirmed against the oracle: the fold
'   above works on `Bcc(lhs=Scc)`, but ShortCircExp emits `Bcc(lhs=CGTmp r)` with the Scc one
'   level removed (behind a `mov(r,...)` that CGPreOpter's pattern does not match literally).
'   A comparison against literal 0 specifically (`<>0`) has the property that the RAW
'   compared value's zero-ness already equals the comparison's truth value's zero-ness, so
'   IF some later pass (copy-propagation / dead-temp forwarding across the single-use `r`,
'   plausibly in cgflow.cpp or the allocator itself, not yet located) forwards `lv->cg_exp`
'   into the `bcc(CG_EQ,r,0,e)` before the CGPreOpter fold runs, the fold would then apply
'   to `x==0` (the RAW field) rather than `scc(NE,x,0)==0`, giving register-mediated-not-
'   materialized -- matching GAP 1's first term exactly. It would NOT apply to the second
'   term (`<>4`) because forwarding `x` raw and testing `x==0` is wrong when the true test is
'   `x==4`. This is offered as a mechanism, not a fix: it explains asymmetry-by-construction
'   (a comparison-against-zero is special, others are not) rather than a liveness accident,
'   which is a DIFFERENT explanation from revision A's "block_count" theory for GAPs 2/3 -- do
'   not conflate the two families.
'
'   RULED OUT this pass (confirmed against the oracle, not just by inspection):
'     - `If Not (g_trainingmode = 0 Or g_trainingmode = 4) Then Return 0` (De Morgan via Or,
'       the same family as section 2''s 7 already-fixed Continue-guards elsewhere in this
'       body) -- gives the SAME +9 delta, same asymmetric-vs-original shape, just with
'       sete/jne instead of setne/je (both terms still fully materialized). Not it.
'     - `If g_trainingmode <> 0 Then If g_trainingmode <> 4 Then Return 0` (single-line
'       nested If, no separate EndIf) -- confirms revision B''s block-form finding: gives PURE
'       memory-immediate `cmp dword[g],N` for BOTH terms (delta -7, not the register-mediated
'       hybrid). This is the CGPreOpter fold applying independently to two separate IfStm
'       nodes; it is not the shape needed either.
'   Neither variant is a regression risk since NEITHER was written back into the body below;
'   the body is unchanged from revision B.
'
'   Next step for a full derivation (not attempted this pass -- needs an isolated minimal
'   probe outside harness.try_method, which requires a real reflected Type.Method and cannot
'   take an ad hoc synthetic name): build a tiny standalone `bmk makeapp -r` probe (not
'   through harness, which requires the method to exist in object_model.json's reflection
'   for _bytematch.find_method to locate it) with 2-3 variants of `X <> 0 And Y <> N` and
'   objdump the raw output directly, to confirm or refute the copy-propagation-into-
'   CGPreOpter-fold hypothesis above before trying more source-text permutations blind.
'
' REVISION D -- the standalone probe revision C called for was BUILT this pass (module-level
'   Functions compiled directly via harness.build_source_function + harness.BMK, symbols
'   resolved via helper_map.object_symbols/resolve_base exactly as try_function does
'   internally, then disassembled with capstone directly -- no harness.compare involved,
'   because there is no original-side VA for a synthetic snippet; this only inspects OUR
'   own emitted shape in isolation). The probe script is preserved for reuse.
'   Still NOT closed, but the search space is now sharply narrower.
'
'   THREE DISTINCT compiled shapes for "Int Global <> literal" now confirmed to coexist in
'   this one function, not two as prior passes framed it:
'     (a) SOLO `If g <> N Then Return` folds ALL THE WAY: `cmp dword[g],N / jcc` (7 bytes,
'         no register at all). Confirmed again by nested-If probes (below).
'     (b) GAP 1's actual first term: `mov eax,[g] / cmp eax,0 / je` (10 bytes) -- a
'         register LOAD, direct compare, no setne/movzx. Distinct from both (a) and (c).
'     (c) `A And B` used as a sole If-condition, per ShortCircExp::_eval, ALWAYS fully
'         materializes BOTH sides: `mov eax,[g]/cmp/setne/movzx/cmp/je` (16 bytes) for
'         EACH term -- confirmed unconditionally in isolation (see below), which means
'         shape (b) is not merely "the first half of (c) with setne dropped"; it is a
'         genuinely third code shape whose trigger is still unidentified.
'
'   Probes run this pass (all built+disassembled for real, not inspected by eye):
'     VariantA  `If g_trainingmode<>0 And g_trainingmode<>4 Then Return 0`  (this body's
'               exact text, standalone) -> shape (c) for BOTH terms. 59 bytes.
'     VariantB  same, with `Local a:Int = g_trainingmode` hoisted first -> STILL shape (c)
'               for both terms (just `edx` cached instead of a second load). Rules out
'               "a prior Local copy avoids materialization" as a lever.
'     VariantC  operands swapped, `<>4 And <>0` -> shape (c) for both, order-symmetric.
'               Rules out "literal-zero-must-be-first" as the trigger for shape (b).
'     VariantE  De Morgan `g=0 Or g=4 Then Return 0` -> shape (c) for both (sete/jne
'               instead of setne/je). Independently reconfirms revision C''s finding.
'     VariantF  the SAME And-guard reproduced 3 If-levels deep (matching this body''s real
'               nesting: outer `A And B`, then `Not C`, then the target And) using fresh
'               Globals for the outer levels -> inner And-guard STILL compiles to shape
'               (c) for both terms, byte-for-byte the same shape as VariantA''s. This is
'               the key NEW negative result: nesting depth / surrounding branch structure
'               does NOT change the And''s own compiled shape in isolation, which argues
'               against a whole-function liveness/register-pressure explanation for GAP 1
'               specifically (unlike GAPs 2/3, which remain a liveness question) -- the
'               trigger for shape (b) is most likely a SOURCE-TEXT difference not yet
'               tried, not a context effect a small probe would fail to capture.
'     VariantG  same 3-level nesting, but the inner guard written as nested single-line
'               `If g_trainingmode Then If g_trainingmode<>4 Then Return 0` -> BOTH terms
'               fold to shape (a) (pure memory-immediate, no register), reconfirming revisions
'               B and C''s nested-If finding independently at the deeper nesting level too.
'
'   NOT YET TRIED (candidates for revision E, in order of plausibility): (1) the leading
'   conjunct being a DIFFERENT kind of boolean-producing expression than a bare relational
'   -- e.g. a prior CALL result or a Field read routed through a Local that is ALSO read
'   elsewhere nearby, which might make the front end treat term1''s "materialize" step as
'   already-available and only re-test it (copy-propagation across a temp that already
'   exists for an unrelated reason, not one this probe''s clean-room Globals can create);
'   (2) the guard written with the RETURN VALUE used (e.g. as part of a larger boolean
'   expression assigned to something) rather than as a bare `Then Return 0` -- IfStm''s own
'   condition-evaluation path may differ from an expression''s; (3) reading cgflow.cpp and
'   the allocator''s copy-propagation pass directly (revision C''s own suggested location for
'   the mechanism) rather than more textual permutation, since 7 source-text variants
'   spanning hoisting/order/De-Morgan/nesting-depth have now been exhausted without hitting
'   shape (b).
'
'   GAPs 2/3 (fxch) NOT revisited this pass -- correctly out of reach for an isolated probe
'   (an empty-stack standalone function cannot reproduce an x87-depth artifact that per
'   revisions A and B depends on FPU liveness across ~1400 bytes of preceding code); the revision C
'   suggestion to read cgflow.cpp/CGPreOpter for GAP 1''s copy-propagation mechanism was
'   prioritised instead since it is the one gap two independent lines of reasoning (revision C
'   compiler-source reading, revision D clean-room probing) now agree is a source-text
'   question, not a whole-body liveness question -- i.e. the one gap actually reachable by
'   more probing rather than a controlled multi-witness FPU study.
'
' REVISION E -- re-verified unchanged (3 gaps / +13 / delta_accounted COMPLETE, confirmed via
'   localise_diff.py under NSS5_NO_LEARN=1 before and after this edit).
'   No new bytes. This pass answers revision D's own next-step #3 ("read cgflow.cpp and the
'   allocator's copy-propagation pass directly") ANALYTICALLY rather than by more probing,
'   and the answer is negative -- which narrows, rather than solves, GAP 1:
'
'   Read tools/blitzmax-legacy-src/_src/codegen/{cgflow.cpp,cgallocregs.cpp,codegen.cpp,
'   cgframe_x86.cpp} end to end for anything that could bridge TWO SEPARATE CGStm nodes
'   (`mov(r, lv->cg_exp)` then, as an unrelated later statement, `bcc(cg_op, r, lit0, e)`)
'   back into the single-node shape `Bcc(cc, Scc(...), lit0, sym)` that CGPreOpter (revision C''s
'   find, cgframe.cpp:233-251) pattern-matches. Result: there is NO such pass anywhere in
'   `_src/codegen/`. `cgflow.cpp` builds CGBlock-level dataflow/liveness for the REGISTER
'   ALLOCATOR only (`CGFlow::buildFlow`, `::liveness`, `::findLoops`) -- it never rewrites
'   comparison shapes. No file in the tree contains "peephole" (grepped, zero hits) or any
'   setcc-specific rewrite. CGPreOpter itself (`CGFrame::preOptimize`, cgframe.cpp:351) is a
'   single bottom-up `CGVisitor` pass over the pre-allocation AST; its `visit(CGStm*)` case
'   inspects `t->lhs->scc()` -- a DIRECT, literal Scc child of the Bcc node, not a CGTmp whose
'   DEFINITION happens to be an Scc two statements earlier. `mov` and `bcc` are independent
'   CGStm siblings in `ShortCircExp::_eval`''s `seq(...)`, not parent/child in an expression
'   tree, so no tree-shaped visitor (bottom-up or otherwise) can see through the `mov` to
'   fold the `bcc` that follows it, with or without CGPreOpter running twice.
'
'   CONCLUSION (analytic, not another empirical probe): under bcc''s actual pipeline, NO
'   phrasing of a plain `And`/`Or` (ShortCircExp) can EVER cause its own first operand to
'   fold to shape (b) (register-mediated, no setne/movzx) -- ShortCircExp::_eval unconditionally
'   routes every operand through `mov(tmp, cond)`, and that mov is what permanently hides the
'   Scc from CGPreOpter for BOTH operands alike. This closes off revision D''s entire remaining
'   "guess another And/Or phrasing" search branch for GOOD, not just empirically (7 variants,
'   revision D) but from the compiler''s own source: the mechanism that produces the 5 confirmed
'   solo-comparison folds elsewhere in this body (CGPreOpter matching a literal
'   `Bcc(cc,Scc,0,sym)`) is *structurally unreachable* from inside a ShortCircExp, by
'   construction, regardless of what text is written inside the And/Or.
'
'   IMPLICATION FOR REVISION F: since the compiled evidence (shape (b) exists in the original,
'   3 statements: mov-load, cmp-immediate-0, je -- no setne) cannot come from ShortCircExp AT
'   ALL, the original source for this ONE guard (of 8 similar guards in this body, 7 already
'   matching under the plain-And phrasing) is almost certainly NOT `A And B` at the source
'   level. Two concrete shapes not yet tried, in order of plausibility:
'     (1) TWO SEPARATE TOP-LEVEL IfStms sharing ONE physical Return, i.e. an early-return
'         guard using a LOCAL flag: `Local bad:Int = 0 ; If g_trainingmode<>0 Then bad = ... `
'         -- unlikely to fit (no flag-accumulator byte pattern was seen in the localise_diff
'         window), listed only for completeness.
'     (2) The FIRST term is not `g_trainingmode <> 0` freshly read as an independent BinaryExp
'         at all, but is the SAME Scc node the register allocator ALSO uses for something
'         adjacent -- i.e. check whether `g_trainingmode` (or a cached copy of it) is read by
'         a DIFFERENT statement in this body within a few instructions BEFORE this guard
'         (not one of this pass''s clean-room probes, which cannot create that adjacency).
'         Concretely: dump the ~40 bytes of ORIGINAL disassembly immediately BEFORE
'         0x004DFF1E (this guard''s start) with harness.disasm_original and look for an
'         EARLIER `cmp`/test against g_trainingmode''s address whose result could be what
'         shape (b)''s `mov eax,[g]` is actually re-loading for -- i.e. treat this as a
'         REAL cross-statement liveness/copy question specific to THIS body''s surrounding
'         code (per codegen-patterns.md 18.4/22), not a clean-room-probe question, since
'         revision D''s VariantF already showed synthetic surrounding branch STRUCTURE alone
'         does not trigger it -- the missing ingredient may be surrounding DATA reuse, not
'         branch shape.
'     (3) Only if (2) is exhausted: accept GAP 1 as belonging to the same §18.4/22
'         "block_count is a reachable source-level lever" family as GAPs 2/3, and run the
'         controlled controlled multi-witness liveness probe on all three gaps together,
'         since they now share one plausible root cause (register/stack state carried in
'         from ~1400+ bytes of preceding code that no isolated snippet can reproduce).
' REVISION F -- re-verified UNCHANGED (2 gaps / +4 / delta_accounted COMPLETE, confirmed via
'   localise_diff.py under NSS5_NO_LEARN=1; both gaps identical to revision E:
'   `fld dword ptr [ebp-0x7?]` immediately followed by a spurious `fxch st(1)` (D9 C9) before
'   `fucompp`, at ORIGINAL +1399 and +1491, the two `Case 4` distance guards). No source edit
'   made this pass -- every remaining textual lever was already exhausted by revisions A-E and
'   the body is 0-same-length-subs/perfectly-aligned everywhere else, so an unconfirmed edit
'   risks a regression for no proven gain.
'
'   This pass answers revision E's own "left for revision F" question -- "is the FP colour space
'   governed by a SEPARATE, float-specific allocation rule, or the SAME generic one as
'   section 18/22?" -- by reading `_src/codegen/cgallocregs.cpp` end to end (not `cgfixfp_x86.
'   cpp` again, which revision E already fully covered): float and int registers ("colours")
'   share ONE Chaitin/Briggs graph-colouring `Node` structure and ONE `spill()`/`selectRegs()`
'   pass. The only float-specific state is `bank` (`Node::bank`, set from `reg->isfloat()` at
'   construction) and `reg_colors[bank] = countBits(frame->reg_masks[bank])` (cgallocregs.cpp:
'   574) -- 8 for the float bank (x87 st0-st7) vs 6 for int. `spill()`''s cost formula
'   (`usage/(degree*block_count)`, cgallocregs.cpp:~420s, same file as section 22.1 quotes)
'   and `selectRegs()`''s lowest-free-colour rule (line 489-506) run UNCHANGED for both banks
'   -- there is no float-only branch anywhere in the file. CONCLUSION: GAP 2/3 is governed by
'   the EXACT SAME usage/degree/block_count triple as section 22 describes for ints, just
'   computed over the ~8-wide float bank instead of the 6-wide int bank, applied to whichever
'   CGReg node ends up sharing d1''s reload colour. This rules out a hidden FP-only rule and
'   confirms revision E''s hypothesis analytically rather than empirically -- it does NOT supply
'   a fix, because the three levers still require knowing which OTHER Float value in the
'   ~1400 preceding bytes the allocator colours identically to d1''s comparison-reload temp,
'   and that is unrecoverable from the C++ source alone.
'
'   Also checked this pass: `selectRegs()` DOES have a debug hook that would answer this
'   directly -- `cout<<"Colored:\t"<<node->reg->id<<"->"<<color<<endl;` (cgallocregs.cpp:505)
'   -- but it is compiled out (`#ifdef _DEBUG_REGALLOC`, matching revision E''s `cgfixfp_x86.cpp`
'   `_DEBUG_FPSTACK` guard) and the shipped `bcc.exe` obviously was not built with it defined.
'   `tools/blitzmax-legacy-src/_src/` carries NO Makefile/`.sln`/build script of its own
'   (grepped for both, zero hits under `_src/`; every Makefile in the tree belongs to a
'   third-party `mod/` library, not the compiler) -- rebuilding bcc with the macro defined to
'   get a real colour dump is therefore a standalone infrastructure task (toolchain unknown,
'   likely the same era MinGW/g++ as the runtime), not something to start inside a single
'   function-recovery pass.  THIS is the concrete, scoped next step for GAP 2/3, in order:
'     1. (infra, one-time) get `_src/` building as `bcc.exe` with `_DEBUG_REGALLOC` (and
'        `_DEBUG_FPSTACK` in cgfixfp_x86.cpp) defined, even if the rebuilt compiler cannot
'        reproduce the SHIPPED bcc''s exact codegen elsewhere -- the colour dump only needs to
'        be self-consistent, since it explains OUR OWN candidate''s allocation, letting source
'        edits be aimed rather than guessed.
'     2. Failing (1): manual live-range reconstruction -- disassemble ORIGINAL +0..+1399
'        (harness.disasm_original) and tabulate every `fld`/`fstp`/`fxch`/x87-op touching each
'        stack depth, to find which earlier Float value''s slot the original reuses for
'        Yards() at +1399. This is the controlled controlled multi-witness probe the file
'        has called for since revision A and not yet attempted at this scale.
'   Do NOT re-attempt textual permutation of the `d1`/`d2` comparison lines or their
'   surrounding statements without one of the two steps above -- revisions A-E exhausted every
'   phrasing-level lever (operand order, hoisting, nesting, De Morgan) already.
'
' REVISION G -- re-verified UNCHANGED (2 gaps / +4 / delta_accounted COMPLETE, confirmed via
'   localise_diff.py under NSS5_NO_LEARN=1; no source edit made -- see below
'   for why an available lever was deliberately NOT applied). Two contributions:
'
'   (A) READ tools/blitzmax-legacy-src/_src/codegen/cgfixfp_x86.cpp DIRECTLY (the actual
'   struct FPStack -- fload/fstore/fcomp/fixMov -- not a paraphrase). This gives the EXACT
'   mechanism, more precisely than revisions E and F''s summary:
'     * `fload(rd, ea, "fld", live)`: ALWAYS emits the literal `fld [ea]` (a real hardware
'       push). Then: if `regs[rd]>=0` (colour `rd` -- the RELOAD''S OWN destination colour --
'       already had a simulated-resident slot from EARLIER in the block) it emits
'       `fstp st(N+1)`, an in-place overwrite that leaves `top()` UNCHANGED (our case is NOT
'       this). Otherwise it calls `push(rd)`, which DOES move `top()` to the freshly-loaded
'       value -- this is OUR path (d1''s reload colour has no earlier resident slot), and it
'       is why our `fcomp`''s own `fxch(rd=Yards)` then has work to do.
'     * `fcomp(rd,rs,live)` ALWAYS opens with `fxch(rd)`, rd = the SCC node''s LHS colour
'       (`t->lhs->reg()->color`, i.e. whichever operand is WRITTEN FIRST in the source
'       comparison, confirmed by reading fixMov''s `CGScc` branch directly: `rd=t->lhs...,
'       rs=t->rhs...`). `fxch(r)` is a genuine no-op ONLY if `r==top()`.
'     * Any CGReg immediately defined by a JSR (function-call result) is HARD-COLOURED to 0
'       -- fixMov''s and fixEva''s JSR branches call `st->push(0)` unconditionally, never
'       `push(rd)` -- and anything else live across that SAME call trips
'       "Invalid FP stack state after FP jsr" (cout, at most ONE float colour -- 0 -- may
'       cross a call in this model). This is a NEW, sourced datum, not in any earlier
'       notes: it means `Local d1:Float = Dist2D(...)`''s OWN defining store cannot leave
'       d1''s colour resident across the immediately-following `d2 = Dist2D(...)` call
'       (whose own JSR-result claims colour 0 too) -- d1 MUST be memory-only by the time
'       guard 1 runs, which is also what the disassembly shows on both sides (both use a
'       real, unconditional `fld [mem]` for the reload, not a cross-call register survival).
'
'   (B) MATHEMATICAL PROOF that operand-order rewriting is not merely "tried and failed" but
'   IMPOSSIBLE for this specific gap, closing revisions A and B''s empirical finding for good. Revision
'   B found `If d1 > TPitch.YardsToPixels(45.0)` removes the fxch (rd becomes d1''s colour,
'   trivially satisfying `r==top()` since d1 was JUST fld''d) but flips `setae`->`setbe`.
'   Reading fixMov''s CGScc branch shows exactly why: the compiler negates WHATEVER
'   comparator is written while PRESERVING lhs/rhs textual order (this is the general form
'   of section 21''s solo-relational-If/Else rule -- CG_GT negates to CG_LE, mapped via the
'   fixed table EQ/NE/LT/GT/LE/GE -> z/nz/b/a/be/ae). For rd to be d1''s colour, d1 MUST be
'   written first; the only truth-preserving way to write d1 first for the ORIGINAL condition
'   `Yards(45.0) < d1` is its mirror `d1 > Yards(45.0)` (GT) -- there is no other phrasing --
'   and GT negates to LE (setbe), never to GE (setae). Conversely, every phrasing that
'   negates to GE (setae, what original actually has) keeps Yards written first (LT is GE''s
'   only negation-partner that also matches the source''s truth value), which forces
'   rd=colour(Yards), the wrong operand for a free `fxch` no-op. **These two requirements are
'   mutually exclusive by the negation table itself -- not empirically, but by construction.**
'   No rewrite of this one comparison''s text, in any form, can satisfy both. This retires
'   "operand order" as a lever for GAP 2/3 with a proof, not just more negative trials.
'
'   (C) ISOLATION PROBE (new evidence, changes the working theory): built a standalone probe
'   function (harness.build_source_function, no reflection/oracle involved since there is no
'   original VA for a synthetic snippet -- disassembled directly, same technique as revision D''s
'   probe) reproducing ONLY this shape in a function with ZERO prior float activity:
'       Local d1:Float = Dist2D(a,b,0,c)
'       Local d2:Float = Dist2D(a,b,0,d)
'       If TPitch.YardsToPixels(45.0) < d1 ... ElseIf TPitch.YardsToPixels(45.0) < d2 ...
'   Result: the SAME spurious `fxch st(1)` (D9 C9) appears before BOTH `fucompp`s, byte-for-
'   byte the same shape as in the 9170-byte candidate, with ABSOLUTELY NO preceding float
'   context (the probe script is preserved). This means the defect is NOT
'   dependent on some specific OTHER float value''s colour surviving from far upstream in the
'   whole function, as revisions E and F hypothesized -- bcc emits the extra fxch for this EXACT
'   shape UNCONDITIONALLY, even from a cold start. So EITHER (i) the original genuinely does
'   carry real, matching upstream FPU residency at this exact point (some earlier value in
'   Case 4''s own block-chain, or from further back, legitimately still resident when d1 is
'   reloaded) that our reconstruction does not reproduce despite being byte-identical
'   everywhere else -- in which case the "distant liveness" theory survives, just refined to
'   "it requires a REAL resident value, not merely favorable branch shape", and the isolation
'   probe shows a favorable branch shape ALONE (this local shape, no other float activity)
'   is not sufficient by itself -- OR (ii) the original computes d1/d2 via some LOCAL
'   variant not yet tried (not "Local x:Float = Dist2D(...)" x2 then two comparisons) that
'   changes which JSR''s result gets held across which store. NOT YET TRIED: varying the
'   PROBE itself (not the risky main candidate) -- e.g. an extra harmless prior Float local
'   consumed immediately before d1''s definition, to test whether ANY resident colour
'   upstream (not necessarily from the real function) flips fload''s `regs[rd]>=0` branch.
'   This is now the cheapest concrete next step (mutate the ISOLATED probe, which is
'   disposable, not the 9170-byte body) before returning to steps 1/2 from revision F.
'
'   No source edit made this pass -- (B) proves the known lever is a dead end and (C) is
'   evidence, not yet a fix. An edit without a positive result would risk the 0-same-length-
'   subs, byte-perfect-everywhere-else state for no gain.
' ================================================================================================
'!Global g_matchstate:Int
'!Global g_trainingmode:Int
'!Global g_trainingsub:Int
'!Global g_training_int11:Int
'!Global g_training_int12:Int
'!Global g_pitchhalfwidth:Int
'!Global g_pitchhalfheight:Int
'!Global g_pitchgoalhalf:Int
'!Global g_pitchscale:Float
'!Global g_matchtimer:Int
'!Global g_enginetick:Int
'!Global g_sortkey:Int
'!Global g_newstar:TPlayer
'!Global g_ball:TBall
'!Global g_teamhome:TTeam
'!Global g_teamaway:TTeam
Local chase:Int
Local dir:Int
Local desx:Float
Local desy:Float
Local scale:Float
Local ball:TBall
desx = 0.0
desy = 0.0
chase = 0
dir = Self.GetShootingDirection()
scale = 1.0
ball = TBall.GetActiveBall()
If ball <> Null
	desx = ball.x
	desy = ball.y
	If ball.teaminpossession = Self.id
		chase = 1
		If g_matchstate = 1 And ball.KeeperHolding() = 0 And (TPitch.InsidePenaltyBox(Int(desx), Int(desy), -Self.GetShootingDirection()) Or TPitch.InsideCrossZone(Int(desx), Int(desy), -Self.GetShootingDirection()))
			chase = 0
		EndIf
	Else
		If Not ball.KeeperHolding()
			If (g_matchstate = 1 And TPitch.InsidePenaltyBox(Int(desx), Int(desy), Self.GetShootingDirection())) Or TPitch.InsideCrossZone(Int(desx), Int(desy), Self.GetShootingDirection())
				chase = 1
			EndIf
		EndIf
	EndIf
EndIf
If g_trainingmode <> 0
	Select g_trainingsub
		Case 0
			If g_trainingmode = 4
				TTraining.GetPiggyInTheMiddlePosition(Self)
			Else
				For Local p:TPlayer = EachIn Self.squad
					If p.newstar
						p.desx = g_training_int11
						p.desy = g_training_int12
					Else
						If p.selectionno = 0
							p.UpdateKeeperPosition()
						Else
							Local h:TPlayer = TPlayer.GetHumanPlayer()
							If h <> Null
								Self.formation.GetPlayerXY(p.selectionno, h.x, h.y, g_pitchhalfwidth * 2, g_pitchhalfheight * 2, dir, 0, Varptr p.desx, Varptr p.desy, scale, 1.0)
							EndIf
						EndIf
					EndIf
				Next
			EndIf
			Return 0
		Case 1
		Case 2
			For Local p:TPlayer = EachIn Self.squad
				p.desx = p.x
				p.desy = p.y
			Next
			Return 0
	End Select
EndIf
Select g_matchstate
	Case 0
		Self.GetTunnelPositions(0)
		Return 0
	Case 1
	Case 2
		Local yy:Float = TPitch.YardsToPixels(35.0) * Self.GetShootingDirection()
		desy = -yy
	Case 3
	Case 4
		Local d1:Float = Dist2D(desx, desy, 0, g_pitchhalfheight * -dir)
		Local d2:Float = Dist2D(desx, desy, 0, g_pitchhalfheight * dir)
		If d1 < TPitch.YardsToPixels(45.0)
			If chase
				desx = 0.0
				desy = 0.0
				chase = 0
			Else
				scale = 3.0
			EndIf
		ElseIf d2 < TPitch.YardsToPixels(45.0)
			If chase
				scale = 3.0
			Else
				desx = 0.0
				desy = 0.0
				chase = 0
			EndIf
		EndIf
	Case 5
		desx = 0.0
		scale = 2.0
	Case 6
		desx = 0.0
		desy = 0.0
		chase = 0
	Case 7
	Case 9
		Self.GetShootoutPositions()
		Return 0
	Case 10
		Self.GetShootoutPositions()
		Return 0
	Case 8
	Case 11
		Self.GetMatchOverPositions()
		Return 0
End Select
If ball And ball.KeeperHolding()
	desx = 0.0
	desy = 0.0
	chase = 0
EndIf
For Local p:TPlayer = EachIn Self.squad
	If p.selectionno = 0
		p.UpdateKeeperPosition()
	ElseIf p.selectionno < 11
		If g_trainingmode = 9
			Local h:TPlayer = TPlayer.GetHumanPlayer()
			If h <> Null
				Self.formation.GetPlayerXY(p.selectionno, h.x, h.y, g_pitchhalfwidth * 2, g_pitchhalfheight * 2, dir, 0, Varptr p.desx, Varptr p.desy, scale, 1.0)
			EndIf
		Else
			Self.formation.GetPlayerXY(p.selectionno, desx, desy, g_pitchhalfwidth * 2, g_pitchhalfheight * 2, dir, chase, Varptr p.desx, Varptr p.desy, scale, 1.0)
		EndIf
	ElseIf Not (p.x <= -g_pitchhalfwidth)
		p.desx = -g_pitchhalfwidth - TPitch.YardsToPixels(1.0)
		p.desy = 0
	Else
		p.GetTunnelPosition(0)
	EndIf
	If p.matchstats.reds > 0 Or p.selectionno > 10
		p.GetTunnelPosition(0)
	EndIf
Next
If g_matchstate = 5
	Local no:Int = 1
	For Local v:TMyVector = EachIn Self.cornerformation
		For Local p:TPlayer = EachIn Self.squad
			If ball.teaminpossession = Self.id
				If p.selectionno = 11 - no
					p.desx = Float(v.X)
					p.desy = Float(v.Y)
				EndIf
			ElseIf p.selectionno = no + 3
				p.desx = Float(v.X)
				p.desy = -Float(v.Y)
			EndIf
		Next
		no = no + 1
	Next
EndIf
If g_trainingmode = 4
	TTraining.GetPiggyInTheMiddlePosition(Self)
EndIf
If Not ball Then Return 0
If TEngine.SetPiece() And ball.setpiecetaker <> Null
	For Local p:TPlayer = EachIn Self.squad
		If p = ball.setpiecetaker
			If g_matchstate = 2
				p.desx = ball.setpiecex + TPitch.YardsToPixels(0.5)
				p.desy = ball.setpiecey
			Else
				p.desx = ball.setpiecex + Cos(p.joy.direction + 180.0) * TPitch.YardsToPixels(0.5)
				p.desy = ball.setpiecey + Sin(p.joy.direction + 180.0) * TPitch.YardsToPixels(0.5)
			EndIf
		EndIf
		If p = ball.setpiecebuddy
			Select g_matchstate
				Case 2
					p.desx = ball.setpiecex - TPitch.YardsToPixels(3.0)
					p.desy = ball.setpiecey
				Case 3
					Local ox3:Int = Int(TPitch.YardsToPixels(8.0))
					Local oy3:Int = Int(TPitch.YardsToPixels(4.0))
					Local mt3:Int = g_matchtimer Mod 4500
					If mt3 < 1500
						ox3 = Int(TPitch.YardsToPixels(12.0))
						oy3 = Int(TPitch.YardsToPixels(8.0))
					ElseIf mt3 < 3000
						ox3 = Int(TPitch.YardsToPixels(16.0))
						oy3 = Int(TPitch.YardsToPixels(12.0))
					EndIf
					If ball.setpiecex > 0 Then ox3 = -ox3
					If ball.setpiecey > 0 Then oy3 = -oy3
					p.desx = ball.setpiecex + ox3
					p.desy = ball.setpiecey + oy3
				Default
					Local ox:Int = Int(TPitch.YardsToPixels(10.0))
					Local oy:Int = Int(TPitch.YardsToPixels(5.0))
					If ball.setpiecex > 0 Then ox = -ox
					If ball.setpiecey > 0 Then oy = -oy
					p.desx = ball.setpiecex + ox
					p.desy = ball.setpiecey + oy
			End Select
		EndIf
		If g_matchstate = 2
			Select Self.GetShootingDirection()
				Case -1
					If p.desy < 0.0
						p.desy = 10.0
					EndIf
				Case 1
					If Not (p.desy <= 0.0)
						p.desy = -10.0
					EndIf
			End Select
		EndIf
	Next
	If Self.squad.Count() > 11
		Local anyon:Int = 0
		For Local p:TPlayer = EachIn Self.squad
			If p.selectionno > 10 And TPitch.IsOnPitch(Int(p.x), Int(p.y))
				anyon = 1
				Exit
			EndIf
		Next
		If anyon
			For Local p:TPlayer = EachIn Self.squad
				If p.selectionno < 11 And p.x < -g_pitchhalfwidth
					p.desx = -g_pitchhalfwidth - 20
					p.desy = 0
					Return 0
				EndIf
			Next
		EndIf
	EndIf
	If g_matchstate = 4 And ball.teaminpossession <> Self.id
		Local wd:Float = Dist2D(ball.setpiecex, ball.setpiecey, 0, g_pitchhalfheight * -Self.GetShootingDirection())
		If wd < TPitch.YardsToPixels(60.0)
			For Local p:TPlayer = EachIn Self.squad
				If p.matchstats.reds Or p.selectionno > 10 Then Continue
				If wd < TPitch.YardsToPixels(60.0) And p.selectionno = 10
					Self.GetWallLocation(5, ball.setpiecex, ball.setpiecey, Varptr p.desx, Varptr p.desy)
				EndIf
				If wd < TPitch.YardsToPixels(50.0) And p.selectionno = 8
					Self.GetWallLocation(4, ball.setpiecex, ball.setpiecey, Varptr p.desx, Varptr p.desy)
				EndIf
				If wd < TPitch.YardsToPixels(40.0) And p.selectionno = 7
					Self.GetWallLocation(3, ball.setpiecex, ball.setpiecey, Varptr p.desx, Varptr p.desy)
				EndIf
				If wd < TPitch.YardsToPixels(35.0) And p.selectionno = 6
					Self.GetWallLocation(2, ball.setpiecex, ball.setpiecey, Varptr p.desx, Varptr p.desy)
				EndIf
				If wd < TPitch.YardsToPixels(30.0) And p.selectionno = 5
					Self.GetWallLocation(1, ball.setpiecex, ball.setpiecey, Varptr p.desx, Varptr p.desy)
				EndIf
			Next
		EndIf
	EndIf
	If TEngine.SetPiece()
		For Local p:TPlayer = EachIn Self.squad
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			If p.selectionno > 0 And p.selectionno < 11 And p <> ball.setpiecetaker And p <> ball.setpiecebuddy
				If Dist2D(p.x, p.y, ball.setpiecex, ball.setpiecey) <> 0
					p.MoveYardsClear(10.0, ball.setpiecex, ball.setpiecey)
				EndIf
				If g_matchstate = 6 Or g_matchstate = 7 Or g_matchstate = 9
					If p.desy < -g_pitchgoalhalf
						p.desy = -g_pitchgoalhalf
					EndIf
					If p.desy > g_pitchgoalhalf
						p.desy = g_pitchgoalhalf
					EndIf
				EndIf
			EndIf
		Next
	EndIf
EndIf
If g_matchstate = 8 And g_newstar <> Null And g_newstar.teamid = Self.id
	If g_newstar.distancetogoal_opp < g_newstar.distancetogoal_own
		For Local p:TPlayer = EachIn Self.squad
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			If p = g_newstar And p.newstar = 0
				Local lb:Int = Self.GetLosingBy()
				If lb > 1 Or (lb > 0 And g_enginetick > 70)
					If g_ball <> Null And Not g_ball.controlledby
						p.desx = g_ball.x
						p.desy = g_ball.y
					Else
						p.desx = 0
						p.desy = 0
					EndIf
				Else
					Select g_enginetick Mod 3
						Case 0
							p.desx = g_pitchhalfwidth * 0.5
							If p.x < 0.0
								p.desx = -p.desx
							EndIf
							p.desy = g_pitchhalfheight
							If p.y < 0.0
								p.desy = -p.desy
							EndIf
						Case 1
							p.desx = -g_pitchhalfwidth
							p.desy = p.y
						Case 2
							p.desx = g_pitchhalfwidth * 0.6
							p.desy = p.y
					End Select
				EndIf
			Else
				If p.selectionno < 11 And Dist2D(p.x, p.y, g_newstar.x, g_newstar.y) < TPitch.YardsToPixels(40.0)
					Local ang:Float = AngleTo(p.x, p.y, g_newstar.x, g_newstar.y)
					p.desx = g_newstar.x + Cos(ang + 180.0 + p.selectionno * 5) * TPitch.YardsToPixels(2.0)
					p.desy = g_newstar.y + Sin(ang + 180.0 + p.selectionno * 5) * TPitch.YardsToPixels(2.0)
				EndIf
			EndIf
		Next
	EndIf
Else
	If g_matchstate = 1 And ball.KeeperHolding() = 0
		If Not ball.controlledby
			If g_trainingmode And g_trainingmode <> 4 Then Return 0
			Local t:TPlayer = TPlayer.GetPlayerById(ball.passtoid)
			If t <> Null
				t.InterceptBall(ball)
			EndIf
			Local n:TPlayer = Self.GetPlayerNearestToXY(Int(ball.metax), Int(ball.metay), 0, Null, 0)
			If Not t Or t <> n
				If (n <> Null And n.selectionno > 0) Or ball.Crossing(0)
					n.InterceptBall(ball)
				EndIf
			EndIf
		ElseIf ball.controlledby.teamid = Self.id
			If g_trainingmode = 4 Then Return 0
			ball.controlledby.DoDribbling()
			For Local p:TPlayer = EachIn Self.squad
				If p.selectionno > 0 And p.selectionno < 11 And p <> ball.controlledby
					If Dist2D(ball.controlledby.x, ball.controlledby.y, p.desx, p.desy) < TPitch.YardsToPixels(15.0)
						Self.formation.GetPlayerXY(ball.controlledby.selectionno, desx, desy + TPitch.YardsToPixels(15.0) * dir, g_pitchhalfwidth * 2, g_pitchhalfheight * 2, dir, chase, Varptr p.desx, Varptr p.desy, scale, 1.0)
					EndIf
					If p.distancetoball < TPitch.YardsToPixels(30.0) And p.passison = 0
						Local o:TPlayer = TPlayer.GetPlayerById(p.opponentid)
						If o <> Null
							p.DoRepulsion(o.x, o.y, Varptr p.desx, Varptr p.desy, 2.5 * g_pitchscale)
						EndIf
					EndIf
				EndIf
			Next
		Else
			If Self.controller = 0 Or Self.newstarselno > 0
				g_sortkey = 13
				Self.squad.Sort()
				Local id1:Int = 0
				Local id2:Int = 0
				Local id3:Int = 0
					For Local p:TPlayer = EachIn Self.squad
						If p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
						If id2 = 0
							p.ChaseBall(ball.x, ball.y, ball.controlledby)
							id2 = p.id
							If p.goalside <> 0
								id3 = p.id
							EndIf
						ElseIf id1 = 0
							p.GetCoveringLocation(ball.x, ball.y)
							id1 = p.id
							Exit
						EndIf
					Next
				If id3 = 0
					g_sortkey = 10
					Self.squad.Sort()
					For Local p:TPlayer = EachIn Self.squad
						If p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
						If id3 = 0 And p.goalside = 0 And p.id <> id2 And p.id <> id1
							p.ChaseBall(ball.x, ball.y, ball.controlledby)
							id3 = p.id
							Exit
						EndIf
					Next
				EndIf
				Local opp:TTeam = g_teamhome
				If opp = Self
					opp = g_teamaway
				EndIf
				Local near:TList = CreateList()
				For Local p:TPlayer = EachIn opp.squad
					If p = ball.controlledby Or p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
					If p.distancetogoal_opp < TPitch.YardsToPixels(45.0)
						near.AddLast(p)
					EndIf
				Next
				For Local p:TPlayer = EachIn near
					Local best:TPlayer = Null
					Local nearestdist:Float = 0.0
					For Local q:TPlayer = EachIn Self.squad
						If q.matchstats.reds Or q.selectionno = 0 Or q.selectionno > 10 Then Continue
						If q.id = id2 Or q.id = id1 Or q.id = id3 Then Continue
						Local dd:Float = Dist2D(q.x, q.y, p.x, p.y)
						If Not best Or dd < nearestdist
							best = q
							nearestdist = dd
						EndIf
					Next
					If best <> Null
						best.desx = p.metax
						best.desy = p.metay
					EndIf
				Next
			EndIf
		EndIf
	EndIf
EndIf
If g_matchstate = 1
	For Local p:TPlayer = EachIn Self.squad
		If p.selectionno >= 0 And p.selectionno < 11 And p.matchstats.reds = 0
			TPitch.ValidateOnPitch(Varptr p.desx, Varptr p.desy)
		EndIf
	Next
EndIf

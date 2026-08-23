' TPlayer.RecordPlayerStats
' VA 0x004ff67c   15154 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, vtable slot 0x230
'
' REVISION N -- MATCH. 15154/15154, mode=reloc, 1076 relocation-masked operands, zero gaps,
' zero substitutions. Verified twice by harness.try_method on the tracked file with
' NSS5_WORKER=273 and NSS5_NO_LEARN=1 (asserted H.NO_LEARN is True inside the second run);
' the result carries no learned_helpers key. Starting point was revision M's recorded state,
' re-measured fresh and confirmed: our_len 15156, delta +2, 36 gaps, first_diff 5,
' prologue "sub esp,0x4C" against the original's "sub esp,0x54".
'
' The whole body closed in one pass along a single thread of evidence. Recorded in the order
' it was found, because each step only became visible once the previous one landed.
'
'   N.1  THE ASSIGNED LEAD: the CountStat(6)/(17)/(3) cluster (+58@11225, -29@11414,
'   -29@11623). Diagnosis and fix, both confirmed by direct disassembly: the original is NOT
'   the nested nested-If revisions C/D/H assumed. It is a FLAT If / ElseIf / ElseIf chain,
'   each arm holding its own inner If rating>65 / Else:
'       If CountStat(6) > 6      -> GOODHEADING  / GOODHEADINGHOWEVER
'       ElseIf CountStat(17) > 9 -> GOODTACKLING / GOODTACKLINGHOWEVER
'       ElseIf CountStat(3) > 14 -> GOODPASSING  / GOODPASSINGHOWEVER
'   Semantically identical to the old nested form; the difference is purely which arm is the
'   fallthrough and which is the jump target. Evidence: (a) 0x502255 "cmp eax,6 / jle
'   0x502312" hands the FALSE path to the CountStat(17) test and the TRUE path to the string
'   block, i.e. the reverse of our nesting; (b) 0x502312's false path goes to the CountStat(3)
'   test at 0x5023E3, whose false path goes to the shared exit 0x5024AF -- a three-link chain,
'   not a nest; (c) each true arm ends "jmp <inner join>" and the inner join is itself
'   "jmp 0x5024AF", the textbook If-inside-ElseIf join pair; (d) harness.read_string on
'   0xc7b0e4 / 0xc7b118 / 0xc7b158 / 0xc7b18c / 0xc7b1d0 / 0xc7b204 gives HEADING,
'   HEADINGHOWEVER, TACKLING, TACKLINGHOWEVER, PASSING, PASSINGHOWEVER in ascending ADDRESS
'   order, which is literal emission order, which is source order -- independently confirming
'   the chain order and refuting the old source's reverse ordering.
'   Result: all three gaps closed outright (36 -> 33 gaps), delta unchanged at +2. Four
'   instructions in the block became newly aligned and were then reported as substitutions,
'   all four the pre-existing [ebp-0x1c] vs [ebp-0x18] frame-slot difference, not new defects.
'   NEGATIVE RESULT, recorded explicitly because revision M predicted the opposite: fixing
'   this control-flow difference did NOT move the frame. "sub esp,0x4C" before and after. The
'   hypothesis that a wrong basic-block shape here was what shifted the frame is REFUTED.
'
'   N.2  WHAT ACTUALLY CAUSED THE 21-vs-19 FRAME (the MAJOR OPEN FINDING since revision D).
'   Found by a census nobody had run: extract every [ebp-N] reference from both bodies, pair
'   them by positional proximity across the two instruction streams, and read off which
'   original depth maps to which of ours. The result is not a cost puzzle at all -- it is
'   arithmetic:
'     * orig -0x04..-0x14 map to ours -0x04..-0x14 with IDENTICAL reference counts;
'     * orig -0x3c..-0x54 map to ours -0x34..-0x4c, a clean shift of 8, seven depths,
'       reference counts equal on every one;
'     * orig -0x18 (3 refs: one store, two "cmp ...,0x2d") had NO counterpart on our side.
'       It is iVar7, the GetPlayTime(g_playtimearg) result. The ORIGINAL SPILLS IT; we kept
'       it in esi. That is one missing slot. Revision M listed iVar7 as "never picked as
'       victim ... independently confirmed by earlier revisions' own direct disassembly reads
'       to ALSO hold a register in the original". THAT CLAIM IS WRONG, and it is why three
'       passes looked past this value: 0x00500CA6 is "mov dword ptr [ebp-0x18],eax".
'     * ours -0x2c carried 7 references where the original has TWO slots, -0x20 (2 refs) and
'       -0x30 (5 refs). 2+5=7. Our source reused one Local, iVar11, for CountStat(2) and
'       CountStat(10). That is the other missing slot.
'   So the deficit was never an allocator tie-break. It was TWO REUSED LOCAL NAMES merging
'   values the original keeps apart -- the same defect class revision M found for iVar8/iVar9,
'   and the one Ghidra's own census recorded as "iVar7 x2" and nobody followed up. The same
'   census also showed our iVar8 carrying 12 extra references (the S18 cascade index) with no
'   original-side slot at all, and our iVar7 carrying five independent lives.
'
'   N.3  THE FIXES, in the order applied, each measured on its own. "sub esp,N" after each.
'     a) N.1's flat ElseIf chain.                     36 -> 33 gaps, delta +2, 0x4C
'     b) split iVar7's four later lives (CountStat(9), MyTeam, locale Select, temp_* max)
'        off the GetPlayTime life.                    33 -> 32 gaps, delta  0, 0x4C
'     c) give the iVar4.locale Select subject its own Local.  32 gaps, 2 subs closed, 0x4C
'     d) fuse "Local iVar14 = CountStat(7)" + "Local iVar15 = CountStat(8)" +
'        "iVar14 = iVar14 + iVar15" into "Local iVar14 = CountStat(7) + CountStat(8)".
'                                        32 -> 24 gaps, 183 -> 76 subs, delta +4, **0x50**
'     e) split iVar11's CountStat(10) life into its own Local.
'                                        24 -> 25 gaps,  76 -> 63 subs, delta +4, **0x54**
'     f) split the S18 cascade index off iVar8.
'                                        25 -> 14 gaps,  63 -> 28 subs, delta -11, 0x54
'     g) "local_8 = iVar8*2 + iVar12*2 + (iVar10 - 5)" -- the original computes the third
'        term into its own register before adding (0x00500F58 "mov edx,[ebp-0x38] / sub
'        edx,5 / add eax,edx"); we had folded it into the accumulator.
'                                                            14 -> 13 gaps, delta -9, 0x54
'     h) the cVar18 "Case 0" arm is a NESTED SELECT, not nested If/Else. The original loads
'        the field VALUE into eax before comparing ("mov eax,[eax+0x18] / cmp eax,1" -- the
'        10.2 Select signature) and emits two extra "EB 00" join jumps, one per Select END.
'                                                            13 ->  9 gaps, delta -1, 0x54
'     i) "If g_profile.temp_positioning > iVar22", not "> 0" -- the original compares against
'        the running-max REGISTER even on the first iteration.  9 ->  8 gaps, delta -2, 0x54
'     j) the four "CREPORT_BOSSMOTM/GOOD/OK/POOR" + Rand(5,1) calls share ONE register-
'        resident 5, defined once at orig +10320 ("mov eax,5") and pushed as "push eax" at
'        +10754 / +10881 / +11008 / +11117, where every other Rand call in the body pushes an
'        immediate. Modelled as "Local iVar25:Int = 5" declared immediately before the
'        bossreport chain, with the four calls spelled Rand(iVar25,1).
'        PREDICTION REGISTERED BEFORE BUILDING: this closes -5@10320, the four +1s, AND
'        -1@10518 -- the last one because the original is forced into the 6-byte
'        "mov edx,[global]" form there precisely because eax is held by the 5.
'        CONFIRMED, all six at once:                          8 ->  2 gaps, delta  0, 0x54
'     k) split the temp_* max-scan value into its own Local.      2 gaps, 26 -> 4 subs
'     l) split the MyTeam (clubid/nationid) value into its own Local.            MATCH
'
'   N.4  WHY (k) AND (l) WERE NEEDED, AND A CORRECTION TO codegen-patterns.md 18.1. That
'   section says "which of ebx/esi/edi a Local lands in is byte-neutral -- do not spend time
'   predicting the identity". True for push/pop; FALSE for everything else. The last 26
'   substitutions in this body were all pure register-identity differences in instructions
'   that encode the register in a ModRM byte: "cmp ebx,0" vs "cmp esi,0", "mov edx,[global]"
'   vs "mov ecx,[global]", "cmp esi,ebx" vs "cmp ebx,esi". Same length, different bytes, and
'   they block a MATCH exactly as hard as a missing statement. The lever is the colour number
'   (0=eax 1=edx 2=ecx 3=ebx 4=esi 5=edi, lowest free wins): the original's max-scan values
'   take edx/ecx because that scan contains no calls, while our merged five-life node was
'   live across calls and so started at ebx. Splitting the lives let each take its natural
'   colour. Predicting the identity is still not necessary; MATCHING it is, and the way to
'   match it is to give each independent value its own Local.
'
'   N.5  TWO PRIOR "DO NOT RE-TRY" NOTES WERE STALE, AND RE-TESTING THEM IS WHAT UNBLOCKED
'   THIS BODY. Revisions J and M both tested the iVar14/iVar15 fusion (N.3d) and both
'   reverted it -- J at +10 bytes, M at +14 with a new +362-byte gap 6000 bytes away -- and M
'   wrote "do not re-try ... confirmed twice, on two different baselines, by two different
'   people's passes". On the post-N.3b baseline the SAME edit is the single largest win in
'   the file: 8 gaps and 107 substitutions closed, and the frame moved 0x4C -> 0x50. The same
'   thing happened to the S18 cascade-index split (N.3f), tried here first on the pre-fusion
'   baseline (delta -15, 59 gaps, rejected) and worth 11 gaps and 35 substitutions on the
'   post-fusion one. The lesson is specific and worth keeping: in a body whose register
'   allocation is globally coupled, a source edit's measured effect is a property of the
'   BASELINE, not of the edit. "Reverted, made it worse" is evidence about one baseline only.
'   Re-test after any change that moves the frame size.
'
'   N.6  WHAT WAS RULED OUT ALONG THE WAY (negative results, so nobody re-walks them):
'     * the CountStat cluster does not affect the frame size (N.1);
'     * splitting iVar11 alone, on the pre-fusion baseline, made things worse (delta +2 ->
'       -2, 33 -> 39 gaps): the split value took a register instead of a slot. The identical
'       edit on the post-fusion baseline is the one that produces "sub esp,0x54". Same
'       baseline-dependence as N.5;
'     * the +173/-173 pair at 6625/6733 and the +32/-32 pair at 9388/9423, which four
'       revisions recorded as "artefact, net zero", really were alignment artefacts. Both
'       vanished with no edit aimed at them, once the surrounding register assignment
'       matched. Revision M's "an extra call visible in OURS around orig_off 9401 that the
'       original does not have" was the aligner's window sliding, not an extra call;
'     * no allocator, compiler or toolchain change was involved anywhere in this pass, which
'       is consistent with allocator-knob-sweep.md and bcc-149-allocator.md. Every one of the
'       twelve fixes is source text.
'
' ---------------------------------------------------------------------------------------------
' HISTORY -- revisions A through M, kept verbatim. Read N.5 before acting on any "do not
' re-try" note below: several were measured on baselines this body no longer has.
' ---------------------------------------------------------------------------------------------
' REVISION M -- liveness archaeology using scripts/workflow/walloc_report.py (the first pass
' to have real per-Local usage/degree/block_count/cost numbers for this file, not guessed from
' the cost FORMULA alone). NSS5_WORKER=251, harness.try_method + localise_diff.py max_gaps=200,
' NSS5_NO_LEARN=1 throughout. Starting point re-measured fresh (not trusted from revision L's
' header) and confirmed byte-identical to revision L's recorded state: our_len 15158,
' orig_len 15154, delta +4, 36 gaps, 179 same-length subs, first_diff=5 (prologue
' "sub esp,0x54" vs "0x4C" -- the MAJOR OPEN FINDING below is UNCHANGED and UNRESOLVED by
' this revision; see the explicit negative check at the end of this entry).
'
'   WALLOC NUMBERS (worker w251, tools/bmx-workers/w251, instrumented bcc rebuilt fresh this
'   pass). Read the tool's own module docstring first if you re-run this -- it documents a
'   real cross-process non-determinism for near-tied costs. --self-test on THIS rebuild did
'   NOT reproduce the docstring''s own TScreen_MatchPrep.CreateScreen numbers exactly (usage
'   off by 1 on two Locals, degree/block_count off by small amounts on several) -- flagging
'   this openly rather than hiding it: treat every number below as accurate for RELATIVE
'   ranking (which value is cheaper than which) and for clearly-non-tied costs (orders of
'   magnitude apart, which is nearly everything below), but do not treat any single absolute
'   number as exact to the last unit without rebuilding and cross-checking.
'
'   Named-Local outcomes, current (post-fix, see below) source, worker w251:
'     local_30  stack [ebp-40]   local_28  stack [ebp-32]   local_48  stack [ebp-60]
'     local_40  stack [ebp-52]   piVar17   edi (usage=82, final spill-candidate cost 0.569,
'       never picked as victim -- safely register, matches revision J/K''s own disasm-verified
'       finding that the original also keeps piVar17''s value in a register at its own site)
'     cVar18    stack [ebp-64]   (--compare-original heuristic: literal=0 matches ours=-0x40,
'       orig=-0x48 -- SAME identity, different depth, the already-catalogued "same set,
'       different rank" finding from revisions E/F, not new)
'     iVar4     stack [ebp-72]   (matches revision F''s own finding: orig=-0x50, ours=-0x48,
'       same identity, different rank -- not new, not part of the 2-slot deficit)
'     piVar5    stack [ebp-24]   iVar7   esi (usage=32, cost range 0.0066-0.099 across passes,
'       never picked as victim)
'     iVar8     stack [ebp-28]   (usage=20, degree 358->49, block_count=133 -- see the FIX
'       below, this is the reused-name Local the fix partially untangles)
'     iVar10    stack [ebp-48]   iVar11  stack [ebp-44]   iVar12  stack [ebp-56]
'     iVar13    ebx (usage=7, cost range 0.0012-0.0165 across passes, never picked as victim --
'       the CLOSEST-to-competitive register-resident named Local in the whole file, but still
'       clearly separated from the real victims'' picked costs (piVar5 0.0109, the next-lowest
'       "kept" cost here at 0.0165 is HIGHER, i.e. iVar13 would lose the comparison to piVar5
'       even at its cheapest recorded point -- not a live candidate for the 2-slot deficit
'       without a source-level block_count change nobody has identified evidence for)
'     iVar14    stack [ebp-36]   (usage=10, degree=332, block_count=128 -- see FIX below)
'     iVar15    eax (usage=2, degree=15, block_count=1 -- a genuine one-shot expression temp,
'       CountStat(8)''s raw call result, consumed once by the iVar14 accumulation; too small
'       and too locally-scoped to be a plausible spill candidate)
'     bVar19    stack [ebp-68]   bVar20  eax (usage=2, degree=16, block_count=1, same shape
'       as iVar15)
'     local_8   stack [ebp-4], FORCED (address-escaped via Varptr at the ClampInt calls --
'       never enters the allocator, matches the original at -4 on both sides, not a lever)
'     4 unnamed CGReg nodes take real slots at [ebp-8],[ebp-12],[ebp-16],[ebp-20] (Self /
'     EachIn enumerators / expression temps competing on equal terms per codegen-patterns.md
'     18.1 -- not independently named, not addressable from source)
'     1 compiler-internal (non-CGReg) scratch slot, 4 bytes, matching the -0x54 one-shot
'     idiv/fild memory round-trip for "piVar5.matchstats.rating / 10 < 7.5" that revisions
'     E/F already traced and ruled out of the 2-slot deficit (it spills on BOTH sides, at
'     [ebp-0x4c] ours / [ebp-0x54] original -- same identity, different rank, not new).
'
'   Register SET SIZE is IDENTICAL on both sides (verified by direct fresh disasm of the
'   original''s own prologue: "push ebx / push esi / push edi", all three, exactly matching
'   ours). So the 21-vs-19 slot deficit is NOT "the original uses fewer registers" -- both
'   builds commit exactly 3 physical registers (ebx/esi/edi, plus scratch eax/edx/ecx) to
'   long-lived values; the deficit is purely in how many DISTINCT VALUES fail to colour and
'   need their OWN permanent stack slot (section 22.2: slots are never reused/coalesced
'   across different CG temporaries, so this really is a "2 more distinct values" question,
'   not a re-ranking of the existing set).
'
'   HYPOTHESIS TESTED AND REJECTED (RE-TESTED on the CURRENT baseline, not assumed from
'   revision J''s old note -- see revision J''s own "re-tested... no longer applies to the
'   current file" precedent for why a re-test was warranted): fusing candidate lines
'   1031-1033 ("Local iVar14 = CountStat(7)" / "Local iVar15 = CountStat(8)" /
'   "iVar14 = iVar14 + iVar15") into one "Local iVar14 = CountStat(7) + CountStat(8)"
'   (removing iVar15 as a distinct node) was re-tried fresh this pass via
'   localise_diff.localise_body on a scratch copy (not committed). RESULT ON THE CURRENT
'   BASELINE: our_len 15158 -> 15168 (delta +4 -> +14), WORSE, and not just locally worse --
'   a brand NEW +362-byte gap appeared at ORIGINAL +11827, inside the GOODFREEKICKS..
'   GOODPENALTIES max-index Select cascade (revision B''s own fix, candidate lines ~927-955,
'   nowhere near iVar14/iVar15 textually), where none existed before. Removing iVar15 from
'   the interference graph visibly perturbs register allocation in an UNRELATED, distant part
'   of the function -- direct, current-baseline confirmation of revision J''s original finding
'   (+10 net, no distant-gap detail recorded there) and a stronger warning than that original
'   note carried: this is not a locally-contained tradeoff, it is a global one. REVERTED
'   (never applied to the tracked file). Do not re-try fusing iVar14/iVar15 again without new
'   evidence; this is now confirmed twice, on two different baselines, by two different
'   people''s passes.
'
'   FIX APPLIED THIS PASS (disassembly-verified, source-level, liveness/block_count class):
'   candidate lines 1213/1218/1220 (now: "Local iVar9:Int = g_fixture.GetWinningTeamId()" /
'   "LogLine('WinningTeam:' + iVar9)" / "LogLine('MyTeam:' + iVar7)" / "If iVar9 = iVar7").
'   BEFORE this fix these three statements reused the file''s existing top-level "iVar8"
'   Local (declared at candidate line 1026 as "piVar5.matchstats.CountStat(4)", last read at
'   line 1177, i.e. a SEPARATE, unrelated earlier value) purely by plain "=" reassignment --
'   the SAME textual pattern already used correctly elsewhere in this file for iVar8''s THIRD,
'   still-later reuse as a cascade index starting at line 1319. Because bcc''s allocator
'   treats one `Local` declaration as ONE node for its WHOLE textual scope regardless of how
'   many logically-independent values pass through it, reusing "iVar8" here forced this
'   short-lived GetWinningTeamId() value to inherit iVar8''s combined live range (line
'   1026 to ~1361, spanning the whole achievement-check gauntlet in between) -- exactly the
'   "reused variable name spans multiple independent scopes" class this file ALREADY has two
'   confirmed instances of (Ghidra''s own "iVar4 x2" and "iVar7 x2" -- see revision I''s
'   variable census), just not yet applied to this THIRD instance, which the census recorded
'   as a single "iVar8" with no "x2" (an apparent gap in that census, not re-verified against
'   Ghidra directly this pass -- flagging honestly rather than asserting Ghidra agrees).
'
'   EVIDENCE (fresh harness.disasm_original read at orig_off 9364-9480, the WinningTeam:/
'   MyTeam: LogLine pair and the following "If iVar8 = iVar7" comparison, candidate lines
'   ~1213-1220): the ORIGINAL holds this value in a REGISTER (esi) for its entire span here
'   -- loaded once, pushed for the first LogLine call, then compared directly register-to-
'   register ("cmp esi,ebx") with no intervening memory access at all. Before this fix OUR
'   build instead spilled it to [ebp-0x1c] immediately after computing it and reloaded it
'   from memory for both the LogLine push and the final compare -- the walloc numbers explain
'   why: as ONE node spanning lines 1026-1361, iVar8''s combined block_count (133) crushes its
'   cost (0.0031 when picked as victim) regardless of this specific 8-line span''s own tiny,
'   real usage. Splitting this span into its own `Local iVar9` gives it its OWN short live
'   range (declared and dead within ~8 source lines), independent of iVar8''s other two lives,
'   letting it win a register on its own merits instead of being dragged down by a live range
'   it does not actually need. PREDICTION REGISTERED BEFORE BUILDING: splitting would let
'   walloc_report show the new node register-resident, closing some or all of the byte delta
'   at this specific site. CONFIRMED both ways: walloc_report on the post-fix source shows
'   "iVar9  regid=280  outcome: ebx" (a physical register, never spilled), and a fresh
'   localise_diff run on the ACTUAL TRACKED FILE (not a scratch copy) shows the two gaps at
'   this site shrank from +34/-31 (net +3) to +32/-32 (net 0) -- both sides now use a
'   register for both compared values, matching the original''s shape; the small remaining
'   +32/-32 residual is a SEPARATE, not-yet-diagnosed difference in the surrounding
'   String-concatenation call sequence (an extra call visible in OURS around orig_off 9401
'   that the original does not have), not examined further this pass.
'
'   WHOLE-FUNCTION RESULT: our_len 15158 -> 15156 (delta +4 -> +2), gap count unchanged at 36
'   (same 36 offsets except 9362(+1) replaced by 9536(+2) -- a small, real, not-yet-diagnosed
'   knock-on side effect from the allocation shift near the edit, a net +1 regression there
'   partially offsetting the -3 win at the main site; net across both is the recorded -2).
'   Verified via harness.try_method on the tracked file under NSS5_NO_LEARN=1: status
'   MISMATCH (expected -- not a MATCH, do not promote), mode=len, our_len=15156,
'   orig_len=15154, first_diff=5. Re-ran walloc_report on the post-fix tracked file:
'   the NAMED-Local slot set is otherwise UNCHANGED (still the same 18 named/unnamed real
'   stack slots plus the 1 compiler-scratch slot = 19 total, "sub esp,0x4C" unchanged) --
'   iVar9 becoming a register did NOT reduce or increase the slot count, so this fix is
'   CONFIRMED, by direct re-measurement, to be ORTHOGONAL to the frame-size deficit below,
'   not a step toward closing it. Do not read this fix as progress on the MAJOR OPEN FINDING.
'
'   MAJOR OPEN FINDING STATUS -- explicitly re-checked, NOT closed, NOT advanced this pass:
'   the original''s prologue is still "sub esp,0x54" (21 slots) against ours "sub esp,0x4C"
'   (19 slots) -- fresh disasm this pass reconfirmed the exact same 21 depths revision E
'   recorded (-4 through -0x54, verified by direct regex scan of a full fresh
'   harness.disasm_original dump, not assumed). All three previously-identified "extra"
'   original depths (-0x48=cVar18, -0x50=iVar4, -0x54=fild-temp) were independently
'   re-confirmed this pass by reading their first-store context fresh and STILL each match an
'   existing value that ALSO spills on our side (different rank, same identity) -- these are
'   not the 2 missing values, exactly as revisions E/F already established; this pass adds no
'   new information here, just an independent reconfirmation. The three named, register-
'   resident Locals this pass has real cost numbers for (piVar17, iVar7, iVar13) are each
'   individually too far from the competitive spill-cost range to be plausible single-lever
'   candidates (see the walloc numbers above), AND each is independently confirmed by earlier
'   revisions'' own direct disassembly reads to ALSO hold a register in the original at its
'   own use site. The 2 missing values remain UNLOCATED. The most promising untried lead is
'   still the "OPEN (deep)" CountStat(6)/(17)/(3) branch-target-graph cluster (below,
'   unchanged) -- it is the one place in this file where the original''s CONTROL FLOW shape
'   (not just register choice) is confirmed to differ from ours (shared fallthrough blocks
'   the candidate does not reproduce), which is exactly the kind of change that could
'   introduce a genuinely NEW compiler temp neither build currently has. Re-deriving that
'   branch graph, not another named-Local liveness probe, is the next pass''s best lever.
'
' REVISION L -- one disassembly-verified source-spelling fix (NSS5_WORKER=440,
' harness.try_method + scripts/localise_diff.py max_gaps=200, fresh isolated tree). Starting
' point was revision K's state exactly as recorded below (our_len 15163, orig_len 15154,
' delta +9, 38 gaps, 178 same-length subs).
'
'   Candidate line 955, "local_8 = local_8 + (iVar14 + iVar13) * 2 - 6" (the CountStat(7)+
'   CountStat(8)+CountStat(11) rating-delta term, right after "g_profile.coachrep_boss :+
'   local_8"). Read the original directly at orig_off+6007..6017: it computes the RHS
'   entirely in eax (load iVar14 from its own stack slot, add edi/iVar13, shl 1, sub 6) and
'   then applies it to local_8 with a single "add dword ptr [ebp-4], eax" -- a memory
'   read-modify-write with NO preceding load of local_8's own current value. Our build's
'   compiled form for the plain "=" reassignment instead loaded local_8 into a register
'   FIRST ("mov edx,[ebp-4]"), then added the computed term into that register, then stored
'   it back -- an extra load the original does not have. Every other self-referencing
'   reassignment in this file was checked individually against its own disassembly before
'   touching anything (g_profile.thisweeksassistbonus/thisweeksgoalbonus at candidate lines
'   857-858, g_profile.coachrep_fame at 931, iVar14=iVar14+iVar15 at 944, and all six
'   local_8=local_8+/-1 single-increment sites at 966-979): every one of those already
'   matches the original's own bytes exactly (the Global-field sites reload the global
'   pointer three times on both sides regardless of "=" spelling; the bare +1/-1 sites
'   compile to the identical memory-immediate add/sub either way, since there is no second
'   operand to load). Candidate line 955 is the only site in the file where the RHS is a
'   multi-term expression pulling in other named Locals, and it is the only site where the
'   "=" vs ":+" spelling changes the emitted bytes. Rewrote as the compound form:
'       local_8 :+ (iVar14 + iVar13) * 2 - 6
'   This is the same value, computed the same way, written the way the original spells a
'   local variable being incremented in place rather than reassigned from itself.
' Result: our_len 15163 -> 15158 (delta +9 -> +4), closing both the +3@6007 and +2@6014
' gaps outright (localise_diff drops from 38 to 36 length-changing gaps; the -5 total exactly
' matches the sum of those two closed gaps, confirmed by a fresh full-body rebuild and
' oracle call, not a probe). Same-length subs went 178 -> 179; the one new entry is the
' expected residual at the same statement (mov eax,[ebp-0x28]/add eax,edi in the original
' vs mov eax,[ebp-0x24]/add eax,ebx in ours) -- an operand-slot/register-name difference of
' the same already-catalogued frame-size/register-allocation class as every other sub in
' this file's list, not a new defect class. Re-scanned the full subs list afterward for any
' setcc/jcc mnemonic mismatch (grepped for je/jne/jle/jge/sete/setne/setl/setg across every
' SUB entry): none found, matching revision K's own closing note that this class of defect
' is fully closed.
'
' All 36 remaining gaps were individually re-examined against fresh disassembly this pass
' (not assumed from the header) and every one falls into a family already diagnosed by
' revisions D through K, or into one newly confirmed and folded into that same family here:
'   * +173/-173 @ 6625/6733 -- the pre-existing "ARTEFACT, net zero" pair. Read in full this
'     pass: two near-identical decrement/notify blocks (one per counter field, +0x68 and
'     +0x6c) that are present, in the same source order, on both sides; the aligner just
'     cannot line the two up locally because they are structurally identical. Not a
'     reordering defect -- left untouched, matching every prior revision's conclusion.
'   * +58/-29/-29 @ 11225/11414/11623 -- the CountStat(6)/(17)/(3) nested-guard cluster
'     revision H already tested (literal flip, reverted) and revision D/C first diagnosed as
'     a whole branch-target graph, not independently fixable one comparison at a time. Not
'     re-attempted; the header's own evidence for this one is still accurate.
'   * +10/-9/-2 @ 5820/5789/5833 -- the CountStat(11)/(7)/(8) triad revision J already tested
'     (fusing the three Local declarations into one expression, reverted for making our_len
'     worse). Re-read the disassembly fresh this pass: original keeps CountStat(11) in edi
'     and the CountStat(7)+CountStat(8) sum in ebx the whole time; the three-statement
'     source form already produces exactly that register plan, so the register CHOICE (edi
'     vs ebx numbering) is the only remaining difference, not the source shape.
'   * +34/-31 @ 9388/9423 -- NEW this pass, same family: two debug LogLine calls
'     ("WinningTeam:" + esi_var, then "MyTeam:" + ebx_var, confirmed via harness.read_string
'     on 0xc7ae6c/0xc7ae90) followed by a comparison of the two values. Both sides call
'     LogLine in the same order with the same two strings; the byte difference is purely
'     which of the two values our build keeps live in a register (esi) versus which one it
'     spills to a stack slot ([ebp-0x1c]) across the two calls, where the original keeps
'     both in registers (esi/ebx) the whole time. Register-allocation, not source order.
'   * -5 @ 10320 and +1 x4 @ 10753/10880/11007/11116 -- confirmed, by tracing eax's origin
'     backward from the -5 site, to be the SAME accident the header already documented for
'     the four Rand(5,1) push-immediate-vs-push-register sites: "mov eax,5" at +10320 is a
'     register preload that survives, unused at that point, all the way to the first Rand
'     call far downstream. One root cause, five gaps, already catalogued.
'   * -4/-2/-2 @ 775/735/746 -- the iVar4.locale/comptype and CLEFT/CRIGHT bare-field-check
'     sites revision C/H already traced (original always reloads the field VALUE into a
'     register before comparing; flattening the If/ElseIf shape was tested and reverted for
'     no length change). Not re-attempted.
'   * +3/+2/+2/+1 x9 @ 12146/11827/12126/11856..12096 -- the GOODFREEKICKS..GOODPENALTIES
'     max-index Select cascade (S18), already documented as the running index staying in a
'     register the whole cascade in the original versus being spilled and reloaded at each
'     comparison in ours. The source (iVar8, already a Select per revision B) is unchanged
'     and correct.
'   * -2 @ 6364, -1 @ 6036/6391/5674/9362/10518 -- each individually re-disassembled this
'     pass. All six are single-instruction register-vs-memory-operand or register-numbering
'     differences (a value the original keeps in one register for a longer span, that our
'     shorter 19-slot frame either keeps in a different register or spills earlier) with no
'     corresponding source-text choice available to change them -- confirmed one at a time,
'     not assumed from the pattern.
' Every one of the above resolves to the same root cause flagged since revision D: the
' original's frame uses 21 [ebp-N] depths against our 19, already proven (revisions E, F, I,
' independently, three times) not to be a missing Local declaration. Not re-opened here, per
' the standing guidance not to spend further budget on the frame-size prologue itself.
'
' REVISION K -- thirteen disassembly-verified source-spelling fixes, all instances of the
' "match the operand order the original evaluates, not just the meaning" class (a > b and
' b < a compile to different setcc/jcc bytes even though they mean the same thing), plus one
' bare-truthiness/Then-Else-swap pair of the same shape as the file's existing GetCurrentStats
' fix. Starting point was revision J's state exactly as recorded below (our_len 15154,
' orig_len 15154, delta +0, 41 gaps, 188 same-length subs). NSS5_WORKER=420,
' harness.try_method + scripts/localise_diff.py (max_gaps=200), fresh isolated tree each call,
' scripts/disasm.py / harness.disasm_original read directly for every fix before writing it.
'
'   1. Candidate line ~668, "If piVar17 = Null Or piVar17.matchstats.rating <
'      piVar3.matchstats.rating" (the MOTM-loop guard flagged STILL OPEN by revision C/D as
'      the "488/508/514" triplet). Original spells the Null guard as bare object truthiness
'      negated ("Not piVar17": cmp edi,Null / setne / movzx / cmp / sete / movzx / cmp / jne,
'      the double-materialise shape) where the candidate had the direct "piVar17 = Null" short
'      form (single sete). Rewrote as "Not piVar17". Then, independently, the second Or-term:
'      original loads piVar3''s rating first (esi, the loop var) and compares with setg
'      ("piVar3.rating > piVar17.rating") where the candidate evaluated piVar17 first with
'      setl ("piVar17.rating < piVar3.rating") -- same meaning, wrong evaluation order.
'      Rewrote as "piVar3.matchstats.rating > piVar17.matchstats.rating". Combined:
'          If Not piVar17 Or piVar3.matchstats.rating > piVar17.matchstats.rating
'      The Not-piVar17 half alone closed the 488/508/514 gap trio but grew our_len by +9
'      (15154 -> 15163, confirmed by localise_diff as the trio collapsing to a clean 0-net
'      insert/delete pair, not a regression); the rating-order half was a same-length sub fix
'      (setl -> setg) that also collapsed two adjacent gaps as a side effect (41 -> 38 total
'      length-changing gaps by the end of this revision, not from this fix alone -- see below).
'   2. Six sites, one recurring construct: "local_40 < local_48" written with local_40
'      evaluated first, where the original always evaluates local_48 first (setg, not setl).
'      Confirmed independently at each site's own disassembly (not generalised from one):
'      candidate lines ~718 ("piVar5.matchstats.rating > 80 And local_40 < local_48"), ~833
'      and ~1032 (both "cVar18 = 4 And local_40 < local_48", two separate occurrences of
'      identical source text at different call sites), ~1023, ~1026, ~1029 (cVar18 = 0/1/2,
'      same CREPORT_BOSSMOTM/GOOD/OK/POOR cascade as 1032). All six rewritten
'      "local_48 > local_40". The mirror-image phrasing "local_48 < local_40" (candidate
'      lines ~887, ~1216) was checked too and already matched as-is -- left untouched, per
'      the standing rule not to blanket-convert a phrasing without checking each site.
'   3. Candidate line ~1211/~1217, the RIVALSWEWON/RIVALSWELOST coachrep_fans guard inside
'      the bVar19 block. Two sub-fixes at each of the two sites: first, "coachrep_fans < 1"
'      compiled against the literal 1 (cmp field,1/jge) where the original compares against 0
'      (cmp field,0/jle) -- rewrote as "coachrep_fans <= 0", which fixed the immediate but
'      left the jcc polarity inverted (jle vs jg, exact opposites). Reading the string
'      operands at the original's fallthrough vs jump targets (harness.read_string on
'      0xc7b478/0xc7b4b4/0xc7b4ec) showed the ORIGINAL's fallthrough (bare "> 0") is the GOOD
'      report and its jump target (<= 0) is the BAD report -- i.e. original''s Then/Else
'      bodies are the reverse of the candidate's ("BAD" written first, "GOOD" second in the
'      candidate; original has GOOD first). Rewrote as bare "coachrep_fans > 0" with the GOOD
'      branch first and BAD second, at both the WON and LOST sites (four report strings, two
'      guards). All four jcc bytes now match exactly.
'   4. Candidate lines ~727-733, "If g_profile.GotSponsor() = 0" (no compound, plain If/Else,
'      COACHYELLOW vs COACHYELLOWSPONSORS). Same shape as fix 3: original''s fallthrough
'      (GotSponsor() true, eax<>0) is COACHYELLOWSPONSORS and its jump target (GotSponsor()
'      false, eax=0) is COACHYELLOW -- reversed from the candidate''s "=0 -> COACHYELLOW,
'      Else -> SPONSORS" order. Confirmed via harness.read_string on 0xc7a93c/0xc7a980.
'      Rewrote as bare "If g_profile.GotSponsor()" with SPONSORS first, COACHYELLOW second.
'   5. Candidate line ~882 ("If local_40 < local_48 ... local_8 :+ 1 ... ElseIf local_48 <
'      local_40 ... local_8 :- 1") and its second occurrence at candidate line ~1209 (inside
'      "If bVar19"). Both are the same local_40/local_48 evaluation-order defect as fix 2, but
'      as a bare relational If (no setcc materialised -- a direct cmp+jcc), not an And-term:
'      original always keeps local_48 as the direct memory cmp operand and loads local_40 into
'      a register, producing jle/jge on the SAME operands rather than a reversed pair. Both
'      rewritten "If local_48 > local_40" (the paired "ElseIf local_48 < local_40" at each site
'      already matched and was left alone).
'   6. Candidate line ~1034, "If local_40 + 4 < local_48" (the CheckAchievement(22) guard right
'      after the cVar18 cascade from fix 2). Original evaluates local_40+4 into a register but
'      keeps local_48 as the LHS memory operand of the cmp (cmp [local_48],eax / jle), i.e. the
'      original''s comparison is spelled with local_48 first: "local_48 > local_40 + 4".
'      Rewritten accordingly.
' Net result of fixes 1-6: our_len 15154 -> 15163 (delta +0 -> +9, all nine bytes are fix 1''s
' Not-piVar17 half; every other fix in this revision was same-length). localise_diff after all
' thirteen edits: 38 length-changing gaps (was 41), +9 bytes total, delta_accounted COMPLETE;
' 178 same-length subs (was 188); zero remaining setcc (setg/setl/sete/setne) or jcc
' (je/jne/jle/jge) mismatches anywhere in the sub list -- confirmed by grepping the full
' subs section for every conditional mnemonic after the last edit landed clean. Every
' remaining sub is a pure "mov/push/cmp [ebp-N]" displacement residual with an IDENTICAL
' mnemonic on both sides, i.e. the same already-catalogued frame-size/register-allocation
' finding (orig_len''s frame is 21 stack-slot depths vs our 19, first_diff still lands on the
' "sub esp,0x54" vs "0x4c" prologue immediate) that revisions D through J spent five separate
' passes falsifying every source-level hypothesis for (missing Local, name-coalescing,
' literal-spelling flips on the CountStat(6)/(17) guards, ElseIf-flattening -- see the OPEN
' (deep) and MAJOR OPEN FINDING sections below, both still accurate and untouched by this
' revision). The three still-open length gaps this revision did not attempt (+173/-173
' artefact at 6625/6733, +58/-29/-29 at 11225/11414/11623, +34/-31 at 9388/9423, +10/-9 at
' 5820/5789) are exactly revision H''s already-tested-and-reverted set; this revision did not
' re-open them. Stopping here per the register-allocator-tie guidance rather than grinding
' further on the frame-size root cause -- the next lever, if anyone picks this up, is still
' revision F''s suggested full per-slot census, not another source-text guess.
'
' REVISION J -- three disassembly-verified source fixes, closing the length delta to 0 for
' the first time (harness.try_method NSS5_WORKER=400, NSS5_NO_LEARN=1, fresh isolated tree).
' State: our_len 15154 == orig_len 15154 exactly, mode='diff', matched=3035/15154, status
' still MISMATCH -- first_diff=5, the prologue "sub esp,0x54" vs "0x4c" frame-size gap
' catalogued since revision D remains OPEN and unresolved by this pass (see below). Still,
' matched rose from 1215 to 3035 and the whole-body gap list (scripts/localise_diff.py,
' max_gaps=200) shrank from 46 entries netting +16 to 41 entries netting 0.
'
'   1. Candidate line 821, "If piVar5.matchstats.motm <> 0 And local_8 < 1" -- read the
'      original directly at orig_off+6243..6294: the first (motm) operand of the And is
'      tested with a bare "cmp eax,0 / je", no setne/movzx pair, where our build compiled
'      the explicit "<> 0" into a materialised sete/movzx before the branch test (the S-rule
'      "bare Int truthiness vs an explicit nonzero test differ"). Rewrote the first operand
'      as bare "piVar5.matchstats.motm" (kept "local_8 < 1", whose own setl/movzx already
'      matched, untouched). Closed the +9@6265 gap outright, our_len 15170 -> 15161.
'   2. Candidate line 971, "If TCompetition.SelectById(g_fixture.compid).IsCupFinal() <> 0
'      And g_fixture.matchtype <> 4" -- same S-rule, confirmed independently at
'      orig_off+9483..9514 (IsCupFinal's own result tested bare, matchtype's setne/movzx
'      unaffected). NOTE: an earlier revision (see "FIXED in revision C" section below)
'      tried dropping this same "<> 0" and reverted it because whole-function our_len got
'      WORSE at the time -- that measurement predates fix 1 above and was measuring a
'      different, since-changed baseline; re-tested here in isolation against the CURRENT
'      source with a full rebuild and confirmed by localise_diff that this specific +9@9492
'      gap, and only that gap, closes (our_len 15161 -> 15152). Do not re-revert this on the
'      strength of the old note alone -- it no longer applies to the current file.
'   3. Candidate lines 978-981, "If iVar4.level = 0 ... ElseIf iVar4.level = 1 ... EndIf" (no
'      final Else, nested inside "Case 1" of the "Select iVar7" locale cascade) -- a third,
'      previously unnoticed instance of the same iVar4.level Select-vs-If/ElseIf pattern
'      revision A already fixed twice elsewhere in this file (S10.2: original loads the
'      field once and chains cmp/je with no reload; If/ElseIf reloads per arm). Confirmed at
'      orig_off+9580..9638 directly: original is "mov eax,[iVar4] / mov eax,[eax+0x1c] /
'      cmp eax,0/je / cmp eax,1/je / jmp" (18 bytes, one load) where our If/ElseIf reloaded
'      iVar4.level's memory operand directly per arm instead. Rewrote as "Select iVar4.level
'      / Case 0 / Case 1 / End Select". Closed the -9@9580/+9@9619/-2@9638 trio outright (all
'      three gone from localise_diff's output, not just netted), our_len 15152 -> 15154,
'      reaching orig_len exactly. matched jumped from ~1215 to 3035 on this fix alone,
'      confirming the alignment stage was starved by the leftover length mismatch, not by
'      this construct's own logic.
'
'   ONE HYPOTHESIS TESTED AND REJECTED, recorded so nobody re-tries it: candidate lines
'   781-783 ("Local iVar14 = CountStat(7)" / "Local iVar15 = CountStat(8)" / "iVar14 = iVar14
'   + iVar15") were fused into a single "Local iVar14 = CountStat(7) + CountStat(8)" on the
'   theory that iVar15, used exactly once, is a reconstruction-introduced temporary (the
'   S22 "extra named Local" class). RESULT: our_len got WORSE (15170 -> 15180, +10), not
'   better. REVERTED. The three-statement form already in this file is correct; do not
'   re-try fusing it.
'
'   NOT YET RESOLVED -- the remaining ~188 subs and the frame-size gap itself. Traced one
'   concrete NEW instance of the same register-vs-memory split the frame-size finding (two
'   sections below) already describes for iVar4 and the -0x54 fild temp: the "GOODFREEKICKS
'   .. GOODPENALTIES" max-index cascade (candidate lines ~927-955, revision B's own Select
'   fix) carries its running winning-index value in EAX across all nine comparisons in the
'   original ("mov eax,N" 5-byte immediate loads, no memory store until the Select header
'   reads it), where our build spills that same index to [ebp-0x1c]/[ebp-0x14] and reloads it
'   at each of the nine sites ("mov dword ptr [ebp-N],imm", 7-byte memory stores) -- the
'   source (iVar8, already a Select per revision B) is unchanged and correct; only the
'   register-vs-memory placement differs, accounting for the +1 x7 cluster at
'   11856/11886/11916/11946/11976/12006/12036/12066/12096 and the +3@12146 Select-header
'   reload already catalogued below as "Pure register-allocation residual (S18)". Same
'   diagnosis applies, by direct read of the disassembly this pass, to the CountStat(11)/(7)/
'   (8) triad at candidate lines 780-782 (-9@5789/+10@5820/-2@5833: iVar13 stays in a
'   register the whole time in the original but is fused into ebx there vs a different
'   register choice + earlier spill in ours) and to the iVar4.locale/iVar4.comptype nested
'   test at candidate lines 614-621 (-2@735/-2@746/-4@775: original always reloads the field
'   VALUE into a register before comparing where ours compares the memory operand directly --
'   tested flattening to an ElseIf chain, no length change and matched dropped slightly,
'   reverted). All four are the same class of finding as the pre-existing "MAJOR OPEN
'   FINDING" below: a single function-wide register-allocation/spill-order difference, not a
'   source-text defect, and not fixed by any source rewrite tried so far (fusing Locals,
'   flattening If/ElseIf chains, or reordering statements) -- every attempt this pass either
'   made no difference or moved the gap without closing it. Flagging for whoever picks this
'   up next: the lead most likely to pay off is still revision F's suggested full per-slot
'   census (which variable the original keeps live in a register across the whole cascade,
'   and why our allocator doesn't), not further one-off source edits in this class.
'
' REVISION I -- NO SOURCE EDIT (assigned to re-chase the "declare the 2 missing Locals"
' framing of the frame-size bug; re-tested it from scratch and it still does not hold).
' State unchanged: MISMATCH, our_len=15170, orig_len=15154, first_diff=5 (prologue
' "sub esp,0x4C" vs "0x54"), re-confirmed via bytematch.py against the current
' nss5_assembled.exe before touching anything.
'
'   Cross-checked every named Local in the Ghidra header (fVar1, piVar2, piVar3, iVar4 x2,
'   piVar5, uVar6, iVar7 x2, iVar8, puVar9, iVar10-15, puVar16, piVar17, cVar18, bVar19,
'   bVar20, fVar21, local_48/40/30/28/8) against this file's `Local` statements one for
'   one: every genuine source-level Local IS already declared here (grep "^\s*(For )?Local"
'   lists 23 distinct declarations, matching the header's variable set with no gaps).
'   fVar1/uVar6/piVar2/puVar9/fVar21 are not extra Locals -- they are Ghidra's names for
'   call-result/refcount-release/FPU-spill compiler temps that already exist implicitly
'   wherever the corresponding statement compiles (confirmed by reading their use sites).
'   So there is no textually-missing `Local` statement to add here -- do not re-open this
'   specific sub-hypothesis again without new evidence.
'
'   Independently re-ran revisions E and F's slot census (fresh disasm of the ORIGINAL via
'   harness.disasm_original(0x004FF67C,15154) and of OURS via bytematch.find_method on the
'   current src/assembled/nss5_assembled.exe -- no probe build needed, both read-only):
'   original uses 21 distinct [ebp-N] depths (4,8,...,0x54), ours uses 19 (4,8,...,0x4C),
'   a clean superset -- reproduces revision E's numbers exactly, byte for byte, on a fresh
'   independent run. The two depths original has that ours does not, -0x50 and -0x54,
'   decode to exactly what revisions E and F already reported: -0x50 is iVar4 (the
'   TCompetition.SelectById(g_fixture.compid) result, already declared at candidate line
'   554, first stored at orig_off+705 right after the `call [0xc6160c]` SelectById slot
'   call) and -0x54 is the one-shot `idiv ecx` / `fild dword ptr [ebp-0x54]` memory
'   round-trip for the `piVar5.matchstats.rating / 10 < 7.5` comparison (candidate line
'   779), touched nowhere else. BOTH already exist as statements in this file today; revision
'   F already showed both also get a slot in OUR build too (just at shallower depths,
'   -0x48 and -0x4c respectively, ranked 2nd/1st-from-the-end of our own 19 rather than
'   the original's 21) -- i.e. neither is a value our source fails to compute, only a value
'   our allocator keeps in a register for longer. CONFIRMS, again, that the 2-slot deficit
'   is a register-allocation/spill-choice difference somewhere else in the body, not a
'   missing declaration -- the task framing "the original has two more local variables...
'   find them... declare them" does not hold up under a fresh, independently-reproduced
'   check. Do not act on that framing literally; it has now been tested and falsified by
'   three separate methods across revisions E, F and this one.
'
'   Also re-derived, for completeness, the full first-store byte-offset for every shared
'   depth on both sides (not just the two extra ones) to look for a cheaper lead: the SET
'   of 19 depths matches, but individual variables do NOT land on the same numeric depth
'   in both builds (e.g. local_30's first store is depth -0x2c in the original vs -0x28 in
'   ours, both at the identical byte offset +28 -- same statement, different depth
'   number). That rules out reading original depth number as a direct pointer to "which
'   source statement" without also cross-checking the byte offset/call-site shape, as revision
'   H already warned. Slot depth in this file tracks the allocator's internal spill/colour
'   order, not declaration order or first-use byte order -- confirmed on a second variable
'   (local_30) beyond the bVar19 case revision H already had. NOT a new technique for finding
'   the 2-slot deficit by itself; recorded so the next pass does not re-derive it. The only
'   avenue that would actually resolve this (revision F''s full per-slot identity census
'   across ALL 19-21 depths, cross-referenced statement-by-statement) still needs a build
'   loop to test candidate reorderings against, which this pass did not have -- flagging
'   for the next pass with a build available. scratch_census.py (temp, not committed) in
'   the repo root has the working read-only harness/bytematch plumbing to reuse: it grabs
'   both disassemblies without any assemble.py/bmk invocation.
'
' REVISION H -- NO SOURCE EDIT (reverted both experiments below; state unchanged). Re-verified
' revision G's exact numbers first (harness.try_method, NSS5_NO_LEARN=1, fresh isolated tree):
' MISMATCH, our_len=15170, orig_len=15154, first_diff=5 (still the "sub esp,0x54" vs "0x4C"
' prologue immediate -- the frame-size root cause flagged since revision D is STILL open). Spent
' this pass's budget testing two concrete, cheap hypotheses for the 2-dword deficit instead of
' chasing another single gap; both came back negative, recorded here so nobody re-spends time
' on them:
'
'   1. HYPOTHESIS: bcc coalesces two Locals of the SAME NAME declared in non-overlapping
'      scopes (candidate lines ~485/486's loop-local "iVar4"/"iVar7" vs the outer "iVar4"
'      TCompetition ref and the later outer "iVar7" GetPlayTime local) into ONE physical
'      stack slot, so the true slot count is 2 lower than a naive per-statement count and the
'      deficit is a genuine MISSING Local elsewhere. TESTED: renamed the loop-local pair to
'      iVar4x/iVar7x (pure rename, zero behaviour change, only their own nested If/ElseIf
'      block touched) and rebuilt the WHOLE function fresh. RESULT: our_len and first_diff
'      were BYTE-IDENTICAL to the unrenamed build (15170 / 5). If bcc were coalescing by
'      name, freeing the identifier would have to change slot count by introducing a fresh
'      one -- it did not. FALSIFIED: each textually distinct Local statement already gets its
'      own slot regardless of name reuse; the revision D header's "more likely a genuinely
'      missing declaration than a shadowing bug" steer is now doubly confirmed, not just
'      argued. Do not re-try any name-coalescing theory on this file.
'   2. Re-examined the "OPEN (deep)" nested-If cluster (+58@11225/-29@11414/-29@11623,
'      candidate lines ~937-955, piVar5.matchstats.CountStat(6)/(17)/(3) cascade). The
'      existing header evidence (right above, the earliest revisions) already shows the original spells
'      the two outer guards "> 6" / "> 9" where the candidate has "< 7" / "< 10". TESTED, in
'      isolation, WITHOUT re-deriving the branch-target graph: rewrote just those two literal
'      comparisons ("CountStat(6) < 7" -> "> 6", "CountStat(17) < 10" -> "> 9"), leaving the
'      nested-If shape untouched. RESULT: our_len unchanged (15170) and localise_diff's full
'      46-gap list is IDENTICAL in every delta, only the +58 gap's anchor offset shifted by
'      +9 bytes (11225 -> 11234) to track the edit's own position. CONFIRMS, empirically, the
'      header's own warning: this specific pair of comparisons is not independently
'      fixable -- the cluster's whole branch-target graph has to be re-derived and rewritten
'      together, or the edit just relocates the same unclosed delta. REVERTED, not applied.
'   3. NOTE (no test needed -- read off revision G's own evidence above): bVar19, one of the
'      LAST-declared Locals in this file, already spills to a real stack slot in BOTH builds
'      (ebp-0x44 ours / ebp-0x4C original, per the revision G rivalid1/2/3 fix note above). That
'      refutes using local_alloc_stats.py's "the last three declared Locals always get a
'      register" corpus finding as a way to GUESS which 2 Locals differ here -- it is a loose
'      correlation measured on small bodies, explicitly flagged there as not exact, and does
'      not hold as a precise model for a ~40-Local, 15KB body like this one. Do not use it to
'      pick candidates without checking the actual disassembly first.
'
' NEXT PASS: revisions D, E and F already confirmed original=21 stack slots vs
' ours=19, a clean superset by DEPTH (not identity), and ruled out both of revision E's own
' extra-slot candidates (iVar4's SelectById result, the idiv/fild rating-comparison temp) as
' the source -- they spill in both builds, just at different ranks. This pass's two additional
' guesses are now also ruled out. The only approach nobody has finished is revision F's own
' suggested one: a full per-slot CENSUS matching every distinct [ebp-N] store site in the
' ORIGINAL to the SAME source-level value in ours by call-site identity (not by depth number),
' to find which 2 values spill in the original but stay in a register the whole time in ours.
' scripts/_w21_disasm.py and scripts/_w22L2_*.py have reusable probe-disassembly scaffolding.
' Chasing any more of the 46 small gaps below WITHOUT first closing this is low-value: even a
' full, perfect close of every gap (delta 0, as revision D briefly reached) still left 188
' same-length "subs" and a catastrophic raw byte-agreement score, because nearly every
' [ebp-N] stack reference in a 15KB function disagrees once the frame size itself is wrong.
'
' REVISION G -- two real, disassembly-verified fixes (localise_diff.py + harness.py,
' NSS5_NO_LEARN=1, isolated tree, no shared state touched; scripts/assemble.py NOT run).
' State: still MISMATCH (frame-size root cause below is unresolved), our_len now 15170
' (was 15154 -- see why below), first_diff still byte 5 (prologue, untouched).
'
'   1. The four drug-test coachrep penalties (candidate block ~966-975, "coachrep_boss :- 50
'      / coachrep_team :- 30 / coachrep_fans :- 30 / coachrep_sponsors :- 50") compiled as
'      SUB (83 E8 imm) at orig_off 14153/14173/14193/14213; the original uses ADD with a
'      NEGATIVE immediate (83 C0 imm) at every one of the four sites (confirmed by direct
'      disasm diff, not inferred) -- e.g. orig `add eax,-0x32` (C7... 83 C0 CE) vs ours
'      `sub eax,0x32` (83 E8 32). Same arithmetic result, different opcode byte + immediate
'      encoding -- a spelling difference (":+  -50" compiles ADD; ":- 50" compiles SUB),
'      exactly the S10.1 "match the opcode, not just the meaning" class. Rewrote all four as
'      ":+  -N". Verified: those 4 same-length SUB-list entries (188 -> 184) disappeared
'      entirely from localise_diff's output; no other byte in the function moved (gap list
'      identical, 49 gaps, delta_accounted +0 of +0 COMPLETE both before and after). Zero
'      risk: same length, same behaviour, only the encoding of a compile-time-constant
'      arithmetic op changed. NOTE: every OTHER ":- N" in this file (lines ~588, 648, 650,
'      655, 664, 666, 668, 673, 675, 677) was checked against the same disasm and already
'      matches as plain SUB -- do NOT blanket-convert every ":- N" in the file, only these
'      four proved to differ.
'
'   2. `Local bVar19:Int = local_30.rivalid1=local_28.id Or local_30.rivalid2=local_28.id Or
'      local_30.rivalid3=local_28.id` (candidate line ~614) was flagged OPEN since revision C
'      ("-9/+9/-9" -- actually three separate gaps once isolated: -7@6058, +6@6129,
'      -15@6134). Read the full original disasm for this span directly (not the Ghidra C,
'      which just shows `bVar19=(...)==...; if(!bVar19) bVar19=...;` and hides the byte
'      shape). FINDING: right before the FIRST rivalid comparison the original has a bare
'      `mov dword [bVar19-slot], 0` that our build never emitted at all (GAP @ 6058, -7)
'      -- i.e. bVar19 starts pre-zeroed. Then ALL THREE disjuncts (not just the first two)
'      use the identical short-circuit shape: sete/movzx to a scratch register, test it,
'      and on the LAST disjunct specifically `je <past-the-store>` / (fallthrough)
'      `mov dword [bVar19-slot], 1` -- i.e. even the final term never stores its OWN raw
'      flag into bVar19's slot; it only ever writes the LITERAL constant 1, conditionally,
'      into an already-zeroed slot (GAP @ 6129/6134, the "+6"/"-15" pair -- ours instead
'      eagerly stored the bare last-term flag straight into bVar19's slot, 6 bytes short of
'      the original's explicit `mov ...,1` + reload). That whole shape (pre-zero the
'      destination, converge every disjunct -- including the last -- on one shared
'      "store literal 1" tail) is the codegen for an If/Then value-assignment, not a flat
'      "Local x = A Or B Or C" expression value (a flat Or-as-value naturally short-circuits
'      the FIRST N-1 disjuncts to a shared true-tail but just stores the LAST disjunct's own
'      computed flag directly, since if you reach it unshortcircuited the Or's value IS that
'      last term -- which is exactly what our old flat-expression source produced, and is a
'      different, shorter shape). Rewrote as:
'          Local bVar19:Int = False
'          If local_30.rivalid1 = local_28.id Or local_30.rivalid2 = local_28.id Or local_30.rivalid3 = local_28.id
'              bVar19 = True
'          EndIf
'      Verified: all three gaps (-7@6058, +6@6129, -15@6134) are GONE from localise_diff's
'      output after this edit -- that whole span now compiles as SAME-LENGTH subs whose only
'      remaining difference is the pre-existing stack-slot-depth offset (e.g. ebp-0x44 here
'      vs ebp-0x4c in the original), the same already-catalogued symptom of the unresolved
'      frame-size bug below, not a new problem. bVar20's flat expression
'      (`bVar19 And (iVar12>0 Or iVar8>0)`, next line) was checked too and does NOT need the
'      same treatment -- its own disasm already matches as a flat value-Or (store first
'      disjunct's raw flag, overwrite with the last disjunct's raw flag if the first was
'      false), consistent with it staying a plain expression, not an If/Then. Do not
'      "generalise" this fix to bVar20 or to any other flat Or/And Local in this file without
'      re-checking that specific site's own disasm the same way.
'
'   CONSEQUENCE, read before touching this again: fixing #2 grew our_len from 15154 to
'   15170 (+16 -- the original's If/Then shape for bVar19 really is 16 bytes longer than a
'   flat expression there, this is not a mistake). Before this pass, that -16 was silently
'   CANCELLING an unrelated +16 of excess bytes elsewhere in the function that nobody has
'   isolated yet, which is how orig_len==our_len==15154 was reached in revision D despite this
'   specific span being wrong the whole time. localise_diff confirms delta_accounted is
'   still COMPLETE (all of +16 is accounted for by the remaining 46 gaps, nothing hidden) --
'   so the next lever is to find the OTHER, still-uncatalogued +16 excess among those 46 gaps
'   (the gap list and every individual gap's delta are otherwise IDENTICAL to revisions D-F's,
'   just renumbered from 49 to 46 after removing the three closed above) and close it,
'   which would restore orig_len==our_len at a genuinely-correct 15170 instead of the old,
'   coincidental 15154. Do NOT chase this by reverting fix #2 -- #2 is disasm-verified
'   correct; the remaining excess is a SEPARATE, still-unlocated bug.
'
' REVISION F -- resolved revision E's one open sub-question (whether the -0x54
' one-shot `fild` temp at orig_off+6475/+6478, `piVar5.matchstats.rating / 10 < 7.5`, is
' itself part of the 2-slot deficit) and RULED IT OUT, precisely. State UNCHANGED (still
' MISMATCH, orig_len==our_len==15154, first_diff=5 in the prologue "sub esp,N" immediate) --
' no source edit made this pass; harness.try_method under NSS5_NO_LEARN=1 reproduces revision
' D and E's numbers exactly (verified first, before any new work).
'
' Method: rebuilt the probe (harness.try_method(..., keep=True) -> workdir/probe.exe),
' located OUR compiled body with bytematch.find_method, disassembled the WHOLE 15154-byte
' body with capstone, and read off every `idiv`/`fild` pair plus the full sorted set of
' distinct `[ebp-N]` depths actually referenced (19 slots: 4,8,...,0x4C -- matches
' `sub esp,0x4C` exactly, confirms revision E's slot census independently by a different
' method).
'
'   OUR build has the identical idiv-then-fild shape at our_off+6447/+6453
'   (`idiv ecx` / `fild dword ptr [ebp-0x4c]`) -- confirming revision E's guess (a): the
'   original statement really does force the same one-instruction-wide memory round-trip in
'   BOTH builds, so this was never a missing-statement question.
'
'   THE KEY NEW FACT: in OUR build this temp lands at `[ebp-0x4c]`, which is OUR OWN LAST
'   slot (rank 19 of our 19, the highest depth we use at all) -- not "some already-dead slot
'   reused from the middle" as revision E's hypothesis (a) allowed for. And `iVar4` (the
'   SelectById result, revision E's other extra-slot candidate) sits at `[ebp-0x48]`, which is
'   rank 18 of our 19 -- i.e. SECOND-TO-LAST, not "~16 of 19" as revision E estimated by eye.
'   On the ORIGINAL side the same two values are at `[ebp-0x50]` (iVar4, rank 20 of the
'   original's 21) and `[ebp-0x54]` (the fild temp, rank 21 of 21) -- also last and
'   second-to-last.
'
'   So the RELATIVE finishing order of these two particular values is IDENTICAL in both
'   builds (fild-temp dead last, iVar4 immediately before it) -- neither one is the source
'   of the 2-slot gap. What differs is that the ORIGINAL has 19 other things finish spilling
'   before it reaches iVar4 (positions 1-19 of 21), while OURS has only 17 (positions 1-17 of
'   19). Two additional values fail to colour in the original SOMEWHERE ELSE in the body,
'   entirely before iVar4's slot is cut -- not at the tail, not touching either of revision E's
'   two candidate slots. This directly answers revision E's open question ("NOT distinguished
'   this pass") and retires hypothesis (a) as a dead end: do not spend further time on the
'   fild-temp or on iVar4 itself, the 2-slot deficit is not there.
'
' NOT done this pass, for the next pass: a full census of EVERY distinct source-level
' Local's live range (first store -> last load, by source line) cross-referenced against
' the ORIGINAL's slot-store offsets the way revision E did for iVar4 specifically, to find
' which 2 (of the ~40+ named Locals in this file) spill in the original but colour to a
' register in ours. `scripts/w22_L0_disasm.py` (kept, not scratch-only) has the working
' probe-disassembly + slot-census code to build on; point it at `local_alloc_stats.py`-style
' per-Local touch enumeration next, per revision D's own suggested approach at line ~142 above.
' Budget ran out before that census; this pass spent its time closing the one open thread
' revision E left rather than opening a new one half-finished.
'
' REVISION E -- pursued the revision D "MAJOR OPEN FINDING" (sub esp,0x54 vs
' 0x4C) to a precise, byte-verified characterisation of the frame-size gap. State
' UNCHANGED (still MISMATCH, first_diff=5, our_len==orig_len==15154, 49 gaps net to 0,
' 188 subs, harness.try_method/localise_diff.py re-run and confirm revision D numbers exactly)
' -- no source edit made this pass -- but the open finding is now MUCH more specific:
'
'   Enumerated EVERY distinct `[ebp-N]` stack-slot address referenced anywhere in the
'   FULL 15154-byte body on both sides (script: harness.disasm_original(0x004FF67C,15154)
'   vs bytematch.disasm_original() on the compiled probe's own VA via find_method(), both
'   parsed for every `ebp - <disp>]` operand). CAUTION for whoever re-runs this: Capstone
'   prints displacements 1-9 WITHOUT a "0x" prefix ("ebp - 4]", "ebp - 8]") but >=10 WITH
'   one ("ebp - 0x10]") -- a regex assuming `0x[0-9A-Fa-f]+` silently drops slots -4 and -8
'   from the count. (Cost this pass ~15 minutes the first time through; the corrected
'   regex is `ebp - (0x[0-9A-Fa-f]+|[0-9]+)\]`.)
'
'   RESULT: original uses all 21 slots -4,-8,-0xC,...,-0x54 (matching sub esp,0x54).
'   Ours uses exactly the first 19 of that same sequence, -4,-8,...,-0x4C (matching
'   sub esp,0x4C) -- a CLEAN SUPERSET, not a shifted/renumbered set: every depth ours uses
'   is also used in the original at the SAME numeric depth, and the original simply has
'   TWO MORE, at -0x50 and -0x54, that do not exist ANYWHERE in our build. (Note this does
'   NOT mean any individual variable's slot matches between the two builds by depth -- slot
'   depth is spill ORDER, section 22.2, and e.g. `local_30`'s very first spill already
'   differs, -0x2C original vs -0x28 ours, SUB 2 at orig_off+28 -- only the raggregate SET
'   of 19 depths is shared.)
'
'   Both extra slots identified and their content read directly from the original
'   disassembly (not guessed):
'     * -0x50 is `iVar4` itself, the `TCompetition.SelectById(g_fixture.compid)` result
'       (candidate line 297). First store at orig_off+705, immediately after the
'       `call dword ptr [eax+0xc0]` SelectById slot call (matches candidate line 297
'       exactly). Read again at +708/+735/+746 (the first Select iVar4.level cascade,
'       candidate lines 298-311), then AGAIN at +1691 (field+0x1c=level, matches the second
'       `Select iVar4.level` at candidate line 351) and AGAIN at +9536/+9580 (field+0x18=
'       locale then +0x1c=level, matches `iVar7 = iVar4.locale` / nested `iVar4.level` at
'       candidate lines 658/663/665) and AGAIN at +14219 (field+0x1c=level, matches the
'       THIRD `Select iVar4.level` at candidate line 849, the drug-test cascade). So this
'       one Local is read continuously from +705 to +14219 -- 13,514 bytes, 89% of the
'       function's length -- i.e. it plausibly has the largest block_count of any Local in
'       the body. That is exactly the S18.4/S22.1 signature of a spill victim (`cost =
'       usage/(degree*block_count)`; a huge block_count divides cost down regardless of
'       usage, see the `h` vs `wnum` case in TScreen_MatchPrep.CreateScreen). In OUR build
'       the very same statement (SelectById result store) lands at [ebp-0x48] instead --
'       confirmed by the identical call-then-store shape at our_off+696, right after our
'       `call dword ptr [eax+0xc0]` at +687 -- which is INSIDE the shared 19-slot set, not
'       one of the two novel ones. So our allocator spills iVar4 too, just much EARLIER in
'       its internal eviction order (rank ~16 of 19) than the original's (rank 20 of 21,
'       second-to-last). WHY our build's interference graph gives iVar4 a smaller effective
'       block_count/degree than the original's is NOT yet identified -- this needs a
'       statement-placement experiment (S22.3 lever 3), not more reading.
'     * -0x54 is a ONE-SHOT compiler temp, not a named Local at all: at orig_off+6475,
'       `idiv ecx` (an Int/Int division, `piVar5.matchstats.rating / 10`, candidate line
'       519's `If piVar5.matchstats.rating / 10 < 7.5 ...`) stores its quotient to
'       [ebp-0x54], and the VERY NEXT INSTRUCTION (+6478) is `fild dword ptr [ebp-0x54]` --
'       materialising the Int quotient to memory purely because x87's `fild` requires a
'       memory operand (it cannot load directly from an integer register). This slot is
'       touched nowhere else in the whole function. In principle this needs no source
'       change at all -- the same statement should force the same idiv-then-fild shape in
'       our build too -- so either (a) our build reuses an already-dead slot from the
'       shared 19-set for this same temp (plausible: its live range is one instruction wide,
'       trivially the cheapest thing in the whole function to coalesce with anything already
'       freed), which would make it a FALSE lead for "why 2 fewer slots", or (b) something
'       about how candidate line 519 is written avoids the memory round-trip. NOT
'       distinguished this pass -- would need our own disassembly at the equivalent
'       statement (candidate line 519, "rating / 10 < 7.5") read directly, which was not
'       reached before the time budget.
'
'   RULED OUT this pass: checked whether candidate line 656
'   (`TCompetition.SelectById(g_fixture.compid).IsCupFinal()`) SHOULD instead reuse
'   `iVar4.IsCupFinal()` -- it should not. Read the original directly at orig_off+9463:
'   `mov eax,[g_fixture] / push [eax+0x40] / call [0xc6160c]` is a FRESH call through the
'   IDENTICAL classtable+slot immediate (0xc6160c) as the first SelectById at +692 -- the
'   original genuinely re-fetches here too, exactly as the candidate already has it. Do
'   not "fix" this call; it was already correct. (This also means the S22.3 block_count
'   lever cannot be tried by ADDING a reference at this site -- it is not a missing
'   reference, the original plainly re-fetches.) The block_count lever therefore has to be
'   found somewhere else in iVar4's ~13.5 KB live range, or on the -0x54 temp's true cause
'   -- NEITHER located this pass.
'
' Candidate length: 15154 bytes  (delta 0 -- EXACT LENGTH MATCH, first time any
' revision has reached this). harness.try_method: mode='diff' now (lengths agree so the tool
' compares content), status still MISMATCH: first_divergence=3 (the prologue "sub esp,N"
' immediate itself differs -- see "MAJOR OPEN FINDING" below), 49 length-neutral gaps that
' net to zero, 188 same-length subs, 39 branch_shifts. NOT a MATCH. Worked across nine
' successive revisions; this file holds revision D's state, verified under NSS5_NO_LEARN=1.
'
' FIXED in revision D -- two isolated fixes, each confirmed by rebuilding the WHOLE 15KB
' function and reading harness.try_method's our_len directly:
'   1. orig_off 9536 (candidate lines 598-610, the CheckAchievement(23/24/25/86) cascade
'      keyed on "iVar7 = iVar4.locale"): was "If iVar7=0 ... ElseIf iVar7=1 ... ElseIf
'      iVar7=2 ... EndIf" (no final Else). Original's header is a classic Select signature
'      (S10.2): load iVar4.locale ONCE into eax, "cmp eax,0/je L0 / cmp eax,1/je L1 /
'      cmp eax,2/je L2 / jmp Lexit", 23 bytes, no reload between compares. Rewritten as
'      "Select iVar7 / Case 0 / Case 1 / Case 2 / End Select" (body of each Case unchanged).
'      Closed the -12 gap (delta -12 -> -8); a small downstream knock-on shifted the
'      separate -4@9580/+3@9640/-2@9680 trio into a -9@9580/-2@9638 pair
'      (net +2 further, all accounted for by localise_diff, zero regressions elsewhere --
'      confirmed the untouched gap list is otherwise byte-identical before/after).
'   2. orig_off 8745 and 8803 (candidate lines 538/541, "TPitch.MetresToPixels(20.0) <
'      puVar16.distance" / "...(30.0) < puVar16.distance", the CheckAchievement(92/93)
'      radar-pass-distance checks): each closed a -6 gap when the comparison was FLIPPED to
'      "puVar16.distance > TPitch.MetresToPixels(20.0/30.0)". Evidence: the original's FPU
'      sequence for both sites is "fld [distance]/fstp [temp] (spill BEFORE the call, 6
'      bytes) ... call MetresToPixels ... fld [temp] (reload, ST0=distance,ST1=result) /
'      fucompp / setbe" -- i.e. the LHS operand (distance) is evaluated and spilled to a
'      stack temp FIRST, then the call (RHS) runs, then the temp is reloaded for the
'      compare. That is exactly left-to-right evaluation of "distance > MetresToPixels(N)",
'      NOT of "MetresToPixels(N) < distance" (which would evaluate the call first). Our old
'      source (written as "call < distance") compiled as "call first, then fld distance,
'      fxch st(1) (2 bytes) to reorder, fucompp, setae" -- semantically identical (A<B ==
'      B>A) but a different, shorter instruction sequence. Flipping the source to match the
'      original's operand order (and therefore its evaluation order) reproduced the exact
'      fld/fstp/.../fld/fucompp/setbe shape byte-for-byte. Closed both -6 gaps in one pass
'      (12 bytes) after fixing 1 and finding it generalised immediately to the 2nd site.
' Combined effect: our_len 15142 -> 15154 (delta -12 -> 0), gap count 55 -> 49 (max_gaps=200).
' A THIRD candidate fix was tried and REVERTED: dropping "<> 0" from "IsCupFinal() <> 0 And
' g_fixture.matchtype <> 4" (candidate line 596) to bare "IsCupFinal() And ..." made our_len
' WORSE (15146 -> 15137, i.e. -9), so the "<> 0" spelling against a call result IS the
' original's shape there -- do not retry this without new evidence.
'
' MAJOR OPEN FINDING, NOT YET DIAGNOSED -- likely the highest-leverage lever left:
' Now that orig_len == our_len, the prologue itself differs: original "sub esp, 0x54" (84
' bytes = 21 dwords of frame) vs ours "sub esp, 0x4c" (76 bytes = 19 dwords). The original
' allocates a stack frame EXACTLY 2 dwords (8 bytes) larger than ours. This has been present
' since the earliest revisions -- it was always tracked as a same-length "sub" (not a "gap", since
' both encodings are 3 bytes: "83 EC 54" vs "83 EC 4C") and so was invisible to every earlier
' gap-only triage; it is orig_off 3, the very first entry in the 188-item sub list.
' Every pass's "our_len" arithmetic was correct in isolation, but this ONE structural
' mismatch (we are declaring, or the allocator is packing, 2 fewer dword-slots than the
' original's Local set requires) is a plausible root cause for a meaningful fraction of the
' remaining 188 subs: once the frame size is wrong, every later ebp-relative offset can
' legitimately still byte-match BY COINCIDENCE (small immediates re-landing on the same
' value) or legitimately mismatch, so this is NOT provably the cause of all 188, but it is
' the single most structural, most under-examined finding in the whole file and should be
' chased FIRST next pass, before any more one-off gap chasing. NOT investigated further here
' due to time budget -- no candidate missing Local identified yet. Approach for the next
' pass: use scripts/local_alloc_stats.py (reads the prologue's Local-slot layout) on both
' the original VA and our compiled body; enumerate every "Local" declaration actually
' present in this file (the file has several SAME-NAME Locals shadowed in nested scopes --
' e.g. iVar4/iVar7 at candidate lines 224-225 inside the "For Local piVar3" loop vs the
' outer iVar4 at line 237 and iVar7 at line 403 -- each textually distinct "Local" statement
' should already get its own slot under bcc's flat allocator, so the 2-slot deficit is more
' likely a genuinely MISSING declaration -- a Local the candidate source never introduced --
' than a shadowing bug). Do not guess-insert a filler Local; find it from the disassembly
' (a "mov [ebp-0xNN], ..." store to an offset our frame doesn't reach) the way every other
' fix in this file has been derived.
'
' FIXED in revision C (this pass) -- two clean, isolated fixes, both confirmed by rebuilding
' the WHOLE function and reading harness.try_method's our_len directly (no assumptions):
'   1. The six "If g_profile.<banfield> = 2" checks (baninternational x2, bancontinent x2,
'      banclub x2, at candidate lines 226/235/269/278/293/302) each closed a -5 gap when
'      rewritten "If g_profile.<banfield> - 1 = 1" -- confirmed against
'      object_model.json (TProfile 0x194=currentyellowsinternational, 0x198=banclub,
'      0x19c=bancontinent, 0x1a0=baninternational, all Int) and against the original's
'      disassembly, which reloads the field AFTER the :+3/:+2 increment, subtracts 1, and
'      compares to 1 (sub eax,1 / cmp eax,1) rather than comparing the field directly to 2
'      (our old form: cmp [field],2). Same integer semantics ("this is your SECOND ban"),
'      different bytes -- exactly the relational-spelling class of difference in
'      codegen-patterns.md S10.1/S21, just against a self-referencing threshold rather
'      than a literal. All 6 sites share one field cluster and one shape; fixing one and
'      grepping for the same literal (candidate line 16.6-style) generalised immediately.
'   2. "If g_profile.GetCurrentStats(cVar18) = Null" (candidate line 246, no Else) closed a
'      -9 gap when rewritten "If Not g_profile.GetCurrentStats(cVar18)" -- the original
'      spells this null-check via the "If Not x" LONG form (S10.3: setne/movzx/cmp/sete-
'      no, here just setne+movzx+cmp+jne since eax already holds the call result, 16
'      bytes) rather than the SHORT direct "cmp eax,addr/jne" form (7 bytes) our old
'      source produced. Both are semantically "if x is Null", but bcc spells "Not x" and
'      "x = Null" with different bytes even outside a compound Or (contra a naive reading
'      of S10.3, which only documented the two forms for object truth-tests, not for a
'      call-result compared to Null with no Else arm) -- so "x = Null" with a plain If/no-
'      Else is NOT always the short form; check the actual bytes, not just the shape.
' Both fixes verified independently: rebuilt the WHOLE 15KB function after each edit (not
' a probe), read our_len from a fresh harness.try_method call, confirmed the length delta
' matched the edit''s predicted byte count exactly before moving to the next candidate.
'
' NOT ATTEMPTED further this pass -- flagged for the next pass, in order of promise:
'   * insert +6 @ orig_off 6129 (candidate line ~355, the THIRD term of the rivalid1/2/3
'     Or-chain: "local_30.rivalid3 = local_28.id"). Full original disassembly read
'     (VA 0x004FF67C+5670, 500 bytes) alongside ours at the same point. FINDING: for the
'     FIRST TWO Or-terms (rivalid1, rivalid2), original and ours are IDENTICAL shape
'     (sete/movzx al, then at the shared landing label "cmp eax,0/jne <skip-rest>" with NO
'     intervening store -- true short-circuit Or). For the THIRD (last) term, ours ADDS a
'     redundant store+reload ("mov [ebp-0x3c],eax / mov eax,[ebp-0x3c]", 6 bytes) between
'     the movzx and the cmp/je that original does not have -- original tests eax directly,
'     then (only if the WHOLE Or is true) does a separate CONDITIONAL "mov
'     dword[ebp-0x4c],1" into bVar19''s real slot; ours appears to eagerly store the raw
'     last-term flag into bVar19''s slot before the final branch. Candidate line 355 is
'     already written as one flat "A Or B Or C" Local assignment, matching the apparent
'     source shape -- the difference is in HOW bcc treats the LAST disjunct specifically,
'     not a wrong statement. Not chased further; a source-level lever was not identified.
'   * -15 @ 6134 -- same rivalid1/2/3 construct, immediately downstream of the above; likely
'     shares one root cause with it (do not fix independently -- fix +6@6129 first and
'     re-measure before touching this one).
'   * -12 @ 9536, -9 x1 @ 5789, +9 x3 @ 6265/9492/9619, -7 @ 6058 -- not examined this pass.
'   * +58/-29/-29 @ 11225/11414/11623 (revision B S4) and +34/-31 @ 9388/9423 --
'     the two deep, already-diagnosed liveness/branch-graph clusters, unchanged.
'   * The four ~1-byte gaps at 10753/10880/11007/11116 (candidate lines 592/594/596/598,
'     the CREPORT_BOSSMOTM/GOOD/OK/POOR Rand(5,1) calls, confirmed via harness.read_string
'     on the literal operands 0xc7b038/b064/b090/b0b8): original passes Rand''s "max" arg
'     via a bare "push eax" (1 byte) where ours emits "push 5" (2 bytes, "6A 05"). Traced
'     eax''s origin backward -- it is NOT recomputed in this arm at all; it is whatever
'     value survives from an EARLIER, unrelated code path (the arm at VA 0x0050205C is a
'     jump target, not fallthrough), so eax coincidentally already holds 5 there in the
'     original. This is a register-liveness accident, not a source-text difference our
'     Rand(5,1) can be rewritten to reproduce -- flagging so the next pass does not
'     re-derive this, but not a promising lever (4 bytes total across 4 sites).
'
' scripts/localise_diff.py TPlayer.RecordPlayerStats <this file>, NSS5_NO_LEARN=1,
' localise_body(..., max_gaps=200) [use max_gaps>=100 -- even 20-30 truncates this body's
' real tail] reports delta_accounted COMPLETE at -12, 55 gaps (revision C state). Full list
' by |delta| descending -- see "NOT ATTEMPTED further this pass" above for the ones with
' evidence attached; the rest are the untouched the earlier tail plus a scatter of
' +-1/+-2 byte residuals (10320,775,9580,6007,9640,12146,735,746,5833,6014,6364,8765,8823,
' 9680,11827,12126,5674,6036,6391,9362,10518, and eleven ~30-bytes-apart +1 gaps at
' 10753/10880/11007/11116/11856/11886/11916/11946/11976/12006/12036/12066/12096 --
' the last four of which are the Rand(5,1) liveness accident above and the rest not yet
' traced individually, though the identical +1 spacing suggests they may be more instances
' of the same accident, unconfirmed):
'     +173/-173 @ +6625/+6733  -- ARTEFACT, net zero, do not chase as length
'     +58       @ +11225        -- see "OPEN (deep)" below: same root cause as the two
'                                  -29 gaps, NOT independently fixable
'     +34/-31   @ +9388/+9423   -- iVar7 live-range problem: must stay in ebx across
'                                  WinningTeam:/MyTeam: LogLines AND into IntToString, no reload.
'                                  Every Local in this region (iVar7,iVar8,iVar10..15) is reused
'                                  dozens of times downstream -- a blind guess risks moving
'                                  several registers at once.
'     -29 x2    @ +11414,+11623 -- see "OPEN (deep)" below
'     -15       @ +6134         -- rivalid1/2/3 Or-chain, downstream of the +6@6129 finding above
'     -12       @ +9536         -- not examined
'     +10       @ +5820         -- not examined
'     +6        @ +6129         -- rivalid3 (3rd Or-term) redundant store+reload, see revision C
'                                  finding above (full evidence, no source-level fix found yet)
'     -9        @ +5789         -- not examined
'     +9 x3     @ +6265,+9492,+9619 -- not examined, may share one root cause (same delta)
'     -7        @ +6058         -- not examined
'     +3        @ +12146        -- residual of the revision B Select fix: original keeps the Select
'                                  subject (iVar8) live in eax across the whole preceding
'                                  max-computation cascade AND into the Select header; ours
'                                  spills it to [ebp-0x14] and reloads with one extra
'                                  "mov eax,[ebp-0x14]" (3 bytes) right before the cmp cascade.
'                                  Pure register-allocation residual (S18) -- NOT a logic gap.
' CONFIRMED (re-measured revision C, do not re-derive): "-9 @ 2774" is CLOSED (fix 2's "If Not
' x" rewrite applies to it too -- same GetCurrentStats-shaped Null check). "-9/+9/-9 @
' 488/508/514" (the piVar17=Null Or ...rating<...rating MOTM-loop double-negate triplet,
' candidate line 149) is STILL OPEN -- confirmed present in the revision C gap list by direct
' offset lookup. It is a DIFFERENT shape from fix 2 (a double setne+movzx+cmp+sete+movzx+
' cmp idiom on ONE relational term of a compound Or, not a solitary Null check with no
' Else), so fix 2's rewrite does not generalise to it -- do not assume it is closed.
'
' FIXED in revision B (this pass) -- the iVar8 "GOODFREEKICKS..GOODPENALTIES" cascade
' (candidate lines ~600-622, "If iVar7 > 5 / If iVar8=1 ... ElseIf iVar8=2 ... ElseIf
' iVar8=10 / EndIf") is a Select/Case in the original, exactly like revision A's iVar4.level
' fix -- proven by the classic Select signature (S10.2): original loads iVar8 ONCE then
' emits ALL 10 "cmp eax,N / je Ln" back-to-back with a single trailing "jmp <shared-exit>"
' for the no-match case, whereas our If/ElseIf form re-tested at the top of EVERY arm
' (an extra "cmp [stack],N / jne next" INSERTED at the start of all 9 later arms -- 9
' gaps of +6 bytes each, 12321/12405/12489/12573/12657/12741/12825/12909/12990) and also
' spilled the selector across the whole cascade (contributing to the old -85 gap at
' 12146). Rewriting as "Select iVar8 / Case 1 ... Case 10 / End Select" closed ALL 9 of
' the +6 gaps outright and shrank the old -85 gap to a mere +3 (see above -- a pure
' register-allocation residual, not a structural one). Also closed one more, then-
' unlisted "-2 @ 13069" gap as a side effect (same construct's tail). Net: -87 -> -51,
' verified twice (build, then a fresh independent harness.try_method call before writing
' this header), zero regressions (old gap list is a strict superset of the new one).
'
' OPEN (deep) -- +58@11225 and -29 x2@11414,11623 are ONE root cause, not three.
' These bracket the nested nested-If at candidate lines ~490-508:
'   If piVar5.matchstats.CountStat(6) < 7
'       If piVar5.matchstats.CountStat(17) < 10
'           If piVar5.matchstats.CountStat(3) > 14 ... (GOODPASSING/HOWEVER)
'       ElseIf rating>65 ... Else ... EndIf   (GOODTACKLING/HOWEVER)
'   ElseIf rating>65 ... Else ... EndIf        (GOODHEADING/HOWEVER)
' Original does NOT compile this as nested nested-If. Evidence (harness.disasm_original
' via localise_diff, context>=15):
'   - the CountStat(6) comparison in the original is "cmp eax,6 / jle <false>" (immediate
'     6, jle) where ours emits "cmp eax,7 / jge <false>" (immediate 7, jge) for the
'     literal source text "CountStat(6) < 7" -- SAME semantics for integers, DIFFERENT
'     bytes (S10.1: match the setcc/immediate exactly, not the meaning). The original's
'     true-branch condition is spelled "> 6", not "< 7".
'   - the CountStat(6) false-branch target in the original is NOT the GOODHEADING code
'     directly -- it falls straight into the CountStat(17) test's code (offset +11225),
'     i.e. no separate "ElseIf" reload of anything; the two tests are laid out as
'     sequential fallthrough, not nested blocks.
'   - the CountStat(17) test in the original is "cmp eax,9 / jle <target>" (immediate 9)
'     for source text "CountStat(17) < 10" -- again ">9" not "<10" spelling, and its
'     FALSE target (+11443, cmp[eax+0x28],0x41) is the same code block that appears
'     after the CountStat(6) false-path in OUR build today -- i.e. the original reuses
'     ONE shared "field+0x28 / GOODTACKLING-or-HOWEVER" block as the fallthrough/false
'     target of BOTH the CountStat(6) and (indirectly) CountStat(17) tests, not two
'     separate copies the way nested-If naturally would (unless bcc's shared-tail-merge
'     applies -- unconfirmed).
'   - the CountStat(3) test is "cmp eax,0xe / jle 0x5024af" (immediate 14, jle) where
'     0x5024af is the OUTER construct's shared exit (skips straight past the whole
'     three-level nest with NO GOODPASSINGHOWEVER fallback) -- so "> 14" with NO
'     corresponding Else arm reachable via this path; the Else (GOODPASSINGHOWEVER) must
'     be reached some other way not yet located, or the source nesting itself differs
'     from what candidate lines 490-508 currently encode.
' This needs a full re-derivation of the branch target graph for this whole block
' (all six literals: GOODPASSING, GOODPASSINGHOWEVER, GOODTACKLING, GOODTACKLINGHOWEVER,
' GOODHEADING, GOODHEADINGHOWEVER) before touching the source -- a partial rewrite risks
' moving the -58/+29/+29 delta without closing it. NOT attempted this pass; flagging with
' full evidence so the next pass does not have to re-find these three call sites.
'
' FIXED in revision A:
'   1. bossreport=GetText(...) for CREPORT_BOSSMOTM/GOOD/OK/POOR (candidate lines ~482-488)
'      is actually wrapped in DoNews(text,local_30,local_28,0,0) -- confirmed by the call
'      shape (slot 0x80 = TProfile.DoNews) and by harness.read_string() on all four literals.
'      Closed 8 gaps, +116 bytes, first attempt.
'   2. "If iVar4.level = 1 ... ElseIf iVar4.level = 0 ... EndIf" (candidate lines ~109 and
'      ~605, both with NO final Else) is a Select/Case in the original -- proven by the
'      single-field-load-then-two-compares signature (S10.2 of codegen-patterns.md) versus
'      our reload-per-test shape. TCompetition field 0x1c = level, confirmed from
'      object_model.json. Closed 4 gaps, +2 net bytes (offset by unrelated pre-existing
'      gaps elsewhere -- see report), zero regressions.
' =================================================================================================
'
'!Global g_fixture:TFixture
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_playerlist:TList
'!Global g_profile:TProfile
'!Global g_playtimearg:Int
'!Global g_matchcontext:Int
'!Global g_appcount_a:Int
'!Global g_appcount_b:Int
' CASE DIRECTION CORRECTED 2026-08-22: 2 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
LogLine("RecordPlayerStats")
TPlayer.UpdateMatchRatingAll()
Local local_30:TBase_Team
Local local_28:TBase_Team
Select g_fixture.level
	Case 0
		local_30 = TClub.SelectById(g_fixture.GetHomeTeamId())
		local_28 = TClub.SelectById(g_fixture.GetAwayTeamId())
	Case 1
		local_30 = TNation.SelectById(g_fixture.GetHomeTeamId())
		local_28 = TNation.SelectById(g_fixture.GetAwayTeamId())
End Select
Local local_48:Int = g_fixture.score1
Local local_40:Int = g_fixture.score2
Local piVar17:TPlayer = Null
For Local piVar3:TPlayer = EachIn g_playerlist
	If piVar3.newstar And piVar3.GetMyTeam() = g_awayteam
		local_48 = g_fixture.score2
		local_40 = g_fixture.score1
		Select g_fixture.level
			Case 0
				local_30 = TClub.SelectById(g_fixture.GetAwayTeamId())
				local_28 = TClub.SelectById(g_fixture.GetHomeTeamId())
			Case 1
				local_30 = TNation.SelectById(g_fixture.GetAwayTeamId())
				local_28 = TNation.SelectById(g_fixture.GetHomeTeamId())
		End Select
	EndIf
	piVar3.matchstats.motm = 0
	If Not piVar17 Or piVar3.matchstats.rating > piVar17.matchstats.rating
		piVar17 = piVar3
	ElseIf piVar3.matchstats.rating = piVar17.matchstats.rating
		Local iVar4:Int = piVar3.matchstats.CountStat(5)
		Local iVar7:Int = piVar17.matchstats.CountStat(5)
		If iVar4 > iVar7
			piVar17 = piVar3
		ElseIf iVar4 = iVar7
			If piVar3.matchstats.distance > piVar17.matchstats.distance
				piVar17 = piVar3
			EndIf
		EndIf
	EndIf
Next
piVar17.matchstats.motm = 1
Local cVar18:Int = 0
Local iVar4:TCompetition = TCompetition.SelectById(g_fixture.compid)
Select iVar4.level
	Case 1
		cVar18 = 4
	Case 0
		Select iVar4.locale
		Case 1
			cVar18 = 2
		Default
			Select iVar4.comptype
			Case 1
				cVar18 = 1
			Default
				cVar18 = 0
			End Select
		End Select
End Select
Local piVar5:TPlayer = TPlayer.GetHumanPlayer()
If piVar5 <> Null
	LogLine("Player Found: " + piVar5.name)
	Select g_matchcontext
		Case 1
			g_appcount_a :+ 1
		Case 2
		Case 3
			g_appcount_b :+ 1
	End Select
	If piVar5.matchstats.rating < 80
		piVar5.matchstats.motm = 0
	EndIf
	If piVar5.GetMyTeam().rating < piVar5.GetOppTeam().rating - 15 And local_48 = local_40
		piVar5.matchstats.motm = 0
	EndIf
	If piVar5.GetMyTeam().rating < piVar5.GetOppTeam().rating - 5 And local_48 < local_40
		piVar5.matchstats.motm = 0
	EndIf
	If piVar5.matchstats.rating > 80 And local_48 > local_40
		g_profile.interviewchance = 1
	EndIf
	If piVar5.matchstats.distance > 0.0
		g_profile.WearBoots()
	EndIf
	g_profile.newsheadline = Left(g_hometeam.name.ToUpper(),9) + " " + g_fixture.score1 + " - " + g_fixture.score2 + " " + Left(g_awayteam.name.ToUpper(),9)
	g_profile.newsrating = piVar5.matchstats.rating
	g_profile.newsmotm = piVar5.matchstats.motm
	If piVar5.matchstats.reds > 0
		g_profile.coachreport = GetText("CREPORT_COACHRED")
	ElseIf piVar5.matchstats.yellows = 1
		If g_profile.GotSponsor()
			g_profile.coachreport = GetText("CREPORT_COACHYELLOWSPONSORS")
		Else
			g_profile.coachreport = GetText("CREPORT_COACHYELLOW")
		EndIf
	ElseIf piVar5.matchstats.yellows = 2
		g_profile.coachreport = GetText("CREPORT_COACHYELLOWS")
	EndIf
	Select iVar4.level
	Case 1
		g_profile.GetCurrentStats(cVar18).UpdateStats(piVar5.matchstats)
		g_profile.currentyellowsinternational :+ piVar5.matchstats.yellows
		If piVar5.matchstats.yellows = 2 Or piVar5.matchstats.reds > 0
			g_profile.baninternational :+ 3
			g_profile.currentyellowsinternational = 0
			If g_profile.baninternational - 1 = 1
				g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_international")).Replace("$num",String(g_profile.baninternational - 1))
			Else
				g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_international")).Replace("$num",String(g_profile.baninternational - 1))
			EndIf
		EndIf
		If g_profile.currentyellowsinternational > 4
			g_profile.baninternational :+ 2
			g_profile.currentyellowsinternational = 0
			If g_profile.baninternational - 1 = 1
				g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_international")).Replace("$num",String(g_profile.baninternational - 1))
			Else
				g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_international")).Replace("$num",String(g_profile.baninternational - 1))
			EndIf
		Else
			If piVar5.matchstats.yellows = 1 And g_profile.currentyellowsinternational = 1
				g_profile.coachreport :+ " " + GetText("CREPORT_COACHBANIMMINENT").Replace("$matchtype",GetText("matchtype_international"))
			EndIf
		EndIf
	Case 0
		If Not g_profile.GetCurrentStats(cVar18)
			LogLine("No stats:" + cVar18)
			Return 0
		EndIf
		g_profile.GetCurrentStats(cVar18).UpdateStats(piVar5.matchstats)
		g_profile.GetCurrentStats(3).UpdateStats(piVar5.matchstats)
		g_profile.thisweeksassistbonus = g_profile.thisweeksassistbonus + piVar5.matchstats.CountStat(4) * g_profile.contractassistbonus
		g_profile.thisweeksgoalbonus = g_profile.thisweeksgoalbonus + piVar5.matchstats.CountStat(5) * g_profile.contractgoalbonus
		Select piVar5.GetMyTeam()
			Case g_hometeam
				If g_fixture.score1 = 0
					g_profile.thisweekscleanbonus :+ g_profile.contractassistbonus
				EndIf
			Case g_awayteam
				If g_fixture.score2 = 0
					g_profile.thisweekscleanbonus :+ g_profile.contractassistbonus
				EndIf
		End Select
		If cVar18 = 2
			g_profile.currentyellowscontinent :+ piVar5.matchstats.yellows
			If piVar5.matchstats.yellows = 2 Or piVar5.matchstats.reds > 0
				g_profile.bancontinent :+ 3
				g_profile.currentyellowscontinent = 0
				If g_profile.bancontinent - 1 = 1
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_continental")).Replace("$num",String(g_profile.bancontinent - 1))
				Else
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_continental")).Replace("$num",String(g_profile.bancontinent - 1))
				EndIf
			EndIf
			If g_profile.currentyellowscontinent > 2
				g_profile.bancontinent :+ 2
				g_profile.currentyellowscontinent = 0
				If g_profile.bancontinent - 1 = 1
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_continental")).Replace("$num",String(g_profile.bancontinent - 1))
				Else
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_continental")).Replace("$num",String(g_profile.bancontinent - 1))
				EndIf
			Else
				If piVar5.matchstats.yellows = 1 And g_profile.currentyellowscontinent = 1
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBANIMMINENT").Replace("$matchtype",GetText("matchtype_continental"))
				EndIf
			EndIf
		Else
			g_profile.currentyellowsclub :+ piVar5.matchstats.yellows
			If piVar5.matchstats.yellows = 2 Or piVar5.matchstats.reds > 0
				g_profile.banclub :+ 3
				g_profile.currentyellowsclub = 0
				If g_profile.banclub - 1 = 1
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_club")).Replace("$num",String(g_profile.banclub - 1))
				Else
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_club")).Replace("$num",String(g_profile.banclub - 1))
				EndIf
			EndIf
			If g_profile.currentyellowsclub > 4
				g_profile.banclub :+ 2
				g_profile.currentyellowsclub = 0
				If g_profile.banclub - 1 = 1
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN1").Replace("$matchtype",GetText("matchtype_club")).Replace("$num",String(g_profile.banclub - 1))
				Else
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_club")).Replace("$num",String(g_profile.banclub - 1))
				EndIf
			Else
				If piVar5.matchstats.yellows = 1 And g_profile.currentyellowsclub = 4
					g_profile.coachreport :+ " " + GetText("CREPORT_COACHBANIMMINENT").Replace("$matchtype",GetText("matchtype_club"))
				EndIf
			EndIf
		EndIf
	End Select
	If cVar18 = 4 And local_48 > local_40
		g_profile.UpdateRelationship(6,3)
		g_profile.coachrep_sponsors :+ 3
	EndIf
	If piVar5.matchstats.motm <> 0
		g_profile.UpdateRelationship(6,3)
		g_profile.coachrep_sponsors :+ 3
		If g_profile.GetAge() = 16 And Rand(4,1) = 1
			g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHSTARMANYOUNG" + Rand(5,1)),local_30,local_28,0,0)
		Else
			g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHSTARMAN" + Rand(15,1)),local_30,local_28,0,0)
		EndIf
		g_profile.coachrep_fame = g_profile.coachrep_fame + g_profile.UpdateRelationship(7,3)
	ElseIf piVar5.matchstats.rating < 65
		g_profile.UpdateRelationship(6,-2)
		g_profile.coachrep_sponsors :- 1
	EndIf
	Local iVar7:Int = piVar5.matchstats.GetPlayTime(g_playtimearg)
	Local iVar8:Int = piVar5.matchstats.CountStat(4)
	Local iVar10:Int = piVar5.matchstats.CountStat(3)
	Local iVar11:Int = piVar5.matchstats.CountStat(2)
	Local iVar12:Int = piVar5.matchstats.CountStat(5)
	Local iVar13:Int = piVar5.matchstats.CountStat(11)
	Local iVar14:Int = piVar5.matchstats.CountStat(7) + piVar5.matchstats.CountStat(8)


	If iVar13 + iVar14 = 0
		piVar5.AddPlayerRating(7,-5,"")
	ElseIf iVar13 = 0
		piVar5.AddPlayerRating(7,-2,"")
	ElseIf iVar13 + iVar14 < 4
		piVar5.AddPlayerRating(7,-1,"")
	EndIf
	Local local_8:Int = piVar5.matchstats.rating / 10 - 6
	g_profile.UpdateRelationship(1,local_8)
	g_profile.coachrep_boss :+ local_8
	local_8 :+ (iVar14 + iVar13) * 2 - 6
	ClampInt(Varptr local_8,-5,5)
	If iVar7 < 45
		ClampInt(Varptr local_8,-3,5)
	EndIf
	Local bVar19:Int = False
	If local_30.rivalid1 = local_28.id Or local_30.rivalid2 = local_28.id Or local_30.rivalid3 = local_28.id
		bVar19 = True
	EndIf
	Local bVar20:Int = bVar19 And (iVar12 > 0 Or iVar8 > 0)
	If bVar20
		local_8 = local_8 + 1
	EndIf
	If local_48 > local_40
		local_8 = local_8 + 1
		If bVar19
			local_8 = local_8 + 1
		EndIf
	ElseIf local_48 < local_40
		local_8 = local_8 - 1
		If local_30.id = g_hometeam.id
			local_8 = local_8 - 1
		EndIf
		If bVar19
			local_8 = local_8 - 1
		EndIf
	EndIf
	If piVar5.matchstats.motm And local_8 < 1
		local_8 = 1
	EndIf
	ClampInt(Varptr local_8,-5,5)
	g_profile.UpdateRelationship(3,local_8)
	g_profile.coachrep_fans :+ local_8
	local_8 = iVar8 * 2 + iVar12 * 2 + (iVar10 - 5)
	ClampInt(Varptr local_8,-5,5)
	If iVar7 < 45
		ClampInt(Varptr local_8,-3,5)
	EndIf
	g_profile.UpdateRelationship(2,local_8)
	g_profile.coachrep_team :+ local_8
	If piVar5.matchstats.rating / 10 < 7.5 And iVar11 > 5 And iVar12 = 0
		g_profile.UpdateRelationship(2,-2)
		g_profile.coachrep_team :- 2
		g_profile.UpdateRelationship(3,-2)
		g_profile.coachrep_fans :- 2
		g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHSHOTS" + Rand(5,1)),local_30,local_28,0,0)
	EndIf
	If iVar13 > iVar14 / 2
		g_profile.UpdateRelationship(6,-2)
		g_profile.coachrep_sponsors :- 2
		If iVar13 > 5
			g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHFOULS" + Rand(5,1)),local_30,local_28,0,0)
		EndIf
	EndIf
	Local iVar22:Int = piVar5.matchstats.CountStat(9)
	Local iVar21:Int = piVar5.matchstats.CountStat(10)
	If iVar21 > 0
		g_profile.UpdateRelationship(6,-10)
		g_profile.coachrep_sponsors :- 10
		g_profile.UpdateRelationship(1,-10)
		g_profile.coachrep_boss :- 10
		g_profile.UpdateRelationship(2,-10)
		g_profile.coachrep_team :- 10
		g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHREDCARD" + Rand(5,1)),local_30,local_28,0,0)
	Else
		If iVar22 > 0
			g_profile.UpdateRelationship(6,-5)
			g_profile.coachrep_sponsors :- 5
			g_profile.UpdateRelationship(1,-3)
			g_profile.coachrep_boss :- 3
			g_profile.UpdateRelationship(2,-1)
			g_profile.coachrep_team :- 1
		EndIf
	EndIf
	If cVar18 = 4
		If g_profile.GetStat(12,4,0,0) = 1
			If piVar5.matchstats.motm <> 0
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_INTDEBUT_MOTM"),local_30,local_28,0,0)
			ElseIf iVar21 > 0
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_INTDEBUT_REDCARD"),local_30,local_28,0,0)
			ElseIf piVar5.matchstats.rating > 80
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_INTDEBUT_GOOD"),local_30,local_28,0,0)
			ElseIf piVar5.matchstats.rating > 55
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_INTDEBUT_AVERAGE"),local_30,local_28,0,0)
			Else
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_INTDEBUT_POOR"),local_30,local_28,0,0)
			EndIf
		EndIf
	Else
		If g_profile.GetStat(12,3,g_profile.clubid,0) = 1
			If piVar5.matchstats.motm <> 0
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DEBUT_MOTM" + Rand(4,1)),local_30,local_28,0,0)
			ElseIf iVar21 > 0
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DEBUT_REDCARD"),local_30,local_28,0,0)
			ElseIf piVar5.matchstats.rating > 80
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DEBUT_GOOD" + Rand(2,1)),local_30,local_28,0,0)
			ElseIf piVar5.matchstats.rating > 55
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DEBUT_AVERAGE" + Rand(2,1)),local_30,local_28,0,0)
			Else
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DEBUT_POOR" + Rand(2,1)),local_30,local_28,0,0)
			EndIf
		EndIf
	EndIf
	If cVar18 <> 4
		If iVar12 > 0
			g_profile.CheckAchievement(1)
		EndIf
		If iVar12 > 2
			g_profile.CheckAchievement(2)
		EndIf
		If g_profile.GetStat(5,3,0,0) > 49.0
			g_profile.CheckAchievement(3)
		EndIf
		If g_profile.GetStat(5,3,0,0) > 99.0
			g_profile.CheckAchievement(4)
		EndIf
	EndIf
	For Local puVar16:TStat = EachIn piVar5.matchstats.list
		If puVar16.stype = 5
			If puVar16.distance > TPitch.MetresToPixels(20.0)
				g_profile.CheckAchievement(92)
			EndIf
			If puVar16.distance > TPitch.MetresToPixels(30.0)
				g_profile.CheckAchievement(93)
			EndIf
		EndIf
	Next
	If local_40 = 0
		g_profile.CheckAchievement(5)
	EndIf
	If iVar8 > 0
		g_profile.CheckAchievement(6)
	EndIf
	If iVar8 > 2
		g_profile.CheckAchievement(7)
	EndIf
	If iVar14 > 4
		g_profile.CheckAchievement(8)
	EndIf
	If iVar14 > 9
		g_profile.CheckAchievement(9)
	EndIf
	If iVar14 > 14
		g_profile.CheckAchievement(10)
	EndIf
	If iVar10 > 9
		g_profile.CheckAchievement(11)
	EndIf
	If iVar10 > 19
		g_profile.CheckAchievement(12)
	EndIf
	If iVar10 > 29
		g_profile.CheckAchievement(13)
	EndIf
	If cVar18 = 0 And local_48 > local_40
		g_profile.CheckAchievement(18)
	EndIf
	If cVar18 = 1 And local_48 > local_40
		g_profile.CheckAchievement(19)
	EndIf
	If cVar18 = 2 And local_48 > local_40
		g_profile.CheckAchievement(20)
	EndIf
	If cVar18 = 4 And local_48 > local_40
		g_profile.CheckAchievement(21)
	EndIf
	If local_48 > local_40 + 4
		g_profile.CheckAchievement(22)
	EndIf
	Local iVar9:Int = g_fixture.GetWinningTeamId()
	Local iVar27:Int = g_profile.clubid
	If g_fixture.level = 1
		iVar27 = g_profile.nationid
	EndIf
	LogLine("WinningTeam:" + iVar9)
	LogLine("MyTeam:" + iVar27)
	If iVar9 = iVar27
		If TCompetition.SelectById(g_fixture.compid).IsCupFinal() And g_fixture.matchtype <> 4
			LogLine("CupFinal")
			Local iVar23:Int = iVar4.locale
			Select iVar23
				Case 0
					g_profile.CheckAchievement(23)
				Case 1
					Select iVar4.level
						Case 0
							g_profile.CheckAchievement(24)
						Case 1
							g_profile.CheckAchievement(25)
					End Select
				Case 2
					g_profile.CheckAchievement(25)
					g_profile.CheckAchievement(86)
			End Select
		EndIf
	EndIf
	If cVar18 <> 4
		If g_profile.GetStat(12,3,g_profile.clubid,0) > 99.0
			g_profile.CheckAchievement(87)
		EndIf
		If g_profile.GetStat(12,3,g_profile.clubid,0) > 199.0
			g_profile.CheckAchievement(88)
		EndIf
		If g_profile.GetAverageForm(3,0,0) >= 10.0
			g_profile.CheckAchievement(85)
		EndIf
	Else
		g_profile.CheckAchievement(29)
		If g_profile.GetStat(12,4,0,0) > 49.0
			g_profile.CheckAchievement(30)
		EndIf
		If g_profile.GetStat(12,4,0,0) > 99.0
			g_profile.CheckAchievement(31)
		EndIf
		If iVar12 > 0
			g_profile.CheckAchievement(32)
		EndIf
		If iVar12 > 2
			g_profile.CheckAchievement(33)
		EndIf
		If g_profile.GetStat(5,4,0,0) > 49.0
			g_profile.CheckAchievement(34)
		EndIf
		If g_profile.GetStat(5,4,0,0) > 99.0
			g_profile.CheckAchievement(35)
		EndIf
		If g_profile.GetAverageForm(4,0,0) >= 10.0
			g_profile.CheckAchievement(85)
		EndIf
	EndIf
	Local iVar25:Int = 5
	If iVar21 <> 0
		If piVar5.matchstats.rating > 85
			g_profile.bossreport = GetText("CREPORT_BOSSREDCARDGOOD")
		ElseIf piVar5.matchstats.rating > 65
			g_profile.bossreport = GetText("CREPORT_BOSSREDCARDOK")
		Else
			g_profile.bossreport = GetText("CREPORT_BOSSREDCARDBAD")
		EndIf
	ElseIf g_profile.injury <> 0
		If piVar5.matchstats.rating > 85
			g_profile.bossreport = GetText("CREPORT_BOSSINJURYGOOD")
		ElseIf piVar5.matchstats.rating > 65
			g_profile.bossreport = GetText("CREPORT_BOSSINJURYOK")
		Else
			g_profile.bossreport = GetText("CREPORT_BOSSINJURYBAD")
		EndIf
	ElseIf piVar5.matchstats.motm <> 0
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSMOTM" + Rand(iVar25,1)),local_30,local_28,0,0)
	ElseIf piVar5.matchstats.rating > 85
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSGOOD" + Rand(iVar25,1)),local_30,local_28,0,0)
	ElseIf piVar5.matchstats.rating > 65
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSOK" + Rand(iVar25,1)),local_30,local_28,0,0)
	Else
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSPOOR" + Rand(iVar25,1)),local_30,local_28,0,0)
	EndIf
	If piVar5.matchstats.CountStat(6) > 6
		If piVar5.matchstats.rating > 65
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODHEADING")
		Else
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODHEADINGHOWEVER")
		EndIf
	ElseIf piVar5.matchstats.CountStat(17) > 9
		If piVar5.matchstats.rating > 65
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODTACKLING")
		Else
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODTACKLINGHOWEVER")
		EndIf
	ElseIf piVar5.matchstats.CountStat(3) > 14
		If piVar5.matchstats.rating > 65
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODPASSING")
		Else
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODPASSINGHOWEVER")
		EndIf
	EndIf
	Local iVar26:Int = 0
	Local iVar24:Int = 0
	If g_profile.temp_positioning > iVar26
		iVar26 = g_profile.temp_positioning
		iVar24 = 4
	EndIf
	If g_profile.temp_shortpassing > iVar26
		iVar26 = g_profile.temp_shortpassing
		iVar24 = 5
	EndIf
	If g_profile.temp_longpassing > iVar26
		iVar26 = g_profile.temp_longpassing
		iVar24 = 6
	EndIf
	If g_profile.temp_aggression > iVar26
		iVar26 = g_profile.temp_aggression
		iVar24 = 7
	EndIf
	If g_profile.temp_longshots > iVar26
		iVar26 = g_profile.temp_longshots
		iVar24 = 8
	EndIf
	If g_profile.temp_finishing > iVar26
		iVar26 = g_profile.temp_finishing
		iVar24 = 9
	EndIf
	If g_profile.temp_crossing > iVar26
		iVar26 = g_profile.temp_crossing
		iVar24 = 3
	EndIf
	If g_profile.temp_freekicks > iVar26
		iVar26 = g_profile.temp_freekicks
		iVar24 = 1
	EndIf
	If g_profile.temp_corners > iVar26
		iVar26 = g_profile.temp_corners
		iVar24 = 2
	EndIf
	If g_profile.temp_penalties > iVar26
		iVar26 = g_profile.temp_penalties
		iVar24 = 10
	EndIf
	If iVar26 > 5
		Select iVar24
			Case 1
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODFREEKICKS")
			Case 2
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODCORNERS")
			Case 3
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODCROSSING")
			Case 4
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODPOSITIONING")
			Case 5
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODSHORTPASSING")
			Case 6
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODLONGPASSING")
			Case 7
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODAGGRESSION")
			Case 8
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODLONGSHOTS")
			Case 9
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODFINISHING")
			Case 10
				g_profile.bossreport :+ " " + GetText("CREPORT_GOODPENALTIES")
		End Select
	EndIf
	If bVar19
		If local_48 > local_40
			If g_profile.coachrep_fans > 0
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWEWONGOOD" + Rand(2,1))
			Else
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWEWONBAD" + Rand(2,1))
			EndIf
		ElseIf local_48 < local_40
			If g_profile.coachrep_fans > 0
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWELOSTGOOD" + Rand(2,1))
			Else
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWELOSTBAD" + Rand(2,1))
			EndIf
		EndIf
	Else
		If g_profile.coachrep_fans < -1 And Rand(3,1) = 1 And iVar12 = 0
			g_profile.bossreport :+ " " + GetText("CREPORT_FANSLOW" + Rand(2,1))
		ElseIf g_profile.coachrep_team < -1 And Rand(3,1) = 1
			g_profile.bossreport :+ " " + GetText("CREPORT_TEAMLOW" + Rand(2,1))
		EndIf
	EndIf
	If g_profile.drugs > 0 And g_profile.physioreport <> "" And Rand(50,1) = 1
		If g_profile.drugs = 0
			g_profile.physioreport = GetText("CREPORT_PHYSIODRUGSTESTGOOD")
		Else
			g_profile.drugs = 99
			g_profile.physioreport = GetText("CREPORT_PHYSIODRUGSTESTBAD")
			g_profile.coachrep_boss :+ -50
			g_profile.coachrep_team :+ -30
			g_profile.coachrep_fans :+ -30
			g_profile.coachrep_sponsors :+ -50
			Select iVar4.level
			Case 1
				g_profile.baninternational :+ 5
				g_profile.bossreport = GetText("CREPORT_BOSSDRUGSTESTBAD")
				g_profile.coachreport = GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_international")).Replace("$num",String(g_profile.baninternational - 1))
				g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DRUGTESTFAIL"),local_30,Null,0,g_profile.baninternational - 1)
			Case 0
				If cVar18 = 2
					g_profile.bancontinent :+ 5
					g_profile.bossreport = GetText("CREPORT_BOSSDRUGSTESTBAD")
					g_profile.coachreport = GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_continental")).Replace("$num",String(g_profile.bancontinent - 1))
					g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DRUGTESTFAIL"),local_30,Null,0,g_profile.bancontinent - 1)
				Else
					g_profile.banclub :+ 5
					g_profile.bossreport = GetText("CREPORT_BOSSDRUGSTESTBAD")
					g_profile.coachreport = GetText("CREPORT_COACHBAN2").Replace("$matchtype",GetText("matchtype_club")).Replace("$num",String(g_profile.banclub - 1))
					g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_DRUGTESTFAIL"),local_30,Null,0,g_profile.banclub - 1)
				EndIf
			End Select
		EndIf
	EndIf
EndIf
g_profile.ShowRatingChanges()
g_profile.UpdateMyRatings()

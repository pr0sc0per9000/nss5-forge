' =========================== NOT VERIFIED -- DO NOT COUNT AS MATCHED ===========================
' TPlayer.RecordPlayerStats   VA 0x004FF67C   original length 15154 bytes
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
	If piVar17 = Null Or piVar17.matchstats.rating < piVar3.matchstats.rating
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
		If iVar4.locale <> 1
			If iVar4.comptype <> 1
				cVar18 = 0
			Else
				cVar18 = 1
			EndIf
		Else
			cVar18 = 2
		EndIf
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
	If piVar5.matchstats.rating > 80 And local_40 < local_48
		g_profile.interviewchance = 1
	EndIf
	If piVar5.matchstats.distance > 0.0
		g_profile.WearBoots()
	EndIf
	g_profile.newsheadline = Left(Lower(g_hometeam.name),9) + " " + g_fixture.score1 + " - " + g_fixture.score2 + " " + Left(Lower(g_awayteam.name),9)
	g_profile.newsrating = piVar5.matchstats.rating
	g_profile.newsmotm = piVar5.matchstats.motm
	If piVar5.matchstats.reds > 0
		g_profile.coachreport = GetText("CREPORT_COACHRED")
	ElseIf piVar5.matchstats.yellows = 1
		If g_profile.GotSponsor() = 0
			g_profile.coachreport = GetText("CREPORT_COACHYELLOW")
		Else
			g_profile.coachreport = GetText("CREPORT_COACHYELLOWSPONSORS")
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
	If cVar18 = 4 And local_40 < local_48
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
	Local iVar14:Int = piVar5.matchstats.CountStat(7)
	Local iVar15:Int = piVar5.matchstats.CountStat(8)
	iVar14 = iVar14 + iVar15
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
	local_8 = local_8 + (iVar14 + iVar13) * 2 - 6
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
	If local_40 < local_48
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
	If piVar5.matchstats.motm <> 0 And local_8 < 1
		local_8 = 1
	EndIf
	ClampInt(Varptr local_8,-5,5)
	g_profile.UpdateRelationship(3,local_8)
	g_profile.coachrep_fans :+ local_8
	local_8 = iVar8 * 2 + iVar12 * 2 + iVar10 - 5
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
	iVar7 = piVar5.matchstats.CountStat(9)
	iVar11 = piVar5.matchstats.CountStat(10)
	If iVar11 > 0
		g_profile.UpdateRelationship(6,-10)
		g_profile.coachrep_sponsors :- 10
		g_profile.UpdateRelationship(1,-10)
		g_profile.coachrep_boss :- 10
		g_profile.UpdateRelationship(2,-10)
		g_profile.coachrep_team :- 10
		g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_MATCHREDCARD" + Rand(5,1)),local_30,local_28,0,0)
	Else
		If iVar7 > 0
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
			ElseIf iVar11 > 0
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
			ElseIf iVar11 > 0
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
	If cVar18 = 0 And local_40 < local_48
		g_profile.CheckAchievement(18)
	EndIf
	If cVar18 = 1 And local_40 < local_48
		g_profile.CheckAchievement(19)
	EndIf
	If cVar18 = 2 And local_40 < local_48
		g_profile.CheckAchievement(20)
	EndIf
	If cVar18 = 4 And local_40 < local_48
		g_profile.CheckAchievement(21)
	EndIf
	If local_40 + 4 < local_48
		g_profile.CheckAchievement(22)
	EndIf
	iVar8 = g_fixture.GetWinningTeamId()
	iVar7 = g_profile.clubid
	If g_fixture.level = 1
		iVar7 = g_profile.nationid
	EndIf
	LogLine("WinningTeam:" + iVar8)
	LogLine("MyTeam:" + iVar7)
	If iVar8 = iVar7
		If TCompetition.SelectById(g_fixture.compid).IsCupFinal() <> 0 And g_fixture.matchtype <> 4
			LogLine("CupFinal")
			iVar7 = iVar4.locale
			Select iVar7
				Case 0
					g_profile.CheckAchievement(23)
				Case 1
					If iVar4.level = 0
						g_profile.CheckAchievement(24)
					ElseIf iVar4.level = 1
						g_profile.CheckAchievement(25)
					EndIf
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
	If iVar11 <> 0
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
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSMOTM" + Rand(5,1)),local_30,local_28,0,0)
	ElseIf piVar5.matchstats.rating > 85
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSGOOD" + Rand(5,1)),local_30,local_28,0,0)
	ElseIf piVar5.matchstats.rating > 65
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSOK" + Rand(5,1)),local_30,local_28,0,0)
	Else
		g_profile.bossreport = g_profile.DoNews(GetText("CREPORT_BOSSPOOR" + Rand(5,1)),local_30,local_28,0,0)
	EndIf
	If piVar5.matchstats.CountStat(6) < 7
		If piVar5.matchstats.CountStat(17) < 10
			If piVar5.matchstats.CountStat(3) > 14
				If piVar5.matchstats.rating > 65
					g_profile.bossreport :+ " " + GetText("CREPORT_GOODPASSING")
				Else
					g_profile.bossreport :+ " " + GetText("CREPORT_GOODPASSINGHOWEVER")
				EndIf
			EndIf
		ElseIf piVar5.matchstats.rating > 65
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODTACKLING")
		Else
			g_profile.bossreport :+ " " + GetText("CREPORT_GOODTACKLINGHOWEVER")
		EndIf
	ElseIf piVar5.matchstats.rating > 65
		g_profile.bossreport :+ " " + GetText("CREPORT_GOODHEADING")
	Else
		g_profile.bossreport :+ " " + GetText("CREPORT_GOODHEADINGHOWEVER")
	EndIf
	iVar7 = 0
	iVar8 = 0
	If g_profile.temp_positioning > 0
		iVar7 = g_profile.temp_positioning
		iVar8 = 4
	EndIf
	If g_profile.temp_shortpassing > iVar7
		iVar7 = g_profile.temp_shortpassing
		iVar8 = 5
	EndIf
	If g_profile.temp_longpassing > iVar7
		iVar7 = g_profile.temp_longpassing
		iVar8 = 6
	EndIf
	If g_profile.temp_aggression > iVar7
		iVar7 = g_profile.temp_aggression
		iVar8 = 7
	EndIf
	If g_profile.temp_longshots > iVar7
		iVar7 = g_profile.temp_longshots
		iVar8 = 8
	EndIf
	If g_profile.temp_finishing > iVar7
		iVar7 = g_profile.temp_finishing
		iVar8 = 9
	EndIf
	If g_profile.temp_crossing > iVar7
		iVar7 = g_profile.temp_crossing
		iVar8 = 3
	EndIf
	If g_profile.temp_freekicks > iVar7
		iVar7 = g_profile.temp_freekicks
		iVar8 = 1
	EndIf
	If g_profile.temp_corners > iVar7
		iVar7 = g_profile.temp_corners
		iVar8 = 2
	EndIf
	If g_profile.temp_penalties > iVar7
		iVar7 = g_profile.temp_penalties
		iVar8 = 10
	EndIf
	If iVar7 > 5
		Select iVar8
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
		If local_40 < local_48
			If g_profile.coachrep_fans < 1
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWEWONBAD" + Rand(2,1))
			Else
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWEWONGOOD" + Rand(2,1))
			EndIf
		ElseIf local_48 < local_40
			If g_profile.coachrep_fans < 1
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWELOSTBAD" + Rand(2,1))
			Else
				g_profile.bossreport :+ " " + GetText("CREPORT_RIVALSWELOSTGOOD" + Rand(2,1))
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

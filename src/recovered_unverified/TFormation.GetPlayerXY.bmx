' TFormation.GetPlayerXY -- VA 0x004D8B85, 2898 bytes, vtable slot 0x58 -- NOT VERIFIED (MISMATCH)
'
' === LATEST PASS: IMPORTANT CORRECTION TO EVERYTHING BELOW, READ THIS FIRST ===
' The narrative below claims (repeatedly, in detail) that this body is LENGTH-EXACT
' (our_len==orig_len==2898) with only 3 confirmed same-length substitutions remaining (the
' setbe/setae sites) and that everything else is harmless stack-slot-renumbering aligner
' noise. THIS WAS RE-CHECKED AGAINST THE REAL STATUS/SCORE PIPELINE (status/score/
' TFormation.GetPlayerXY.txt, and independently reproduced with harness.try_method against
' the SAME src on-disk state before this pass touched it) AND IT DOES NOT HOLD: the body this
' header describes as "length match, 3 subs" actually scores 693/2898 (23.9%), and the very
' FIRST byte difference is in the PROLOGUE -- `sub esp,0x34` (original) vs `sub esp,0x30`
' (ours) -- i.e. the original's stack frame reserves ONE MORE 4-byte slot than ours. That
' single missing slot shifts every Local's ebp-relative displacement after it by 4 bytes,
' which cascades into a real-but-misleading difference at nearly every instruction touching a
' Local for the rest of the function -- this fully explains the low raw score even though the
' *shape* of the code is largely right. Do not trust the "our_len==orig_len, only 3 subs"
' claim below without re-verifying it yourself; it is not reproducible against the current
' file or against the real scoring pipeline. (Root cause unknown: confirmed empirically, via
' harness.try_method with a dummy live Float Local, that adding ANY extra genuinely-used
' Float Local closes the sub-esp gap to 0x34, so the frame really is short by exactly one
' spill/Local slot -- but which real value needs that slot, and where, was not found this
' pass; see the many failed attempts in the later sections below, which -- despite the
' unreliable length claim -- do contain real, independently-reverified disassembly detail
' about the tail (xshift/leg) region that is worth reading.)
'
' ONE CONFIRMED, MEASURED IMPROVEMENT WAS MADE THIS PASS (verified via harness.try_method
' against binary/NSS5.exe, not asserted): the `a1 = a1 - Float(xOff)` step before the
' xshift/xshiftnoball If/Else was rewritten to materialize the subtraction as a fresh
' `Local xAdj:Float` reused inside both branches, instead of re-mutating `a1` in place:
'     Local xAdj:Float = a1 - Float(xOff)
'     If a6 <> 0
'         a1 = xAdj - (xAdj - (a3 / 2.0 - Float(xOff))) / g_form_xshift
'     Else
'         a1 = xAdj - (xAdj - (a3 / 2.0 - Float(xOff))) / g_form_xshiftnoball
'     EndIf
' Measured: 693/2898 (23.9%) -> 729/2898 (25.2%), our_len 2898 -> 2887 (still MISMATCH, frame
' size still short by one slot -- this did not close that gap, it just improved alignment
' downstream of it). Tried and REJECTED as worse, for the record so the next pass does not
' repeat them: reusing `dxRatio` instead of a fresh Local for the same spot (identical to
' baseline, 693/2898, i.e. no effect); the same "extra Local" treatment applied to the `leg`
' formula's repeated `(a2+Float(yOff))` term via a `yAdj` Local (652/2898 alone, 650/2898
' combined with xAdj -- worse, leave `leg` exactly as already written); regrouping the
' Case 1 depth-adjust multiply as `hSpacing * (g_form_depth * 0.5)` to match a byte-for-byte
' confirmed operand order in the real disassembly at 0x004D8D52-0x4D8D68 (240/2898 alone,
' 273/2898 combined with xAdj -- confirmed CORRECT against the real bytes at that isolated
' instruction range, yet net-negative for the whole-function score, evidence of how sensitive
' this cascading-offset landscape is: a locally-correct fix can still regress the aggregate
' metric); swapping which branch (a6=0 vs a6<>0) is primary in the row<=2 widepush/Abs()
' block to mirror Ghidra's if/elseif printing (9.2%, much worse -- the current branch order,
' primary on `a6<>0`, is confirmed better, Ghidra's shown order is not the source order here);
' folding `a1-Float(xOff)` into one repeated-text expression with no separate Local (22.1%,
' worse -- bcc does not dedupe a textually-repeated compound subexpression, only a fresh
' Local reused by name gets the benefit); materializing the widepush*0.5 term as its own
' Local (23.6%, marginally worse, leave it inlined). Given the volatility just demonstrated,
' do not assume any single further local change will move the score monotonically toward the
' original -- rebuild and measure after every change.
'
' Everything from here down is the PRE-EXISTING header, kept per the project's
' record-keeping rule. Treat its specific "our_len==orig_len, 3 subs" factual claim as
' UNVERIFIED/WRONG per the correction above; its disassembly-level observations about the
' tail region (xshift/leg FPU-stack reuse, setbe/setae/fxch mechanism) were independently
' spot-checked this pass and are directionally consistent with the real binary.
'
' Two concurrent lines of work were merged here; the findings below are additive, not
' conflicting.
'
' CURRENT STATE: MISMATCH, our_len 2898 vs orig_len 2898 -- LENGTH-EXACT (delta 0). It was -39
' before any of the fixes below, -25 after the first three, closed to -4 by the tail-refusion
' fix (next section), then to EXACTLY 0 by additionally changing `If row < 3` to
' `If row <= 2` (both mirrors). localise_diff.py reports
' delta_accounted: COMPLETE (0 of 0). DO NOT write this to src/recovered -- it is a LENGTH
' match, not a byte match: 3 confirmed same-length substitutions remain (see "STILL WRONG"
' below), plus ~46 same-length subs that are pure cascaded stack-slot renumbering
' (S18.2 tie-break noise, not defects -- confirmed by direct disassembly comparison, not just
' asserted; see note 2 below).
'
' === THE FIRST THREE FIXES (all carried forward unchanged, all still correct) ===
'
' 1. wBoost is NOT a materialised Local. Original stores directly into wSpacing inside EACH
'    branch (duplicated -- bcc has no CSE), never into a separate temp:
'        If a5 = 1
'            wSpacing = wSpacing + (a4 - a2) / 30.0
'        Else
'            wSpacing = wSpacing + a2 / 30.0
'        EndIf
'    Confirmed both divisor constants read 30.0 via harness/bytematch.read_va (0xC74BC0,
'    0xC74BC4 -- two separate rdata slots holding the identical value, consistent with bcc
'    NOT deduping per-occurrence literals). Removing the `Local wBoost:Float` and its two
'    assignments and writing the add-in-place directly inside each branch matched the
'    original's duplicated-store shape byte length exactly for this span (-8 bytes closer).
'
' 2. `adj` is NOT a materialised Local either, in BOTH mirrors. Disassembly at 0x004D8F4D
'    (the a5=1, row>=3, bVar8 branch) is INSTRUCTION-FOR-INSTRUCTION identical to ours (down
'    to which Global loads first, which register spills around the Abs() call, and the
'    store-before-call/reload-after-call pattern) once written as one expression with no
'    intermediate store:
'        yOff = Int(Float(yOff) - hSpacing * (g_form_widepush * 0.5) * Abs(dxRatio))
'    (the rejected alternative was `adj = g_form_widepush * 0.5` then `... - adj * hSpacing * ...`, which
'    forced an extra `fstp`/`fld` pair that the original never has). Removed the
'    `Local adj:Float` declaration and both assignment statements; applied the same inlining
'    to the a5<>1 mirror (`... + hSpacing * (g_form_widepush * 0.5) * Abs(dxRatio)`).
'    VERIFIED by direct our-vs-original disassembly diff of the whole bVar8-body span for
'    the a5=1 mirror: every opcode and operand matches except stack-slot depth (a uniform
'    4-byte renumbering, i.e. cascaded tie-break noise per S18.2, not a real defect) and the
'    obviously-masked relocated addresses/call targets.
'
' 3. Operand order in the final `leg` (yLeg) formula was backwards. Original computes
'    `a2 + Float(yOff)` and `a4/2.0 + Float(yOff)` (the plain Float/param term FIRST, the
'    Int->Float-converted accumulator SECOND -- tell: `fld [param-or-local]` precedes the
'    `mov [tmp],reg / fild [tmp]` conversion pair), not `Float(yOff) + a2` /
'    `Float(yOff) + a4/2.0` (which would emit the conversion FIRST).
'    Fixed to:
'        leg = (a2 + Float(yOff)) - ((a2 + Float(yOff)) - (a4/2.0 + Float(yOff))) / g_form_yshift
'    (+4 bytes closer).
'
' All three fixes are of the SAME family: earlier passes over-materialised intermediate
' quantities as named `Local`s where the original keeps them purely in FPU registers across
' the statement.
'
' === FURTHER FIXES (applied on top of the three above) ===
'
' 4. THE TAIL FUSION (this is what finding "A" below describes and calls unsolved --
'    it is now solved). Hand-traced the x87 stack through 0x004D9490-0x004D95D5 (note:
'    `FSUBP st(i),st(0)` computes st(i) = st(i) - st(0), THEN pops -- get the direction
'    backwards and the derived formula inverts). The block builds four bare stack values with
'    NO fstp to any named slot (R1=a3/2.0-Float(xOff), R2=a4/2.0+Float(yOff), R3=a1-
'    Float(xOff), R4=a2+Float(yOff); R3/R4 are each duplicated on-stack via `fld st(n)` for
'    reuse, confirming xOff/yOff subtraction happens once at the source level), then, still
'    with no store: xResult = R3-(R3-R1)/G_x (G_x = g_form_xshift if a6<>0 else
'    g_form_xshiftnoball), yResult = R4-(R4-R2)/g_form_yshift -- both feeding straight into the
'    wSpacing*wScale*0.5 / hSpacing*hScale*0.5 clamps with zero stores between. So the X piece
'    is NOT a separate Local at all -- it is `a1` reassigned twice, same shape as the
'    already-correct Y formula:
'        a1 = a1 - Float(xOff)
'        If a6 <> 0
'            a1 = a1 - (a1 - (a3 / 2.0 - Float(xOff))) / g_form_xshift
'        Else
'            a1 = a1 - (a1 - (a3 / 2.0 - Float(xOff))) / g_form_xshiftnoball
'        EndIf
'    This alone closed the delta from the -39 baseline to -4.
'
' 5. `If row < 3` should be `If row <= 2` (both mirrors, lines ~212/271). Original's skip-
'    branch is `cmp [row],2 / jg`ONLY when the source is spelled with `<=`; `< 3` compiles to
'    a differently-shaped `cmp ...,3 / jge` sequence in our bcc. Confirmed by direct
'    disassembly: before this fix ours emitted `cmp [row],3 / jge`, after it emits
'    `cmp [row],2 / jg`, matching byte-for-byte (mod the usual slot renumbering). Together
'    with #4 this closed the LAST 4 bytes -- our_len now EQUALS orig_len exactly (2898).
'
' 6. VERIFIED BY DIRECT COMPARISON, NOT BY THE ALIGNER: localise_diff.py's aligner reports a
'    huge, confusing cluster at original offsets ~968-1957 (one gap shows replace +926!) and
'    several more scattered through the tail. This is ALIGNMENT-TOOL NOISE from cascaded
'    stack-slot renumbering, not missing/extra statements -- confirmed by dumping our probe's
'    raw bytes against the original at the literal VA range directly (bypassing the aligner):
'    e.g. 0x004D8FDA..0x004D9070 and the corresponding span in ours are BYTE-FOR-BYTE
'    IDENTICAL in shape (same opcodes, same relative jump targets, same call targets),
'    differing only in which ebp-relative stack slot each Local lands in and which relocated
'    Global address is used. The aligner's key does not blank ebp-relative displacements, so a
'    slot renumbering upstream desyncs its greedy match for a long stretch even when the
'    underlying content is correct. Do not trust a giant aligner gap at face value when the
'    whole-function delta is small; dump both sides at the literal VA/offset and eyeball it.
'    (This is also why a couple of `subs` entries the aligner reports, e.g. an apparent
'    fsub-vs-fadd at reported orig_off 1025, land at wildly implausible `ours` addresses --
'    e.g. our reported address is ~1440 bytes past where a genuinely-corresponding
'    instruction would sit at that point in the stream. Treat any `subs` entry whose `ours`
'    address does not track `orig_off` in roughly the expected proportion as aligner noise,
'    not a real finding, until directly re-checked against a clean disassembly dump.)
'
' 7. TRIED AND REVERTED -- do not repeat without a new idea. To try to kill finding "STILL
'    WRONG" #1 below, flipped `If a3 - wSpacing*3.0 < a1 Then a1 = a3 - wSpacing*3.0` to
'    `If a1 > a3 - wSpacing*3.0 Then a1 = a3 - wSpacing*3.0` (and the hSpacing/a2 analogue).
'    Flipping BOTH pairs: whole-function delta got WORSE (2890/2898, i.e. -8, not 0).
'    Flipping ONLY the a1 pair alone: also worse (2896/2898, i.e. -2). The `<` form as
'    currently written is confirmed locally optimal; the setbe/setae difference is not fixed
'    by any operand-order flip tried so far -- it needs a different idea, not a retry of this
'    one.
'
' === STILL WRONG (honest, not patched over) -- 3 confirmed same-length substitutions ===
'
' 1. `setbe` (orig) vs `setae` (ours) at THREE places: original offsets +237, +327 (the two
'    early input clamps `If a1 < wSpacing*3.0` / `If a3-wSpacing*3.0 < a1` and their
'    hSpacing/a2 analogues) and +2802 (inside the final `row=0 And col>1 And col<5` a4/12.0
'    clamp). Same underlying boolean, opposite FPU compare direction (ST0/ST1 swapped versus
'    original, so bcc picks the complementary setcc to get the same logical result) -- same
'    class as codegen-patterns S10.1, but for FLOAT (fucompp) comparisons, and #7 above shows
'    the obvious source-level flip does not fix it (in fact makes byte LENGTH worse elsewhere,
'    meaning the two effects are coupled through the allocator, not independent). NEXT STEP:
'    since these three are now the ONLY confirmed real defect and the length already matches,
'    this is close: try instrumenting bcc's register-allocator dump (an instrumented build
'    already exists under tools/bmx-workers/) or try alternate source restructurings of
'    just ONE clamp (e.g. swap which branch is "Then" vs implicit-continue, or introduce/
'    remove a redundant parenthesis) rather than flipping the whole relational operator.
' 2. Field/Global/const identifications: all still correct. Abs =
'    0x004A7FE0 (project-wide knowledge). g_form_wscale_default (0x00C74BC8),
'    g_form_hscale_default (0x00C74BCC), g_form_posnoise (0x00C74D10) confirmed again
'    by direct float read (all 0.0 -- dead defaults, harmless). g_form_xshift/
'    g_form_xshiftnoball/g_form_yshift confirmed this pass to be RUNTIME Globals (data-section
'    float 0.0, mutable, not literals) at 0xC5BB4C / 0xC5BB50 / 0xC5BB54 respectively --
'    adjacent to the already-known g_form_width/widthnoball/height/depth cluster at
'    0xC5BB3C/40/38/44.
'
' 1. SIG, params, GetColFromSelectionNo/GetRowFromSelectionNo identification, Global names
'    (g_form_height/width/widthnoball/depth/widepush/xshift/xshiftnoball/yshift/ymargin,
'    matching TFormation.SetUp.bmx's declaration order), the `a2 = -a2` split-fusion fix,
'    and the Select-not-If shape of both big dispatches all carried over unchanged from
'    earlier passes and remain correct (confirmed again here).
'
' 2. NEW: wSpacing is NOT a shared-temp-then-divide. Confirmed by disassembly at 0x4D8BF0:
'      cmp edi,0 / je -> fld[a3]/fld[g_form_widthnoball]/fmul[a9]/fdivp/fstp[[wSpacing]]
'      (else) fld[a3]/fld[g_form_width]/fmul[a9]/fdivp/fstp[wSpacing]
'    i.e. TWO SEPARATE, differently-worded divisions, one per branch of `If a6 <> 0`:
'        If a6 <> 0
'            wSpacing = a3 / (g_form_width * a9)
'        Else
'            wSpacing = a3 / (g_form_widthnoball * a9)
'        EndIf
'    (an earlier pass suspected this from the C; this nails the exact source form.)
'
' 3. NEW and the main find this pass: the bVar8 "short-circuit chain" that earlier passes could not
'    close is not the multi-statement comma-operator form Ghidra prints at all. Read
'    directly off silicon (0x004D92A1..0x004D92E8, the a5<>1 mirror):
'        fldz; fld [dxRatio]; fucompp; setb   -> eax = (dxRatio < 0.0)
'        je +skip                             -> if eax=0 (dxRatio>=0), skip the AND term
'        mov eax,[col]; cmp eax,0; sete        -> eax = (col = 0)     [only when dxRatio<0]
'      +skip: cmp eax,0 / jne +done            -> if eax<>0 (first AND true), keep it, skip OR
'        fldz; fld [dxRatio]; fucompp; setae   -> eax = (dxRatio >= 0.0)
'        je +done2
'        mov eax,[col]; cmp eax,6; sete        -> eax = (col = 6)
'      +done/+done2: (eax is the final bVar8)
'    This is EXACTLY the natural short-circuit lowering of ONE assignment expression:
'        bVar8 = (dxRatio < 0.0 And col = 0) Or (dxRatio >= 0.0 And col = 6)
'    with the a5=1 mirror using strict `>` / `<=` instead (confirmed the same way at
'    0x004D8C94ish region, consistent with the earlier "0.0 < fVar1 Then bVar8=(col=0)" note):
'        bVar8 = (dxRatio > 0.0 And col = 0) Or (dxRatio <= 0.0 And col = 6)
'    Writing it this way as a single expression (not the nested-If translation of Ghidra's
'    comma-operator C) reproduces the WHOLE region exactly -- every gap attributed to
'    this chain (both mirrors) is gone; only genuinely separate issues remain (see below).
'    Lesson for the corpus: when Ghidra shows `x = A; if (B) x = C; if ((!x) && (x=D,D)) x=E;`
'    on a value that is immediately consumed by `if (x)`, read the raw disassembly before
'    trusting the printed form -- it can be pure decompiler noise for `x = (B And C) Or (D And E)`.
'
' 4. Applied the "every OTHER plain two-way branch on a6 is `If a6 <> 0`" rule
'    to the 10 row-case hScale picks and the final xshift/xshiftnoball divisor choice (both
'    confirmed still needed -- dropping either one costs bytes).
'
' (The original findings A-D above described the tail as unsolved and flagged the same
' setbe/setae issue independently -- both are settled by the sections above: A is
' SOLVED (see fix #4), the setbe/setae issue is confirmed real and still open (see "STILL
' WRONG" #1 above), and the +968..+1923 "residuals" are confirmed as pure aligner noise (#6).)
'
' Reproduction: harness.try_method('TFormation','GetPlayerXY', <this file's body>) then
' scripts/localise_diff.py TFormation.GetPlayerXY --exe <probe.exe> --max-gaps 60. Expect
' our_len == orig_len == 2898 and exactly 3 confirmed-real same-length subs (setbe/setae at
' orig offsets +237/+327/+2802) plus ~46 slot-renumbering subs (harmless, see #6).
'
' === THE EXACT MECHANISM, READ FROM bcc's OWN SOURCE -- still not closed ===
'
' State reconfirmed unchanged this pass: MISMATCH, our_len 2898 == orig_len 2898, same 3
' same-length subs at +237/+327/+2802. This pass's contribution is NOT a new byte fix -- it is
' the root cause, read directly from
' tools/blitzmax-legacy-src/_src/codegen/cgfixfp_x86.cpp, which the earlier passes did not
' consult. This turns "opposite FPU compare direction" from an observation into a mechanism,
' and gives an exact, falsifiable recipe for closing all 3 sites AT ONCE (not yet executed --
' see "why not applied" below).
'
' THE MECHANISM (cgfixfp_x86.cpp):
'   FPStack::fcomp(rd,rs,live) ALWAYS starts with fxch(rd) -- bring the LHS operand (AS
'   WRITTEN in source, before any skip negation) to top of stack. fxch() is defined as
'   "if(r==top()) return;" -- i.e. IT EMITS ZERO BYTES when rd already happens to be on top,
'   and a real 2-byte `fxch st(n)` otherwise. The caller (fixMov, ~line 444) reads
'   `rd=t->lhs->reg()->color; rs=t->rhs->reg()->color` directly off the (possibly-negated,
'   for a skip-only If-with-no-Else) comparison node -- so which operand is "lhs" is fixed by
'   which operand is written on the LEFT of the relational operator in source, not by
'   evaluation order. Then setcc is chosen directly from the (negated) condition code via a
'   fixed table (CG_LT->b, CG_GT->a, CG_LE->be, CG_GE->ae) -- no further swap logic anywhere.
'   Separately, evaluation order (which operand is fld'd onto the FPU stack first) empirically
'   puts the MORE COMPLEX sub-expression first and the SIMPLE bare Local/param LAST (=naturally
'   on top) at every site checked in this function -- confirmed at clamps 1 and 3 (both
'   "var < simpleProduct", var loaded last, no fxch either side) and clamps 2 and 4 (both
'   "complexDiff < var", var loaded last on BOTH sides, ours and original alike -- see below).
'
' WHY OURS HAS A SPURIOUS fxch AT CLAMPS 2 AND 4 (+237, +327) BUT ORIGINAL DOESN'T:
'   Disassembly (ours vs original, both fresh this pass) confirms BOTH sides evaluate clamp 2
'   ("a3 - wSpacing*3.0 < a1") in the SAME order -- X computed first, `fld [a1]` loaded last,
'   landing naturally on top. But because our source is written `X < a1`, fixMov's rd is X
'   (the LHS AS WRITTEN), and fcomp emits a real `fxch` to drag X back to the top over a1 --
'   2 extra bytes. Original has NO fxch here and uses `setbe` directly. Given the fixed cc
'   table above, `setbe` = CG_LE, which is the negation of CG_GT (`a1 > X`) -- i.e. original's
'   SOURCE is `If a1 > a3 - wSpacing*3.0 Then a1 = a3 - wSpacing*3.0`, NOT the `X < a1` spelling
'   this candidate carries. With that spelling, rd=a1 (LHS as written), which the SAME
'   complex-first evaluation order already places on top -- fxch(rd) is then the free no-op
'   original shows. Symmetric reasoning applies to clamp 4 (hSpacing/a2): original's source
'   must be `If a2 > a4 - hSpacing*1.0 Then a2 = a4 - hSpacing*1.0`.
'
' EMPIRICALLY CONFIRMED THIS PASS (harness, both isolated from the tail fix below):
'   - Flipping ONLY clamp 2 to `If a1 > a3 - wSpacing*3.0 Then ...`: our_len 2898 -> 2896
'     (exactly -2, i.e. the fxch is gone and NOTHING else moved -- matches the mechanism
'     exactly). Flipping ONLY clamp 4 the same way: also 2898 -> 2896 (-2). Flipping BOTH
'     together: 2898 -> 2894 (-4, additive, as expected).
'   - Note #7 above tried this exact flip on clamp 2 alone and reported it made things
'     WORSE ("2896/2898") -- that is the SAME number this pass measured, just read as a
'     regression at the time, because the tail (below) had not yet reached its own
'     zero-sum -4. It is not a contradiction; it is the same true fact, and it tells you
'     EXACTLY how much the tail fix must supply: +4.
'
' SITE 3 (+2802, inside `If row=0 And col>1 And col<5`) -- WHY IT'S A LENGTH DEFICIT, NOT A
' SURPLUS, AND WHY THAT'S THE OTHER HALF OF THE SAME +4/-4 LEDGER:
'   Original's fcomp for BOTH the a5=1 sub-branch (`leg < a4/2.0-a4/12.0`) and the a5<>1
'   sub-branch (`a4/12.0+a4/2.0 < leg`) compiles to the "rd IS live" path of fcomp -- `fxch
'   st(2)` then `fucom st(2)` (non-popping: both operands survive the compare), THEN a SECOND
'   `fxch st(2)` + `fstp st(0)` to explicitly discard the loser (the `fpop(rs)` helper, called
'   because rs is not live either way). `st(2)` means THREE values are live on the FPU stack
'   at this compare: the freshly-computed LOW/HIGH bound (pushed on top), the OTHER live float,
'   and -- underneath both -- `leg` itself, UNSTORED since its own last write (the immediately
'   preceding hSpacing/hScale clamp pair, which this candidate already reproduces byte-exactly
'   as ordinary Local-backed clamps). Our candidate reloads `leg` fresh from memory at this
'   point (confirmed: ours uses `fxch st(1)`/`fucom st(1)`/`fucomp st(1)`-style 2-deep forms,
'   never st(2)) -- i.e. in the ORIGINAL, `leg`'s FPU-resident value survives, unspilled,
'   across the ENTIRE integer-only `row=0 And col>1 And col<5` test and into BOTH branches of
'   the `a5=1` dispatch. Measured byte cost of this specific difference in isolation: the a5=1
'   sub-branch's compare block is length-IDENTICAL both ways (24 bytes; `fxch st(2)`/`fucom
'   st(2)` and `fxch st(1)`/`fucom st(1)` are both 2-byte opcodes, so depth alone doesn't cost
'   anything there) -- but the a5<>1 sub-branch collapses in OUR version from original's 3-op
'   `fxch st(2)+fucom st(2)+fxch st(2)` (6 bytes) down to a single 2-byte `fucomp st(1)`,
'   because with only 2 live values (not 3) `fcomp`'s "rs is not live either" `stoff(rs)==1`
'   fast path fires instead. That is the missing 4 bytes, precisely accounting for the -4
'   needed to offset the +4 that fixing clamps 2 and 4 (above) would cost.
'
' WHY NOT APPLIED THIS PASS: the clamp-2/clamp-4 fix is mechanically certain (source-level,
' confirmed by direct harness measurement). The tail fix is NOT -- it requires `leg` to reach
' the row=0 check without ANY interceding fstp, which is a backend liveness/spill decision
' (governed by cgblock.cpp/cgflow.cpp's basic-block FP-stack reconciliation, not consulted
' this pass) rather than something controllable by rephrasing one line of BlitzMax. Applying
' ONLY the clamp fix regresses the whole-function delta from 0 to -4 (confirmed: see numbers
' above) -- worse than the current state under this project's MATCH bar, so it was NOT written
' into the body below. NEXT STEP: find a source-level restructuring of the row=0 block (still
' assigning `leg` via ordinary BlitzMax, no way to force spill/no-spill directly) that leaves
' `leg`'s prior value unstored going into the `row=0 And col>1 And col<5` test -- e.g. try
' folding the two preceding hSpacing/hScale clamp lines and the row=0 block into one extended
' If/ElseIf chain with no statement boundary between them, or consult cgblock.cpp's
' `adjustStack`/block-merge logic for what specifically triggers a spill at a block join. Once
' found, apply it TOGETHER WITH the clamp 2/4 flips above (not separately) -- the ledger above
' says the three changes net to exactly 0 and should reach full MATCH in one shot.
'
' === CLAMP 2/4 MECHANISM DIRECTLY CONFIRMED ON SILICON; SITE 3's "OTHER
' LIVE FLOAT" IDENTIFIED AS a1; FOUR RESTRUCTURING IDEAS TRIED AND RULED OUT ===
'
' State reconfirmed unchanged: MISMATCH, our_len 2898 == orig_len 2898, same 3 same-length
' subs. No byte fix landed. Body below is IDENTICAL to the state above -- only this header grew.
'
' 1. CLAMP 2/4: the mechanism read from cgfixfp_x86.cpp source is now confirmed by DIRECT
'    disassembly diff (ours vs original) at the actual instruction level, not just inferred.
'    At original offset +215 (0x004D8C6A-0x004D8C72): `fld [a1]; fucompp; setbe` -- fucompp
'    compares top-two-and-pops, using WHICHEVER operand evaluation naturally placed on top
'    (a1, pushed last). OUR compiled probe at the same logical point (dumped via
'    `bytematch.find_method`+`disasm_original(path=probe.exe)`) is `fld [a1]; fxch st(1);
'    fucompp; setae` -- ours has a genuine EXTRA `fxch st(1)` (2 bytes, D9 C9) that original
'    lacks, because our source `If a3-wSpacing*3.0 < a1` makes fixMov's rd = the bound
'    (LHS-as-written), which sits at st(1) after evaluation and must be dragged to top; with
'    the source flipped to `If a1 > a3-wSpacing*3.0` rd=a1, already on top from evaluation
'    order, so fxch(rd) is the free no-op original shows -- AND the setcc flips from setae to
'    setbe as a consequence of the same source-level operand-order change (not a second,
'    independent fix). This is the exact -2/-2/-4 the harness already measured; now it is
'    verified against real bytes on both sides, not merely predicted from the allocator's
'    source code. No new number; this closes the chain of evidence for #general codegen-
'    patterns knowledge, not just this function.
'
' 2. SITE 3's mysterious "OTHER live float" (st(2)'s third resident value in the account above)
'    is now IDENTIFIED: it is `a1`. Full disassembly read of 0x004D9490-0x004D96D6 (the tail
'    fusion through the function epilogue, ~320 bytes, every instruction) shows: entering the
'    row=0 block the FPU stack holds exactly TWO resident values with NO named-slot store since
'    their last write -- `a1` on top (unspilled since the xshift/xshiftnoball If/Else finished,
'    several statements earlier) and `leg` immediately beneath it (unspilled since its own two
'    hSpacing/hScale clamps). The row=0 test itself is pure-integer (mov/cmp/sete on ebp-slots,
'    zero FPU traffic) so it does not disturb this. Inside EACH row=0 sub-branch, the bound
'    computation pushes 1-2 fresh values ON TOP of these two, explaining the "st(2)" depth
'    seen above (a1 and leg are BOTH still under there, not just leg). After the row=0 block
'    (whichever branch, or neither), execution falls straight into
'    `fld[a3]/fdiv(2.0)/fsubp -> *a7 = a1-a3/2.0` then `fld[a4]/fdiv(2.0)/fsubp -> *a8 =
'    leg-a4/2.0` then negate `*a8` -- i.e. the LAST two statements of the function
'    (`a7[0]=a1-a3/2.0` / `a8[0]=leg-a4/2.0`) are reading `a1` and `leg` DIRECTLY off the FPU
'    stack with no `fld [ebp-N]` from either one anywhere in this whole span. This confirms
'    the already-verified xshift a1-formula and the leg formula are correct in VALUE, and
'    narrows the open question to exactly one thing: what source shape keeps `leg` (not `a1`,
'    which already stays resident with no source change needed) un-spilled across the row=0
'    block's own two conditional writes to it.
'
' 3. FOUR RESTRUCTURING IDEAS TRIED THIS PASS, ALL MEASURED WORSE OR NEUTRAL -- do not repeat
'    without new evidence:
'    a. Reuse `a2` directly instead of declaring `Local leg`, mirroring how `a1` is reused
'       in place for the X side (rename every `leg` read/write in the tail to `a2`, since `a2`
'       is not read again after the Y-accumulator stage). Measured: our_len 2898 -> 2912
'       (+14, worse). `a2` is referenced far earlier and far more often than `a1` is (it feeds
'       the a5/a6 depth-adjustment `Select` blocks), so its allocator degree/usage profile is
'       not equivalent to `a1`'s late, narrow live range -- the analogy does not transfer.
'    b. Reorder statements so `Local leg = ...` and its two clamps come AFTER the `a1`
'       wScale/hScale clamp pair instead of before (pure reordering, same statements). our_len
'       stayed exactly 2898, same 3 subs -- a byte-neutral no-op for this body. Ruled out as a
'       lever on its own; combined with fix (d) below it still does not reach 0 (see below).
'    c. Flip ONLY the a5<>1 sub-branch's row=0 clamp to put `leg` as the written LHS
'       (`ElseIf leg > a4/12.0+a4/2.0 Then leg=a4/12.0+a4/2.0`, mirroring the already-`leg`-
'       LHS a5=1 sub-branch), on the theory that the clamp-2/4 rd=LHS-as-written rule should
'       apply here too. Measured ALONE: our_len 2898 -> 2904 (+6, worse) -- the flip does NOT
'       simply remove/add an fxch the way it did for clamps 2/4, confirming (per finding 2)
'       that site 3 is not a same-family "extra fxch" defect: original already uses the
'       preserve-and-discard-loser idiom (fxch st(2)+fucom st(2), non-popping) on BOTH
'       sub-branches, which is a fundamentally different shape from clamps 2/4's simple
'       recompute-and-fucompp-pop idiom, and no purely-syntactic operand-order flip changes
'       which of the two idioms bcc emits -- that is controlled by whether `leg` is spill-
'       or register-colour, an allocator decision this pass did not find a source-level lever
'       for.
'    d. Combined (b)+the clamp-2/4 flips+(c): our_len 2898 -> 2900 (+2). Consistent with the
'       individual deltas being additive (-4 from clamp2/4, +6 from the ElseIf flip, +0 from
'       the reorder) and NOT cancelling -- confirms (c) is not the missing piece paired with
'       the already-correct clamp 2/4 fix; something else entirely is needed for site 3.
'
' NEXT STEP (unchanged in kind, sharpened by finding 2): the remaining problem is
' purely "why does OUR allocator spill `leg` to a real ebp-slot across the row=0 block while
' `a1` (a parameter, not a Local, immediately adjacent in the same span) does not spill".
' Since `a1` proves parameters/Locals CAN stay FPU-resident this deep into the function without
' any special source trick, the next lever to try is not operand-order syntax (four variants
' now ruled out across two passes) but the reference-count/degree book-keeping itself: count
' every textual occurrence of `leg` in the candidate vs. try adding or removing a redundant
' but semantically-inert read (e.g. an unused `Local legCopy:Float = leg` immediately before
' the row=0 block, or restructuring the two hSpacing/hScale clamps into a single combined
' expression the way clamps 1/3 already are) and watch whether `leg`'s spill/colour decision
' flips, per codegen-patterns S18 (reference count is a RANK, ties break on declaration order,
' block_count divides spill cost) -- this function is exactly the S18.4 gadget-liveness case,
' not the S18.2 flat-declaration-order case, so per S18.4 read the touch census
' (`scripts/w14S0_live.py`) for `leg` specifically rather than guessing another rewrite blind.
'
' === THE INSTRUMENTED-ALLOCATOR DUMP POINTED AT THIS ACTUAL FUNCTION FOR
' THE FIRST TIME -- node-ID/bank decoding solved, real spill set now GROUND TRUTH, still not
' closed ===
'
' State reconfirmed unchanged: MISMATCH, our_len 2898 == orig_len 2898, same 3 same-length subs
' at orig +237/+327/+2802 (setbe/setae). No byte fix landed. Body below is IDENTICAL to end of
' the state above -- only this header grew.
'
' An instrumented `bcc.exe` exists under `tools/bmx-workers/` (built earlier, long unused)
' that dumps the FULL Chaitin-Briggs interference graph
' (`NSS5GRAPH fn=<mangled name>` / `NSS5NODE id=... usage=... degree=... block_count=...
' cost=... edges=[...]`) plus a live `Spilling:`/`Spilled:`/`Colored:` trace, per function, to
' stdout. This pass is the first to point it at `__bb_TFormation_GetPlayerXY` specifically
' (earlier passes only read the allocator SOURCE, never its live output for this function).
'
' HOW: point `NSS5_WORKER` at that tree, run this file's body through `harness.build_source` +
' `harness.BMK makeapp -r -t console` directly (NOT through `try_method`, whose `message`
' field truncates to the last 1500 chars -- the raw log for the whole probe is ~4.7 MB since
' EVERY function in the probe gets a dump). Grep the log for
' `;--- NSS5GRAPH fn=__bb_TFormation_GetPlayerXY ---;` (appears twice, once per allocator
' pass -- see below) and slice out everything up to the next function's marker. The relevant
' slice for the current candidate was saved out (87 KB) so a later pass does not have to
' regenerate the whole-probe log to get back to this point.
'
' NODE-ID DECODING (not documented anywhere before this pass -- the dump prints bare
' `node->reg->id`, no source-variable name, no bank flag):
'   - `createGraph()` only links an edge between two nodes of the SAME `bank`
'     (`x->bank==y->bank`), so a node's edge-list membership identifies its bank by
'     association with the precoloured physical registers, which are always the first
'     N entries `frame->regs` and always have `degree=2147483647` (already-coloured, so
'     `node->degree=node->colored()?0x7fffffff:...`).
'   - ids 0-7 = the INT bank's 8 precoloured slots in construction order
'     (eax,edx,ecx,ebx,esi,edi,ebp,esp -- ids 6/7 are unused in the graph, masked out by
'     `reg_masks[0]=0x3f`).
'   - ids 8-14 = the FLOAT bank's 7 precoloured slots (fp0..fp6, `reg_masks[1]=0x7f`).
'     Confirmed directly: nodes 8-14 all share the SAME usage/edges shape (id 8 has
'     usage=34, ids 9-14 usage=30, all edging to the identical set
'     `{17,18,19,20,25,26,27,32,33,36,37,122,124,186,188}`) -- exactly the "7 identical
'     physical registers, each touched at every FP call site" signature.
'   - Therefore the FLOAT bank's real (non-precoloured) temporaries in THIS function are
'     precisely that 15-element set: `{17,18,19,20,25,26,27,32,33,36,37,122,124,186,188}`.
'     (INT-bank temporaries with superficially similar large degree, e.g. 21/22/23/24,
'     are a red herring -- they edge to ids 0/1/2 = eax/edx/ecx, not 8-14, so they are
'     INT, not FLOAT.)
'
' GROUND TRUTH ON THE REAL SPILL, from the `Spilled:` trace (selectRegs(), the FINAL,
' non-optimistic spill -- NOT the `Spilling:` trace, which is spill()'s worklist selection
' and does not by itself guarantee a real memory location; confirmed by reading both
' functions' source in cgallocregs.cpp this pass):
'   pass 1 really spills 20 nodes: `17 18 19 20 21 23 24 25 26 27 29 31 32 33 36 37 122 124
'   186 188` (`__bb_TFormation_GetPlayerXY passes=2 spills=20` is the trailer line). ALL 15
'   identified FLOAT-bank temporaries are in this list -- i.e. in OUR compile, at least once,
'   EVERY non-parameter/non-trivial float value in this function fails to keep a permanent
'   FPU-pseudo-register colour and round-trips through a real memory slot somewhere. This is
'   consistent with the body still being length-EXACT overall (a spilled PARAMETER's memory
'   slot is its own pre-existing argument slot at a positive `[ebp+N]`, so spilling costs
'   nothing extra there -- ONLY a spilled Local pays for a fresh negative-offset slot AND an
'   initial store) -- but it means the search for "why does leg spill while a1 doesn't" is
'   not answerable from THIS coarse a signal (degree/block_count/cost are printed per NODE for
'   its WHOLE-FUNCTION lifetime, not per the one block boundary where the divergence from the
'   original actually happens), and the dump does not (yet) name which of the 15 ids IS `leg`
'   vs `a1`/`a2`/`a3`/`a4`/`dxRatio`/`wSpacing`/`hSpacing`/`wScale`/`hScale` -- there is no
'   source-variable-name instrumentation anywhere in this pass. Attempting to infer the
'   mapping from usage/degree magnitude alone (e.g. "the four with the biggest block_count
'   must be a1..a4, since they are live almost everywhere") was tried informally this pass and
'   did NOT produce a confident, falsifiable assignment -- do not trust such a mapping without
'   adding a real correlation (see next step).
'
' NEXT STEP FOR WHOEVER PICKS THIS UP: the coarse whole-function dump is not enough; it needs
' to be correlated to individual IR statements. Two ways in, neither tried yet:
'   (a) Add a second `#ifdef _DEBUG_REGALLOC` print inside `createGraph()`'s `def`/`use` walk
'       (cgallocregs.cpp ~line 152-165, the `for( def_it=as->def.begin(); ... )` loop) that
'       also emits `as->assem` (the not-yet-fixed-up FASM text, which DOES still carry
'       source-adjacent context via bcc's own comments/labels in some builds) alongside each
'       `x->usage+=use_cost` -- that directly ties node ids to the statement that touches them.
'   (b) Cheaper and does not require another rebuild: run the SAME instrumented bcc
'       against a MINIMAL synthetic probe shaped like the row=0 span in isolation (a Float
'       PARAMETER and a Float LOCAL, each reassigned inside two prior `If cond Then x=...`
'       clamps with no `Else`, then read inside a pure-integer nested `If`, then both read at
'       a final `Return`) -- with only 2-3 float values total the dump is small enough to read
'       by eye and unambiguously identifies which id is the parameter and which is the Local,
'       closing the mapping gap without touching the 2898-byte body at all. This is the
'       natural next move; not done this pass for lack of remaining time budget.
' Neither of these was attempted this pass; recovering and reading the raw dump/mechanism
' (this section) is the actual contribution. The saved graphdump file already contains
' everything needed to resume at step (a) or (b) without re-running the 900s whole-probe build.
'
' === TRIED the cheap option (b) above -- MINIMAL SYNTHETIC PROBE. Result is
' a NEGATIVE finding that rules the approach out in its minimal form, not a byte fix ===
'
' State reconfirmed unchanged: MISMATCH, our_len 2898 == orig_len 2898, same 3 same-length
' subs at orig +237/+327/+2802 (setbe/setae). No byte fix landed. Body below is IDENTICAL to
' the state above -- only this header grew. Re-ran `localise_diff.py` fresh this pass too: still
' `31 length-changing gap(s), +0 bytes total`, `delta accounted for by gaps: +0 of +0 ->
' COMPLETE`, confirming the 3 setbe/setae subs remain the ONLY real defect (everything else in
' the aligner's noisy middle section is the already-documented cascaded-slot-renumbering
' artefact, re-verified, not a new lead).
'
' THE EXPERIMENT: built a probe with TFormation.GetPlayerXY's real signature (so
' harness.build_source's reflection lookup works unmodified) but a deliberately tiny body --
' one Float PARAMETER (a1) and one Float LOCAL (legT), each clamped by two prior
' `If cond Then x=...` (no Else), separated by a pure-integer `If` with zero float traffic,
' both read at the very end -- structurally the same shape as the real row=0 span. Ran it
' through the SAME instrumented bcc as above, via `harness.build_source` +
' `harness.BMK makeapp -r -t console` directly (not `try_method`). Script saved at
' `scripts/w22_L3_synth.py`; the full log and the extracted graph slice were scratch-only
' output, so the SCRIPT is the artefact worth keeping since it is trivially rerunnable.
'
' RESULT: in this minimal probe, `__bb_TFormation_GetPlayerXY`'s allocator dump shows NO
' `Spilling:`/`Spilled:` trace at all -- every one of the 12 real (non-precoloured,
' non-coalesced) temp nodes reaches the `;--- Popping stack ---;` phase and gets a `Colored:`
' line. Nothing spills. This holds for the float cluster too (the 8-node component
' {17,18,19,20,27,31,35,36}, identified as float-bank by elimination -- it shares no edges
' with the int-bank component {0,6,16,21,23,24,28,29,32,33,34} rooted at precoloured id=0/eax
' -- all 8 either get simplified+coloured directly or get coalesced into a sibling that does).
' Also notable: the FP-precoloured ids 8-14 (fp0-fp6, per the decoding above) carry EMPTY edge
' lists here (`edges=[ ]`), unlike the real function where all 15 float temps were found
' edging to the full {8..14} set -- i.e. this minimal shape never creates the FPU-stack-depth
' pressure that forces an interference edge against a precoloured FP slot at all.
'
' CONCLUSION -- rules out option (b) AS WRITTEN, does not just leave it "not yet
' tried": a probe minimal enough to hand-read the dump by eye is also too minimal to
' REPRODUCE the phenomenon under investigation (leg-spills-but-a1-doesn't never happens here --
' NEITHER spills). So the divergence is not a two-value-shape property answerable in isolation;
' it needs enough co-live surrounding values to generate real spill pressure, which puts the
' dump back to the scale already found unreadable by eye. Confirms (does not merely
' repeat) the standing conclusion that the effect is a whole-function interference
' property, not a local one.
'
' NEXT STEP FOR WHOEVER PICKS THIS UP: option (a) above -- instrumenting
' `createGraph()`'s def/use walk (cgallocregs.cpp ~line 152-165) to also print `as->assem` (the
' pre-fixup FASM text) per def/use, then rebuilding `bcc.exe` and re-running the ACTUAL
' 2898-byte body through it -- is now the only unexplored path with a plausible payoff; a
' bigger-but-still-synthetic probe (e.g. deliberately padding in enough dummy co-live floats to
' force a real spill, then checking whether the padded-in Local or the padded-in parameter is
' the one that spills) is a cheaper intermediate step worth trying before a bcc rebuild, and was
' NOT attempted this pass for lack of remaining time budget.

'!Global g_form_height:Float
'!Global g_form_width:Float
'!Global g_form_widthnoball:Float
'!Global g_form_depth:Float
'!Global g_form_widepush:Float
'!Global g_form_xshift:Float
'!Global g_form_xshiftnoball:Float
'!Global g_form_yshift:Float
'!Global g_form_ymargin:Float
'!Global g_form_wscale_default:Float
'!Global g_form_hscale_default:Float
'!Global g_form_posnoise:Float
'!Global g_player_int01:Int
	Method GetPlayerXY:Float(a0:Int, a1:Float, a2:Float, a3:Float, a4:Float, a5:Int, a6:Int, a7:Float Ptr, a8:Float Ptr, a9:Float, a10:Float)
		a2 = -a2
		Local dxRatio:Float = a1 / (a3 / 2.0)
		a1 = a1 + a3 / 2.0
		a2 = a2 + a4 / 2.0
		Local col:Int = Self.GetColFromSelectionNo(a0)
		Local row:Int = Self.GetRowFromSelectionNo(a0)
		Local wSpacing:Float
		If a6 <> 0
			wSpacing = a3 / (g_form_width * a9)
		Else
			wSpacing = a3 / (g_form_widthnoball * a9)
		EndIf
		Local hSpacing:Float = a4 / (g_form_height * a10)
		Local yOff:Int = 0
		Local xOff:Int = 0
		If a1 < wSpacing * 3.0 Then a1 = wSpacing * 3.0
		If a3 - wSpacing * 3.0 < a1 Then a1 = a3 - wSpacing * 3.0
		If a2 < hSpacing * 1.0 Then a2 = hSpacing * 1.0
		If a4 - hSpacing * 1.0 < a2 Then a2 = a4 - hSpacing * 1.0
		If a5 = 1
			wSpacing = wSpacing + (a4 - a2) / 30.0
		Else
			wSpacing = wSpacing + a2 / 30.0
		EndIf
		Local wScale:Float = g_form_wscale_default
		Local hScale:Float = g_form_hscale_default
		Local bVar8:Int
		If a5 = 1
			Select a6
				Case 0
					a2 = a2 + hSpacing * g_form_depth
				Case 1
					a2 = a2 + g_form_depth * 0.5 * hSpacing
			End Select
			Select row
				Case 0
					yOff = Int(hSpacing * 1.25)
					If a6 <> 0 Then hScale = 1.8 Else hScale = 1.0
				Case 1
					yOff = Int(hSpacing * 0.5)
					If a6 <> 0 Then hScale = 1.6 Else hScale = 1.2
				Case 2
					yOff = Int(-(hSpacing * 0.25))
					If a6 <> 0 Then hScale = 1.4 Else hScale = 1.4
				Case 3
					yOff = Int(-(hSpacing * 1.0))
					If a6 <> 0 Then hScale = 1.2 Else hScale = 1.6
				Case 4
					yOff = Int(-(hSpacing * 1.75))
					If a6 <> 0 Then hScale = 1.0 Else hScale = 1.8
			End Select
			If row <= 2
				If a6 <> 0
					If col = 0 Or col = 6
						yOff = Int(Float(yOff) - hSpacing * g_form_widepush)
					EndIf
				Else
					bVar8 = (dxRatio > 0.0 And col = 0) Or (dxRatio <= 0.0 And col = 6)
					If bVar8
						yOff = Int(Float(yOff) - hSpacing * (g_form_widepush * 0.5) * Abs(dxRatio))
					EndIf
				EndIf
			EndIf
			Select col
				Case 0
					xOff = Int(-(wSpacing * 4.5))
					wScale = 1.5
				Case 1
					xOff = Int(-(wSpacing * 3.5))
					wScale = 2.0
				Case 2
					xOff = Int(-(wSpacing * 1.5))
					wScale = 3.0
				Case 3
					xOff = 0
					wScale = 3.5
				Case 4
					xOff = Int(wSpacing * 1.5)
					wScale = 3.0
				Case 5
					xOff = Int(wSpacing * 3.5)
					wScale = 2.0
				Case 6
					xOff = Int(wSpacing * 4.5)
					wScale = 1.5
			End Select
		Else
			Select a6
				Case 0
					a2 = a2 - hSpacing * g_form_depth
				Case 1
					a2 = a2 - g_form_depth * 0.5 * hSpacing
			End Select
			Select row
				Case 0
					yOff = Int(-(hSpacing * 1.25))
					If a6 <> 0 Then hScale = 1.8 Else hScale = 1.0
				Case 1
					yOff = Int(-(hSpacing * 0.5))
					If a6 <> 0 Then hScale = 1.6 Else hScale = 1.2
				Case 2
					yOff = Int(hSpacing * 0.25)
					If a6 <> 0 Then hScale = 1.4 Else hScale = 1.4
				Case 3
					yOff = Int(hSpacing * 1.0)
					If a6 <> 0 Then hScale = 1.2 Else hScale = 1.6
				Case 4
					yOff = Int(hSpacing * 1.75)
					If a6 <> 0 Then hScale = 1.0 Else hScale = 1.8
			End Select
			If row <= 2
				If a6 <> 0
					If col = 0 Or col = 6
						yOff = Int(hSpacing * g_form_widepush + Float(yOff))
					EndIf
				Else
					bVar8 = (dxRatio < 0.0 And col = 0) Or (dxRatio >= 0.0 And col = 6)
					If bVar8
						yOff = Int(Float(yOff) + hSpacing * (g_form_widepush * 0.5) * Abs(dxRatio))
					EndIf
				EndIf
			EndIf
			Select col
				Case 0
					xOff = Int(wSpacing * 4.5)
					wScale = 1.5
				Case 1
					xOff = Int(wSpacing * 3.5)
					wScale = 2.0
				Case 2
					xOff = Int(wSpacing * 1.25)
					wScale = 3.0
				Case 3
					xOff = 0
					wScale = 3.5
				Case 4
					xOff = Int(-(wSpacing * 1.25))
					wScale = 3.0
				Case 5
					xOff = Int(-(wSpacing * 3.5))
					wScale = 2.0
				Case 6
					xOff = Int(-(wSpacing * 4.5))
					wScale = 1.5
			End Select
		EndIf
		If g_player_int01 = 1 Then hScale = hScale * g_form_ymargin
		Local xAdj:Float = a1 - Float(xOff)
		If a6 <> 0
			a1 = xAdj - (xAdj - (a3 / 2.0 - Float(xOff))) / g_form_xshift
		Else
			a1 = xAdj - (xAdj - (a3 / 2.0 - Float(xOff))) / g_form_xshiftnoball
		EndIf
		Local leg:Float = (a2 + Float(yOff)) - ((a2 + Float(yOff)) - (a4 / 2.0 + Float(yOff))) / g_form_yshift
		If a1 < wSpacing * wScale * 0.5 Then a1 = wSpacing * wScale * 0.5
		If a3 - wSpacing * wScale * 0.5 < a1 Then a1 = a3 - wSpacing * wScale * 0.5
		If leg < hSpacing * hScale * 0.5 Then leg = hSpacing * hScale * 0.5
		If a4 - hSpacing * hScale * 0.5 < leg Then leg = a4 - hSpacing * hScale * 0.5
		If row = 0 And col > 1 And col < 5
			If a5 = 1
				If leg < a4 / 2.0 - a4 / 12.0 Then leg = a4 / 2.0 - a4 / 12.0
			ElseIf a4 / 12.0 + a4 / 2.0 < leg
				leg = a4 / 12.0 + a4 / 2.0
			EndIf
		EndIf
		a7[0] = a1 - a3 / 2.0
		a8[0] = leg - a4 / 2.0
		a8[0] = -a8[0]
		Return g_form_posnoise
	End Method

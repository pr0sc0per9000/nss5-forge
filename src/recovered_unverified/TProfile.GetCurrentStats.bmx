' UNVERIFIED -- NOT PROVEN. Do not promote to src/recovered/ without closing the gap below.
' TProfile.GetCurrentStats   VA 0x00569A31
' Ghidra-authoritative length: 211 bytes.  Ours: 215 bytes (delta +4).  status=MISMATCH mode=len.
'
' Semantics are believed CORRECT (see mapping below) and fully faithful. localise_diff.py
' reports verdict COMPLETE: all 8 length-changing gaps trace to exactly ONE root cause, not
' eight independent problems.
'
' ROOT CAUSE (confirmed, not guessed): register allocator gives edi to `a0` in our build,
' while the original gives edi to `Self` for the whole function and never colours `a0` at
' all (every a0 use in the original is a direct `cmp reg,[ebp+0xc]` / `cmp [ebp+0xc],imm`
' memory operand, no register ever loaded for it). In ours, Self loses edi and every
' Self.field access becomes a 2-instruction reload (`mov eax,[ebp+8]` then
' `mov eax,[eax+N]`) instead of the original's 1-instruction `mov eax,[edi+N]`. This is a
' section-18/22 spill-victim ranking flip (usage/degree/block_count), not a wrong
' declaration and not a wrong field/call mapping.
'
' RULED OUT (produced byte-identical output, i.e. no effect on the entry-block coloring):
'   * swapping comparison operand order: `s.statlevel = a0` vs `a0 = s.statlevel`
'   * swapping `Self.clubid = s.teamid` vs `s.teamid = Self.clubid`
'   * dropping explicit `Self.` on field/method references (implicit receiver)
' NOT YET TRIED: deliberately shrinking Self's block_count by restructuring statement
' placement (section 22.3, lever 3) -- e.g. hoisting the two post-loop Self-receiver calls
' (CreateNewInternationalStats / recursive GetCurrentStats) into a form that reduces the
' number of blocks where Self is live-in+live-out. Time-boxed out this pass.
'
' ADDITIONAL DATA POINTS (still not closed, ruled out further, do NOT retry
' these exact forms):
'   * early-return trailer (`If a0<>4 Then Return Null` / body / `Return Self.GetCurrentStats(4)`
'     instead of the If/EndIf block) -- byte-identical to baseline, 215/211, first_diff=11.
'     Does not touch the a0-vs-Self coloring at all.
'   * hoisting `Self.date.GetYear()` into a `Local yr:Int` BEFORE the loop -- WRONG SEMANTICS
'     (original recomputes GetYear() every iteration -- confirmed from full original
'     disassembly at 0x00569A8C-0x00569A98, inside the loop, between the statlevel test and
'     the eq-compare) but happened to land at 212/211 (delta +1, closest yet). Do not use --
'     it is not faithful, it is a coincidence of the coloring being perturbed by the extra
'     Local.
'   * swapping BOTH the outer And-operand order (`a0 = s.statlevel And
'     Self.date.GetYear() = s.year`) AND the two inner comparisons (`s.teamid = Self.clubid`)
'     together flips the sign of the delta: 207/211 (delta -4) instead of 215/211 (delta +4).
'     Confirms the a0-vs-Self register choice is sensitive to operand order (section 10.1
'     applies to allocation, not just cmp encoding) but neither direction reaches 0.
'   * Full original disassembly captured this pass (0x00569A31, 211 bytes) shows: edi=Self
'     for the WHOLE function (loaded once, never reloaded from [ebp+8]); esi=s (the EachIn
'     loop var, reassigned each iteration from NextObject's eax); ebx is used for exactly ONE
'     value, `s.year`, held live only across the single GetYear() call at 0x00569A95 (pushed
'     into ebx at 0x00569A8F, compared at 0x00569A9B, never touched again) -- i.e. ebx is a
'     genuinely short-lived callee-saved register, not a whole-function one. a0 is NEVER
'     loaded into any register in the original: all three uses are direct memory operands
'     (`cmp eax,[ebp+0xc]` and `cmp dword [ebp+0xc],4` x2) -- consistent with section 22.2's
'     allocSpill "parameter falls back to its own argument slot when it fails to colour"
'     (a0 costs bcc's allocator NO local_sz, hence sub esp,8 covers only the 2 real spills:
'     the enumerator temp at [ebp-4] and its saved eax at [ebp-8]).
'   * Manual usage-weight count (10^loop_level per def/use) on the header's original-order
'     body gives Self~23, a0~21 -- Self SHOULD outrank a0 by the section-18.2 rank rule, yet
'     every build of this shape gives a0 the register and Self the reload. This means either
'     the hand count is missing uses/defs bcc's IR inserts (e.g. an implicit temp per method
'     call) or block_count is doing the work here, not usage -- exactly section 18.4's
'     scenario, and exactly why this stayed open across two passes. NEXT STEP for whoever
'     picks this up: instrument with `scripts/w14S0_live.py`-style live-range census on a
'     matched sibling function to get bcc's ACTUAL usage/block_count numbers rather than a
'     hand count, since the hand count is demonstrably not predicting the observed outcome.
'
' FOLLOW-UP PASS (item 50 of refine.json, this session) -- used harness.try_method directly
' (isolated tree, no shared state touched) to test the two
' concrete untried levers this file's own notes point at. Both made things WORSE, so the
' baseline body below is confirmed to still be the best candidate found so far:
'   * Section 22.3 lever 3 (block_count / CFG shape): rewrote the loop guard from the
'     nested `If A And B / If.../ EndIf` (implicit fall-through-to-Next) into the De Morgan
'     `If Not A Or Not B Then Continue` guard-and-continue shape that fixed the analogous
'     TTable.Draw case (codegen-patterns.md section 22, "block_count IS a reachable
'     source-level lever"). Semantics-preserving (BlitzMax Or short-circuits, so GetYear()
'     is still only called when statlevel matches). Result: 217/211 (delta +6, worse than
'     +4), first_diff still 11 -- edi is still `a0`, the extra Not-logic just adds bytes.
'     RULED OUT.
'   * Standalone inner-compare swap (isolated from the already-ruled-out combined-swap data
'     point above): `Self.date.GetYear() = s.year` instead of `s.year =
'     Self.date.GetYear()`, outer short-circuit order left untouched. This is not merely a
'     local operand-order flip -- it perturbs the WHOLE function's interference graph (one
'     global graph-colouring pass over the whole body, per cgallocregs.cpp), and the entry
'     block changes shape: `sub esp,4` instead of `sub esp,8` (Self.careerstats gets
'     coloured into ebx instead of being spilled to [ebp-4] and immediately reloaded, itself
'     a divergence from the original's redundant load-store-reload of that temp). Result:
'     209/211 (delta -2, numerically smaller) but first_diff moves EARLIER, to byte 5
'     (inside the prologue's `sub esp,N` immediate) instead of byte 11 -- fewer leading
'     bytes match than the baseline, a strictly worse result despite the smaller |delta|.
'     RULED OUT; do not be tempted by the smaller absolute delta number alone.
' Net: the edi=a0-vs-Self allocation is unmoved by any semantics-preserving source rewrite
' tried across two sessions now (10+ variants). Left UNCHANGED below. The only lever not
' yet executed is an actual w14S0_live.py-style live-range census built for THIS pair of
' builds (not just citing the tool) to get real usage/degree/block_count numbers instead of
' a hand count -- that is real tooling work, not a source permutation, and is the honest
' next step rather than another blind rewrite.
'
' Field/call mapping (verified via object_model.json + vtable_map.tsv):
'   Self.careerstats   TProfile +0x40 (:TList of TStats_Team)
'   Self.date          TProfile +0x10 (:TMyDate)         -- date.GetYear() slot 0x54
'   Self.clubid        TProfile +0x20 (Int)
'   s.statlevel         TStats_Team +0x08
'   s.teamid            TStats_Team +0x0C
'   s.year              TStats_Team +0x10
'   slot 0x50 = TProfile.CreateNewInternationalStats  (confirmed in vtable_map.tsv)
'   slot 0x94 = TProfile.GetCurrentStats itself (this method calls itself recursively
'               after creating a new international-stats record when a0=4 and no
'               existing record matches the current year)
' Standard EachIn desugaring per codegen-patterns.md section 5 (ObjectEnumerator/
' HasNext/NextObject/bbObjectDowncast); TStats_Team classtable confirmed in the decompiled
' downcast operand.
'
' SIG (i):TStats_Team   -- a0 = stat level filter (4 = international)
'
' Body-only format: statements only, parameters are a0, a1, ...

For Local s:TStats_Team = EachIn Self.careerstats
	If s.statlevel = a0 And s.year = Self.date.GetYear()
		If a0 = 4 Then Return s
		If Self.clubid = s.teamid Then Return s
	EndIf
Next
If a0 = 4
	Self.CreateNewInternationalStats()
	Return Self.GetCurrentStats(4)
EndIf
Return Null

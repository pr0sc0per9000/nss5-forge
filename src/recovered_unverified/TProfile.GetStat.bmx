' NOT VERIFIED -- near miss only. Do NOT move to src/recovered without closing the gap.
' VA 0x00569329   772 bytes   vtable slot 0x88   sig (i,i,i,i)f
' TProfile.GetStat  -- KIND=Method, slot 0x88
' VA 0x00569329   ORIGINAL 772 bytes   sig (i,i,i,i)f
' OURS: 772 bytes -- SAME LENGTH, but 4 gaps that net to zero (localise_diff.py, worker
' w22_S6): the sub-loop that walks a TStats_Team.form:Int[] array (the "Case 18" branch,
' averaging match ratings) uses different registers for its loop counter/end-pointer than
' the original (ecx/edx in the original vs edx/eax in ours; see the two SUB entries below).
' Every OTHER byte in the 772 -- the Select dispatch table, all field offsets, every
' CreateGadgetImage-style non-issue here, both TList/TListEnum vtable-slot calls, the
' g_profile_float02/03/04 globals, the And-short-circuit average-when-cnt>0 tail -- is
' byte-identical; localise_diff confirms "delta accounted for by gaps: +0 of +0 -- COMPLETE"
' with only register-identity substitutions remaining, not a length problem.
'
' STRUCTURE, fully proven from harness.disasm_original (KIND=Method, so a0..a3 map onto the
' original's param_2..param_5 at [ebp+0xC]..[ebp+0x18]):
'   a0 = which stat to sum (dispatch value, see Select below)
'   a1,a2,a3 = forwarded straight to Self.GetStats(a1,a2,a3):TList  (slot 0x90, already
'     established by the verified TProfile.GetAverageForm.bmx)
'   TList.IsEmpty() [slot 0x38] gates an early return of g_profile_float02.
'   Otherwise result:Float starts at g_profile_float03, cnt:Int starts at 0, and a
'   `For Local s:TStats_Team = EachIn l` loop (ObjectEnumerator/HasNext/NextObject, slots
'   0x8c/0x30/0x34, plus the usual _bbObjectDowncast(ClassTable_TStats_Team) with its
'   implicit Null-skip -- same shape as the verified TCombo.DrawItems.bmx) walks it. The
'   dispatch on a0 is proven to be a `Select`, NOT an If/ElseIf chain (codegen-patterns
'   10.2): the original loads a0 into eax ONCE at 0x005693B8 then runs a flat cmp/je chain
'   against 1,2,3,4,6,17,9,10,11,5,12,13,14,15,16,18 in that exact order, with every case
'   body placed out-of-line and ending in `jmp` to the shared post-loop point -- an
'   If/ElseIf chain (tried first) instead re-tests a0 per branch and inlines each body,
'   which came out 147 bytes shorter at this VA alone.
'   Case 16 dispatches to nothing (its target is the bare shared `jmp`, same target as every
'   other case's tail jump) -- reproduced as an explicitly empty `Case 16`. ' ORIGINAL BUG
'   (or at least ORIGINAL GAP): stat id 16 has a dispatch slot but no effect (VA 0x0056957E).
'   Case 18 (average match rating) is the one with the array walk: accumulate
'   `v / 10.0` over s.form on the x87 stack (never spilled to a Local in the original either
'   -- confirmed by the missing store between the fld and the loop), then, ONLY if
'   s.form.Length <> 0 (the guide-11.2 .Length spelling, offset +0x14, already established by
'   TProfile.GetAverageForm.bmx), add total/Length into result and cnt :+ 1. The
'   `fstp st(0)` on the Length=0 path is just discarding the unused x87 accumulator.
'   Field offsets used (all already fixed by src/recovered/TStats_Team.*): distance(+0x44
'     via param_2=1... -- see the table below), shots(+0x1c,2), passes(+0x28,3),
'     assists(+0x2c,4), headers(+0x30,6), tackles(+0x34,17), yellowcards(+0x3c,9),
'     redcards(+0x40,10), fouls(+0x38,11), goals(+0x20,5), appearances(+0x14,12),
'     subs(+0x18,13), hattricks(+0x24,14), manofthematch(+0x48,15), form(+0x4c,18).
'   Final tail is `If a0 = 18 And cnt > 0 Then result :/ cnt` -- proven by the
'   sete/movzx-then-setg/movzx-then-AND-via-shared-eax short-circuit chain at 0x5695EE.
'
' THE ONE UNCLOSED GAP: a Local (`Local f:Int[] = s.form`) had to be introduced before the
' array EachIn to get the total byte count to agree at all (without it: -5 bytes, a REAL
' length deficit, not just a register choice -- so some such split is genuinely load-bearing,
' just not exactly this one). With it, the array-bounds setup (data-pointer + 0x18,
' end = start + BBArray-length-in-bytes) computes the identical VALUES in the identical
' NUMBER of instructions and bytes, but the original keeps the loop counter in ecx and the
' end-pointer in edx (matching the outer function's ebx/esi/edi register economy elsewhere),
' while our build keeps the counter in edx and the end in eax. Tried: reordering `f`/`total`
' declaration (made it WORSE, -8), reusing `s.form` directly with no Local (worse, -5 net).
' Left for a pass with section-18/22 spill-order budget: this is a function-wide
' register-coloring question (what ebx/esi/edi/etc. are pinned to elsewhere in the 772-byte
' body), not something guessable from this loop in isolation.
'
' RE-VERIFIED (status/score/TProfile.GetStat.txt, 730/772=94.6%, len delta +0), against the
' live src/assembled/nss5_assembled.exe and a capstone disassembly of both sides -- NO CODE
' CHANGED this pass, both parts of the 42-byte gap confirmed non-actionable from source:
'   (a) ~13 bytes (offsets 54-56/65-67/107-109/122-123/134-135) are the four
'       g_profile_float02/03/04 FLD operands + the 10.0 divisor -- pure data-segment
'       relocation, not a source defect. Proof: re-ran the SAME raw byte scorer
'       (scripts/bytematch.py, which does NOT mask relocations -- score_bodies.py calls it
'       directly) against TProfile.GetAverageForm, a sibling already banked to
'       src/recovered/ as byte-PERFECT. It still reads 283/309 (91.6%) for the identical
'       reason (its four .rdata Float literals land at different absolute addresses in our
'       assembled probe than in NSS5.exe). A body the project itself certifies correct
'       cannot clear this bar, so neither can this one, by source changes alone.
'   (b) ~29 bytes (offsets 601-644, the Case 18 array walk) -- disassembled BOTH sides at
'       their current compiled VAs (orig 0x569580-0x5695ae, ours 0x5b7d1a-0x5b7d48):
'       identical instruction COUNT, identical instruction ORDER, identical operations
'       (mov/add/fild/fdiv/faddp/cmp/jne) -- only the register LABELS differ. Original
'       holds {arrayptr, loopctr, endptr, scratch} in {ebx, ecx, edx, eax}; ours holds the
'       same four roles in {eax(transient), edx, eax(final), ebx}. This is bcc's expression-
'       temporary allocator (a stack-depth-keyed scratch-register rotation, not a
'       source-visible construct) reacting to something upstream of this branch -- not a
'       missing statement. Confirms the prior worker's conclusion; not re-attempted blind
'       given the two already-documented attempts both regressed (-8, -5). Left as is.
'
' FOLLOW-UP PASS (scripts/workflow/walloc_report.py, worker 433) -- NO CODE CHANGED this
' pass. Read out bcc's own allocator trace for the whole function to check whether the
' Case 18 rotation is source-reachable: the four contested registers (arrayptr, loopptr,
' endptr, loop-body scratch) are internal temporaries the EachIn-over-Int[]-array codegen
' creates for itself, not named Locals -- they carry no source name in the trace (this is
' exactly the hidden-enumerator limit the tool's own header documents for TTable.Draw), so
' only `f` and `total` are addressable levers in this block, and both were already
' exhausted. Re-ran both existing candidates fresh against this session's oracle to confirm
' the verdict still holds: declaring `f` ahead of `total` scores 724/772 matched (worse
' than the 729/772 this file already gets); referencing `s.form` directly in the For..EachIn
' with no `f` Local collapses the array-walk shape itself, landing at a 767-byte candidate
' and 533/772 matched -- a real length deficit, not a register swap. The `Local f:Int[] =
' s.form` statement is REQUIRED to hold total length at 772 (drop it and the array-walk
' codegen shrinks to a different, shorter shape) and is SIMULTANEOUSLY the reason the
' rotation exists: its own tmp() call shifts every EachIn-internal temp's sequential id by
' one slot relative to the original, which evaluates `s.form` directly as the loop's source
' expression with no separate materializing statement ahead of it. The two levers pull in
' opposite directions from the same cause. No third placement remains: `total` and `f` are
' the only two statements in this block with reordering freedom (each must precede its own
' first use), their only other relative order regresses, the post-loop `s.form.Length` check
' already matches byte-for-byte, and any statement moved in from outside this block risks
' the roughly 700 bytes elsewhere that already match. Verdict: the 43-byte gap sits entirely
' in unnamed compiler-internal register selection for an EachIn array walk, with no
' remaining statement-placement lever under this toolchain. UNCERTAIN: whether a change to
' cgallocregs.cpp's own tmp-id/coalescing order (out of scope -- source only) would close it.
'
' Body-only format below (statements only, Self implicit, parameters are a0..a3).
	'!Global g_profile_float02:Float
	'!Global g_profile_float03:Float
	'!Global g_profile_float04:Float
	Local l:TList = Self.GetStats(a1, a2, a3)
	If l.IsEmpty() Then Return g_profile_float02
	Local result:Float = g_profile_float03
	Local cnt:Int = 0
	For Local s:TStats_Team = EachIn l
		Select a0
			Case 1
				result :+ s.distance
			Case 2
				result :+ s.shots
			Case 3
				result :+ s.passes
			Case 4
				result :+ s.assists
			Case 6
				result :+ s.headers
			Case 17
				result :+ s.tackles
			Case 9
				result :+ s.yellowcards
			Case 10
				result :+ s.redcards
			Case 11
				result :+ s.fouls
			Case 5
				result :+ s.goals
			Case 12
				result :+ s.appearances
			Case 13
				result :+ s.subs
			Case 14
				result :+ s.hattricks
			Case 15
				result :+ s.manofthematch
			Case 16
			Case 18
				Local total:Float = g_profile_float04
				Local f:Int[] = s.form
				For Local v:Int = EachIn f
					total :+ v / 10.0
				Next
				If s.form.Length <> 0
					result :+ total / s.form.Length
					cnt :+ 1
				EndIf
		End Select
	Next
	If a0 = 18 And cnt > 0
		result :/ cnt
	EndIf
	Return result

' TProfile.GetCurrentStats
' VA 0x00569a31   211 bytes   vtable slot 0x94   sig (i):TStats_Team
' byte-identical vs NSS5.exe (211/211, harness mode=reloc, first_diff=None, under
'   NSS5_NO_LEARN=1, learned_helpers=None; reproduced 4/4 across separate process launches
'   -- see "why re-verify occasionally" below, this body sits on an exact allocator tie).
'
' WHAT CLOSED IT, after this body had been parked for three passes as "allocator-only,
' not reachable from source". That diagnosis was wrong. There were TWO independent source
' defects, and the second one was masking the first:
'
'   1. THE IN-LOOP a0 TEST IS A `Select`, NOT AN `If`. Two independent tells in the
'      original at 0x00569AA8, both from codegen-patterns 10.2:
'        * `Select` evaluates its subject ONCE into a register. The original emits
'          `mov eax,[ebp+0xc]` / `cmp eax,4` (6 bytes). Every If form -- `If a0 = 4`,
'          `If a0 <> 4 ... Else` -- folds the spilled parameter straight into the compare
'          as `cmp dword [ebp+0xc],4` (4 bytes), which is what our old body emitted.
'        * `Select` is LONGER than the equivalent If/ElseIf (10.2 measured this three
'          times). The original is exactly 2 bytes longer here than the If/Else form.
'      Layout agrees: `je` forward to the Case-4 body at +141, Default falling through at
'      +127, and the `jmp` over the Case body at +139 (0x00569ABC, `EB 04`).
'   2. THE INNER COMPARE OPERANDS ARE `s.teamid = Self.clubid`, not the reverse. The
'      original loads the RHS first -- `mov eax,[edi+0x20]` (Self.clubid) then
'      `cmp [esi+0xc],eax` (s.teamid) -- i.e. LHS is s.teamid (23.4: operand order
'      survives into the bytes even when the operation commutes).
'      This file's old header recorded that swap as RULED OUT / "byte-identical". It was
'      byte-identical only while Self was spilled: with Self in memory both orders lower
'      to the same 9-byte shape, so the test could not see the difference. Once Self is
'      in edi the two orders differ. DO NOT trust a ruled-out operand swap that was
'      measured under the wrong register map.
'
' THE ALLOCATOR STORY, MEASURED (scripts/workflow/walloc_report.py, instrumented bcc).
' The old header's root cause -- "the allocator gives edi to a0 instead of Self" -- was a
' correct OBSERVATION and a wrong DIAGNOSIS: the register choice was a consequence of
' defect 1, not an independent compiler problem. cost = usage/(degree*block_count):
'
'   shape                        the three contested long-lived nodes      pick outcome
'   ---------------------------  ---------------------------------------  ---------------
'   OLD body (two sequential If) u=24 bc=11 -> 0.198347                    24-node spilled
'                                u=22 bc=10 -> 0.200000  (x2)              FIRST, by 0.8%
'   If/Else form                 u=24 bc=12 -> 0.181818                    EXACT 3-WAY TIE
'                                u=22 bc=11 -> 0.181818  (x2)              (24/12 = 22/11)
'   `Select` form (this body)    u=24 bc=12 -> 0.181818                    same tie, scan
'                                u=22 bc=11 -> 0.181818  (x2)              order resolves
'                                                                          it the other way
'   (degree was 11 at each of these pick points; costs quoted at that point.)
'
' Read that table carefully, because it is the honest result: `Select` did NOT move
' block_count. V1 (If/Else) and this body have IDENTICAL usage/degree/block_count. What
' the Select changed is the node set and therefore the scan order of the pointer-ordered
' std::set the spill scan walks, and the tie fell the other way. block_count IS a real
' lever here and it was measured working (below) -- it is just not what closed this body.
'
' LIVENESS LEVER, MEASURED AND CONFIRMED BY ADVANCE PREDICTION (keep this, it generalises).
' Prediction registered before the build: adding ONE basic block inside the loop in which
' both the 24-usage and the 22-usage values are live-in AND live-out should take them to
' bc 13 and bc 12, making the 22-node strictly cheaper (22/(11*12)=0.166667 vs
' 24/(11*13)=0.167832) and flipping edi. Measured: exactly that, all four numbers, and the
' emitted code took the original's register map (first divergence moved from +9 to +74,
' i.e. the whole prologue and Self's edi load became byte-exact).
' The general condition for the 24-usage value to keep the register is
'         block_count(22-node) / block_count(24-node) > 22/24 = 11/12.
' Structurally block_count(24) = block_count(22) + 1 here, because Self's last use
' (Self.GetCurrentStats(4)) is one block after a0's last use (the post-loop `If a0 = 4`),
' so the ratio can only be reached at bc(22) >= 12 -- which the original's instruction
' stream has no room for. Liveness alone could NOT have closed this body. The statement
' form had to be right first.
'
' WHY RE-VERIFY OCCASIONALLY. The winning decision is an EXACT cost tie (0.181818 three
' ways), resolved by the order a std::set<Node*> is walked -- ordered by heap pointer, not
' by anything about the program (walloc_report.py's own docstring warns about this for
' near-ties). It reproduced 4/4 here across separate processes and across two different
' bcc binaries (stock and instrumented), so it is stable in practice, but if this body
' ever reports MISMATCH after an unrelated change, suspect the tie before suspecting the
' source.
'
' NOTE FOR THE ALLOCATOR-KNOB WORK (docs/reference/allocator-knob-sweep.md). This body was
' in the 28-body screen set for all six knobs, carrying the OLD source shape -- in which
' there is no tie at all (0.198347 vs 0.200000, a clear winner). K2 (`cost<min` ->
' `cost<=min`, last-wins-on-tie) therefore could not have moved it even in principle. Any
' knob conclusion drawn about this body from that sweep is about the wrong source.
'
' Field/call mapping (object_model.json + vtable_map.tsv):
'   Self.careerstats   TProfile +0x40 (:TList of TStats_Team)
'   Self.date          TProfile +0x10 (:TMyDate)   -- date.GetYear() slot 0x54
'   Self.clubid        TProfile +0x20 (Int)
'   s.statlevel        TStats_Team +0x08
'   s.teamid           TStats_Team +0x0C
'   s.year             TStats_Team +0x10
'   slot 0x50 = TProfile.CreateNewInternationalStats
'   slot 0x94 = TProfile.GetCurrentStats itself (recurses once after creating a new
'               international-stats record when level=4 and no record matches this year)
' Standard EachIn desugaring per codegen-patterns 5 (ObjectEnumerator/HasNext/NextObject/
' bbObjectDowncast); `sub esp,8` = careerstats temp at [ebp-4] and the enumerator at
' [ebp-8]. Self keeps edi for the whole function, s is esi, s.year is a short-lived ebx,
' and the level parameter never takes a register at all -- all three of its uses are
' direct memory operands on its own argument slot [ebp+0xc] (22.2: a parameter that fails
' to colour falls back to its argument slot and costs no local_sz).
'
' a0 is the stat-level filter (4 = international). Parameter named a0 per the
' src/recovered convention (386 of 396 parameterised bodies use it; localise_diff's CLI
' does not apply reverify.body_of's positional rename, so a real name builds only through
' body_of and BUILD_FAILs through the CLI).
'
' Self.date.GetYear() is recomputed every iteration. Do not hoist it into a Local before
' the loop -- confirmed from the original at 0x00569A8C-0x00569A98, the call is inside the
' loop between the statlevel test and the year compare.
	Method GetCurrentStats:TStats_Team(a0:Int)
		For Local s:TStats_Team = EachIn Self.careerstats
			If s.statlevel = a0 And s.year = Self.date.GetYear()
				Select a0
					Case 4
						Return s
					Default
						If s.teamid = Self.clubid Then Return s
				End Select
			EndIf
		Next
		If a0 = 4
			Self.CreateNewInternationalStats()
			Return Self.GetCurrentStats(4)
		EndIf
		Return Null
	End Method

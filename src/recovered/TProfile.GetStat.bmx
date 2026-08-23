' VERIFIED byte-identical vs NSS5.exe -- harness.try_method MATCH 772/772, first_diff=None,
' mode='reloc', under NSS5_NO_LEARN=1, reproduced 3/3 on separate process launches (worker 230).
' VA 0x00569329   772 bytes   vtable slot 0x88   sig (i,i,i,i)f
' TProfile.GetStat  -- KIND=Method, slot 0x88
'
' STRUCTURE, proven from harness.disasm_original (KIND=Method, so a0..a3 map onto the
' original's param_2..param_5 at [ebp+0xC]..[ebp+0x18]):
'   a0 = which stat to sum (dispatch value, see Select below)
'   a1,a2,a3 = forwarded straight to Self.GetStats(a1,a2,a3):TList  (slot 0x90, already
'     established by the verified TProfile.GetAverageForm.bmx)
'   TList.IsEmpty() [slot 0x38] gates an early return of g_profile_float02.
'   Otherwise result:Float starts at g_profile_float03, cnt:Int starts at 0, and a
'   `For Local s:TStats_Team = EachIn l` loop (ObjectEnumerator/HasNext/NextObject, slots
'   0x8c/0x30/0x34, plus the usual _bbObjectDowncast(ClassTable_TStats_Team) with its
'   implicit Null-skip -- same shape as the verified TCombo.DrawItems.bmx) walks it. The
'   dispatch on a0 is a `Select`, NOT an If/ElseIf chain (codegen-patterns 10.2): the
'   original loads a0 into eax ONCE at 0x005693B8 then runs a flat cmp/je chain against
'   1,2,3,4,6,17,9,10,11,5,12,13,14,15,16,18 in that exact order, with every case body
'   placed out-of-line and ending in `jmp` to the shared post-loop point -- an If/ElseIf
'   chain (tried first) instead re-tests a0 per branch and inlines each body, which came
'   out 147 bytes shorter at this VA alone.
'   Case 16 dispatches to nothing (its target is the bare shared `jmp`, same target as every
'   other case's tail jump) -- reproduced as an explicitly empty `Case 16`. ' ORIGINAL BUG
'   (or at least ORIGINAL GAP): stat id 16 has a dispatch slot but no effect (VA 0x0056957E).
'   Case 18 (average match rating) walks s.form:Int[]: accumulate `v / 10.0` on the x87
'   stack (never spilled to a Local -- confirmed by the missing store between the fld and
'   the loop), then, ONLY if s.form.Length <> 0 (the guide-11.2 .Length spelling, offset
'   +0x14, already established by TProfile.GetAverageForm.bmx), add total/Length into
'   result and cnt :+ 1. The `fstp st(0)` on the Length=0 path discards the unused x87
'   accumulator.
'   Field offsets used (all already fixed by src/recovered/TStats_Team.*): distance(+0x44,1),
'     shots(+0x1c,2), passes(+0x28,3), assists(+0x2c,4), headers(+0x30,6), tackles(+0x34,17),
'     yellowcards(+0x3c,9), redcards(+0x40,10), fouls(+0x38,11), goals(+0x20,5),
'     appearances(+0x14,12), subs(+0x18,13), hattricks(+0x24,14), manofthematch(+0x48,15),
'     form(+0x4c,18).
'   Final tail is `If a0 = 18 And cnt > 0 Then result :/ cnt` -- proven by the
'   sete/movzx-then-setg/movzx-then-AND-via-shared-eax short-circuit chain at 0x5695EE.
'
' HOW THE LAST 42 BYTES CLOSED, AND WHY EVERY EARLIER PASS MISSED IT.
' Three prior passes parked offsets +605..+645 (the Case 18 array walk) as "bcc's expression-
' temporary allocator reacting to something upstream -- not source-reachable", on the grounds
' that both sides had identical instruction COUNT and ORDER with only register LABELS differing.
' That reading was wrong on the ORDER claim, and the error hid the real defect. Lining the two
' loop bodies up instruction by instruction:
'     ORIGINAL +624  mov eax,[ecx] / mov [ebp-0x10],eax / fild [ebp-0x10] / add ecx,4 / fdiv / faddp
'     OURS     +624  mov ebx,[edx] / add edx,4 / mov [ebp-0x10],ebx / fild [ebp-0x10] / fdiv / faddp
' The pointer increment sits in a DIFFERENT PLACE. That is not an allocator decision: bcc's
' _src/compiler/stm.cpp `ForEachStm::evalArray` emits, in fixed order,
'     b->assignRef( var, next->forEachCast(var_ty) );          // var = *beg
'     b->emit( mov(beg, bop(CG_ADD,beg,lit(elem_ty->size()))) ); // beg :+ 4
' so anything emitted BETWEEN the element load and `add beg,4` has to be part of the
' `var = *beg` assignment itself. `forEachCast` falls through to `explicitCast`, so declaring
' the loop variable **Float** over an Int[] puts the whole Int->Float conversion
' (mov [ebp-0x10],reg ; fild [ebp-0x10]) inside that assignment, ahead of the increment --
' which is exactly the original's shape. With `v:Int` the conversion instead belongs to the
' body expression `v / 10.0` and therefore lands AFTER the increment. Same instructions, same
' byte count, different order: invisible to a byte-count triage, and it is why the residual
' looked like a register rotation.
'   `Local v:Float` and `Local v:Int` are semantically identical here -- `v / 10.0` promotes
'   an Int operand to Float anyway -- so this is a spelling difference with no behaviour change.
' Second, once the loop variable was Float, the previously load-bearing `Local f:Int[] = s.form`
' became a pure cost: `ForEachStm::eval` already emits `mov(c, coll)` into its own fresh temp,
' so a named `f` forces TWO materialisations of s.form (mov eax,[esi+0x4c] ; mov ecx,eax) where
' the original coalesces the field load straight into the collection temp (mov ebx,[esi+0x4c]).
' Iterating `s.form` directly is what the original did. Measured, worker 230, NSS5_NO_LEARN=1:
'     baseline (v:Int, Local f)                        4 gaps netting +0, 2 subs, 772 bytes
'     v:Float, Local f kept                            1 gap  +2 bytes, 0 subs, 774 bytes
'     v:Float, no Local f, EachIn s.form               CLEAN -> MATCH 772/772
' The two earlier attempts that regressed (-5 and -8 bytes) both dropped or moved `f` while
' leaving `v:Int`, so they were removing the compensating error rather than the error.
'
' LIVENESS WAS NOT THE LEVER -- measured, not assumed (scripts/workflow/walloc_report.py,
' instrumented bcc built in worker 230 from tools/blitzmax-legacy-src/_src, restored after).
' bcc's own allocator numbers for this function, BEFORE the fix (usage / degree / block_count):
'     l       regid 21   3 / 8->6   / 1    -> ebx
'     result  regid 24   304 / 27->7 / 46  -> spilled [ebp-4]   cost 0.944099 (victim)
'     cnt     regid 25   23 / 47->11 / 45  -> spilled [ebp-8]   cost 0.0464646 (victim)
'     total   regid 32   220 / 3->2  / 4   -> fp1 (x87, never a spill candidate)
'     f       regid 33   20 / 6->3   / 1   -> eax, cost 3.33333, never spilled
' AFTER the fix the same numbers are: l 3/8->6/1 ebx; result 304/28->7/46 [ebp-4] cost
' 0.944099; cnt 23/46->11/45 [ebp-8] cost 0.0464646; total 220/4->3/4 fp1. Not one
' block_count moved, no spill victim changed, and both stack slots stayed where they were.
' `f`'s block_count was already 1 -- the floor -- so there was never a liveness lever on it
' to pull. The four contested registers in the array walk are unnamed EachIn-internal temps
' (109 unnamed nodes before, 110 after; 24 coalesced before, 25 after) and they re-coloured
' as a consequence of the emission-order change, not of any cost change. Anyone reaching for
' block_count on a body whose two sides have equal length and equal instruction COUNT should
' first check instruction ORDER against the emitting front-end routine in _src/compiler/stm.cpp.
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
				For Local v:Float = EachIn s.form
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

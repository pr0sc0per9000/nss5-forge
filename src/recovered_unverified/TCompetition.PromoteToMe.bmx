' NOT VERIFIED -- MISMATCH, mode=len. VA 0x0050F841  orig_len=1076  ours=1089 (delta +13,
' VA 0x0050f841   1076 bytes   vtable slot 0x128   sig (:TTableData,:TCompetition)i
' byte-identical vs NSS5.exe (1076/1076, mode=reloc, 5 relocations masked, original length
' from Ghidra's inventory)
' pre-this-pass; not yet re-scored).
' KIND=Method, sig (:TTableData,:TCompetition)i, vtable slot 0x128.
' Started from -113 (naive translation), driven down to +13
' (98.8% of the length gap closed) across ~8 iterations with localise_diff.py. Every
' semantic field/slot binding below is CONFIRMED against the annotated decompile
' (extracted/decomp_annotated/TCompetition.PromoteToMe@0050f841.c) -- what remains is
' PURELY shape/codegen, not meaning.
'
' PASS N+1 (this edit, no fresh build available -- see notes at GAP 1 below for why this is
' evidence-driven rather than speculative): re-examined GAP 1, the Case 0 "find a less-full
' pool" loop, against two byte-identical siblings of the SAME Type that iterate the SAME
' `teampool` field -- TCompetition.DoPromotionPlaces.bmx, whose own header says outright
' "iteration auto-skips Null array slots, no explicit guard needed in source", and
' TCompetition.GetStringTeamPosition.bmx, which iterates `Self.teampool` with a plain
' `For Local p:TTeamPool = EachIn Self.teampool` and never null-tests `p` inside the loop
' (only the CAPTURED result, after the loop, gets a `tp <> Null` check). That directly
' contradicts this body's `tp <> Null And (...)` guard -- dropped it. Separately, the
' annotated decompile's do-while caches `tp.list.Count()` into one value (iVar3) and tests
' it twice (`iVar3 <> 0`, `cnt0 <= iVar3`); this body was calling `tp.list.Count()` twice,
' once per side of the Or, forcing a second virtual dispatch the original never makes --
' cached it into a Local instead, reused for both comparisons. Both changes target GAP 1's
' two sub-gaps (+17 at the loop head, +14 at the inner compare) at once. Re-examined GAP 3
' too: the annotated decompile shows the Case 0 `teampool.Length = 1` guard compiles to
' `*(Self.teampool + 0x14) == 1` -- exactly `teampool.Length = 1` as already written here --
' so GAP 3 looks like a misattribution from before the annotation existed, not a real
' gap; left that line alone. GAP 2 re-checked against the same annotated decompile and the
' two `bestclub.continentalcompid = id` assignments it shows are already both present below
' (one per branch) -- no third site visible in the decompiled C, so left that alone too.
' None of this was re-scored against a fresh assemble (off-limits here); if a later pass
' finds GAP 1's fix regressed things, the prior explicit-Null, double-Count() form is in
' version control history.
'
' A note on the score report's "FIRST DIFFERENCE: byte 80": that's the call-target address
' operand of the first `TClub.SelectById(a0.teamid)` (the push+call opcode bytes around it
' match exactly), and the trailing bytes shown in that same report snippet (`E9 C3 03` vs
' `E9 D0 03`, a relative jmp displacement) differ by exactly 13 -- the function's own +13
' overall length delta. That means this early region is not a distinct bug: the call-target
' is a cross-module slot address baked in by the linker from the WHOLE assembled program's
' symbol layout (not from anything this one Method writes), and the jmp displacement is a
' pure downstream consequence of the real size gap living later in the function (GAP 1).
' Not something a source-level edit to this file can target directly.

' FIELD MAPPING (TCompetition, all confirmed against object_model.json + the annotated
' decompile's own SYM table):
'   Self: level(+28) locale(+24) comptype(+36) id(+8) startweek(+44) compstatus(+80)
'         teampool(+108, []:TTeamPool)
'   a0:TTableData  teamid(+12) teamname(+16) teamstrength(+20)
'   a1:TCompetition  locale(+24) groups(+64)
'   TClub  leagueid(+104) continentalcompid(+108)
'   TTeamPool  list:TList(+8)
' slots: 0x00c59e0c=TClub+0x60=SelectById(i):TClub; 0x00c6160c=TCompetition+0x4c=
'   SelectById(i):TCompetition; TCompetition 0xbc=GetHighestClubNotInContinentalComp():TClub,
'   0xa0=GetNoofQualifiers()i, 0x124=DoPromotionPlaces()i; TTeamPool 0x38=AddItem(i,$,i)i,
'   0x3c=AddItemLeagueContinuation(:TTableData)i, 0x40=AddTableDataItem(:TTableData)i,
'   0x58=ShuffleIds()i; TList 0x70=Count()i.

' THREE REMAINING GAPS, all localised. GAP 1
' has an evidence-driven fix applied this pass (see PASS N+1 note above); GAP 2 and GAP 3
' are left as documented, with a re-assessment note on each.
'
' 1. (+31 bytes total, two sub-gaps -- FIX ATTEMPTED THIS PASS, not yet re-scored) The
'    Case 0 "find a less-full pool" search loop. Original is a raw do-while pointer walk
'    over teampool's backing array with exactly ONE Null test per iteration, fused with
'    the pool's Count()-based accept/reject test into a single bottom-tested condition.
'    Two byte-identical siblings of this Type (TCompetition.DoPromotionPlaces.bmx,
'    TCompetition.GetStringTeamPosition.bmx) iterate this same `teampool` field with a
'    bare `For Local x:TTeamPool = EachIn teampool` and no null-test on the loop variable
'    inside the loop -- DoPromotionPlaces says so explicitly in its own header. That is
'    good evidence the `tp <> Null And (...)` guard here was pure duplication of what
'    EachIn already does for free, which independently explains the "+17 bytes at the
'    loop head" sub-gap. The other sub-gap (+14 bytes at the inner comparison) lines up
'    with `tp.list.Count()` being called twice in the old condition (once per side of the
'    Or) where the annotated decompile shows the value computed once (iVar3) and reused --
'    this compiler does not appear to common-subexpression-eliminate a repeated method
'    call written twice in source (nothing in src/recovered/*.bmx relies on that), so a
'    second textual call means a second dispatch. Rewrote the loop to drop the `tp <> Null`
'    guard and cache `tp.list.Count()` in a Local, reused for both comparisons.
'
' 2. (-16 bytes) A 16-byte block right after the `club.continentalcompid < 1` Else's
'    first assignment path (ORIGINAL +362, ends with `jmp` to a join point that itself
'    contains a THIRD, physically separate copy of `club.continentalcompid = id`-shaped
'    code before falling into `Return 0`). Re-checked against the annotated decompile this
'    pass: it shows exactly TWO `*(iVar3+0x6c) = Self.id` sites (one under `compB.status <
'    Self.status`, one under the `compB.status = Self.status And startweek` ElseIf), both
'    already present below as separate statements. No third site is visible in the
'    decompiled C. Left unchanged -- if a third copy genuinely exists it is a pure codegen
'    duplication (e.g. two branches each getting their own inlined copy of the assignment
'    instead of sharing a join) that would need the raw disassembly, not the C, to locate.
'
' 3. (+10 bytes, PROBABLE MISATTRIBUTION -- re-assessed this pass, left unchanged) Case 0's
'    `If teampool.Length = 1` inner branch was suspected of actually testing a SelectById
'    club's `continentalcompid` field at this spot instead. The annotated decompile
'    resolves this cleanly: `*(int *)(Self.teampool + 0x14) == 1`, i.e. exactly
'    `teampool.Length = 1` as already written below (0x14 is the array-header length field
'    used consistently for `.Length` throughout this Type's other verified siblings, e.g.
'    TCompetition.Test_CheckNoofTeamsInLeagues.bmx). This gap was most likely raised before
'    the annotated decompile existed to disambiguate `param_1[0x14]`-style raw
'    Ghidra output. Left the guard as-is.
'
' Everything else -- the flat `level=0 And locale=0 And comptype=0` / `level=0 And
' locale=1 And (comptype=0 Or comptype=1) And a1.locale=0` short-circuit guards (NOT
' nested-If-with-boolean-Locals, which was tried first and cost -20 more bytes), the
' `compB.startweek > startweek` operand order (not `startweek < compB.startweek` --
' same truth value, opposite cmp/setl-vs-setg encoding), the Select-with-duplicated-
' Case-3-and-Case-2-bodies (not `Case 3, 2` sharing one body -- original truly repeats
' the machine code), the `Local dur...`-style explicit `Return 0` at the end of every
' early-exit branch (each one is its own `mov eax,0 / jmp epilogue`, not one shared
' fall-through zero) -- all confirmed byte-identical against NSS5.exe.
'
' PASS N+2 (this edit, localise_diff.py run with NSS5_WORKER=409): the entries above for
' GAP 1 and GAP 2 were a misattribution. The raw disassembly at VA 0x0050F921 shows
' `cmp dword ptr [esi+0x6c], 0` / `jle 0x50f9ad`, meaning the source condition is
' `club.continentalcompid > 0`, with the SMALL block (`club.continentalcompid = id`)
' as the out-of-line Else and the LARGE compA/bestclub/compB block as the in-place Then --
' the reverse of what this body had (`< 1` with the small block as Then). Fixing the
' condition and swapping which block is Then vs Else closed both GAP 1 (the 16-byte
' out-of-line copy of the id-assignment at VA 0x0050F9AD reappeared automatically once it
' became a genuine Else target) and GAP 2 (the extra `jmp` this body was emitting to skip
' over an inline id-assignment no longer exists once that code is the Else, reached by
' falling out of the Then block's own internal jumps at VA 0x0050F9AB).
' Separately, at VA 0x0050FAE7 the original sets `found = False` BEFORE computing
' `teampool[0].list.Count()` (stored at ebp-4, whereas `found` sits at ebp-0xc) -- this body
' had the two Locals declared in the opposite order; swapped, matching VA 0x0050FAE7..0x0050FB03.
' At VA 0x0050FB46 the original is `cmp edx, dword ptr [ebp-4]` / `setl` with `cnt` (edx)
' already resident in a register and `cnt0` left in memory -- i.e. source order `cnt < cnt0`,
' not `cnt0 > cnt` (which forces a load of cnt0 into eax first, 2 extra bytes). Fixed the
' operand order.
' Three explicit `Return 0` statements were missing relative to the disassembly's actual
' shape, each verified against its own out-of-line `mov eax,0 / jmp` at: VA 0x0050F9B6
' (end of the `level=0 And locale=1...` ElseIf arm, after its inner If/Else), VA 0x0050FBA9
' (end of Case 0's `Else` arm, after the `If Not found` block), and VA 0x0050FC60 (end of
' Case 5, after its `If Count()=GetNoofQualifiers()` block) -- all three now added. With all
' of the above applied the oracle reports MATCH at 1076/1076 bytes (mode=reloc, 5 relocations
' masked).
Method PromoteToMe:Int(a0:TTableData, a1:TCompetition)
	If level = 0 And locale = 0 And comptype = 0
		Local club:TClub = TClub.SelectById(a0.teamid)
		club.leagueid = id
		Return 0
	ElseIf level = 0 And locale = 1 And (comptype = 0 Or comptype = 1) And a1.locale = 0
		Local club:TClub = TClub.SelectById(a0.teamid)
		If club.continentalcompid > 0
			Local compA:TCompetition = TCompetition.SelectById(club.leagueid)
			Local bestclub:TClub = compA.GetHighestClubNotInContinentalComp()
			Local compB:TCompetition = TCompetition.SelectById(club.continentalcompid)
			If compB.compstatus < compstatus
				bestclub.continentalcompid = id
			ElseIf compB.compstatus = compstatus And compB.startweek > startweek
				bestclub.continentalcompid = id
			Else
				bestclub.continentalcompid = club.continentalcompid
				club.continentalcompid = id
			EndIf
		Else
			club.continentalcompid = id
		EndIf
		Return 0
	Else
		Select comptype
			Case 3
				teampool[0].AddTableDataItem(a0)
				If teampool[0].list.Count() = GetNoofQualifiers()
					DoPromotionPlaces()
				EndIf
				Return 0
			Case 2
				teampool[0].AddTableDataItem(a0)
				If teampool[0].list.Count() = GetNoofQualifiers()
					DoPromotionPlaces()
				EndIf
				Return 0
			Case 0
				If teampool.Length = 1
					teampool[0].AddItem(a0.teamid, a0.teamname, a0.teamstrength)
					Return 0
				Else
					Local found:Int = False
					Local cnt0:Int = teampool[0].list.Count()
					For Local tp:TTeamPool = EachIn teampool
						Local cnt:Int = tp.list.Count()
						If cnt = 0 Or cnt < cnt0
							tp.AddItem(a0.teamid, a0.teamname, a0.teamstrength)
							found = True
							Exit
						EndIf
					Next
					If Not found
						teampool[0].AddItem(a0.teamid, a0.teamname, a0.teamstrength)
					EndIf
					Return 0
				EndIf
			Case 1
				teampool[0].AddItem(a0.teamid, a0.teamname, a0.teamstrength)
				If a1.groups < 2
					teampool[0].ShuffleIds()
				EndIf
				Return 0
			Case 4
				teampool[0].AddItemLeagueContinuation(a0)
				Return 0
			Case 5
				teampool[0].AddTableDataItem(a0)
				If teampool[0].list.Count() = GetNoofQualifiers()
					DoPromotionPlaces()
				EndIf
				Return 0
		End Select
	EndIf
End Method

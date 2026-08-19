' UNVERIFIED -- NOT byte-matched. Do not promote to src/recovered without closing the gap below.
' VA 0x0051986c   800 bytes   vtable slot 0x88   sig ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
' byte-identical vs NSS5.exe
' TLabel.CreateLabel  VA 0x0051986C   orig_len=800  our_len=800  MATCH via harness.try_method
'
' localise_diff.py: delta_accounted=3, delta_explained=True, gap_count=9 -- every one of the 9
' gaps traces to the SAME single cause (confirmed by inspection, not just the tool's summary):
' the "style" parameter (a10, sig position 11 = Int) sits in edi across the whole function in
' the original (edi reused for every "a10<>10" test, the Select-cascade dispatch load, and the
' literal style arg pushed into CreateGadgetImage in the a12=0 and imgborder branches) but our
' build keeps it at [ebp+0x30] (memory) throughout instead. This is the SAME class of problem
' as src/recovered_unverified/TProfile.GetCurrentStats.bmx -- a register-allocation tie on a
' parameter that our naive reference-count model gets wrong in the OPPOSITE direction (there a
' parameter won a register it should have lost; here a parameter loses one it should win).
'
' Two REAL fixes were found and are already folded into the body below (worth keeping even
' though the body doesn''t MATCH yet):
'   1. The pointer-image cache guard must be written `If Not g_ptrImage` (BlitzMax truth test
'      on an Object), not `If g_ptrImage = Null` -- codegen-patterns.md #10.3: a bare `= Null`
'      compiles to a 12-byte cmp+je, but `Not x` compiles to the 21-byte setne/movzx/cmp0/jne
'      form with inverted branch sense, and the ORIGINAL uses the wide form (confirmed by the
'      literal bytes at VA+9). Fixed this from -6 total delta down to +3.
'   2. The non-border (a12=0) and border (a12<>0) construction paths in the annotated
'      decompilation print the guard `if (param_11 != 10)` TWICE inside the border branch (once
'      guarding the imgborder build, once guarding the Select) -- do NOT merge them into one
'      wrapping `If a10<>10` around both statements; each needs its OWN separate `If a10<>10`
'      re-test, or the body is 50+ bytes over (the extra cmp+je is real, not decompiler noise).
'
' RULED OUT as the cause of the remaining +3: nothing else differs. All field offsets, all
' Globals (g_ptrImage:TImage @0x00C6329C, new), all six CreateGadgetImage call sites (args
' and literal deltas -1/-2 on w/h per style, matching src/recovered_module/CreateGadgetImage.bmx
' exactly), the SetText/SetIcon/CreateToolTip call argument lists, and the final
' scrollx=Float(a2+a4) computation are BYTE-IDENTICAL in the diff (never flagged as a gap).
'
' FOLLOW-UP PASS: re-verified the above against harness.try_method /
' localise_diff.py directly (both are safe to run standalone -- they build in a private
' uuid temp dir and never touch src/assembled or status/fn -- unlike scripts/assemble.py,
' which was correctly off-limits). Findings:
'   * The a10-in-edi diagnosis is right in spirit but the CURRENT symptom is not "a10 stuck
'     in memory" -- it is a DIFFERENT parameter (a5, height, confirmed via the actual
'     mismatched byte: ours loads [ebp+0x1C]=param_6=a5 where the original loads
'     [ebp+0x30]=param_11=a10) getting edi instead. Which parameter wins is unstable: a
'     Case-10-embedded-in-Select rewrite (no outer guard) flips the winner again, to a3
'     (y), not a10.
'   * Rewriting the a10=2/3/4/5/other dispatch as literal If/ElseIf (matching the
'     decompiled C's surface shape) DOES fix the register -- edi=a10 from the very first
'     instruction, byte-identical to the original through offset +283 -- but the cascade
'     itself then comes out 13-14 bytes SHORT: the original's dispatch shows a `mov
'     eax,edi` subject copy, all five compares (10,2,3,4,5) grouped BEFORE any case body
'     runs, an empty `Case 10` arm that is nothing but a `jmp` to the shared exit, and the
'     `a10=other` arm reached by fallthrough with no guard of its own -- all signature
'     Select codegen, not If/ElseIf's interleaved test-then-body-then-jump shape. So the
'     real source almost certainly IS `Select a10` with `Case 10` empty and no separate
'     outer `If a10<>10` wrapping it -- verified structurally against the original's
'     disassembly, not guessed.
'   * That leaves a contradiction this pass could not close: the disassembly says Select,
'     but every Select-shaped reconstruction tried (outer-guard + Select, and the no-guard
'     Case-10 form) loses the edi register to some other parameter, while every
'     If/ElseIf-shaped reconstruction wins the register but is the wrong shape and the
'     wrong length. Both are worse on the actual oracle than this file's current
'     Select-plus-outer-guard body: bytematch.py-equivalent raw scores measured were
'     292/800 (this file, unchanged) vs 251/786 (If/ElseIf) vs 156/800 (Select, Case 10
'     embedded) -- length mismatches from a wrong-shaped cascade cost far more raw-byte
'     agreement than the register fix recovers, because bytematch.py's compare() is an
'     unmasked positional zip, not an aligned diff, so everything after a length gap reads
'     as noise even where it is logically identical.
'   * Likely the real lever is codegen-patterns.md #18.4 (block_count / live-range
'     "holes", not raw reference count) and is sensitive to some other statement's exact
'     phrasing elsewhere in the function that this pass did not find. Left UNCHANGED
'     rather than swap in a worse-scoring rewrite (rule 4). Next attempt: hold the Select
'     shape fixed and vary ONLY the earlier w/h/x/y Float-conversion statements and the
'     pointer/pointerxoff/pointeryoff assignments -- those are the only remaining source
'     lines upstream of the dispatch that haven't been permuted yet.
'
' RESOLUTION: the register conflict and the block-order gap share one root cause. Each Case
' 2/3/4/5 arm passes `a10` (not the matching literal 2/3/4/5) as the style argument to
' CreateGadgetImage -- a10 equals the case value inside its own arm, so the call is
' semantically identical either way, but writing the parameter instead of the literal is
' what keeps a10's reference count above a5's and lets a10 (not a5) win edi for the whole
' function; the very first instruction (`mov edi,[ebp+0x30]`, param 11 = a10) confirms it.
' The Select carries its own `Case 10` arm (empty, falls straight to the shared exit) with
' no separate outer `If a10<>10` wrapping it, matching the disassembly's single shared
' `mov eax,edi` subject load ahead of all five compares. The outer branch reads
' `If a12<>0 Then <imgborder guard + Select> Else <plain image guard> EndIf`: the border
' path (a12<>0) is the inline fall-through and the plain-image path (a12=0) is the
' out-of-line jump target, which is the reverse of the two branches' source order and is
' what the compiler's `je` (taken when a12=0) demands. Confirmed MATCH 800/800 via
' harness.try_method and localise_diff.py (0 length-changing gaps).
'
' Body-only format: statements only, parameters are a0, a1, ... (KIND=Function, no Self;
' TYPE=TLabel per vtable_map.tsv SLOT=0x88).
'!Global g_ptrImage:TImage
If Not g_ptrImage
	g_ptrImage = LoadImageChecked("GameMedia/Images/Interface/Pointer.png", -1)
	SetImageHandle(g_ptrImage, 16.0, 16.0)
EndIf
Local lb:TLabel = New TLabel
lb.name = a0
lb.x = Float(a2)
lb.y = Float(a3)
lb.w = Float(a4)
lb.h = Float(a5)
lb.alph = a9
lb.forcetxtalpha = a15
lb.colour = a7
lb.SetText(a1, a8, a13, a6)
lb.style = a10
lb.pointer = a16
lb.pointerxoff = a17
lb.pointeryoff = a18
If a12 <> 0
	If a10 <> 10
		lb.imgborder = CreateGadgetImage(a4, a5, a10, a11, 0)
	EndIf
	Select a10
		Case 10
		Case 2
			lb.image = CreateGadgetImage(a4 - 2, a5 - 1, a10, a11, 0)
		Case 3
			lb.image = CreateGadgetImage(a4 - 2, a5 - 1, a10, a11, 0)
		Case 4
			lb.image = CreateGadgetImage(a4 - 1, a5 - 2, a10, a11, 0)
		Case 5
			lb.image = CreateGadgetImage(a4 - 1, a5 - 2, a10, a11, 0)
		Default
			lb.image = CreateGadgetImage(a4 - 2, a5 - 2, a10, a11, 0)
	End Select
Else
	If a10 <> 10
		lb.image = CreateGadgetImage(a4, a5, a10, a11, 0)
	EndIf
EndIf
If a14 <> Null Then lb.SetIcon(a14)
If a19.Length <> 0 Then lb.CreateToolTip(a19)
lb.scrolltext = a20
lb.scrollx = Float(a2 + a4)
Return lb

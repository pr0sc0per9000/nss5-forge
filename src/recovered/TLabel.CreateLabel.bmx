' TLabel.CreateLabel
' VA 0x0051986c   800 bytes   vtable slot 0x88   sig ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
' byte-identical vs NSS5.exe (800/800, mode=reloc, reloc_masked=28)
' KIND=Function (no Self), TYPE=TLabel per vtable_map.tsv SLOT=0x88; body-only format,
'   parameters are a0, a1, ...
'
' Oracle: harness.try_method under NSS5_NO_LEARN=1, MATCH 800/800.
' Negative control (the oracle is discriminating here): sourcing lb.pointerxoff from a18
'   instead of a17 reports MISMATCH 721/800, first_diff=+269.
'
' Three source spellings are load-bearing; each was established from the literal bytes:
'  1. The pointer-image cache guard must be `If Not g_ptrImage`, not `If g_ptrImage = Null`.
'     codegen-patterns.md #10.3: a bare `= Null` compiles to a 12-byte cmp+je, while `Not x`
'     compiles to the 21-byte setne/movzx/cmp0/jne form with inverted branch sense. The
'     original uses the wide form (bytes at VA+9).
'  2. The a12<>0 (border) path re-tests `If a10 <> 10` separately around the imgborder build,
'     and the Select carries its OWN empty `Case 10`. Merging them into one wrapping guard
'     puts the body 50+ bytes over -- the second cmp+je is real, not decompiler noise.
'  3. Each Case 2/3/4/5 arm passes `a10` as CreateGadgetImage's style argument, NOT the
'     matching literal 2/3/4/5. Semantically identical (a10 equals the case value inside its
'     own arm) but it keeps a10's reference count above a5's, which is what lets a10 win edi
'     for the whole function. The first instruction, `mov edi,[ebp+0x30]` (param 11 = a10),
'     is the confirmation; with the literals, a5 (height) takes edi instead and the body runs
'     +3 bytes long. This was the last gap.
'
' Branch order: `If a12<>0 Then <imgborder guard + Select> Else <plain image guard> EndIf`.
' The border path is the inline fall-through and the plain-image path is the out-of-line jump
' target -- the reverse of source order, which is what the compiler's `je` (taken when a12=0)
' demands.
'
' Globals: g_ptrImage:TImage @0x00C6329C (new).
'!Global g_ptrImage:TImage
'
' STALE SCORE RECORD (not fixable from here): status/score/TLabel.CreateLabel.txt in the main tree still
'   reads "291/800 (36.4%), ours 803, delta +3" for a body version that no longer exists. status/ is gitignored
'   regenerated output ("Nothing here is authored"), and scripts/reverify.py --pending -- the
'   only thing that writes it -- scores src/recovered_pending and src/recovered_unverified
'   only, so it will not refresh a record for a body that has been promoted to
'   src/recovered. That contradicting record was one half of the defect here: commit
'   122bd86's bulk pass injected a bare "byte-identical" marker above the VA line while line
'   1 still said NOT VERIFIED, and progress.py accepted a marker anywhere in the first 40
'   lines with no negative test. Delete the stale record by hand, or ignore it -- the oracle
'   run named at the top of this header is the authority.
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

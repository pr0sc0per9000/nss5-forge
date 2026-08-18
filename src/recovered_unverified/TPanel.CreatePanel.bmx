' REVISED this pass -- confirmed via the live compiler probe (harness.try_method):
' status=MATCH, matched=460/460, mode=reloc. Was 456/460 (delta -4, 48.9% raw score).
' VA 0x00519483   ORIGINAL 460 bytes   sig ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'
' WHAT CHANGED AND WHY
' The previous body ended with a nested `If a11 ... Else ... EndIf` wrapping an inner
' `If a10 = 0 ... Else ... EndIf`. That nesting reproduced the branch CONTENT and the
' physical block ORDER correctly (inner-if code first, a11=0 case last, right before the
' shared return), but left two small unexplained codegen gaps right at that
' shape's boundary:
'   GAP 1 (-2 bytes, offset +229): the a11 test compiled as the cheap direct-memory
'     `cmp dword[ebp+0x34],0` instead of the original's `mov eax,[ebp+0x34] / cmp eax,0`.
'   GAP 2 (-2 bytes, offset +446): the original has a redundant `jmp +0` right after the
'     a11=0 branch's single statement, immediately before the shared return-value load;
'     our nested If/Else fell straight through without it.
' Both gaps vanish together once the outer test is written as a Select instead of a
' nested If: `mov eax,[mem]; cmp eax,0` is exactly how a Select loads its subject once
' before the Case comparisons (see TBlackJack.ShowResult.bmx's note 20-22 and
' TDate.GetString.bmx's `Select dy Mod 10` for the established idiom), and a Select's
' Case/Default blocks each close with their own unconditional jump to the End Select
' point -- including the trailing one, even when it lands on the very next instruction
' (0-byte displacement, not peepholed away). That is exactly GAP 2. Confirmed empirically
' (not just by inspection): probing this exact rewrite through harness.try_method gives
' a clean 460/460 MATCH, so no further reasoning about it is needed.
'
' PARAMETER MAPPING (unchanged from the prior pass, proven byte-identical throughout):
'   a0:String name        (Self.name,  TGadget+0xC)
'   a1:String text         -> SetText(a1, "", -1, -1)
'   a2:Int x  a3:Int y  a4:Int w  a5:Int h   (stored Int->Float, TGadget+0x20/0x24/0x2C/0x28)
'   a6:String colour       (TGadget+0x30)
'   a7:String txtcolour    (TGadget+0x34)
'   a8:Int fntSize         (TGadget+0x4C)
'   a9:Float alph          (stored directly, no cast, matches sig position 10 'f')
'   a10:Int, a11:Int, a12:Int -- style/bodyflag/button, dispatched below.
'
' BRANCH STRUCTURE (matches the decompile's `if (param_12==0) {..} else {nested a10 if}`,
' i.e. a11 is the Select subject; Case 0 is the "no body" case, Default covers every
' nonzero a11 and holds the original nested `If a10 = 0` two-way split):
'   Select a11
'       Case 0
'           p.image = CreateGadgetImage(a4, a5, a10, a12, 0)
'       Default
'           If a10 = 0
'               p.image = CreateGadgetImage(a4, a5, 0, 1, 0)
'               p.CreateBody(a11, 0)
'           Else
'               p.image = CreateGadgetImage(a4, a5, 2, 1, 0)
'               p.CreateBody(a11, 3)
'           EndIf
'   End Select
'   Return p
'
' Body-only format below (statements only, parameters are a0, a1, ... per project convention).
	Local p:TPanel = New TPanel
	p.name = a0
	p.x = a2
	p.y = a3
	p.w = a4
	p.h = a5
	p.alph = a9
	p.colour = a6
	p.SetText(a1, "", -1, -1)
	p.txtcolour = a7
	p.fntSize = a8
	Select a11
		Case 0
			p.image = CreateGadgetImage(a4, a5, a10, a12, 0)
		Default
			If a10 = 0
				p.image = CreateGadgetImage(a4, a5, 0, 1, 0)
				p.CreateBody(a11, 0)
			Else
				p.image = CreateGadgetImage(a4, a5, 2, 1, 0)
				p.CreateBody(a11, 3)
			EndIf
	End Select
	Return p

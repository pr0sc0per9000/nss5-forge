' TScreenMessage.Draw -- VERIFIED byte-identical vs NSS5.exe.
' harness.try_method under NSS5_NO_LEARN=1: MATCH, mode=reloc, 1119/1119, 49 reloc-masked,
' first_diff=None. Reproduced 5/5 across separate builds. The tx/dur spill costs below sit
' within 4% of each other, which is the near-tie band walloc_report.py warns is not always
' stable across processes -- it was stable here, but re-run before trusting any future edit
' that touches this body's tail.
' VA 0x0057004C   1119 bytes   vtable slot 0x3c   sig ()i
'
' HOW IT CLOSED -- liveness, not the allocator. This supersedes this file's previous
' header, which said the residual was a register-allocator decision not reachable from
' source. It was reachable. The draft declared Local iw / Local ih and inlined both Float
' arguments of the final DrawImage. Three source-shape facts, each read off the original's
' own bytes:
'  (a) `Local iw:Int = ImageWidth(img)` kept iw alive in a register across the following
'      bmfnt.GetFontHeight() call. The original never materialises it: it loads tx into ebx
'      BEFORE the ImageWidth call and does `sub ebx,eax` straight after, the same `a - f()`
'      shape it already uses for `x - bmfnt.GetTxtWidth(message) / 2`. That one
'      wrongly-placed live range inflated tx's interference degree from 7 to 12, which
'      divided tx's spill cost below dur's, swapped their stack slots, and repacked the
'      whole function (Self edi->esi, ty esi->ebx, sub esp 0x14->0x10, 51 substitutions).
'  (b) The x argument is a Float LOCAL, not an inline argument expression: the original
'      computes it into [ebp-8] before the y argument and later pushes that slot directly
'      (`FF 75 F8`). Inline, bcc evaluates and pushes each argument right-to-left as it
'      goes, which is the wrong order and costs an extra register copy.
'  (c) The y argument is ALSO a Float Local, and is the LAST one declared, so it stays on
'      the x87 stack with no memory slot (codegen-patterns 6 / 10.5). Visible in the
'      original as a `fild` at +1053 with NO `fstp` after it: the value sits in st0 across
'      `push 0` and is popped straight into the argument slot. Written inline instead, bcc
'      emits `push 0` BEFORE the y computation, which was the 2-byte pair of gaps that
'      survived (a) and (b).
'
' MEASURED ALLOCATOR NUMBERS (scripts/workflow/walloc_report.py, instrumented bcc).
' usage / degree / block_count / cost are the compiler's own, read at the spill() pick
' point; cost = usage / (degree * block_count). Slot depth runs in DESCENDING cost order.
'   var    usage  degree  block_count  cost      outcome
'   hbar     5       7         1       0.714286  [ebp-4]
'   ix       2       7         1       0.285714  [ebp-8]      x argument, Float Local
'   tx       7       7         6       0.166667  [ebp-0xc]
'   dur      9       7         8       0.160714  [ebp-0x10]
'   ty       3       6         1       0.5       esi
'   th2      2       3         1       -         eax
'   ihh      2       -         -       -         eax (coalesced away, zero bytes)
'   iy       2       -         1       -         fp0 (x87, no slot)
'   plus 4 bytes of compiler-internal fild scratch at [ebp-0x14]  ->  sub esp,0x14
' The draft's numbers, for comparison: tx degree 12 -> cost 0.0972222, below dur, giving
' hbar[-4] dur[-8] tx[-0xc] and sub esp,0x10. usage and block_count were ALREADY correct
' for every variable in the draft. degree alone carried the whole defect, which is why no
' reordering of the Local declarations could ever have reached it.
'
' THE ORPHAN `cdq` (0x00570431), and why it IS source-reachable.
' The original leaves a bare `cdq` after the discarded ImageHeight call with no completing
' and/add/sar. It is the leading edge of a discarded divide-by-two. bcc's
' _src/codegen/cgframe_x86.cpp genBop(), power-of-2 CG_DIV path, emits
'     genMov( eax,t->lhs );
'     gen( xop(XOP_CDQ,edx,eax),"\tcdq\n" );     ' unconditional -- always emitted
'     ... e=bop(CG_SAR,bop(CG_ADD,eax,bop(CG_AND,edx,lit(i-1))),lit(n));
'     return genExp(e);                          ' a VALUE -- dies when unused
' The cdq goes out through gen() unconditionally; the three-instruction completion goes out
' through genExp() as a value, so when the quotient is never read the completion dies and
' the cdq does not. `Local ihh:Int = ImageHeight(img) / 2` with ihh never read reproduces
' it in exactly one byte. The previous header ruled this out on the grounds that the stored
' form "needs the complete 4-instruction idiom"; it does not, because the store is dead too
' and ihh coalesces onto eax.
'
' BUG (original): two statements here are dead and are reproduced faithfully.
' `bmfnt.GetFontHeight()` and `ImageHeight(img) / 2` compute values nothing reads. An
' `add esp,4` after each of the four GetFontHeight calls confirms four separate calls, so
' they cannot be folded into one real computation. They read as the remains of an earlier
' version of the icon-positioning code.
'
' RESOLVED (do not re-derive):
'  * Fields (object_model.json): x=+8, y=+12, message:$=+16, starttime=+20, delaytime=+24,
'    finishtime=+28, delaystart=+32, alfa:Float=+36, bmfnt:TBitmapFont=+40, img:TImage=+44,
'    imgScale:Float=+48, colour:$=+52, lbl:TLabel=+56. imgScale is never referenced by this
'    body -- confirmed, no [edi+0x30] anywhere in the original's 1119 bytes.
'  * g_matchtime:Int (0x00C6EFD4) is the match/frame millisecond clock. Every comparison
'    against it places g_matchtime first (`cmp [g_matchtime],eax`), matching source text
'    order `g_matchtime <compare> field`; the subtraction forms (`g_matchtime - starttime`,
'    `finishtime - g_matchtime`) keep their own order since a - b <> b - a.
'  * g_engine_int162:Int (0x00C6EFE4) is the backbuffer width.
'  * 0x00C6AFDC is a TList of TScreenMessage (Remove() called via slot 0x74), named
'    g_screenmessages -- extracted/global_address_map.tsv confirms this name unanimous
'    across four bodies.
'  * 0x00C6F34C / 0x00C6F3B0 (TImage) are named g_kits_img1 / g_kits_img2 in
'    TScreen_Kits.Draw.bmx and reused here as the same generic UI-bar images, drawn as a
'    message backdrop via DrawImageRect (bar behind the text, tinted/scaled by alfa).
'  * Self.bmfnt (TBitmapFont) vtable: 0x4c=DrawText($,f,f,i)i, 0x54=GetTxtWidth($)i,
'    0x58=GetFontHeight()i. Self.lbl (TLabel) vtable: 0x44=Draw()i, 0x70=SetAlph(f)i.
'  * The un-decompiled call FUN_00505CEA (SetColourHex, sig ($)i, recovered in
'    src/recovered_module/SetColourHex.bmx) takes Self.colour, the one field on
'    TScreenMessage never otherwise referenced in the body.
'  * The first SetAlpha call in the message-bar block passes `alfa * 0.75`, not bare alfa:
'    the disassembly computes the product on the FPU (`fld`/`fmul 0.75`/`fstp`) before the
'    call, where the second SetAlpha call just pushes the field directly with no FPU work.
'
' Globals (names ours; types load-bearing):
'!Global g_screenmessages:TList
'!Global g_matchtime:Int
'!Global g_engine_int162:Int
'!Global g_object872:TImage
'!Global g_object873:TImage

If g_matchtime < starttime Then Return 0
If g_matchtime > finishtime
	g_screenmessages.Remove(Self)
	Return 0
Else
	Local dur:Float = Float((finishtime - starttime) / 100)
	If dur = 0.0 Then dur = 1.0
	If Float(g_matchtime) < Float(starttime) + dur * 10.0
		alfa = (Float(g_matchtime - starttime) / dur) / 10.0
	EndIf
	If Float(g_matchtime) > Float(starttime) + dur * 90.0
		alfa = (Float(finishtime - g_matchtime) / dur) / 10.0
	EndIf
	ClampFloat(Varptr alfa, 0.0, 1.0)
	If lbl <> Null
		lbl.SetAlph(alfa)
		lbl.Draw()
	Else
		If message.Length <> 0
			Local tx:Int = x - bmfnt.GetTxtWidth(message) / 2
			If Float(g_matchtime) < Float(starttime) + dur * 10.0
				tx = Int(Float(tx) - Float(g_engine_int162) * (1.0 - alfa))
			Else
				If Float(g_matchtime) > Float(starttime) + dur * 90.0
					tx = Int(Float(tx) + (Float(g_engine_int162) - Float(g_engine_int162) * alfa))
				EndIf
			EndIf
			Local ty:Int = y - bmfnt.GetFontHeight() / 2
			SetColor(255, 255, 255)
			SetAlpha(alfa * 0.75)
			Local th2:Int = bmfnt.GetFontHeight()
			Local hbar:Float = Float(th2 + 2) * alfa
			DrawImageRect(g_object872, 0, Float(y - 5) - hbar * 0.5, Float(g_engine_int162), hbar, 0)
			DrawImageRect(g_object873, 0, (Float(y - 5) - hbar * 0.5) - 2.0, Float(g_engine_int162), 4.0, 0)
			DrawImageRect(g_object873, 0, (Float(y - 5) + hbar * 0.5) - 2.0, Float(g_engine_int162), 4.0, 0)
			SetColourHex(colour)
			SetAlpha(alfa)
			bmfnt.DrawText(message, Float(tx), Float(ty), 1)
			If img <> Null
				bmfnt.GetFontHeight()
				Local ihh:Int = ImageHeight(img) / 2
				Local ix:Float = Float(tx - ImageWidth(img))
				Local iy:Float = Float(ty - 1 + bmfnt.GetFontHeight() / 2)
				DrawImage(img, ix, iy, 0)
			EndIf
		EndIf
	EndIf
	SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
EndIf
Return 0

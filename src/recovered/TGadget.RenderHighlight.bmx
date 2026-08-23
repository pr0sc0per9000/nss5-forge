' TGadget.RenderHighlight  -- Method, slot 0x50, sig ()i
' VA 0x00513D11   748 bytes (Ghidra-authoritative)
' byte-identical vs NSS5.exe (748/748). harness.try_method mode=reloc, first_diff=None,
' NSS5_NO_LEARN=1, no learned helpers. Confirmed on 4 independent process launches
' (see NEAR-TIE below for why that count matters here), and localise_diff.py reports
' 0 gaps / 0 subs against the same build.
'
' RESOLVED (every offset, global and callee named; confirmed by direct disassembly, not
' just the decompile):
'   Fields (object_model.json): TGadget.x=+0x20 y=+0x24 h=+0x28 w=+0x2c, all Float.
'   Globals (extracted/globals_final.tsv):
'     0x00c6efe8 Int   g_engine_int163   (also verified by explain_global.py; same slot
'         some other bodies call g_screen_h/g_scr_h/etc -- g_engine_int163 is the
'         globals_final.tsv canonical name and the one TButton.Draw, this function's
'         closest sibling for this exact subexpression, uses)
'     0x00c61728 Float g_screen_float02
'     0x00c7dfa0 Float g_gadget_float   (mutable "highlight pulse" counter; init 128.0 in
'         the exe's .data -- the only one of the four c7dfaX addresses that is a Global)
'     0x00c61cf4 Int   g_gadget_int01   (border thickness; value 4 in the exe's .data)
'   0x00c7dfa4/-a8/-ac are NOT separate Globals -- read directly from the image via
'   scripts/harness._exe + va2off, confirmed the literal float constants 4.0, -128.0,
'   128.0 that bcc pools into .data for FPU-context float literals.
'   Helpers: 0x005b9690 Int(), 0x004a7fe0 Abs(), 0x005ae0a8 SetScale, 0x005adc28 SetAlpha,
'   0x005ad408 DrawRect, 0x005adb6f SetColor (arities/argsizes cross-checked against
'   extracted/call_arity.tsv and extracted/callgraph/callgraph_callargs.tsv).
'
' THE CLAMP COMPARISON IS `iy > threshold`, NOT Ghidra's `threshold < iy`. The
' disassembly shows iy fild'd onto the FPU stack FIRST (0x513d49), the threshold computed
' SECOND (0x513d4c-0x513d63), then fxch+fucompp+SETBE+JNE. Left-to-right evaluation means
' the operand computed first is written first in source. TButton.Draw (0x005151b5) uses
' the same globals for the same clamp and is written the same way, and
' TGadget.UpdateToolTip's header records the identical Ghidra reversal. Likewise `b` is
' one Local, not two: Ghidra prints DAT_00c61cf4 for the first DrawRect and iVar1 for the
' other three, but g_gadget_int01 is read from memory into esi exactly ONCE (0x513e4f)
' and all four DrawRects read esi -- a decompiler SSA-naming artifact.
'
' HOW THE LAST 20 BYTES WERE FOUND: A LIVE-RANGE SPLIT, x2/y2.
' This body sat at 728 bytes for a long time, diagnosed in its own header as an allocator
' tie-break unreachable from source. That diagnosis was wrong, and the reason is worth
' recording because it generalises.
'
' The 728-byte build differed from the original by exactly one register decision plus its
' knock-on slot numbering: 14 length-changing gaps and 23 same-length substitutions, all
' of them either a missing `mov eax,[ebp+8]` (Self reload before a field access) or the
' [ebp-8] -> [ebp-0xc] shift that the extra frame slot causes. The frame size said it
' outright (section 22.4): original `sub esp,8`, ours `sub esp,0xc`. The original puts TWO
' things in memory (one Local slot at [ebp-4] plus the fild conversion scratch at [ebp-8],
' with Self at [ebp+8], which costs no frame slot); the 728-byte build put THREE (ix, iy,
' scratch) and kept Self in edi.
'
' Read out of the instrumented allocator (scripts/workflow/walloc_report.py), the 728-byte
' build's pass-1 spill rounds were:
'     regid 16 ix    usage=5   degree=24  block_count=4  cost=0.0521   <- picked 1st
'     regid 17 iy    usage=7   degree=24  block_count=3  cost=0.0972   <- picked 2nd
'     regid 15 Self  usage=11  degree=24  block_count=4  cost=0.1146   <- picked 3rd
'     regid 19 o     usage=13  degree=24  block_count=1  cost=0.5417
'     regid 18 b     usage=15  degree=24  block_count=1  cost=0.6250
' spill() picks are OPTIMISTIC: they are pushed on the select stack in ascending-cost
' order and popped in reverse, so the LAST value picked is the first offered a colour and
' the FIRST value picked is the one most likely to fail. Five values are live across calls
' in the final block and only three callee-saved registers exist, so exactly two fail.
' Ours failed ix and iy; the original fails Self and iy. To flip it, ix's cost has to rise
' above Self's 0.1146. With usage fixed at 5, that needs block_count 4 -> 1.
'
' ix's block_count is 4 because its definition (top of the body) and its four uses (the
' DrawRects) sit either side of both If blocks. It cannot be moved: the disassembly puts
' `fld [eax+0x20]; call Int` at +9, so Int(x) really is the first thing the body does.
' The lever is not moving the definition but SPLITTING THE LIVE RANGE, and the original's
' own bytes say so directly. At +313 the original emits
'     mov edi, esi          ; copy of ix, taken after SetColor
'     mov [ebp-4], ebx      ; copy of iy, taken after SetColor
' and only then loads b into esi and 2 into ebx. A spilled Local does not look like that:
' bcc's Spiller rewrites every reference to the memory operand, so a spilled iy would
' store at each of its two definitions (which is exactly what the 728-byte build emitted,
' `mov [ebp-4],eax` at +49 and +133). One copy, after the merge, from a register that is
' about to be reused, is a SECOND VALUE. So the original source declares two more Locals
' there. Adding them (`x2`, `y2`, declared before b and o, and used in all four DrawRects)
' reproduces the original exactly.
'
' MEASURED AFTER THE SPLIT (same tool, same worker), prediction registered beforehand:
'     ix   usage 5 -> 2   block_count 4    cost 0.0833   outcome esi   (was [ebp-8])
'     iy   usage 7 -> 4   block_count 3    cost 0.1905   outcome ebx   (was [ebp-4])
'     x2   usage 5        block_count 1    cost 0.2000   } the two new
'     y2   usage 5        block_count 1    cost 0.2083   } short-range values
'     b    usage 15       block_count 1    cost 0.6250   outcome esi
'     o    usage 13       block_count 1    cost 0.5417   outcome ebx
' Self (regid 15) is unchanged at usage=11, block_count=4, cost 0.1146 -- but it is now
' the CHEAPEST of the values live in the final block, so it is picked first, popped last,
' fails to colour and goes to [ebp+8]. That restores all ten `mov eax,[ebp+8]` reloads,
' drops the frame back to `sub esp,8`, and returns the fild scratch to [ebp-8], which is
' every one of the 14 gaps and all 23 substitutions at once. 728 -> 748, MATCH first try.
'
' The general lesson, since several other bodies carry the same "allocator tie-break,
' unreachable from source" diagnosis: block_count is a source-level lever (section 18.4,
' section 22.3) and STATEMENT PLACEMENT is not its only handle. When the definition is
' pinned by evaluation order, the live range can still be cut in half by an explicit copy,
' and the two halves get costed independently. Read the frame size first (section 22.4);
' a `sub esp,N` that is one dword too large means one value too many is in memory, and
' names the decision to attack.
'
' NEAR-TIE, RECORDED HONESTLY. x2 (0.2000, degree 25) and y2 (0.2083, degree 24) sit 4%
' apart, well inside the range walloc_report's own header warns about. The two tools
' disagree about this pair: walloc_report's process reports x2 -> [ebp-4] and y2 -> edi,
' while the harness-built probe emits `mov edi,esi` / `mov [ebp-4],ebx` -- x2 -> edi and
' y2 -> [ebp-4], byte-identical to the original. Each tool is self-consistent on repeat
' runs, so this is either the documented cross-process near-tie behaviour or a naming-join
' artifact in walloc_report for this pair alone (its b/o rows are demonstrably correct);
' this pass did not separate the two. The bytes are authoritative and the harness verdict
' reproduced MATCH on 4 separate launches. If this body ever reads MISMATCH after an
' unrelated change, re-run before believing it, and check whether the two copies at
' +313/+315 have swapped before looking anywhere else.
'
' Rendered geometry (4 border strips of thickness b=g_gadget_int01 framing the gadget,
' colour pulsing green<->white via g_gadget_float decaying by 4.0/frame, wrapping at -128
' back to +128), where ix=Int(x), iy=Int(y) clamped so it never exceeds
' g_engine_int163 - g_screen_float02 - h:
'   top:    DrawRect ix-b-2, iy-b-2, w+b*2+2, b
'   bottom: DrawRect ix-b-2, iy+h+2, w+b*2+4, b
'   left:   DrawRect ix-b-2, iy-b-2, b, h+b*2+2
'   right:  DrawRect ix+w+2, iy-b-2, b, h+b*2+4

'!Global g_engine_int163:Int
'!Global g_screen_float02:Float
'!Global g_gadget_float:Float
'!Global g_gadget_int01:Int
Local ix:Int = Int(x)
Local iy:Int = Int(y)
If Float(iy) > Float(g_engine_int163) - g_screen_float02 - h
	iy = Int(Float(g_engine_int163) - g_screen_float02 - h)
EndIf
SetScale(1, 1)
SetAlpha(1)
g_gadget_float = g_gadget_float - 4.0
If g_gadget_float < -128.0
	g_gadget_float = 128.0
EndIf
SetColor(Int(Abs(g_gadget_float)), 255, Int(Abs(g_gadget_float)))
Local x2:Int = ix
Local y2:Int = iy
Local b:Int = g_gadget_int01
Local o:Int = 2
DrawRect(x2-b-o, y2-b-o, w+b*2+o, Float(b))
DrawRect(x2-b-o, y2+h+o, w+b*2+o*2, Float(b))
DrawRect(x2-b-o, y2-b-o, Float(b), h+b*2+o)
DrawRect(x2+w+o, y2-b-o, Float(b), h+b*2+o*2)
SetColor(255, 255, 255)

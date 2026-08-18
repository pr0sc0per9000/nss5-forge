' TGadget.RenderHighlight  -- Method, slot 0x50, sig ()i
' VA 0x00513D11   748 bytes (Ghidra-authoritative)
' An earlier draft carried the analysis below as "body A" but left it
' entirely commented out -- every statement line was prefixed with a leading `'`, on top
' of the already-commented `'!Global` pragmas, so the file was ALL COMMENTS end to end.
' Per scripts/assemble.py's load_recovered(): "A file here that is 100% comments
' contributes nothing and silently stays an empty stub" -- confirmed exactly by the score
' report (3/14 bytes, i.e. only the shared function prologue matched; ours was the
' 14-byte empty-stub shape). This pass UNCOMMENTS that draft into real code and fixes one
' real bug found by cross-checking against a full Capstone disassembly of the original
' (0x00513d11..0x00513ffc, pulled straight from NSS5.exe via scripts/harness._exe /
' va2off) rather than trusting the decompiled C's comparison spelling at face value:
'
'   THE CLAMP COMPARISON'S OPERATOR/OPERAND ORDER WAS BACKWARDS. Ghidra's C prints the
'   guard as `threshold < iy` (threshold on the left), and the drafted body copied that
'   literally as `g_engine_int163 - g_screen_float02 - h < iy`. The disassembly shows
'   `iy` fild'd onto the FPU stack FIRST (0x513d49), the threshold computed SECOND
'   (0x513d4c-0x513d63), then fxch+fucompp+SETBE+JNE. Left-to-right evaluation means the
'   operand computed first is the one written first in source -- so the true source is
'   `iy > threshold`, not `threshold < iy`. Two byte-identical siblings independently
'   confirm Ghidra does this: TButton.Draw (0x005151b5, itself disassembled to check) uses
'   the exact same globals for the exact same clamp and is written
'   `Float(iy) > (Float(g_engine_int163) - g_screen_float02) - Self.h` -- iy first, `>`,
'   matching evaluation order exactly (fild iy first, seta/setbe complement pattern this
'   compiler uses for both `<` and `>`). And TGadget.UpdateToolTip's own header says it
'   outright: "The two mouse-branch tests really are `x > g_screen_w / 2` / `y > g_screen_h
'   / 2` (the gadget coordinate is fld'd first), even though Ghidra prints them reversed."
'   Same class of bug, independently attested twice. Fixed here to `iy > threshold`.
'   Everything else in the draft -- checked statement-by-statement against the same
'   disassembly -- already matched: SetScale/SetAlpha argument values and order, the
'   g_gadget_float decrement/wrap, the SetColor merge (FUN_004a7fe0/FUN_005b9690 pushes
'   that Ghidra's arg-list merge attributed to the following call), and critically the
'   border-thickness Local `b` -- Ghidra's C prints `DAT_00c61cf4` for the first DrawRect's
'   uses and `iVar1` for the other three, which LOOKS like "first call reads the bare
'   Global, the rest read a cached Local", but the disassembly shows g_gadget_int01 is
'   read from memory into esi exactly ONCE (0x513e4f) and every one of the four DrawRect
'   calls reads esi, never the address again -- that split is a decompiler SSA-naming
'   artifact, not a real difference, so `Local b:Int = g_gadget_int01` used uniformly
'   (as drafted) is correct.
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
Local b:Int = g_gadget_int01
Local o:Int = 2
DrawRect(ix-b-o, iy-b-o, w+b*2+o, Float(b))
DrawRect(ix-b-o, iy+h+o, w+b*2+o*2, Float(b))
DrawRect(ix-b-o, iy-b-o, Float(b), h+b*2+o)
DrawRect(ix+w+o, iy-b-o, Float(b), h+b*2+o*2)
SetColor(255, 255, 255)

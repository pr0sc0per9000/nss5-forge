' TScreen.DoProgressBar -- NOT VERIFIED. Candidate only.
' VA 0x00512DE9   1178 bytes (Ghidra-authoritative)
' KIND=Function (static), SIG (f,$,$,i)i, class-table slot 0xAC
'
' STATUS (this pass): our_len 1168 vs orig 1178 (delta -10, was +64 before this pass).
' scripts/localise_diff.py: delta_accounted=-10, delta_explained=True, 4 length-changing
' gaps + 2 same-length subs, and EVERY ONE of them is the SAME single, well-understood,
' provably-unfixable-at-this-level cause (see "RESIDUAL DELTA" below). Nothing else in
' the function differs at all under harness.compare's masked walk.
'
' ROOT CAUSE OF THE PREVIOUS +64 -- FOUND AND FIXED THIS PASS:
'   The previous draft modelled the three lazy-init object-Globals (g_dpb_bar, g_dpb_bg,
'   g_dpb_panTip) as a HAND-WRITTEN guard: `If (flags & bit) = 0 ... g = Expr ...
'   flags = flags | bit ... EndIf`. That reproduces the right LOGIC but the wrong SOURCE
'   FORM: ordinary BlitzMax assignment (`g = Expr` on an already-declared Object Global)
'   always compiles through Block::assignRef (tools/blitzmax-legacy-src/_src/compiler/
'   block.cpp:119), which retains the new value, RELEASES the old one, and only then
'   stores -- full retain/release traffic. The original's three sites disassemble (via
'   harness.disasm_original, confirmed directly, not from the Ghidra decompiler) to a
'   BARE `inc [new+4]` / `mov [Global],new`, with NO release of any old value at all.
'
'   Read tools/blitzmax-legacy-src/_src/compiler/stm.cpp (GlobalDeclStm::eval) and
'   block.cpp:142-168 (Block::initGlobalRef) to find why: a `Global name:Type = Expr`
'   DECLARATION (not a plain reassignment) with a non-constant initializer goes through
'   initGlobalRef instead of assignRef, which retains-and-stores with NO release (there is
'   provably no old value to release -- it is a declaration), and emits exactly the guard
'   shape seen in the binary:
'       if( lhs->refCounted() ) rhs=rhs->retain();
'       static int init_bit; static CGExp *init_var;   // <-- SHARED, WHOLE-COMPILE state
'       init_bit<<=1;
'       if( !init_bit ){ init_bit=1; CGDat *d=dat(); d->push_back(lit0); init_var=mem(...,d); }
'       CGLit *init_lit=lit(init_bit);
'       emit( bcc(CG_NE, bop(CG_AND,init_var,init_lit), lit0, t) );   // and/cmp/jne skip
'       emit( mov(lhs->cg_exp,rhs->cg_exp) );                        // bare store, no release
'       emit( mov(init_var, bop(CG_ORL,init_var,init_lit)) );        // flags |= bit
'       emit( lab(t) );
'   `init_bit`/`init_var` are FILE-STATIC C++ locals inside the COMPILER, so they persist
'   across every `Global x:Type = Expr` declaration compiled in the WHOLE PROGRAM (not per
'   function, not per Global): each such declaration anywhere claims the next bit of a
'   shared flags dword, and a fresh dword is allocated once 32 bits are used. That exactly
'   explains why bits 0x40000000/0x80000000 of DAT_00c6e2ac (g_dpb_bar/g_dpb_bg, the 31st
'   and 32nd such declaration compiled before this point in the ORIGINAL's build) are
'   immediately followed by g_dpb_panTip claiming BIT 0 of a brand-new dword, DAT_00c7dddc
'   -- which TProfile.CheckAchievement (still unverified) independently claims BIT 1 of,
'   for its own, unrelated, lazily-cached Global. Confirmed: `grep 00c6e2ac` and
'   `grep 00c7dddc` across extracted/decomp/*.c turn up ONLY these two functions, which is
'   exactly what a whole-program shared bit-allocator predicts and a per-Global private
'   flag would not.
'
'   FIX: write the three as plain, UNGUARDED, top-level declarations --
'   `Global g_dpb_bar:TProgressBar = TProgressBar.CreateProgressBar(...)` etc. -- with NO
'   hand-written If around them. (The previous draft's header recorded trying exactly this
'   but wrapping it in an explicit `If...EndIf` of its own, which is a DIFFERENT and wrong
'   thing to do -- that nests the declaration inside a block and bmk then scopes the name
'   to that block, breaking every later reference. Tested this pass via
'   harness.try_method with NSS5_WORKER set to a private tree: the bare, unguarded
'   declaration compiles clean, `g_dpb_bar`/`g_dpb_bg`/`g_dpb_panTip` stay in scope for the
'   rest of the function exactly as the original needs, and the emitted bytes reproduce
'   the original's guard/store/flag-or shape byte-for-byte apart from the bit constant --
'   see RESIDUAL DELTA.) The `g_screen_int19`/`g_profile_int44` flag-Int Globals the
'   previous draft declared and managed by hand are gone; there is nothing to declare,
'   the compiler owns that storage now.
'
' SECONDARY FIX -- the a3 = -1/0/1 branch IS a Select after all:
'   The previous draft's header reported trying `Select a3 / Case -1/0/1 / End Select` and
'   getting WORSE bytes (1248, "+70 net"), and reverted to If/ElseIf. Retested this pass on
'   top of the corrected base above: Select is unambiguously BETTER here (1168 vs 1174 for
'   the If/ElseIf form on the same base) and matches the original's disassembly shape
'   exactly -- `mov eax,ebx` once, then three back-to-back `cmp eax,N / je target`, then one
'   `jmp` for the (unreachable in practice, but present) no-match fallthrough, textbook
'   codegen-patterns.md 10.2 Select-with-no-Default shape. Do not trust a Select/If-ElseIf
'   comparison measured against a base that lacks the Global declaration above: the
'   declaration shifts the baseline by +64 and makes the comparison meaningless.
'
' RESIDUAL DELTA (-10 bytes; scripts/localise_diff.py delta_explained=True): ALL FOUR gaps
' and BOTH subs are the SAME cause -- the once-flags BIT CONSTANT is whatever
' `Block::initGlobalRef`'s shared, whole-program counter happens to be at when each
' declaration compiles (see above). The original's bits are large (0x40000000, 0x80000000,
' 0x1 of a fresh dword), which need a 4-byte immediate (`25 00 00 00 40`, 5-byte AND;
' `81 0D ... 00 00 00 40`, 8-byte OR). This file, built alone in an isolated probe with no
' OTHER `Global x = Expr` declarations ahead of it, starts its own counter fresh and gets
' small bits (1, 2, 4), which encode as the SHORT sign-extended forms (`83 E0 01`, 3-byte
' AND; `83 0D ... 01`, 7-byte OR) -- 2-3 bytes shorter at each of the three sites. This is
' NOT fixable from inside this file: the actual bit position is a property of the WHOLE
' PROGRAM's compile order (how many other files, reconstructed or not, use this same
' idiom, and in what order assemble.py hands files to bcc), exactly analogous to why an
' absolute address can never match bit-for-bit across two independently-linked images --
' except the oracle's masking rules only cover addresses and named call targets, not an
' arbitrary AND/OR immediate, so this specific gap cannot be masked even though it is the
' same category of unavoidable cross-build difference. Do not chase it further per file;
' it may converge on its own as more of the corpus using this idiom gets reconstructed and
' assembled in an order closer to the original's.
'
' WHAT IS SOLID (carried over from the previous pass, still true, not touched this pass):
'   * All field/Global/slot bindings are cross-checked against extracted/object_model.json
'     and extracted/vtable_map.tsv.
'   * Argument-merge resolution for every GetText/Lower nested-call site (Ghidra's printed
'     arg lists are wrong throughout this function; verified against
'     harness.disasm_original line by line, not against the decompiler).
'   * g_dpb_lblTip / g_contractoffer_tplayer / g_screen_float01 (mouse x) /
'     g_screen_float02 (mouse y) / g_screen_float10 (progress percent, ClampFloat'd into
'     [0,100]) / g_engine_int162, g_engine_int163 (signed-halved for progress-bar centring)
'     / g_screenwidth, g_screenheight (0x00C6EFDC/E0, established names) are all read
'     directly out of NSS5.exe's disassembly, addresses given inline in the previous
'     revision's history.
'   * TGadget.x / TGadget.y (offsets 0x20/0x24) are written as PLAIN FLOAT FIELDS, not
'     through TGadget.SetPosition (slot 0x84) -- that slot is used elsewhere in this same
'     function for a DIFFERENT receiver (g_dpb_panTip, not g_dpb_bar). Confirmed by
'     disasm, not by decompiler naming.
'   * The double `g_dpb_lblTip.txt = "" Or g_dpb_lblTip.txt = ""` is written faithfully
'     (two DIFFERENT pooled "" literal addresses in the original, 0x5C7D40 and 0xC5D284 --
'     not a transcription error).
'
'!Global g_dpb_lblTip:TLabel
'!Global g_profile:TProfile
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_float10:Float
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
Global g_dpb_bar:TProgressBar = TProgressBar.CreateProgressBar("loadingbar", Lower(a1), (g_engine_int162 / 2) - 300, g_engine_int163 - 100, 600, 70, 3, "FFFFFF", "00FF00", "FFFFFF", 1.0, 1, Null)
Global g_dpb_bg:TImage = LoadImageChecked("GameMedia/Images/Backgrounds/MyBg.png", -1)
Global g_dpb_panTip:TPanel = TPanel.CreatePanel("pan_Tip", "", 200, 250, 400, 30, "666666", "FFFFFF", 3, 0.5, 1, 170, 0)
g_dpb_panTip.SetText(GetText("help_Tip"), "", -1, -1)
If Not g_dpb_lblTip
	g_dpb_lblTip = TLabel.CreateLabel("lbl_Tip", "", 200, 280, 400, 170, 3, "666666", "FFFFFF", 0.6, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0.0)
	g_dpb_panTip.AddChild(g_dpb_lblTip)
EndIf
g_dpb_panTip.SetPosition(Int(g_screen_float01 + 200.0), Int(g_screen_float02 + 290.0), 1)
Select a3
	Case -1
		g_dpb_panTip.Show()
		g_dpb_lblTip.SetText(g_profile.GetCurrentTip(), "", 1, -1)
	Case 0
		g_dpb_panTip.Hide()
	Case 1
		g_dpb_panTip.Show()
		g_dpb_lblTip.SetText(g_profile.GetNewTip(), "", 1, -1)
End Select
If g_dpb_lblTip.txt = "" Or g_dpb_lblTip.txt = ""
	g_dpb_panTip.Hide()
EndIf
If a0 > -1.0
	g_screen_float10 = a0
	ClampFloat(Varptr g_screen_float10, 0.0, 100.0)
EndIf
g_dpb_bar.x = (g_engine_int162 / 2) - 300
g_dpb_bar.y = (g_engine_int163 / 2) + 220
g_dpb_bar.SetPercent(g_screen_float10, 1)
g_dpb_bar.SetText(Lower(a1), "", -1, -1)
g_dpb_bar.SetColour("FFFFFF", a2)
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
TScreen.RenderBorder()
DrawImageRect(g_dpb_bg, g_screen_float01, g_screen_float02, Float(g_screenwidth), Float(g_screenheight), 0)
g_dpb_bar.Draw()
g_dpb_panTip.Draw()
g_dpb_lblTip.Draw()
SetOrigin(0, 0)
Flip(1)
SetColor(255, 255, 255)
FlushAllInput()

' TScreen.DoProgressBar -- byte-identical vs NSS5.exe
' VA 0x00512DE9   1178 bytes (Ghidra-authoritative)
' KIND=Function (static), SIG (f,$,$,i)i, class-table slot 0xAC
'
' VERIFIED: harness.try_method -> MATCH, mode=reloc, 1178/1178, 97 masked, under
' NSS5_NO_LEARN=1, on two worker trees. The probe needs the '!GlobalInit 95 pragma below;
' without it the SAME source reports MISMATCH, mode=len, 1168 vs 1178. That is a
' probe-context gap, not a reconstruction gap, and the pragma is how the body states the
' context. See harness.py's GLOBALINIT_PRAGMA and docs/reference/whole-program-counters.md.
'
' The whole-program build agrees independently: scripts/localise_diff.py reports
' "CLEAN -- byte-identical modulo the oracle's masks" and check_assembled.py's comparator
' (harness.compare, learn=None) reports mode=reloc, 1178/1178, masked 97, first_diff=-1.
'
' WHERE THE 95 COMES FROM (derived from NSS5.exe, not fitted).
' Scan the exe's code sections for `or dword ptr [abs32], <power of two>`, the second
' immediate of an initGlobalRef guard. The game's own compilation unit gives four flags
' dwords, and because dat() hands them out in emission order their addresses increase in
' that order:
'     0x00C5A31C  bits 1..0x80000000, 32 distinct   #1..#32    all in 0x004BA034
'     0x00C65CC0  bits 1..0x80000000, 32 distinct   #33..#64   module body, VA-contiguous
'     0x00C6E2AC  bits 1..0x80000000, 32 distinct   #65..#96   #65..#94 module body, then
'                                                              #95 g_dpb_bar  0x40000000 at 0x00512E67
'                                                              #96 g_dpb_bg   0x80000000 at 0x00512E97
'     0x00C7DDDC  bits 1, 2                         #97..#98   #97 g_dpb_panTip  at 0x00512EF4
'                                                              #98 TProfile.CheckAchievement at 0x0056CFCF
' Bit position rises strictly with VA across all 98 sites with no gap and no repeat, which
' is what makes the grouping a reading rather than a guess. This body's first guard is
' 2 * 32 + 31 = #95, so the pragma is 95. The next run in the image restarts at bit 1 in a
' fresh dword (0x00C95B8C at 0x0058DBE1) while 0x00C7DDDC still had 30 bits free: that is a
' different bcc invocation, and the direct confirmation that the counter is per-process.
'
' HONEST LIMIT: only (ordinal - 1) mod 32 reaches the emitted bytes, since the flags dword
' is an absolute address the oracle masks. Measured on this body: 94 -> 1183, 95 -> MATCH,
' 96 -> 1173, and 63 and 127 -> MATCH as well. So the probe confirms 95 modulo 32; the
' absolute 95 rests on the exe scan above.
'
' THE CAUSE, VERIFIED IN THE COMPILER SOURCE, NOT INFERRED
' tools/blitzmax-legacy-src/_src/compiler/stm.cpp:182 GlobalDeclStm::eval sends any
' `Global x:T = <expr>` whose initialiser is not Val::constant() (val.cpp:63 -- a CGLit or
' CGSym, i.e. a bare literal) to Block::initGlobalRef, block.cpp:142. That function holds
'     static int init_bit; static CGExp *init_var;
' as C++ FUNCTION-LOCAL STATICS, so they persist for the entire bcc process. Each such
' declaration does init_bit<<=1, claims that bit of a shared flags dword, allocates a fresh
' dword when 32 bits are used, and emits and/cmp/jne, the bare store, then `or [word],bit`.
' The bit VALUE therefore reaches the instruction stream as an AND and an OR immediate, and
' its ENCODING LENGTH depends on the value: bits 1..0x40 are sign-extendable (3-byte
' `83 E0 ib` AND, 7-byte `83 0D disp32 ib` OR), bits 0x80 and up are not (5-byte
' `25 id` AND, 10-byte `81 0D disp32 id` OR). Nothing else in the emit depends on it.
' Note `Global x:T[N]` counts too: parser.cpp parseInitDecl turns the dimension into an
' ArrayExp, which is a bbArrayNew1D call, which is not constant.
'
' The original program makes exactly 98 such declarations, 94 of them in the module
' body, and TScreen.DoProgressBar is the FIRST function in the whole program to make
' one. That is the property a bare probe cannot have. (An earlier header put this at
' "the 31st and 32nd"; that read one flags dword and missed the two before it.)
'
' AND THE RECONSTRUCTION NOW REPRODUCES IT
' The assembled program's module body currently declares exactly 94 as well, from
' extracted/module_globals_decoded.tsv plus the recovered bodies' pragmas, so the counter
' arrives at 0x40000000 at exactly the right statement and all three guards encode
' identically. Measured in the assembled image: three flags dwords of 32, then bit 0 of a
' fourth -- the same shape as the original, 97 declarations to the original's 98 (ours has
' no CheckAchievement site; see below).
' THIS IS NOT STABLE UNDER CORPUS DRIFT, and that is the thing to know. Earlier the same
' day the module body emitted 104 and this body assembled to 1183 bytes with bits
' 0x100/0x200/0x400 -- same six differences, opposite sign. Ten module-scope declarations
' appearing or disappearing anywhere in the program moves this body off and back on.
' scripts/check_assembled.py is what notices; the per-function oracle never will.
'
' LEAD FOR SOMEONE ELSE: TProfile.CheckAchievement (0x0056CF70, 625 bytes, 623 recovered)
' owns the original's #98. Our assembled build emits no site for it at all, so its Global
' is not written as a `Global x:T = Expr` declaration. Same idiom, same file to read.
'
' LIVENESS IS NOT INVOLVED (confirmed by an earlier pass, re-confirmed here): this body
' declares zero named Locals, walloc_report.py sees 138 unnamed CG nodes and no source
' Local, and no [ebp-N] displacement differs on either side. Statement placement cannot
' reach any of the six bytes that differed.
'
' WHAT IS SOLID (carried over, still true, not touched this pass):
'   * All field/Global/slot bindings are cross-checked against extracted/object_model.json
'     and extracted/vtable_map.tsv.
'   * Argument-merge resolution for every GetText/Lower nested-call site (Ghidra's printed
'     arg lists are wrong throughout this function; verified against
'     harness.disasm_original line by line, not against the decompiler).
'   * The three lazy-init Globals are written as PLAIN, UNGUARDED `Global x:T = Expr`
'     declarations. A hand-written `If (flags & bit) = 0 ... EndIf` compiles through
'     Block::assignRef instead and emits a full retain/RELEASE/store; the original has a
'     bare `inc [new+4]` / `mov [Global],new` with no release, which is initGlobalRef.
'     Do not re-wrap them.
'   * The a3 = -1/0/1 branch is a Select, not If/ElseIf (1168 vs 1174 on the same base
'     before the counter was aligned, and it matches the original's cmp/je/cmp/je shape).
'   * g_dpb_lblTip / g_contractoffer_tplayer / g_screen_float01 (mouse x) /
'     g_screen_float02 (mouse y) / g_screen_float10 (progress percent, ClampFloat'd into
'     [0,100]) / g_engine_int162, g_engine_int163 (signed-halved for progress-bar centring)
'     / g_screenwidth, g_screenheight (0x00C6EFDC/E0) are read directly out of NSS5.exe's
'     disassembly.
'   * TGadget.x / TGadget.y (offsets 0x20/0x24) are written as PLAIN FLOAT FIELDS, not
'     through TGadget.SetPosition (slot 0x84) -- that slot is used elsewhere in this same
'     function for a DIFFERENT receiver (g_dpb_panTip, not g_dpb_bar). Confirmed by disasm.
'   * The double `g_dpb_lblTip.txt = "" Or g_dpb_lblTip.txt = ""` is faithful (two
'     DIFFERENT pooled "" literal addresses in the original, 0x5C7D40 and 0xC5D284).
'
'!GlobalInit 95
'!Global g_dpb_lblTip:TLabel
'!Global g_profile:TProfile
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_float10:Float
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
' CASE DIRECTION CORRECTED 2026-08-22: 2 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
Global g_dpb_bar:TProgressBar = TProgressBar.CreateProgressBar("loadingbar", a1.ToUpper(), (g_engine_int162 / 2) - 300, g_engine_int163 - 100, 600, 70, 3, "FFFFFF", "00FF00", "FFFFFF", 1.0, 1, Null)
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
g_dpb_bar.SetText(a1.ToUpper(), "", -1, -1)
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

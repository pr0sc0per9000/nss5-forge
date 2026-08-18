' TScreen_Stable.Draw
' VA 0x005890C9   934 bytes original.   KIND=Function, SIG ()i, slot 0x68
'
' STATUS: MATCH, 934/934 bytes, mode=reloc (reloc_masked=59), verified locally against
' NSS5.exe via harness.try_method('TScreen_Stable','Draw', body) in a private per-pass
' workdir (BuildLock-protected; does NOT touch src/assembled or any other shared state).
' Left in recovered_unverified/ per this task's rules (edit only this file); promotion to
' src/recovered/ is a separate step for whoever owns that pipeline.
'
' WHAT WAS WRONG BEFORE (root cause of the 21.4%/14-byte score): the ENTIRE candidate body
' that a previous pass had already derived and extensively annotated was left commented out
' -- every line prefixed with `'`, so the file compiled to an empty stub (14 bytes, just
' the prologue/epilogue). The candidate itself was already very close. This pass:
'   1. Un-commented it and made it the live body.
'   2. Swapped 3 global names for ones an ALREADY-VERIFIED sibling in src/recovered/ uses
'      at the SAME address (names have no effect on codegen -- harness.py -- but reusing an
'      established name is strictly better than adding a fourth alias for the same slot):
'        g_screen_stable_float02 -> g_stable_startx   (0x00C6DF4C, matches
'          TScreen_Stable.DoRace.bmx, which sets `g_stable_startx = 5500.0`)
'        g_screen_stable_arr04   -> g_stable_arr04    (0x00C6DF60, matches DoRace's
'          `g_stable_arr04[0..2] = 0`)
'      g_screen_stable_int05 (0x00C6DF70) was already the RIGHT name -- confirmed the
'      canonical pick in extracted/global_alias_unified.tsv (g_stable_int05 and
'      g_stable_state both alias INTO it). g_Object845..849/g_screen_stable_arr03/
'      g_screen_stable_float03 are untouched elsewhere in the corpus (grepped clean), so
'      kept as-is -- deliberately NOT reusing g_stable_obj845:Object (DoRace's name for
'      0x00C6DF28) for g_Object845, because that Global is declared :Object there and this
'      body needs :TImage for the DrawImage() call; reusing the name would have let
'      merge_globals()'s first-wins dedup silently hand this body the wrong static type.
'   3. Read the true float CONSTANTS straight out of NSS5.exe's .rdata with
'      scripts/bytematch.read_va (harness.compare masks the ADDRESS of a float load, never
'      the value behind it -- see scripts/check_floats.py -- so a wrong constant costs
'      nothing on this oracle, but "preserve the original, bugs and all" means getting it
'      right anyway now that it's cheap to check):
'        0x00C93B5C = 1.0     0x00C93B60 = 200.0   0x00C93B64 = 11520.0  0x00C93B68 = 11528.0
'        0x00C93B6C = 108.0   0x00C93B70 = 108.0   0x00C93B74 = 11528.0
'      This caught a real bug in the old candidate: it had the g_Object849 call's (x,y) as
'      (319.0+fVar1, 320.0) and the arr03[0] call's as (11520.0+fVar1, 320.0) -- both wrong.
'      Correct (per the constants above and the immediates Ghidra prints, 0x439f8000=319.0,
'      0x43a00000=320.0): g_Object849 gets (11520.0+fVar1, 319.0), arr03[0] gets
'      (11528.0+fVar1, 320.0).
'   4. Fixed the length delta (+1 -> exact) by finding the ACTUAL register-allocation shape
'      the oracle wanted, empirically, one change at a time:
'      a. The 3 position loops originally computed `i + Int(FloatMod(...))` inline as an
'         AddDrawOb argument, which made bcc reuse the loop-counter register as the scratch
'         (clobbering it, and needing a 3rd callee-saved register -- an extra push/pop pair
'         -- across the 3 loops). Pulling the FloatMod/Int result out into its own `Local j`
'         (a separate name from `i`) before the call reproduces the original's exact
'         `mov edx, esi / add edx, eax / mov [ebp-8], edx` shape and drops back to the
'         original's 2 callee-saved registers (ebx/esi only, no edi).
'      b. `fVar1`'s interpolation is `g_stable_startx*g_roulette_float +
'         g_screen_stable_float03*(1.0-g_roulette_float)` -- NOT the natural english order
'         AND not a naive "(1.0-x)*y" grouping either. Both of those alternate groupings
'         compile 1 FPU instruction SHORTER than the original (bcc folds "(1.0 - x)" before
'         multiplying if it is the LEFT operand of the `*`); only writing the constant
'         multiplicand FIRST -- `float03 * (1.0 - roulette)` -- reproduces the original's
'         fld/fld/fld/fsub/fmulp/faddp 7-instruction sequence exactly.
'      c. The last loop's per-horse X offset is `i * 0x6c0` (0x6c0 = 1728) in Ghidra's
'         folded arithmetic, but the ORIGINAL bytes are `imul eax,eax,0x6c` (3 bytes, fits
'         in an imm8) THEN `shl eax,4` (3 bytes) -- i.e. source-level `i * 108 * 16`, not a
'         single `i * 1728` (1728 needs a 6-byte imm32 imul, same total length but the
'         wrong bytes -- this was the actual first_diff once (a) and (b) above were fixed).
'
' ORIGINAL RESOLUTIONS carried over from the prior pass (re-confirmed, not re-derived):
'   * Early-return shape: `g_screen_stable_int05=3 And g_Object845<>Null` is a GUARD
'     (DrawImage + Return 0), and the function falls through to the roulette-position code
'     unconditionally afterward -- confirmed against the full disassembly, not just Ghidra's
'     C, since the guard's Else branch has no jump-around at the end.
'   * FUN_00506456 = SetDrawStateHex (module Function, confirmed via TScreen.Draw.bmx).
'   * FUN_005ad711 = DrawImage, FUN_005ad918 = TileImage (both confirmed via
'     docs/reference/codegen-patterns.md's runtime helper table / brl_functions.tsv).
'   * PTR_FUN_00c5b1b4 = TDrawOb class table slot 0x34 = TDrawOb.AddDrawOb -- the 16-arg
'     signature and the (img,x,y,z,frame,level,alph,rot,col$,sclx,scly,blend,z2,txt$,
'     imgrectw,imgrecth) order are taken verbatim from the byte-verified
'     src/recovered/TDrawOb.AddDrawOb.bmx, not re-derived from Ghidra's merged arg list.
'   * THorse.RenderAllRunners(a0,a1,a2) and TDrawOb.RenderAll(a0,a1,a2) both take 3 Floats,
'     confirmed against their own byte-verified src/recovered/ files; called here with
'     (g_roulette_float, fVar1, 0) and (1.0, 0, 0) respectively (argument order read off the
'     cdecl right-to-left push sequence, not Ghidra's zero-arg-looking call print).
'   * &DAT_005c9c80 = Null (bbNullObject), &PTR_PTR_005c7d40 = "" (bbEmptyString),
'     &PTR_PTR_00c5d680 = "FFFFFF" (a plain string literal, not a Global).
'   * g_screen_int21:Int = 0x00C6EFDC (screen width, 800) -- the dominant, heavily-reused
'     name for this address across 8+ already-verified TScreen_* bodies (TScreen.
'     UpdateOffset.bmx et al.); NOT g_screen_height/g_screen_y, which is what
'     explain_global.py's raw solver output suggests in isolation but which only 1-3 files
'     ever actually used.
'!Global g_screen_stable_int05:Int
'!Global g_Object845:TImage
'!Global g_Object846:TImage
'!Global g_Object847:TImage
'!Global g_Object848:TImage
'!Global g_Object849:TImage
'!Global g_roulette_float:Float
'!Global g_stable_startx:Float
'!Global g_screen_stable_float03:Float
'!Global g_screen_stable_arr03:TImage[]
'!Global g_stable_arr04:Float[]
'!Global g_screen_int21:Int
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
If g_screen_stable_int05 = 3 And g_Object845 <> Null
	DrawImage(g_Object845, 0, 0, 0)
	Return 0
EndIf
Local fVar1:Float = g_stable_startx * g_roulette_float + g_screen_stable_float03 * (1.0 - g_roulette_float)
TileImage(g_Object847, fVar1, 0, 0)
For Local i:Int = -200 To g_screen_int21 + 200 Step 200
	Local j:Int = Int((fVar1 + g_stable_arr04[0]) Mod 200.0)
	TDrawOb.AddDrawOb(g_Object846, i + j, 0, 0, 0, 2, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
Next
TDrawOb.AddDrawOb(g_Object849, 11520.0 + fVar1, 319.0, 0, 0, 2, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
TDrawOb.AddDrawOb(g_screen_stable_arr03[0], 11528.0 + fVar1, 320.0, 0, 0, 2, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
For Local i:Int = -108 To g_screen_int21 + 108 Step 108
	Local j:Int = Int((fVar1 + g_stable_arr04[1]) Mod 108.0)
	TDrawOb.AddDrawOb(g_Object848, i + j, 285.0, 0, 0, 2, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
	Local k:Int = Int((fVar1 + g_stable_arr04[2]) Mod 108.0)
	TDrawOb.AddDrawOb(g_Object848, i + k, 535.0, 0, 0, 4, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
Next
For Local i:Int = 1 To 6
	TDrawOb.AddDrawOb(g_screen_stable_arr03[i], (11528.0 + fVar1) - (i*108*16), 285.0, 0, 0, 3, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
Next
If g_screen_stable_int05 = 2
	THorse.RenderAllRunners(g_roulette_float, fVar1, 0)
EndIf
TDrawOb.RenderAll(1.0, 0, 0)

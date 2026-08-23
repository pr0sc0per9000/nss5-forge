' TProfile.CheckAchievement
' VA 0x0056cf70   625 bytes   vtable slot 0x150   sig (i)i
'
' byte-identical vs NSS5.exe (625/625, mode=reloc, reloc_masked=47), verified with
' harness.try_method under NSS5_NO_LEARN=1. Three separate process launches on worker 321
' and one on an independently created tree (321b): identical verdict, identical
' reloc_masked count every time.
'
' STAYS IN src/recovered_unverified/ ON PURPOSE, exactly like the already-matched
' src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx. It is matched, not
' shippable: it Imports libsteamstub.a, and src/recovered_module/SteamInit.bmx exists to
' keep the Steam link surface out of src/assembled/. Moving it into src/recovered/ would
' put that Import straight back, because assemble.py filters UNVERIFIED_SKIP and nothing
' else. progress.py's VERIFIED_NOT_SHIPPED already counts it in both numerator and
' denominator and labels the absence; that is the whole point of that table.
'
' The MATCH needs the '!GlobalInit 98 pragma below. Without it the SAME source reports
' MISMATCH, mode=diff, 623/625, first_diff=51, with the entire residue in two bytes: the
' immediate `02` at body offsets +51 and +101 (`and eax,2` at VA 0x0056cfa1 and
' `or dword ptr [0xc7dddc],2` at VA 0x0056cfcf), where a probe that starts bcc's
' whole-program init_bit counter at zero emits `01`. Derivation of the 98, and the
' independent exe scan behind it, in THE ONCE-INIT ORDINAL below.
'
' WHAT CHANGED THIS PASS (the previous draft did not build at all; see BUILD below)
'
' 1. THE STEAM CALLS ARE `$z`/`Byte Ptr` EXTERN ARGUMENTS, NOT HAND-WRITTEN ToCString +
'    MemFree. This is the whole reconstruction. bcc converts a String actual argument to
'    a C-string formal automatically (_src/compiler/val.cpp:381-393):
'        if( type->stringType() ){
'            if( dst->cstringType() || dst->ptrType("b") )
'                e=jsr(CG_PTR,"bbStringToCString",cg_exp);
'            CGTmp *t=tmp(CG_PTR); e=esq(mov(t,e),t);
'            cleanup->push_back( eva(jsr(CG_INT32,"bbMemFree",t)) );
'    -- allocate, call, then free the temp after the call. That is exactly the original's
'    0x0056d03c..0x0056d068 and 0x0056d1a9..0x0056d1d2. `name$z` and `name:Byte Ptr` take
'    the same branch and compile to the same bytes (measured both, identical verdict);
'    `name:Byte Ptr` is shipped only because it is the spelling
'    src/recovered_module/Fn_0058D90B.SyncSteamAchievements.bmx already uses for
'    SetSteamAchievement, so the two files' pragmas dedupe cleanly if both are ever built.
'
' 2. THE STEAM GUARD IS ONE `And` EXPRESSION, NOT AN If BLOCK PLUS TWO LOCALS. The
'    previous draft's `steamResult`/`gotIt` locals were an artefact of reading the
'    short-circuit chain as control flow. The tell is bcc's own materialisation rule: a
'    comparison used as a STATEMENT If condition compiles to a direct conditional jump
'    (`cmp dword ptr [0xc6f3b8],1 ; jne` at VA 0x0056d196, 7+2 bytes), while a comparison
'    used as an OPERAND of And/Or is materialised into a 0/1 value with sete/movzx before
'    the branch (`cmp eax,1 ; sete al ; movzx eax,al ; cmp eax,0 ; je` at VA 0x0056d024).
'    The original tests the IDENTICAL condition `g_profile_int43 = 1` in both forms, 0x1c6
'    bytes apart. That is not a peephole inconsistency, it is two different source
'    constructs, and the long form is an And operand. The three-operand chain at
'    0x0056d01f..0x0056d08d then reads straight off:
'        eval A -> eax ; cmp eax,0 ; je merge ; eval B -> eax ; cmp eax,0 ; je merge ;
'        eval C -> eax ; merge: cmp eax,0 ; je past-the-Return
'    with each `je` landing on the NEXT operand's `cmp eax,0`, which is why the guard's
'    `je 0x56d06a` lands on the `cmp eax,0` at 0x0056d06a rather than on the `mov eax,ebx`
'    at 0x0056d068 -- 0x0056d068 is the tail of operand B (the Extern call's saved result
'    being restored after bbMemFree), and eax already holds the And's 0 result on the
'    short-circuit path. The previous header recorded that jump as "genuine
'    register-value-reuse ... unexplained"; it is neither. Same shape as the `Or` chain
'    over a0 at 0x0056cfd6..0x0056d00c, which uses `jne` for the same reason.
'    Measured: this change alone takes the body from BUILD_FAIL (and, once the previous
'    draft's two hand-written locals were made to build at all, 623 with two unexplained
'    gaps) to 625/625 length with zero unmasked bytes outside the init_bit immediate.
'
' 3. BUILD. The previous draft's pragma block ended `'!Raw End Extern`, which does not
'    survive harness.merge_globals: raw lines are deduplicated by lowercased text, and
'    src/recovered_module/Fn_0058D81A.GetClipboardText.bmx already contributes a
'    `'!Raw End Extern` of its own. Whichever appears second is dropped, so the probe was
'    emitted with two `Extern` openers and ONE terminator and bcc failed with
'        Syntax error in extern block - expecting Const, Global, Function or Type
'    at the first `Global` line after the Win32 block. Shipped as `'!Raw EndExtern`
'    instead: `EndExtern` is its own keyword (_src/compiler/toker.cpp:111,
'    `_tokes["EndExtern"]=T_ENDEXTERN`), so it terminates the block identically and does
'    not collide. This is a merge_globals defect, not a body defect -- as written, NO body
'    can carry its own Extern block while GetClipboardText is in the probe. The real fix
'    is to exempt Extern/End Extern/EndExtern delimiters from that dedup; deliberately not
'    done here, because harness.py is shared with every other running job.
'
' 4. assemble.py's UNVERIFIED_SKIP comment for this file was STALE in both its claims and
'    has been corrected in place. The bare `Extern ... End Extern` block written as
'    ordinary body statements is gone (it is pragmas now, item 3), and "performs a
'    reference-release the original does not" is not true of this body: the original
'    retains only (`inc dword ptr [eax+4]` at 0x0056cfc7, no matching release), which is
'    bcc's Block::initGlobalRef path for `Global x:T = <non-constant>`
'    (_src/compiler/block.cpp:142), and this body reproduces those 26 bytes exactly. The
'    file still belongs in UNVERIFIED_SKIP for the ONE remaining reason: libsteamstub.a.
'
' THE ONCE-INIT ORDINAL -- DERIVED FROM NSS5.exe, NOT FITTED TO THE PROBE.
' bcc numbers every `Global x:T = <non-constant>` declaration with a bit in a shared
' 32-bit flags dword (_src/compiler/block.cpp:142-168), from C++ function-local statics
' that are never reset for the life of the bcc process:
'     static int init_bit; static CGExp *init_var;
'     init_bit<<=1; if( !init_bit ){ init_bit=1; ... init_var=mem(CG_INT32,dat()); }
' The bit VALUE reaches the byte stream twice, as the AND immediate of the guard test and
' the OR immediate of the guard set. harness.py's '!GlobalInit pragma is how a body states
' its position in that count; the mechanism, its limits and the derivation method are
' documented at harness.py's GLOBALINIT_PRAGMA and docs/reference/whole-program-counters.md.
'
' The number was derived here independently rather than taken from TScreen.DoProgressBar's
' header (which reaches the same 98 from the other end). Scan the exe's .text and code
' sections for `or dword ptr [abs32], <power of two>` -- both encodings, `83 0D disp32 ib`
' and `81 0D disp32 id` -- and group by flags dword. The game's own compilation unit is
' four dwords, whose addresses rise in emission order:
'     0x00C5A31C   32 sites, 32 distinct bits   VA 0x004ba26b..0x004bab2c   #1..#32
'     0x00C65CC0   32 sites, 32 distinct bits   VA 0x004bab5a..0x004bb595   #33..#64
'     0x00C6E2AC   32 sites, 32 distinct bits   VA 0x004bb5c3..0x00512e97   #65..#96
'     0x00C7DDDC    2 sites,  2 distinct bits   VA 0x00512ef4..0x0056cfcf   #97..#98
' The first three are full (all 32 bits present, no repeat), the fourth holds bit 1 at
' 0x00512ef4 (TScreen.DoProgressBar's third lazy Global) and bit 2 at 0x0056cfcf, which is
' THIS function. 3 * 32 + 2 = 98. The next flags dword in the image, 0x00C95B8C, restarts
' at bit 1 at 0x0058dbe1: a different bcc invocation, and the direct confirmation that the
' counter is per-process rather than per-program.
'
' HONEST LIMIT. Only (ordinal - 1) mod 32 reaches the emitted bytes, because the flags
' dword itself is an absolute address the oracle masks. Measured on this body, all under
' NSS5_NO_LEARN=1: 97 -> MISMATCH 623/625 first_diff 51, 99 -> MISMATCH 623/625 first_diff
' 51, 98 -> MATCH, 130 -> MATCH. So the probe confirms 98 modulo 32 and no more; the
' absolute 98 rests on the exe scan above, not on the probe.
'
' Exactly two functions in NSS5.exe declare a function-scoped initialised Global --
' TScreen.DoProgressBar (#95, #96, #97) and this one (#98). Both now match.
'
' 0x00c8f0a4 IS NOT A MODULE GLOBAL. It is the anonymous CGDat slot bcc allocates for the
' function-scoped `Global` above, written once at 0x0056cfca and read once at 0x0056d141,
' both inside this function -- which is exactly the refs=2 that extracted/globals_final.tsv
' scores as a low-confidence module Global named `g_Object878` (also emitted, unused, at
' src/generated/globals.bmx:1163). Declared here with a local name, `staricon`, so nothing
' reads it as module state. The old name is recorded here so a grep for it lands.
'
' GLOBALS -- addresses read off the disassembly, names as the corpus already established
' them (scripts/explain_global.py, cross-checked against byte-verified siblings):
'   0x00c6f170  g_iconpath:String      CERTAIN, 14 bodies; TScreen_Home.CreateScreen has
'                                      the identical LoadImageChecked(g_iconpath+"Star.png",-1)
'   0x00c6f3b8  g_profile_int43:Int    Steam-enabled flag; unresolved elsewhere, kept
'   0x00c61724  g_screen_mousex:Float  both confirmed via byte-verified
'   0x00c61728  g_screen_mousey:Float  TGadget.UpdateToolTip.bmx, which touches both
'   0x00c6efe0  g_screen_width:Int     STRONG; NOT the same address as g_screen_w/0x00c6efe4
'   0x00c5b1fc  g_player_int01:Int     hand-verified, globals_corrections.tsv; 42 bodies
'   0x00c6efe8  g_engine_int163:Int    byte-verified TBall.Kick.bmx uses this name for this
'                                      address in this exact CreateAlert idiom
'   0x00c6f124  g_Object861:TSound     PlaySound arg 1; unresolved elsewhere, kept
'   0x00c6f090  g_channel:TChannel     alias-unification canonical target, 4 bodies
' String literals (harness.read_string, re-read this pass, not carried over):
'   0x00c8f074 "CheckAchievement:"  0x00c7e53c "Star.png"  0x00c8f0a8 "Bugged Achievement"
'   0x00c8f0d8 "ACHIEVEMENT_"  0x00c8f104 "CACHIEVEMENT_"  0x00c6fc70 "666666"
'   0x00c5d680 "FFFFFF"   ("666666" is pushed last, so it is the EARLIER argument.)
' Float constants read out of the image: 0x00c8f0fc = 41200000 = 10.0,
'   0x00c8f100 = 42ec0000 = 118.0. Both reach _bbFloatToInt (0x005b9690) as a qword, which
'   is the implicit narrowing bcc inserts for `Local x:Int = <float expr>` -- no Int() cast
'   in the source, and adding one changes the bytes.
' Y'S OPERAND ORDER IS LOAD-BEARING and is kept from the previous pass: at 0x0056d0d5 the
'   original does `fld [g_screen_mousey]` FIRST, spills g_screen_width to [ebp-4], `fild`s
'   it second and combines with `faddp st(1)`. That pair only appears with the Float
'   operand written first; `g_screen_width + g_screen_mousey - 118.0` collapses to a single
'   `fadd` and loses 2 bytes overall. Hence `g_screen_mousey + g_screen_width - 118.0`.
'   The `sub esp,4` in the prologue exists solely for that one spill slot.
' TScreenMessage.CreateAlert(i,i,$,i,$,$,:TImage,i,i,i,i,i)i is TScreenMessage slot 0x48
'   (class table 0x00c6b27c); `add esp,0x30` after the call confirms 12 arguments. Ghidra
'   merges most of them into the preceding GetText concat's argument list (the documented
'   merge trap in docs/reference/codegen-patterns.md); the shape here is the one already
'   byte-verified in TBall.Kick.bmx.
' Fields: TProfile.achievements = Int[] @ +0x1bc, TProfile.date:TMyDate @ +0x10,
'   TMyDate.sdate:Int @ +8 -- all from extracted/object_model.json, all visible in the
'   disassembly at 0x0056d0ba..0x0056d0d1.

'!GlobalInit 98
'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function GetSteamAchievement:Int(name:Byte Ptr)
'!Raw Function SetSteamAchievement(name:Byte Ptr)
'!Raw EndExtern
'!Global g_iconpath:String
'!Global g_profile_int43:Int
'!Global g_screen_mousex:Float
'!Global g_screen_width:Int
'!Global g_screen_mousey:Float
'!Global g_player_int01:Int
'!Global g_engine_int163:Int
'!Global g_Object861:TSound
'!Global g_channel:TChannel

	LogLine("CheckAchievement:" + a0)
	Global staricon:TImage = LoadImageChecked(g_iconpath + "Star.png", -1)
	If a0 = 1 Or a0 = 73 Or a0 = 74 Or a0 = 75
		' BUG (original), and the reason for the log line: for these four the
		' already-awarded check `achievements[a0-1] > 0` sits BEHIND the Steam operands,
		' so with Steam disabled (or with GetSteamAchievement returning 0) the And
		' short-circuits before it ever runs and the achievement re-fires on every call.
		' The other 76 reach the same check unconditionally. Preserved.
		LogLine("Bugged Achievement")
		If g_profile_int43 = 1 And GetSteamAchievement("ACHIEVEMENT_" + a0) And achievements[a0-1] > 0
			Return 0
		EndIf
	Else If achievements[a0-1] > 0
		Return 0
	EndIf
	achievements[a0-1] = date.sdate
	Local x:Int = g_screen_mousex + 10.0
	Local y:Int = g_screen_mousey + g_screen_width - 118.0
	If g_player_int01 <> 0
		x = 10
		y = g_engine_int163 - 60
	EndIf
	If a0 <> 80
		TScreenMessage.CreateAlert(x, y, GetText("CACHIEVEMENT_" + a0), 2500, "666666", "FFFFFF", staricon, 3, 0, 0, 0, 1)
		PlaySound(g_Object861, g_channel)
	EndIf
	If g_profile_int43 = 1
		SetSteamAchievement("ACHIEVEMENT_" + a0)
	EndIf
	Return 0

' GameMain -- module-level Function (no Type, no reflection record). NAME IS OURS.
' VA 0x004BCCDB   484 bytes   sig ()i
' byte-identical vs NSS5.exe (484/484, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=53), verified with harness.try_function under NSS5_NO_LEARN=1. MATCH on the
' first attempt once the call mechanism below was worked out.
'
' THE SPINE OF THE WHOLE PROGRAM. Everything else in the game is a leaf this calls, directly
' or indirectly. Full behavioural writeup: docs/game/engine/main-loop.md (read that for what
' the loop DOES; this header is about the reconstruction, not the game).
'
' ============================ THE ONE REAL PROBLEM, SOLVED ============================
' All eight boot/loop calls decompile as `call dword ptr [abs]`, e.g. `call [0xC5A420]`, and
' the brief that assigned this pass framed "what BlitzMax source construct produces that"
' as the open question, guessing a module-level function-pointer Global as the obvious
' candidate. THAT GUESS IS WRONG. Every one of the eight addresses is simply an existing
' Type's own CLASS TABLE plus a method slot -- i.e. these are ORDINARY STATIC CROSS-TYPE
' FUNCTION CALLS (`TFoo.Bar()`, already established as "free" in codegen-patterns.md 3),
' and bcc compiles a static Type.Function() call through the class table indirectly rather
' than with a direct E8 -- confirmed generally
' for TOpenALAudioDriver.Create, and confirmed HERE, specifically, by resolving every one of
' the eight addresses against extracted/class_tables.tsv + extracted/vtable_map.tsv:
'
'   0x00C5A420 = TLocale classtable(0x00C5A3F0)          + 0x30 = Function SetUp()i
'   0x00C5D548 = TOptions classtable(0x00C5D518)         + 0x30 = Function SetUp()i
'   0x00C61C5C = TScreen classtable(0x00C61C2C)          + 0x30 = Function SetUp()i
'   0x00C5BA60 = TEngine classtable(0x00C5BA30)          + 0x30 = Function SetUp()i
'   0x00C63980 = TScreen_Language classtable(0x00C63950) + 0x30 = Function CreateScreen()i
'   0x00C63984 = TScreen_Language classtable(0x00C63950) + 0x34 = Function SetUpScreen(i)i
'   0x00C61C94 = TScreen classtable(0x00C61C2C)          + 0x68 = Function Render(f)i
'   0x00C61CA4 = TScreen classtable(0x00C61C2C)          + 0x78 = Function Update()i
'
' So no '!Global pragma of any kind is needed for the boot/loop calls -- writing plain
' `TLocale.SetUp()`, `TScreen.Update()`, `TScreen.Render(x)` etc. makes bcc emit exactly
' this shape on its own, and it matched on the first compile. The stored VALUE at each slot
' (i.e. which function it points to) is a compile-time constant baked in by bcc from the
' Type's own method declarations, which is also why the brief's "targets are certain, read
' from the .data initialisers" observation was correct even though the mechanism guess
' built on top of it was not.
'
' Because these calls are masked by the general classtable-slot rule (harness.compare
' resolves both sides' operand to the same Type+slot via reflection), the ORIGINAL BODY of
' TLocale.SetUp / TScreen.SetUp / TEngine.SetUp / TScreen_Language.CreateScreen /
' TScreen_Language.SetUpScreen does not need to be independently byte-verified for GameMain
' itself to match -- the harness's own Type-stub generator (harness.py's _build_prelude)
' already places every Type's methods at the correct vtable slot from vtable_map.tsv, which
' is what the compiled address resolves against on our side too.
'
' ============================ THE LOOP ============================
' A textbook fixed-timestep loop with interpolated rendering (docs/game/engine/main-loop.md
' has the full behavioural account). Structurally:
'   * Pre-loop setup computes `matchclock = MilliSecs() - pausedms` once, then
'     `pauseclock = matchclock` (this is "lastFrame = now"; there is no explicit
'     "accumulator = 0" anywhere in the 484 bytes -- it relies on the Global's default
'     zero-initialisation, and the pre-loop block flows straight into the Repeat body
'     with NO separate branch, confirmed by disassembly: 0x004BCD3F falls through directly
'     into 0x004BCD44, the Repeat body's own first instruction).
'   * `Repeat` body: recompute matchclock/frameaccum/pauseclock, drain the inner
'     `While frameaccum >= g_replay_div ... Wend` (TScreen.Update() once per 25 ms tick),
'     then `TScreen.Render(frameaccum / Float(g_replay_div))`.
'   * `Until AppTerminate()`.
'   * No explicit `Return` -- GameMain is declared `:Int` with no final Return statement,
'     so bcc auto-emits `mov eax,0` before the epilogue (codegen-patterns 6), matching the
'     original's `mov eax,0 / jmp +0 / mov esp,ebp / pop ebp / ret` exactly.
'
' The debug overlay (`If g_engine_int161 = 2`) is NOT the "3 randoms, a lookup, a log line"
' an earlier paraphrase suggested -- that was
' a summary of an elided decompile block, not a transcription. Read from the actual
' disassembly, it is three DrawText lines at x=5, y=5/15/25 (float literals, confirmed by
' the raw IEEE-754 bit patterns 0x40A00000/0x41700000/0x41C80000 being pushed as plain
' `push imm32` -- i.e. compile-time float constants, not computed), followed by a
' Ctrl+S hotkey check that prints the profile's contract value:
'   DrawText(FormatMoney(GCMemAlloced(), 0), 5.0, 5.0)    ' memory used, formatted as money
'   DrawText(String(JoyX(0)), 5.0, 15.0)
'   DrawText(String(JoyY(0)), 5.0, 25.0)
'   If KeyDown(162) And KeyHit(83) Then Print("Value=" + String(g_profile.GetValue()))
' 162 (0xA2) = VK_LCONTROL, 83 (0x53) = VK_S in Windows virtual-key numbering -- a developer
' hotkey, not the "Simon Read" name-check mentioned elsewhere in the game.
'
' `KeyDown`/`MouseDown` are call-target ALIASES (0x005B4721, byte-identical bodies,
' codegen-patterns 3h) -- the mask accepts either; `KeyDown` is written because the argument
' (162) is a key code, not a mouse-button index.
'
' PLAIN `And` IS SHORT-CIRCUIT in this legacy compiler -- verified by reading the compiler's
' own source, not assumed: `tools/blitzmax-legacy-src/_src/compiler/exp.cpp`'s
' `ShortCircExp::_eval` (the class T_AND/T_OR parse into, parser.cpp:870) evaluates the LHS,
' branches past the RHS entirely on a false LHS for `And` (`cg_op = T_AND ? CG_EQ : CG_NE`),
' and only evaluates the RHS when the LHS was true -- exactly the observed bytes (KeyDown's
' result sits in eax; if zero, the code jumps straight past the KeyHit call, reusing that
' same eax as the combined truth value). There is no separate "And Then"/"Or Else" token in
' this legacy tokeniser (`toker.cpp` has no such keyword) -- plain `And`/`Or` already do this.
'
' ============================ GLOBALS ============================
' All Int except g_profile. Names and (where noted) types are corroborated against OTHER
' already-verified files reading the SAME addresses -- not invented fresh:
'   0x00C5D244 g_opt_screen  -- TOptions.LoadOptions.bmx (established); SetUpGraphics.bmx's
'     own header independently names GameMain as a caller with this EXACT call shape:
'     "SetUpGraphics(g_opt_screen, g_opt_window, 1) -- boot".
'   0x00C5D248 g_opt_window  -- ditto.
'   0x00C6EFD4 g_matchclock, 0x00C6EFD8 g_pausedms, 0x00C6F030 g_pauseclock,
'     0x00C6F034 g_frameaccum -- ALL FOUR reused verbatim, same computation shape
'     (`matchclock = MilliSecs()-pausedms`, `frameaccum :+ (matchclock-pauseclock)`,
'     `pauseclock = matchclock`, `While frameaccum >= spd ... Wend`), by
'     TEngine.MatchLoop.bmx (already MATCH, 432/432) -- that function is the match-specific
'     inner loop that takes over frame pacing using these SAME four Globals while a match is
'     active; GameMain is the outer 40 Hz loop that owns them the rest of the time. Two
'     other already-recovered files (TBossMessage.Create.bmx, TCompetition.GetBasedNationId
'     .bmx) name 0x00C6EFD4/0x00C6EFD8 "g_ticks"/"g_starttime" instead -- same addresses, a
'     different name choice (the same tolerated same-address-different-name situation
'     TBossMessage.Create.bmx's own header already flags for g_msgy_away/g_msgy_home). The
'     MatchLoop names are used here as the closer structural match.
'   0x00C6F02C g_replay_div:Int = 25 -- THE fixed logic timestep (docs/game/engine/main-loop
'     .md: 40 ticks/second, never written after this initial value). Same address is already
'     named "g_replay_div" by TPlayer.RecordReplayFrame.bmx (a plain division constant
'     there); reused here for corpus consistency. The `= 25` initialiser is added on THIS
'     declaration (codegen-patterns 21.1/21.3 -- merge_globals prefers an initialiser-bearing
'     declaration over a bare one of the same name regardless of which file is seen first),
'     since every other existing reference declares it bare. Does not affect this file's own
'     byte match (the read is `mov eax,[addr]`, address always masked) -- it matters only for
'     the eventual whole-program assembly.
'   0x00C6EF50 g_engine_int161:Int -- the debug-overlay trigger (main-loop.md's "0xC6EF50").
'     Named "g_engine_int161" in three already-recovered files
'     (TScreen_Competitions.ButtonCompressIds/ButtonInflateIds.bmx,
'     TScreen_Leagues.ComboNation.bmx); TScreen_EditCompetition.UpdateComp.bmx's header notes
'     it is semantically "g_debug". Reused here for consistency. What SETS it to 2 remains
'     open (main-loop.md's own "what we do not know yet" section) -- out of scope for this
'     function, which only reads it.
'   0x00C6F028 g_profile:TProfile -- overwhelmingly established across dozens of already-
'     recovered files (TEngine.EndMatch.bmx, TEngine.MatchLoop.bmx, TCompetition.*, etc).
'     GetValue() is TProfile+0xB8 (vtable_map.tsv), matched independently against
'     src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx's own use of the same
'     slot on the same Global.
'
' ============================ OTHER CALLS ============================
'   0x0058D86D SteamInit()            -- already recovered, src/recovered_module/SteamInit.bmx
'   0x00506A5D SetUpGraphics(i,i,i)i  -- already recovered, src/recovered_module/SetUpGraphics.bmx
'   0x004BC874 StartMusic()           -- already recovered, src/recovered_module/StartMusic.bmx
'   0x004A4860 MilliSecs()            -- _bbMilliSecs (runtime_helpers.tsv)
'   0x004A8550 GCMemAlloced()         -- BlitzMax builtin (arity 0, returns Int); matched via
'     the general relocation mask on a recursive same-callee proof (compare()'s path (b)),
'     not via name -- both sides compile this trivial "return a global Int" builtin to the
'     identical `mov eax,[addr]; ret` shape, so the call masks without needing an entry in
'     runtime_helpers.tsv at all. Independently corroborated by two other already-recovered
'     callers, TEngine.EndMatch.bmx and TEngine.RenderGameEngine.bmx.
'   0x0050720B FormatMoney(i,i)$      -- already recovered, src/recovered_module/FormatMoney.bmx
'   0x005AD656 DrawText               -- _brl_max2d_DrawText
'   0x00595794 JoyX, 0x005957B7 JoyY  -- _pub_freejoy_JoyX/JoyY
'   0x004A79D0 _bbStringFromFloat     -- String(floatExpr)
'   0x005B4721 KeyDown|MouseDown (alias set, codegen-patterns 3h) -- _brl_polledinput
'   0x005B46EE KeyHit                 -- _brl_polledinput_KeyHit
'   0x004A7AC0 _bbStringFromInt, 0x004A7C20 _bbStringConcat, 0x0059CC21 Print
'   0x005B141A Flip                   -- _brl_graphics_Flip
'   0x004A8980 GCCollect()            -- _bbGCCollect
'   0x005B46C8 AppTerminate()         -- _brl_polledinput_AppTerminate
' String literal 0x00C6FC40 = "Value=" (harness.read_string).
'!Global g_opt_screen:Int
'!Global g_opt_window:Int
'!Global g_matchclock:Int
'!Global g_pausedms:Int
'!Global g_pauseclock:Int
'!Global g_frameaccum:Int
'!Global g_replay_div:Int = 25
'!Global g_engine_int161:Int
'!Global g_profile:TProfile
	Function GameMain:Int()
		SteamInit()
		TLocale.SetUp()
		TOptions.SetUp()
		SetUpGraphics(g_opt_screen, g_opt_window, 1)
		StartMusic()
		TScreen.SetUp()
		TEngine.SetUp()
		TScreen_Language.CreateScreen()
		TScreen_Language.SetUpScreen(0)
		g_matchclock = MilliSecs() - g_pausedms
		g_pauseclock = g_matchclock
		Repeat
			g_matchclock = MilliSecs() - g_pausedms
			g_frameaccum :+ (g_matchclock - g_pauseclock)
			g_pauseclock = g_matchclock
			While g_frameaccum >= g_replay_div
				TScreen.Update()
				g_frameaccum :- g_replay_div
			Wend
			TScreen.Render(g_frameaccum / Float(g_replay_div))
			If g_engine_int161 = 2
				DrawText(FormatMoney(GCMemAlloced(), 0), 5.0, 5.0)
				DrawText(String(JoyX(0)), 5.0, 15.0)
				DrawText(String(JoyY(0)), 5.0, 25.0)
				If KeyDown(162) And KeyHit(83)
					Print("Value=" + String(g_profile.GetValue()))
				EndIf
			EndIf
			Flip(1)
			If g_engine_int161 = 2 Then GCCollect()
		Until AppTerminate()
	End Function

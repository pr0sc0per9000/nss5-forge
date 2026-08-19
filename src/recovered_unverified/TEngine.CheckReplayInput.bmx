' TEngine.CheckReplayInput   (KIND=Function -- static, no Self)
' VA 0x004D4A9E   1131 bytes   class-table slot 0xA8   sig ()i
' byte-identical vs NSS5.exe
' Body-only format: statements only, no parameters.
'
' What it does: the per-frame input poll while a replay is on screen (called from
' TEngine.CheckInput's `If g_engine_int13 = 3` branch, class-table slot 0xA8). F2 toggles
' the player-name overlay, F3 saves the replay, F4 toggles the on-screen replay controls,
' then Left/Right (the match steering controls, reused here for scrubbing) rewind/advance
' the replay position -- via the analog stick when no joystick button is bound to
' Left/Right, otherwise via the digital Left/Right buttons -- F9/F10 adjust the replay
' camera zoom, holding any action button narrows the scrub step from 4/3 frames to 1/2/1,
' and finally Pause or the Replay button both end the replay and return to the paused match.
'
' *** GHIDRA CALL-ARGUMENT ELISION, CONFIRMED BY RAW DISASSEMBLY ***
' Every call to FUN_005b46ee (KeyHit) and FUN_005b4721 (KeyDown) in THIS function's Ghidra
' decompilation shows zero arguments -- `iVar2 = FUN_005b46ee();` -- even though both are
' the same one-Int-argument functions TEngine.CheckInput calls correctly a few hundred bytes
' away. scripts/disasm.py against NSS5.exe at 0x004D4A9E proves every one of those calls DOES
' push a real argument (`push 0x71`, `push dword ptr [eax+0x18]`, etc.) immediately before
' `call 0x5b46ee`/`call 0x5b4721` -- Ghidra simply failed to render them for this call site.
' Every argument below was read off that raw disassembly, not off the decompile. The FPU
' comparison directions in the analog-stick block (JoyX/JoyY thresholds) are NOT affected by
' this bug and are taken from the decompile as usual.
'
' ASSUMPTIONS -- module Global NAMES resolved via scripts/explain_global.py (exact-address
' match) and cross-checked against extracted/global_alias_unified.tsv's canonical picks
' where an address had several names on record:
'   0x00C5D1A8 g_options_int01:Int        joystick device selector (0/1/2); same test
'     (`= 2`) TEngine.CheckInput/TScreen.GetInput already use at this address.
'   0x00C5D1B4/BC/C4/CC g_options_arr02/03/04/05:Int[]  the Up/Down/Left/Right movement
'     controls, each [0]=key [1]=joy button -- CERTAIN/STRONG at TScreen.GetInput and
'     TScreen_Controls.RefreshButtons, which use exactly this "arrNN" family for this
'     address run. Reused here for replay scrubbing: Left = rewind, Right = advance.
'   0x00C5D1D4/DC/E4 g_options_arr06/07/08:Int[]  the three action-button controls, same
'     addresses and same "arrNN" family TEngine.CheckInput (recovered_pending) already
'     established for this exact address run.
'   0x00C5D1F4/FC g_options_arr10/11:Int[]  the Pause and Replay controls -- CERTAIN at
'     TPanel_Controls.RenderPauseReplay, and the exact pair TEngine.CheckInput already
'     names g_options_arr10 (Pause) / g_options_arr11 (Replay) for these addresses.
'   0x00C6EFEC g_engine_int164:Int        "joystick enabled" gate, identical `<> 0` test
'     TEngine.CheckInput/TScreen.GetInput/TOptions.GetNewControl already use here.
'   0x00C5D240 g_options_int05:Int        CERTAIN (TPanel_Controls.RenderReplay,
'     TPlayer.RenderReplay); read directly from NSS5.exe's data section = 1 (not 0), so the
'     initial value is captured in the pragma below.
'   0x00C5B2D0 g_engine_showcontrols:Int  sole candidate (TEngine.RenderReplayGUI); also
'     reads 1 in the data section, captured below.
'   0x00C5B2CC g_engine_int53:Int         two names on record (g_engine_int53 from
'     TPanel_Controls.RenderReplay, g_replayspeedup from TEngine.MatchLoop); the unified
'     alias table's canonical pick for this address is g_engine_int53, used here.
'   0x00C5B2C8/C4/C0 g_replaycur/g_replaymax/g_replaymin:Int  the scrub position and its
'     clamp bounds -- the exact trio TEngine.StartReplay already declares together at these
'     three addresses (`g_replayCur = g_replayMin`), and the unified alias table's canonical
'     picks for 0x00C5B2C8/C4 agree (g_engine_int51/g_replaymaxframe -> g_replaycur;
'     g_engine_int52 -> g_replaymax).
'   0x00C5B1D4 g_engine_zoom:Float        the LIVE camera zoom. NOTE: extracted/
'     global_address_map.tsv resolves the name "g_engine_float01" to 0x00C5D238, a DIFFERENT
'     address that this function never touches -- TEngine.EndReplay's own header comment
'     claiming g_engine_float01 lives at 0x00C5B1D4 is the prose-vs-solver disagreement the
'     tooling explicitly warns is the weaker evidence. The solver-verified, alias-table
'     canonical name for 0x00C5B1D4 is g_engine_zoom (3 bodies: TEngine.SetUpReplay,
'     TPlayer.GetMouseDirection, TEngine.SetUpMatch), used here; initial data value read
'     directly = 2.0.
'   0x00C5D23C g_enginefloat:Float        sole candidate (TEngine.StartReplay, which reads
'     it back into g_engine_zoom when a replay starts: `g_engineFloat = g_optionsFloat`) --
'     the "saved/persisted replay zoom", which THIS function writes every time the user
'     changes zoom during playback. Distinct from 0x00C5D238 (4 bytes earlier, a separate
'     saved-zoom slot this function never touches). Initial data value read directly = 2.0.
'   0x00C74278 g_engine_int172:Int        NOT in global_address_map.tsv (no recovered body
'     has touched this address before this one) but present in extracted/globals_final.tsv
'     as a "usage" heuristic pick, reused verbatim since it is otherwise unclaimed. A
'     joystick Y-axis "centred" latch: set when |JoyY| drops below the deadzone, cleared if
'     JoyY leaves a (looser) band while set. Initial data value read directly = 0.
' Class-table slot calls, TEngine's own, written unqualified (guide 3d/8), resolved via
' extracted/globals_classtable_slots.tsv:
'   0x00C5BAEC TEngine+0xBC SaveReplay()i       0x00C5BADC TEngine+0xAC UpdateOffsetReplay(f)i
'   0x00C5BAD0 TEngine+0xA0 EndReplay()i
' Module Functions (all confirmed by src/recovered/TOptions.WaitForJoyRelease.bmx /
'   TPlayer.DoKeeperDiveAI.bmx, which use the identical signatures): FUN_005b46ee = KeyHit(i)i,
'   FUN_005b4721 = KeyDown(i)i, FUN_00595705 = JoyDown(i,i)i, FUN_00595746 = JoyHit(i,i)i,
'   FUN_00595794 = JoyX(i)f, FUN_005957b7 = JoyY(i)f, FUN_004a7fe0 = Abs(f)f (TPlayer.
'   DoCelebrations), FUN_00505f90 = ClampFloat(*f,f,f) (TWeather.Update), FUN_00505f6d =
'   ClampInt(*i,i,i) (TScreen_Options.ComboRes).
' Literal Float constants read directly out of NSS5.exe with harness.read_va (never written
'   by any recovered body, i.e. a true read-only constant-pool entry, same pattern
'   TEngine.CheckInput's header documents for 0x00C740B4/B8): 0x00C7427C=-0.5, 0x00C74280=0.5,
'   0x00C74284=-0.5, 0x00C74288=0.5, 0x00C7428C=0.5, 0x00C74290=0.25, 0x00C74294=0.25.
' Key literals: 113/114/115 = F2/F3/F4 (VK codes, matches TEngine.CheckInput's own
'   120/121=F9/F10 and 116=F5 scheme, one higher per key).
'
' SHAPE NOTES
'   * BYTE-CONFIRMED (bytematch, first-diff walk against status/score): four calls --
'     KeyHit(arr02[0]), KeyHit(arr03[0]) early, and JoyHit(arr02[1],joynum),
'     JoyHit(arr03[1],joynum) inside the digital branch -- compile to a genuine `cmp eax,0;
'     je <next instruction>` with NOTHING on either side: a real branch to a no-op join, not
'     a bare statement (a bare discarded-result call compiles to just call+`add esp,N`, no
'     cmp/je at all -- confirmed by direct disassembly, an earlier draft here had them bare
'     and was 4x5=20 bytes short). Reproduced literally as `If KeyHit(...)` / `EndIf` on the
'     next line (empty body), matching the identical empty-If idiom already confirmed
'     byte-exact in src/recovered/TFixture.GetStringArrayForTeamId.bmx ("the dead tail
'     statement is a real `If ... EndIf` with an EMPTY body"). Up/Down are read and thrown
'     away; only Left/Right (arr04/arr05) drive the scrub.
'   * BYTE-CONFIRMED: `Local joynum:Int = g_options_int01 = 2` (a branchless setcc) does NOT
'     match -- the original is a real branch, byte-for-byte the same idiom as
'     src/recovered/TScreen.GetInput.bmx and TEngine.CheckInput's own corrected header note
'     (status/score/TEngine.CheckInput.txt): `mov reg,0 / cmp [g_options_int01],2 / jne +N /
'     mov reg,1`. Written the same way here: `Local joynum:Int = 0` then a separate
'     `If g_options_int01 = 2 Then joynum = 1`.
'   * `Local lft:Int = 0` / `Local rgt:Int = 0`, then `If KeyDown(...) Then lft = 1` /
'     `If JoyX(joynum) < -0.5 Then lft = 1` etc. -- the OR-into-flag idiom matches
'     src/recovered/TPlayer.DoKeeperDiveAI.bmx's lft/rgt/up/down locals exactly (same
'     KeyDown/JoyDown/JoyX-threshold-sets-flag shape, byte-confirmed there).
'   * The analog-stick block only runs `If g_options_arr04[1] = -1` (no joystick button
'     bound to Left) -- otherwise the digital JoyDown/JoyHit block runs instead. Matches
'     TScreen.GetInput's identical `arr04[1] = -1` gate for the same address, reused for
'     Left specifically (the block tests only arr04, not all four arrNN).
'   * The g_engine_int172 latch: only re-armed (=1) when |JoyY(joynum)| drops under 0.5;
'     only disarmed (=0) from inside `If g_engine_int172 <> 0`, each of the two disarm tests
'     independent (not Elseif). Matches the decompile's flat sequential shape exactly.
'   * Holding any of the three action buttons (keyboard OR, if none, joystick OR) changes
'     the scrub step from -4/+3 to -1(-2 if also Left)/+1(+1 if also Right) and sets
'     g_engine_int53 = 1; the position is always then ClampInt'd between g_replaymin and
'     g_replaymax. Matches the decompile's two sequential `sub ...,1` writes (not an
'     algebraic `iVar1 + -2`) exactly.
'   * Zoom step is 0.25 (not CheckInput's F9/F10 step, which is also 0.25 but at a different
'     literal address), clamp bounds 0.75..1.75 (not CheckInput's 0.75..2.0), and
'     UpdateOffsetReplay(1.0) is TEngine's own REPLAY-specific offset-update slot (0xAC),
'     distinct from CheckInput's UpdateOffset (0x58).
'   * Final Pause/Replay test matches TEngine.CheckInput's `KeyHit(x) Or (g_engine_int164
'     And JoyHit(y,joynum))` idiom; both branches call EndReplay() and Return 0 immediately,
'     matching the two identical epilogue jumps in the disassembly.
'   * BYTE-CONFIRMED: the three `g_engine_int164 And (...)` guards (the action-button OR-chain
'     and both Pause/Replay tests) must NOT spell the joystick gate as `g_engine_int164 <> 0`
'     -- bcc's ShortCircExp codegen (tools/blitzmax-legacy-src/_src/compiler/exp.cpp) feeds
'     the left operand of `And` through a bare `mov reg,<expr>` with no lookahead fusion, so
'     an explicit `<>0` (a Scc node) forces a throwaway SETNE/MOVZX the original never emits;
'     a bare Int (already the compiler's own truthy value, no comparison node at all) compiles
'     straight to `mov reg,[g_engine_int164]`. The *standalone* `If g_engine_int164 <> 0`
'     gate a few lines above and `If g_engine_int172 <> 0` are fine as `<>0` -- fed directly
'     to IfStm's own `bcc`, which DOES fuse with the comparison, matching the original's lean
'     2-3 instruction `cmp mem,0 / je` there. Same SETNE-materialization quirk independently
'     documented in src/recovered/TFixture.GetStringArrayForTeamId.bmx's header note #8.

'!Global g_options_int01:Int
'!Global g_options_arr02:Int[]
'!Global g_options_arr03:Int[]
'!Global g_options_arr04:Int[]
'!Global g_options_arr05:Int[]
'!Global g_options_arr06:Int[]
'!Global g_options_arr07:Int[]
'!Global g_options_arr08:Int[]
'!Global g_options_arr10:Int[]
'!Global g_options_arr11:Int[]
'!Global g_engine_int164:Int
'!Global g_options_int05:Int = 1
'!Global g_engine_showcontrols:Int = 1
'!Global g_engine_int53:Int
'!Global g_replaycur:Int
'!Global g_replaymax:Int
'!Global g_replaymin:Int
'!Global g_engine_zoom:Float = 2.0
'!Global g_enginefloat:Float = 2.0
'!Global g_engine_int172:Int
If KeyHit(113)
	g_options_int05 = (g_options_int05 = 0)
EndIf
If KeyHit(114)
	SaveReplay()
EndIf
If KeyHit(115)
	g_engine_showcontrols = (g_engine_showcontrols = 0)
EndIf
Local joynum:Int = 0
If g_options_int01 = 2 Then joynum = 1
g_engine_int53 = 0
Local lft:Int = 0
Local rgt:Int = 0
If KeyHit(g_options_arr02[0])
EndIf
If KeyHit(g_options_arr03[0])
EndIf
If KeyDown(g_options_arr04[0]) Then lft = 1
If KeyDown(g_options_arr05[0]) Then rgt = 1
If g_engine_int164 <> 0
	If g_options_arr04[1] = -1
		If JoyX(joynum) < -0.5 Then lft = 1
		If JoyX(joynum) > 0.5 Then rgt = 1
		If g_engine_int172 <> 0
			If JoyY(joynum) < -0.5 Then g_engine_int172 = 0
			If JoyY(joynum) > 0.5 Then g_engine_int172 = 0
		EndIf
		If Abs(JoyY(joynum)) < 0.5 Then g_engine_int172 = 1
	Else
		If JoyHit(g_options_arr02[1], joynum)
		EndIf
		If JoyHit(g_options_arr03[1], joynum)
		EndIf
		If JoyDown(g_options_arr04[1], joynum) Then lft = 1
		If JoyDown(g_options_arr05[1], joynum) Then rgt = 1
	EndIf
EndIf
If KeyHit(120)
	g_engine_zoom :- 0.25
	ClampFloat(Varptr g_engine_zoom, 0.75, 1.75)
	UpdateOffsetReplay(1.0)
	g_enginefloat = g_engine_zoom
EndIf
If KeyHit(121)
	g_engine_zoom :+ 0.25
	ClampFloat(Varptr g_engine_zoom, 0.75, 1.75)
	UpdateOffsetReplay(1.0)
	g_enginefloat = g_engine_zoom
EndIf
If KeyDown(g_options_arr06[0]) Or KeyDown(g_options_arr07[0]) Or KeyDown(g_options_arr08[0]) Or (g_engine_int164 And (JoyDown(g_options_arr06[1], joynum) Or JoyDown(g_options_arr07[1], joynum) Or JoyDown(g_options_arr08[1], joynum)))
	g_replaycur :- 1
	g_engine_int53 = 1
	If lft Then g_replaycur :- 1
	If rgt Then g_replaycur :+ 1
Else
	If lft Then g_replaycur :- 4
	If rgt Then g_replaycur :+ 3
EndIf
ClampInt(Varptr g_replaycur, g_replaymin, g_replaymax)
If KeyHit(g_options_arr10[0]) Or (g_engine_int164 And JoyHit(g_options_arr10[1], joynum))
	EndReplay()
	Return 0
ElseIf KeyHit(g_options_arr11[0]) Or (g_engine_int164 And JoyHit(g_options_arr11[1], joynum))
	EndReplay()
	Return 0
EndIf
Return 0

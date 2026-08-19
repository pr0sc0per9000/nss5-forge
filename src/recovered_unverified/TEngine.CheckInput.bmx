' TEngine.CheckInput   (KIND=Function -- static, no Self)
' VA 0x004D28E4   1565 bytes   class-table slot 0x6C   sig ()i
' byte-identical vs NSS5.exe
' Body-only format: statements only, no parameters.
'
' What it does: the per-frame match-engine input poll. Checks the Pause control first
' (Return immediately after PauseEngine() if hit); otherwise checks the debug zoom keys
' (F9/F10), the Replay control, a debug Pause+SkipTime hotkey (F5), two hidden developer
' cheats gated on the profile name being "Simon Read" or "Si Read" (F = force a corner,
' C = force a free kick), then either forwards to CheckReplayInput() (replay mode) or
' handles on-screen-message dismissal and the SkipTime "waiting" state machine, finishing
' with a further block of raw debug hotkeys (Tab/T/R/P/M/W) gated behind a second debug
' level.
'
' ASSUMPTIONS -- module Global NAMES resolved via scripts/explain_global.py (exact-address
' match, strongest tier/most-attested candidate at each address); the DECLARED TYPES are
' load-bearing.
'   0x00C5D1A8 g_options_int01:Int        joystick device selector (0/1/2); TScreen.GetInput
'     computes the identical `= 2` test for the same purpose.
'   0x00C5D1F4 g_options_arr10:Int[]      the Pause control: [0]=key [1]=joy button. Confirmed
'     by this function's own shape -- hit -> PauseEngine() and nothing else runs this frame.
'   0x00C5D1FC g_options_arr11:Int[]      the Replay control (TOptions.NewButtonReplay writes
'     g_options_controls[g_options_controlidx] at this same address); hit -> StartReplay().
'   0x00C5D1D4/DC/E4 g_options_arr06/07/08:Int[]  the three action-button controls, same
'     addresses TScreen.GetInput already established.
'   0x00C6EFEC g_engine_int164:Int        "joystick enabled" gate -- identical `<> 0` test to
'     TScreen.GetInput/TOptions.GetNewControl at this address.
'   0x00C5B1D4 g_engine_float01:Float     the camera zoom factor. Raw data-section
'     value 2.0, matches TEngine.Render/TEngine.EndReplay's already-established Global at this
'     exact address (both byte-identical, live).
'   0x00C5D238 g_engine_float09:Float     raw data-section value 1.0; TEngine.EndReplay reads
'     it into g_engine_float01 at startup (`g_engine_float01 = g_engine_float09`), and this
'     function performs the reverse assignment after a manual zoom edit.
'   0x00C6EF50 g_engine_int161:Int        debug-cheat level: nonzero unlocks the two
'     Simon-Read set-piece cheats; exactly 2 additionally unlocks the Tab/T/R/P/M/W block.
'   0x00C6F028 g_profile:TProfile         the active save profile (142-body consensus; the
'     TEngine siblings TEngine.DoYourSubstitutionOff/On, TEngine.SkipMatchTime and
'     TEngine.UpdateSetPieceReady all already use this name for this address). +0x14 = .name.
'   0x00C5B1CC g_engine_int13:Int         the engine/match mode; TCameraMan.Update's
'     byte-identical body confirms `= 3` at this address means "replay in progress".
'   0x00C5B1FC g_player_int01:Int         hand-verified (globals_final.tsv) at this address;
'     also the stronger of two CERTAIN solver clusters (42 bodies/21 forced vs 21/8).
'   0x00C5B200 g_player_int02:Int         sole candidate (TPlayer.UpdateJoy already uses it).
'   0x00C5B204 g_player_int03:Int         sole candidate; sequential with g_player_int01/02
'     (0x1FC/0x200/0x204), a coherent block of TPlayer status ints.
'   0x00C5D1AC g_player_int14:Int         CERTAIN, 12 bodies.
'   0x00C5B210 g_engine_clock:Int         the match clock; TEngine.DrawScores renders it
'     directly (`g_lbl_time.SetText(String(g_engine_clock),...)`) at this exact address --
'     stronger semantic fit than the solver's positionally-forced alternative.
'   0x00C5D62C g_pitchtype:Int  0x00C5D630 g_pitchcond:Int   sole candidates each.
'   0x00C600C4/D8/EC/F0 g_weather_int01/02/05/06:Int   all four already used verbatim by the
'     live, byte-identical TWeather.Update.bmx at these same addresses.
' Class-table slot calls, TEngine's own written unqualified (guide 3d/8), resolved via
' extracted/globals_classtable_slots.tsv:
'   0x00C5BB30 TEngine+0x100 PauseEngine()         0x00C5BACC TEngine+0x9C StartReplay()
'   0x00C5BAD8 TEngine+0xA8 CheckReplayInput()      0x00C5BB14 TEngine+0xE4 SkipTime()
'   0x00C5BAA0 TEngine+0x70 SetUpSetPiece(i,i,i,i)  0x00C5BA88 TEngine+0x58 UpdateOffset(f)
' Other Types, qualified: 0x00C5AEDC TBall+0x44 GetActiveBall():TBall (same slot already
'   established by TCameraMan.Update/TEngine.DoYourSubstitutionOff, always 0 args -- the
'   apparent extra argument on its second call here is a Ghidra push/call merge, see below);
'   0x00C6B268 TScreenMessage+0x34 Count()i; 0x00C6B280 TScreenMessage+0x4C RemoveFirst()i;
'   0x00C6779C TScreen_MatchPaused+0x48 ButtonSkipTime()i; 0x00C5BFEC TFormation+0x30 SetUp()i.
' Module Functions: FUN_005b46ee=KeyHit, FUN_005b4721=KeyDown, FUN_00595746=JoyHit (all
'   confirmed by src/recovered/TOptions.WaitForJoyRelease.bmx); FUN_0059f089=Rand(a,b)
'   (TEngine.SkipMatchTime); FUN_005b9690=Int() (TBall.Render); FUN_00505f90=ClampFloat
'   (TWeather.Update); FUN_004a6a30=String EqEq (158 call sites, e.g.
'   TCompetition.SelectByTLA); FUN_004a4620=End (TScreen_MainMenu.ButtonQuit's entire body).
' Literals read out of the exe with harness.read_string (validated first against the two
'   already-known literals at 0x00C7447C "Substitution" / 0x00C5D680 "FFFFFF"):
'   0x00C740BC "Simon Read", 0x00C740DC "Si Read" -- the game designer's own name, a hidden
'   developer cheat gate. 0x00C740B4/B8 are bare Float literals (0.25 each, read directly),
'   not Globals -- each occurs nowhere else in the corpus (read-only, no other writer).
' Fields (extracted/object_model.json): TProfile.name offset 0x14 ($); TBall.x offset 0x18,
'   TBall.y offset 0x1C (index 6/7 on an Int-scaled pointer, confirmed via
'   TCameraMan.Update's `puVar3[6]`/`puVar3[7]` reading the same GetActiveBall() result).
'
' SHAPE NOTES
'   * FROM THE BYTE ORACLE (status/score/TEngine.CheckInput.txt): the joynum
'     setup is NOT a branchless setcc. The original's first bytes are
'     `mov ebx,0 / cmp [g_options_int01],2 / jne +5 / mov ebx,1` -- a real branch, byte-for-byte
'     the same idiom as the byte-perfect siblings src/recovered/TScreen.GetInput.bmx
'     (`joynum = 0 : If g_options_int01 = 2 Then joynum = 1`) and
'     src/recovered/TOptions.WaitForJoyRelease.bmx (`port = 0 : If g_joyport = 2 Then port = 1`).
'     Written the same way here: `Local joynum:Int = 0` then a separate `If ... Then joynum = 1`.
'     Reused as JoyHit's port argument for every joystick check below.
'   * DISASM-VERIFIED AGAINST THE BYTE ORACLE: "KeyHit(x[0]) Or
'     (g_engine_int164<>0 And JoyHit(x[1], joynum))" written as ONE compound boolean
'     expression is WRONG -- it compiles with an extra materialised setne/movzx for the
'     `<>0` term (confirmed both by direct capstone comparison against the original bytes,
'     which show a bare `cmp eax,0 / je` with no setcc at all, and by the established
'     src/recovered/TCompetition.DoPromotionPlaces.bmx finding that a relational term
'     EMBEDDED as an operand of `Or` always gets materialised, while the same term as the
'     SOLE condition of a plain `If` does not). The original instead assigns the KeyHit
'     result to a real Local, then tests the joystick gate as an entirely separate, un-Or'd
'     `If` that conditionally overwrites it -- i.e. the decompiled
'     `if ((iVar1==0) && (iVar1=0, DAT_00c6efec!=0)) iVar1=JoyHit(...)` is genuinely TWO
'     nested `If`s over one Local, not one collapsed expression. Reproduced as:
'         hit = KeyHit(x[0])
'         If hit = 0
'             If g_engine_int164 <> 0 Then hit = JoyHit(x[1], joynum)
'         EndIf
'     for every one of the six sites this shape occurs (Pause control, Replay control, the
'     two message-dismiss gates, the two SkipTime-request gates). `hit` is one Local,
'     declared once and reused by plain assignment throughout (mirrors how `joynum` is
'     reused, and how Ghidra keeps calling every one of these "iVar1" -- one shared slot,
'     never re-declared). The joystick-ONLY re-check gates (message-dismiss/SkipTime-request
'     arr07/arr08) use the analogous un-Or'd nested form:
'         hit = 0
'         If g_engine_int164 <> 0
'             hit = JoyHit(arr07[1], joynum)
'             If hit = 0 Then hit = JoyHit(arr08[1], joynum)
'         EndIf
'     The key-only fallback pairs (`KeyHit(arr07[0]) Or KeyHit(arr08[0])`) are NOT touched by
'     this fix -- both operands are plain call results already sitting in eax, so `Or`
'     between two calls needs no synthesised boolean and compiles branch-only either way.
'   * The two Simon-Read cheat blocks decompile as `iVar1=0; if(g_engine_int161!=0)
'     iVar1=KeyHit(k); bVar4=false; if(iVar1!=0){bVar4=(name==A); if(!bVar4) bVar4=(name==B);}
'     if(bVar4) SetUpSetPiece(...)` -- an un-Or'd nested `If g_engine_int161<>0 : If KeyHit(k)
'     : If name=A Or name=B : SetUpSetPiece(...)` (matching the hit-reuse idiom above, not a
'     single flat `And`/`Or` chain: a flat chain over these same terms was tried and rejected
'     by the byte oracle -- it materialises an extra setne/movzx on the `<>0` term, same
'     defect as the ruled-out form above). OPEN ISSUE: the oracle still wants `g_engine_int161
'     <> 0` (and, at four other sites above, `g_engine_int164 <> 0`) compiled as `mov eax,[g] /
'     cmp eax,0` (8 bytes) where every source form tried here compiles it as the shorter
'     `cmp dword[g],0` (7 bytes) instead -- confirmed on isolated standalone probes too, so it
'     is not a phrasing issue in this file. Net effect: the oracle's length delta is +18 bytes,
'     concentrated at these five sites plus the near/far jump-size shifts they cause downstream.
'   * PTR_FUN_00c5aedc (TBall.GetActiveBall) is called TWICE with 0 args, once per field --
'     Ghidra shows the second call carrying an apparent argument, but that value is the
'     PRECEDING statement's result being staged for the enclosing SetUpSetPiece() call, not a
'     real parameter (GetActiveBall takes none, confirmed by its own recovered signature).
'     Reproduced as two separate inline `TBall.GetActiveBall()` calls, matching
'     TEngine.SkipMatchTime's own "no named Locals" set-piece argument style.
'   * SetUpSetPiece's argument order is recovered from the evaluation order (rightmost
'     argument computed first, matching TEngine.SkipMatchTime's identical merge pattern):
'     `SetUpSetPiece(4, Rand(2,1), Int(TBall.GetActiveBall().x), Int(TBall.GetActiveBall().y))`.
'   * The message-dismissal block and the SkipTime-request block share one shape: the
'     un-Or'd `hit`-staged arr06 test described above, then -- only when g_player_int14=1 --
'     a SEPARATE `KeyHit(arr07[0]) Or KeyHit(arr08[0])` key-only test, THEN a separate
'     un-Or'd `hit`-staged joystick-only test over arr07/arr08. The two device kinds are NOT
'     interleaved per-control here, unlike the single-control idiom used everywhere else in
'     this function.
'   * `Select g_player_int01` (Case 0/2/5/11/12, no Default) matches the flat repeated
'     `DAT_00c5b1fc == literal` compares against one loaded subject.
'   * `If g_pitchtype > 2 Then g_pitchtype = 0` / `If g_pitchcond > 5 Then g_pitchcond = 0`
'     are unconditional post-increment wrap checks -- the increment itself only happens
'     inside the owning `If KeyHit(...)`, matching the comma-expression
'     `(DAT_x = DAT_x + 1, N < DAT_x)` shape.

'!Global g_options_int01:Int
'!Global g_options_arr10:Int[]
'!Global g_options_arr11:Int[]
'!Global g_options_arr06:Int[]
'!Global g_options_arr07:Int[]
'!Global g_options_arr08:Int[]
'!Global g_engine_int164:Int
'!Global g_engine_float01:Float = 2.0
'!Global g_engine_float09:Float = 1.0
'!Global g_engine_int161:Int
'!Global g_profile:TProfile
'!Global g_engine_int13:Int
'!Global g_player_int01:Int
'!Global g_player_int02:Int
'!Global g_player_int03:Int
'!Global g_player_int14:Int
'!Global g_engine_clock:Int
'!Global g_pitchtype:Int
'!Global g_pitchcond:Int
'!Global g_weather_int01:Int
'!Global g_weather_int02:Int
'!Global g_weather_int05:Int
'!Global g_weather_int06:Int
Local joynum:Int = 0
If g_options_int01 = 2 Then joynum = 1
Local hit:Int = KeyHit(g_options_arr10[0])
If hit = 0
	hit = g_engine_int164
	If hit <> 0 Then hit = JoyHit(g_options_arr10[1], joynum)
EndIf
If hit <> 0
	PauseEngine()
	Return 0
EndIf
If KeyHit(120)
	g_engine_float01 :- 0.25
	ClampFloat(Varptr g_engine_float01, 0.75, 2.0)
	UpdateOffset(1.0)
	g_engine_float09 = g_engine_float01
EndIf
If KeyHit(121)
	g_engine_float01 :+ 0.25
	ClampFloat(Varptr g_engine_float01, 0.75, 2.0)
	UpdateOffset(1.0)
	g_engine_float09 = g_engine_float01
EndIf
hit = KeyHit(g_options_arr11[0])
If hit = 0
	hit = g_engine_int164
	If hit <> 0 Then hit = JoyHit(g_options_arr11[1], joynum)
EndIf
If hit <> 0
	StartReplay()
EndIf
If KeyHit(116)
	PauseEngine()
	TScreen_MatchPaused.ButtonSkipTime()
EndIf
hit = g_engine_int161
If hit <> 0 Then hit = KeyHit(70)
If hit And (g_profile.name = "Simon Read" Or g_profile.name = "Si Read")
	SetUpSetPiece(4, Rand(2,1), Int(TBall.GetActiveBall().x), Int(TBall.GetActiveBall().y))
EndIf
hit = g_engine_int161
If hit <> 0 Then hit = KeyHit(67)
If hit And (g_profile.name = "Simon Read" Or g_profile.name = "Si Read")
	SetUpSetPiece(5, Rand(2,1), Int(TBall.GetActiveBall().x), Int(TBall.GetActiveBall().y))
EndIf
If g_engine_int13 = 3
	CheckReplayInput()
	Return 0
Else
	g_player_int02 = 0
	If TScreenMessage.Count() > 0
		hit = KeyHit(g_options_arr06[0])
		If hit = 0
			hit = g_engine_int164
			If hit <> 0 Then hit = JoyHit(g_options_arr06[1], joynum)
		EndIf
		If hit <> 0
			TScreenMessage.RemoveFirst()
			Return 0
		EndIf
		If g_player_int14 = 1
			If KeyHit(g_options_arr07[0]) Or KeyHit(g_options_arr08[0])
				TScreenMessage.RemoveFirst()
				Return 0
			EndIf
			hit = g_engine_int164
			If hit <> 0
				hit = JoyHit(g_options_arr07[1], joynum)
				If hit = 0 Then hit = JoyHit(g_options_arr08[1], joynum)
			EndIf
			If hit <> 0
				TScreenMessage.RemoveFirst()
				Return 0
			EndIf
		EndIf
	EndIf
	Select g_player_int01
		Case 0
			g_player_int02 = 1
		Case 2
			If g_player_int03 = 0 Then g_player_int02 = 1
		Case 5
			If g_player_int03 = 0
				SkipTime()
				Return 0
			EndIf
		Case 11
			g_player_int02 = 1
		Case 12
			g_player_int02 = 1
	End Select
	If g_player_int02 <> 0
		hit = KeyHit(g_options_arr06[0])
		If hit = 0
			hit = g_engine_int164
			If hit <> 0 Then hit = JoyHit(g_options_arr06[1], joynum)
		EndIf
		If hit <> 0
			SkipTime()
			Return 0
		EndIf
		If g_player_int14 = 1
			If KeyHit(g_options_arr07[0]) Or KeyHit(g_options_arr08[0])
				SkipTime()
				Return 0
			EndIf
			hit = g_engine_int164
			If hit <> 0
				hit = JoyHit(g_options_arr07[1], joynum)
				If hit = 0 Then hit = JoyHit(g_options_arr08[1], joynum)
			EndIf
			If hit <> 0
				SkipTime()
				Return 0
			EndIf
		EndIf
	EndIf
	If g_engine_int161 = 2
		If KeyHit(9) Then End
		If KeyHit(84) Then g_engine_clock :+ 5
		If KeyHit(82) Then TFormation.SetUp()
		If KeyHit(80)
			g_pitchtype :+ 1
			If g_pitchtype > 2 Then g_pitchtype = 0
		EndIf
		If KeyHit(77)
			g_pitchcond :+ 1
			If g_pitchcond > 5 Then g_pitchcond = 0
		EndIf
		If KeyHit(87)
			If KeyDown(162) <> 0
				g_weather_int01 = 1
			Else
				g_weather_int01 = 0
			EndIf
			Select g_weather_int02
				Case 1
					g_weather_int05 = 0
					g_weather_int06 = g_engine_clock
				Case 0
					g_weather_int05 = g_engine_clock
					g_weather_int06 = 120
			End Select
		EndIf
	EndIf
EndIf
Return 0

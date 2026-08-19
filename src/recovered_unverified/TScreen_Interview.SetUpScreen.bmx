' TScreen_Interview.SetUpScreen
' VA 0x0057B109   1335 bytes   KIND=Function (static, no implicit Self), SIG=()i, class-table slot 0x34
' byte-identical vs NSS5.exe
' Reconstructed from extracted/decomp/TScreen_Interview.SetUpScreen@0057b109.c cross-checked
' against a full manual disassembly (scripts/harness.disasm_original) to resolve Ghidra's
' merged call-argument lists.
' Body-only format: statements only, no Function/End Function wrapper (matches
' TScreen_Interview.ButtonAddText.bmx / TScreen_Interview.Success.bmx in src/recovered/).
'
' The interviewskill difficulty cascade compiles as `If skill>8 Then <int03=15 body> Else
' <If skill>5 Then <int03=12 body> Else <250 body>>`. Byte evidence: cmp reg,8/jle, not
' cmp reg,9/jl; cmp reg,5/jle, not cmp reg,6/jl (codegen-patterns 10.1, "match the setcc/
' immediate, not the meaning"); and the int03=15 block sits as the fallthrough immediately
' after the outer test, i.e. it is textually the Then-arm.
'
' The per-button Show/Hide test (buttons 4..15) is `If q <= g_screen_interview_int03 Then
' Show Else Hide`. Byte evidence: `cmp [q],int03; jg` (operand order q-then-int03, SIGNED
' greater), with the jump target Hide and the fallthrough Show.
'
' `n` is a bare `Local n:Int` declaration (bcc zero-stores it) followed by a separate
' assignment statement, not a combined `Local n:Int = expr`: the original stores 0 to
' [ebp-4] immediately before overwriting that slot with the computed value, which only a
' declaration-then-assignment split produces (codegen-patterns 16.3).
'
' The inner-loop collision test is one inline expression with no named Local for the
' downcast result: `If TButton(g_iv_screen.GetGadgetByName("btn_" + String(j))).txt.
' Compare(b.txt) = 0 Then ok = 0`. Evaluating it pushes the simple argument (b.txt) before
' evaluating the more complex receiver chain (the j-th button's GetGadgetByName/downcast),
' matching codegen-patterns 16.2's "evaluates a nested first-argument call LAST" rule; a
' separate `Local b2 = ...` statement pushes both operands back-to-back right before the
' call instead, which does not match.
'
' WHAT IT DOES: builds the interview mini-game screen. Saves the current screen's name so
' ButtonOk can return to it, switches to "interview", pops a "Interview!" toast, derives a
' difficulty (3..5 required answers, 9/12/15 total buttons) from the player's interviewskill
' stat, resizes/repositions the title panel for that difficulty, resets the sentence label
' and running-answer string, gives buttons 1-3 unique "CLICHE_" texts, gives buttons 4-15
' unique CLICHE_ texts too (retrying on collision) and shows/hides them by difficulty, fills
' the answer-order array with unique Rand(1,int03) values (occasionally negating one while a
' "bonus" budget lasts), then hides the OK button and calls EnableAllButtons()/
' DisableAllButtons() to reset button state.
'
' ASSUMPTIONS / GLOBALS (address is fact; name chosen per scripts/explain_global.py, with
' three deviations from the raw address-map tier ranking, argued below):
'   0x00C61700 g_curscreen:TScreen        -- CERTAIN-tier alt g_activescreen exists at the
'     same address (both are unanimous within their own citing bodies -- a genuine unresolved
'     synonym pair). g_curscreen has far more corpus support (16 bodies/9 forced vs 5/4) and
'     TScreen.CreateScreen/.Render/.DoMessage all use it for "the screen currently being
'     drawn", which is what field+8 (TScreen.name, confirmed via object_model.json) is read
'     from here.
'   0x00C6CDE8 g_interview_ret:String     -- confirmed by src/recovered/TScreen_Interview.
'     ButtonOk.bmx, which reads this same Global to call TScreen.SetActive(g_interview_ret,"").
'   0x00C61C88 TScreen+0x5C SetActive($,$):TScreen (static, direct call through a function
'     pointer, per TScreen_Abilities.SetUpScreen.bmx).
'   0x00C91A04 "interview", 0x00C5D284 "" (bcc-pooled empty-string literal).
'   0x00C6B264 TScreenMessage+0x30 Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i (static, direct
'     call) -- signature and argument order confirmed against src/recovered/
'     TScreenMessage.Create.bmx itself. FUN_004C5549(&"Interview!",...) is GHIDRA MERGING
'     GetText's own one argument with five arguments already pushed and waiting for this
'     Create call (duration=1500, font, image=Null, alpha=1.0, colour) -- GetText's own
'     "add esp,4" cleanup only pops its one arg, confirmed by manual disassembly.
'   0x00C5B1C8 g_font2:TBitmapFont       -- address-map STRONG/forced-in-1 (TEngine.
'     DrawMyText). Sibling TScreen_Interview.Fail.bmx calls the same slot "g_engine_font",
'     but that name is globally AMBIGUOUS in the address map (4 bodies, no forcing
'     alignment), so g_font2 is the better-evidenced existing name for this exact address.
'   0x00C6EFE4 g_engine_gfxw:Int, 0x00C6EFE8 g_engine_gfxh:Int -- the (screen width, screen
'     height) pair used for Create's x=w/2, y=h/2, exactly as TScreen_Interview.Fail.bmx and
'     TScreen_Interview.Success.bmx (same Type, same call shape) already name them.
'   0x00C6EFE0 g_screenheight:Int -- DEVIATION from the address map, which lists this as
'     "g_screen_width" (STRONG, forced in 1 body: TScreen.CreateScreen). That forcing is
'     wrong: TScreen.CreateScreen's own decompile (0x005103C3) builds a 480x260 box centred
'     with x = half(DAT_00C6EFDC) - 0xF0 and y = half(DAT_00C6EFE0) - 0x82, and 0xF0 = 480/2
'     while 0x82 = 260/2 EXACTLY -- proof by box-half-size arithmetic that 0xC6EFDC is the
'     width and 0xC6EFE0 is the height, i.e. the OPPOSITE of the address map's pairing. This
'     matches src/recovered/TScreen_Interview.CreateScreen.bmx's own header, which already
'     names 0x00C6EFE0 "g_screenheight" (used there as the Y of "navpanel"). In THIS body,
'     0xC6EFE0 feeds TGadget.SetPosition's Y argument (arg1, confirmed order from
'     src/recovered/TGadget.SetPosition.bmx), and grows more negative (half-145/-170/-195)
'     as CreateBody's height argument grows (250/300/350) for harder difficulty -- panel
'     needs to sit higher to leave room for more button rows, which only makes sense if this
'     is the screen HEIGHT. Kept as g_screenheight, an already-declared name, not an
'     invented one.
'   0x00C6F028 g_profile:TProfile, field +0xC0 = interviewskill:Int -- address map's top
'     candidate here is CERTAIN g_contractoffer_tplayer, but g_profile has 142 citing bodies
'     (vs low single digits for every other name at this address) and is exactly what
'     src/recovered/TScreen_Interview.Success.bmx already uses for this same
'     interviewskill field (`g_profile.interviewskill = g_profile.interviewskill + 1`).
'   0x00505F6D ClampInt(a0:Int Ptr, a1:Int, a2:Int) -- recovered module Function
'     (src/recovered_module/ClampInt.bmx); called here as ClampInt(Varptr x, lo, hi), the
'     exact idiom src/recovered/TScreen_Options.ComboRes.bmx uses. Both calls in this body
'     show Ghidra's args merged onto the PRECEDING statement (empty parens); a manual
'     disassembly confirms `push a2; push a1; push &a0; call` in both cases.
'   0x00C6CDEC g_screen_interview_int02:Int  (interviewskill, clamped >=3 then to [3,5])
'   0x00C6CDF0 g_screen_interview_int03:Int  (9 / 12 / 15 total buttons by difficulty)
'   0x00C6CDF4 g_screen_interview_int04:Int  (gate flag ButtonAddText tests, reset to 0)
'   0x00C6CDF8 g_screen_interview_int05:Int  (g_matchtime + 2500, a "reveal" deadline)
'   0x00C6CDFC g_screen_interview_int06:String (running answer-sentence text, reset to "")
'   0x00C6CE00 g_screen_interview_int07:Int  (1-based current question index, reset to 1)
'   0x00C6CE08 g_screen_interview_arr:Int[]  (per-button answer-order slot, Int per
'     TScreen_Interview.ButtonAddText.bmx's direct Abs()/String() use with no downcast)
'   All six ints/string/array match extracted/globals_final.tsv's auto-numbering
'   (g_screen_interview_int02..int07 in address order) and TScreen_Interview.ButtonAddText.
'   bmx's own pragma declarations exactly.
'   0x00C6EFD4 g_matchtime:Int -- CERTAIN in the address map AND confirmed directly: the
'     called TScreenMessage.Create/CreateAlert bodies use this exact Global for the exact
'     same `finishtime = g_matchtime + duration` idiom this body reuses for int05.
'   0x00C6CDD8 g_iv_screen:TScreen, 0x00C6CDDC g_iv_panel:TPanel, 0x00C6CDE0 g_iv_label:
'     TLabel, 0x00C6CDE4 g_iv_btnok:TButton -- all four are the construction-site names from
'     src/recovered/TScreen_Interview.CreateScreen.bmx (the only body that constructs them);
'     none of the four is STRONG/CERTAIN in the address map yet (single-body AMBIGUOUS), so
'     using CreateScreen.bmx's names is using an existing name, not inventing one. (Other
'     already-recovered siblings use different synonyms at the same addresses -- e.g.
'     DisableAllButtons.bmx's "g_screen_interview" for 0x00C6CDD8, or ButtonAddText.bmx's
'     raw "g_Object796"/"g_Object797" for 0x00C6CDE0/E4 -- left alone as pre-existing
'     corpus disagreement for the unify pass to merge.)
'   Class-table slots (TGadget unless noted, from extracted/vtable_map.tsv):
'     0x90 GetGadgetByName($):TGadget   0x64 SetText($,$,i,i)i   0x54 Hide()i   0x58 Show()i
'     0x84 SetPosition(i,i,i)i (a0=x,a1=y,a2=flag, confirmed via TGadget.SetPosition.bmx)
'     TPanel+0x8C CreateBody(i,i)i (a0=h,a1=style, confirmed via TPanel.CreateBody.bmx)
'   0x00C6CF48/0x00C6CF4C are THIS Type's OWN class table (base 0x00C6CF0C, solved from
'     src/recovered/TScreen_Interview.CreateScreen.bmx's own note that +0x38/+0x44/+0x50 =
'     0x00C6CF44/50/5C = ButtonAddText/Update/ButtonOk): +0x3C = EnableAllButtons,
'     +0x40 = DisableAllButtons, so those two calls are written bare, no Type prefix, per
'     ButtonAddText.bmx calling Success()/DisableAllButtons() the same way.
'   Runtime helpers (E8 direct calls): 0x004A7AC0 bbStringFromInt (String(Int)),
'     0x004A7C20 bbStringConcat, 0x004A8F60 bbObjectDowncast (downcast class table for
'     TButton is 0x00C62344, matching EnableAllButtons/DisableAllButtons/ButtonAddText),
'     0x004A6A30 String.Compare($):i, 0x0059F089 Rand(i,i)i / Rand(i)i (single-arg form
'     shows as Rand(x,1) in Ghidra, per src/recovered/TCard.Shuffle.bmx), 0x004C5549
'     GetText($)$ (src/recovered_module/GetText.bmx), 0x005B9690 bbFloatToInt (Int(f)).
'   String literals (harness.read_string): 0x00C91A90 "Interview!", 0x00C7E308 "btn_",
'     0x00C91AE0 "CLICHE_", 0x00C91AB0 "interview_Instrucs", 0x00C5D680 "FFFFFF".
'
' The Compare receiver/argument order (`<downcast expr>.txt.Compare(b.txt)`, not
' `b.txt.Compare(<downcast expr>.txt)`) is read from which push sits closest to the call
' (the downcast expression's .txt) versus which push survives from many instructions
' earlier (b.txt); Ghidra's own single shown argument for FUN_004A6A30 is the downcast
' expression's .txt, consistent with this reading.
'!Global g_curscreen:TScreen
'!Global g_interview_ret:String
'!Global g_engine_gfxw:Int
'!Global g_engine_gfxh:Int
'!Global g_font2:TBitmapFont
'!Global g_profile:TProfile
'!Global g_screen_interview_int02:Int
'!Global g_screen_interview_int03:Int
'!Global g_screen_interview_int04:Int
'!Global g_screen_interview_int05:Int
'!Global g_screen_interview_int06:String
'!Global g_screen_interview_int07:Int
'!Global g_screen_interview_arr:Int[]
'!Global g_iv_screen:TScreen
'!Global g_iv_panel:TPanel
'!Global g_iv_label:TLabel
'!Global g_iv_btnok:TButton
'!Global g_screenheight:Int
'!Global g_matchtime:Int
g_interview_ret = g_curscreen.name
TScreen.SetActive("interview", "")
TScreenMessage.Create(g_engine_gfxw / 2, g_engine_gfxh / 2, GetText("Interview!"), 1500, g_font2, Null, 1.0, "FFFFFF")
If g_profile.interviewskill < 3 Then g_profile.interviewskill = 3
g_screen_interview_int02 = g_profile.interviewskill
ClampInt(Varptr g_screen_interview_int02, 3, 5)
g_screen_interview_int03 = 9
If g_profile.interviewskill > 8
	g_screen_interview_int03 = 15
	g_iv_panel.CreateBody(350, 3)
	g_iv_panel.SetPosition(Int(g_iv_panel.x), g_screenheight / 2 - 195, 1)
Else
	If g_profile.interviewskill > 5
		g_screen_interview_int03 = 12
		g_iv_panel.CreateBody(300, 3)
		g_iv_panel.SetPosition(Int(g_iv_panel.x), g_screenheight / 2 - 170, 1)
	Else
		g_iv_panel.CreateBody(250, 3)
		g_iv_panel.SetPosition(Int(g_iv_panel.x), g_screenheight / 2 - 145, 1)
	End If
End If
Local n:Int
n = g_profile.interviewskill - g_screen_interview_int02
ClampInt(Varptr n, 0, 3)
g_screen_interview_int04 = 0
g_screen_interview_int06 = ""
g_iv_label.SetText(GetText("interview_Instrucs"), "", -1, -1)
g_screen_interview_int05 = g_matchtime + 2500
g_screen_interview_int07 = 1
For Local i:Int = 1 To 3
	Local b0:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(i)))
	b0.SetText(GetText("CLICHE_" + String(i)), "", -1, -1)
Next
For Local q:Int = 4 To 15
	Local b:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(q)))
	If q <= g_screen_interview_int03
		b.Show()
	Else
		b.Hide()
	End If
	Local ok:Int = 1
	Repeat
		ok = 1
		b.SetText(GetText("CLICHE_" + String(Rand(4, 25))), "", -1, -1)
		For Local j:Int = 1 To q - 1
			If TButton(g_iv_screen.GetGadgetByName("btn_" + String(j))).txt.Compare(b.txt) = 0 Then ok = 0
		Next
	Until ok <> 0
Next
For Local k:Int = 0 To g_screen_interview_int03 - 1
	Local u:Int = 1
	Repeat
		u = 1
		g_screen_interview_arr[k] = Rand(g_screen_interview_int03)
		For Local m:Int = 0 To k - 1
			If g_screen_interview_arr[m] = g_screen_interview_arr[k] Then u = 0
		Next
	Until u <> 0
	If Rand(3) = 1 And n > 0
		n = n - 1
		g_screen_interview_arr[k] = -g_screen_interview_arr[k]
	End If
Next
g_iv_btnok.Hide()
EnableAllButtons()
DisableAllButtons()

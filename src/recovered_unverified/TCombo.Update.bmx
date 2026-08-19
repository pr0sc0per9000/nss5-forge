' TCombo.Update
' VA 0x005183AB   1321 bytes   vtable slot 0x34   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (1321/1321, original length from Ghidra's inventory)
' ORACLE: mode=len  matched=1321/1321  STATUS=MATCH
'
' Written from extracted/decomp/TCombo.Update@005183ab.c, cross-checked line-for-line
' against extracted/decomp_annotated/TCombo.Update@005183ab.c (symbol layer,
' CONFIDENCE=HIGH, STATS resolved=35 rejected-raw=0), which independently resolves
' every call target and Global in this body by name/type via its SYM block.
' Structurally this is the TCombo twin of src/recovered/TTable.UpdateActivated.bmx
' (953/953): same TScreen.GetInput()-driven Select dispatch, same PlaySound/
' TChannel.Playing() gate on the scroll cases, same "mouse-hover repeat-scroll" idiom
' against a per-widget repeat timestamp. Read the two side by side. The mouse-hover-
' highlight EachIn loops (both here and in src/recovered/TCombo.Activate.bmx, 403/403)
' are the standard bbObjectDowncast/refcount boilerplate documented in docs/reference/
' codegen-patterns.md #5 and #10.6: `g_activegadget = b` inside `If cond Then ...`,
' nothing more -- the retain/release traffic around the store is compiler-generated,
' not source.
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C6173C g_screen_int03:Int -- "mouse mode active" flag; same slot/name as
'     TTable.UpdateActivated, TScreen.GetInput, TCombo.DrawItems, TGadget.DrawHighlight.
'     `If g_screen_int03 And g_curscreen <> Null` is copied verbatim from
'     TTable.UpdateActivated's identical guard (same two Globals, same idiom).
'   0x00C61700 g_curscreen:TScreen -- the active screen, only ever compared to Null
'     here (annotator's raw name g_Object101; TScreen.GetInput.bmx's header documents
'     the corpus-wide rename g_Object101 -> g_curscreen for this exact address).
'   0x00C61CFC g_table_int02:Int -- the UI hover repeat-scroll interval, read once into
'     a Local at entry. Same address the annotator's own SYM block resolves to
'     this exact name for THIS function, and the same name/address
'     src/recovered/TTable.UpdateActivated.bmx already declares for its own identical
'     "repeat interval" Local (AMBIGUOUS tier in the address solver -- only 1-2
'     declaring bodies -- but no other name has ever been proposed for this slot).
'     g_table_int02's original data-section value is 80 (read directly from NSS5.exe
'     at 0x00C61CFC: raw bytes 50 00 00 00). Never stored to anywhere in the corpus --
'     same "uncaptured Global initialiser" defect as g_pole_maxz/g_ball_snowthreshold
'     (codegen-patterns 21.1), just on an Int slot instead of a Float one. A bare
'     `'!Global g_table_int02:Int` defaults the assembled build to 0, which collapses
'     the hover repeat-scroll gate below (`g_player_int50 > g_combo_int03 + rep`) to
'     "any elapsed time at all", so it re-fires every 25ms logic tick instead of every
'     80ms -- the dropdown scroll-too-fast symptom.
'   0x00C6EFD4 g_player_int50:Int -- the frame clock; annotator SYM block marks this
'     one "(verified)". Compared/updated against a per-TCombo-instance-independent
'     repeat timestamp (see next).
'   0x00C7E104 g_combo_int03:Int -- TCombo's own scroll-repeat timestamp (mirrors
'     TTable's g_table_int05 at a different address). Not yet declared by any
'     recovered/pending body (explain_global: 0 bodies), so no CERTAIN corpus name
'     exists; using extracted/globals_named.tsv's pre-unify decoder name for this
'     address ("TCombo ... dword int access, 2 writes"), already present verbatim in
'     src/generated/globals.bmx.
'   0x00C61CF8 g_activegadget:TGadget -- CERTAIN/21-body corpus name (raw decoder name
'     g_Object108; same slot src/recovered/TCombo.Activate.bmx and
'     TCombo.Deactivate.bmx already use via g_activegadget/g_activecombo).
'   0x00C6F088 g_chanclick:TChannel, 0x00C6171C g_sndclick:TSound -- CERTAIN, forced
'     from the verified pair TScreen.CheckInput ("PlaySound(g_sndclick, g_chanclick)").
'     Used here for the case-5 "select" PlaySound. NOTE this takes precedence over
'     TTable.UpdateActivated's own weaker, unverified prose names for these same two
'     addresses (g_chan_ui / g_snd_select) -- the address solver treats
'     g_sndclick/g_chanclick as the stronger, forced evidence for those slots.
'   0x00C61720 -- UNRESOLVED by the address solver (0 forced names either way).
'     Reusing TTable.UpdateActivated's own declared name for this exact address
'     (its header states 0x00C61720 -> TSound, "g_snd_move"), the only precedent
'     anywhere in the corpus; used here for the case 1-4 "scroll" PlaySound.
'   TScreen.GetInput() -- static Function, class-table slot 0x80 (a `ct` call per the
'     annotator, not a vtable dispatch): identical first call in
'     TTable.UpdateActivated, translated the same way there.
'   GetChar() -- BRL polledinput.mod builtin (_brl_polledinput_GetChar per
'     extracted/brl_functions.tsv); 0 = nothing typed, 27 = Escape, else an ASCII code
'     forwarded to SelectItemByLetter. 27 (not $1B) matches the decimal-literal Escape
'     convention already used elsewhere in the corpus (e.g. TPitch.DoLineUpImage's
'     `KeyHit(27)`).
'   TGadget.MouseOver() is slot 0x60, inherited, on both btn_head and each TButton in
'     buttons (same class-table walk as src/recovered/TCombo.DrawItems.bmx).
'   `hit > Self.selecteditem Or hit - Self.itemoffset = Self.GetNoofDisplayItems()` is
'     BlitzMax's short-circuit Or, matching the decompiled `if (!bVar9) { bVar9 = ...}`
'     exactly -- no extra Local needed for the intermediate bool. Operand order is
'     byte-observable (codegen-patterns.md #10.1): the `cmp`/`setg` pair loads `hit`
'     first, so the source reads `hit > Self.selecteditem`, not the mirror-image
'     `Self.selecteditem < hit`.
'   `inp > Self.itemoffset And b.MouseOver()` (case 5's own search counter, a Local
'     distinct from case 0's `ch`) is the short-circuit And twin of the same pattern
'     (`iVar4=0; if (itemoffset<iVar3) iVar4=b.MouseOver();`), same operand-order rule.
'   Field offsets (object_model.json TCombo/TGadget): hidden 0x3C, alive 0x38,
'     activated 0x64, btn_head 0x5C, buttons 0x60, selecteditem 0x68, itemoffset 0x70.
'   Guard idiom `If Self.hidden Then Return 0` / `If Not Self.alive Then Return 0` /
'     `If Not Self.activated Then Return 0` copies the exact bare-truth-test forms
'     confirmed byte-identical in src/recovered/TButton.Update.bmx and
'     src/recovered/TTable.Update.bmx for the shared hidden/alive guard pair.
'   The Select subject is the bare call `Select TScreen.GetInput()`: nothing precedes
'     it between the call and the six `cmp eax,N` compares, so no Local holds the
'     dispatch value. Inside Case 0, `ch`/`n`/`hit` are three genuinely fresh Locals
'     (Ghidra's local_14/local_c/local_10); case 5's search counter and the trailing
'     highlight loop's counter are each their own fresh `Local inp:Int = 1`, scoped to
'     their own block -- there is no single dispatch variable carried across the body.
'   Case 5's button-hover branch is `If Self.btn_head.MouseOver() Then
'     Self.selecteditem = 0 Else <search loop>`: the literal (non-negated) MouseOver()
'     test with the two arms in that order, matching the `je`-into-search-loop /
'     fall-through-into-selecteditem=0 order the disassembly shows.
'   Case 0's `If hit = 0 Then Else <content> EndIf`, guarding the hit-handling block,
'     needs the explicit empty `Else`: bcc only emits the unconditional `jmp` past the
'     (empty) Then arm -- the byte the plain `If hit <> 0 Then <content> EndIf` form
'     omits -- when a genuine `Else` clause is present in source, even an empty one.
'   Case 3 and case 4's `For Local i:Int = 1 To Self.GetNoofDisplayItems()` inlines the
'     call as the loop's bound expression: the loop counter is set to 1 before the bound
'     is evaluated (`mov esi,1` precedes the `GetNoofDisplayItems()` call in the
'     disassembly), so there is no separate `Local cnt` computed ahead of the loop.
'   Case 0's hit-search loop stores `g_activegadget = b` BEFORE `hit = n`, not after --
'     confirmed by the refcount traffic (retain b / release+maybe-free old
'     g_activegadget) preceding the `hit=n` store in the original disasm.
'   The trailing loop's `g_activegadget` store is the plain `If cond Then
'     g_activegadget = b` shown below, not a store unconditional on every iteration --
'     confirmed against the byte oracle once the rest of the body was realigned.
'
'!Global g_screen_int03:Int
'!Global g_curscreen:TScreen
'!Global g_table_int02:Int = 80
'!Global g_player_int50:Int
'!Global g_combo_int03:Int
'!Global g_activegadget:TGadget
'!Global g_chanclick:TChannel
'!Global g_sndclick:TSound
'!Global g_snd_move:TSound
If Self.hidden Then Return 0
If Not Self.alive Then Return 0
If Not Self.activated Then Return 0
Local rep:Int = g_table_int02
Select TScreen.GetInput()
Case 0
	Local inp:Int = GetChar()
	If inp = 27
		Self.Deactivate()
		Return 0
	EndIf
	If inp <> 0
		Self.SelectItemByLetter(inp)
		Return 0
	EndIf
	Local n:Int = 1
	Local hit:Int = 0
	If g_screen_int03 And g_curscreen <> Null
		If Not Self.btn_head.MouseOver()
			For Local b:TButton = EachIn Self.buttons
				If b.MouseOver()
					g_activegadget = b
					hit = n
					Exit
				EndIf
				n :+ 1
			Next
		EndIf
		If hit = 0
		Else
			If hit < Self.selecteditem
				If hit < Self.selecteditem - Self.itemoffset Then rep = 0
				If g_player_int50 > g_combo_int03 + rep
					Self.ScrollUp()
					g_combo_int03 = g_player_int50
				EndIf
			ElseIf hit > Self.selecteditem Or hit - Self.itemoffset = Self.GetNoofDisplayItems()
				If hit > Self.selecteditem + 1 Then rep = 0
				If g_player_int50 > g_combo_int03 + rep
					Self.ScrollDown()
					g_combo_int03 = g_player_int50
				EndIf
			EndIf
		EndIf
	EndIf
Case 1
	If g_chanclick.Playing() = 0 Then PlaySound(g_snd_move, g_chanclick)
	Self.ScrollUp()
Case 2
	If g_chanclick.Playing() = 0 Then PlaySound(g_snd_move, g_chanclick)
	Self.ScrollDown()
Case 3
	If g_chanclick.Playing() = 0 Then PlaySound(g_snd_move, g_chanclick)
	For Local i:Int = 1 To Self.GetNoofDisplayItems()
		Self.ScrollUp()
	Next
Case 4
	If g_chanclick.Playing() = 0 Then PlaySound(g_snd_move, g_chanclick)
	For Local i:Int = 1 To Self.GetNoofDisplayItems()
		Self.ScrollDown()
	Next
Case 5
	PlaySound(g_sndclick, g_chanclick)
	Local inp:Int = 1
	If g_screen_int03 And g_curscreen <> Null
		If Self.btn_head.MouseOver()
			Self.selecteditem = 0
		Else
			For Local b:TButton = EachIn Self.buttons
				If inp > Self.itemoffset And b.MouseOver()
					Self.selecteditem = inp
					Exit
				EndIf
				inp :+ 1
			Next
		EndIf
	EndIf
	Self.Deactivate()
	Return 0
Default
	Return 0
End Select
Local inp:Int = 1
For Local b:TButton = EachIn Self.buttons
	If b.hidden = 0 And inp = Self.selecteditem Then g_activegadget = b
	inp :+ 1
Next
Return 0

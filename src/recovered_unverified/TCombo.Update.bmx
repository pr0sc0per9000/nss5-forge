' TCombo.Update
' VA 0x005183AB   1321 bytes   vtable slot 0x34   sig ()i   KIND=Method
' Written from extracted/decomp/TCombo.Update@005183ab.c, cross-checked line-for-line
' against extracted/decomp_annotated/TCombo.Update@005183ab.c (symbol layer,
' CONFIDENCE=HIGH, STATS resolved=35 rejected-raw=0), which independently resolves
' every call target and Global in this body by name/type via its SYM block.
' Structurally this is the TCombo twin of the already-recovered, byte-verified
' src/recovered/TTable.UpdateActivated.bmx (953/953): same TScreen.GetInput()-driven
' Select dispatch, same PlaySound/TChannel.Playing() gate on the scroll cases, same
' "mouse-hover repeat-scroll" idiom against a per-widget repeat timestamp. Read the two
' side by side. The mouse-hover-highlight EachIn loops (both here and in
' src/recovered/TCombo.Activate.bmx, confirmed 403/403) are the standard
' bbObjectDowncast/refcount boilerplate documented in docs/reference/
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
'   `Self.selecteditem < hit Or hit - Self.itemoffset = Self.GetNoofDisplayItems()` is
'     BlitzMax's short-circuit Or, matching the decompiled `if (!bVar9) { bVar9 = ...}`
'     exactly -- no extra Local needed for the intermediate bool.
'   `Self.itemoffset < inp And b.MouseOver()` (inp reused as the case-5 search counter,
'     see the note below) is the short-circuit And twin of the same pattern
'     (`iVar4=0; if (itemoffset<iVar3) iVar4=b.MouseOver();`).
'   Field offsets (object_model.json TCombo/TGadget): hidden 0x3C, alive 0x38,
'     activated 0x64, btn_head 0x5C, buttons 0x60, selecteditem 0x68, itemoffset 0x70.
'   Guard idiom `If Self.hidden Then Return 0` / `If Not Self.alive Then Return 0` /
'     `If Not Self.activated Then Return 0` copies the exact bare-truth-test forms
'     confirmed byte-identical in src/recovered/TButton.Update.bmx and
'     src/recovered/TTable.Update.bmx for the shared hidden/alive guard pair.
'
' FROM THE BYTE-ORACLE DISASM PASS (status/score/TCombo.Update.txt): the case bodies
' do NOT each declare their own fresh Local for `ch`/`sel`/the trailing counter -- the
' decompilation reuses the SAME variable as the Select's own dispatch subject (Ghidra's
' `iVar3`) for all three: `iVar3 = FUN_005b4746()` (GetChar, inside Case 0), `iVar3 = 1`
' (inside Case 5, before its own search loop) and `iVar3 = 1` again after `End Select`
' (the trailing highlight loop). Only Case 0's `n`/`hit` pair are genuinely fresh Locals
' (Ghidra keeps them as separate local_c/local_10 slots, never folded into iVar3). Splitting
' them into `ch`/`sel`/`n2` as brand-new Locals instead pads the stack
' frame by slots the original never allocates and desyncs every `[ebp-N]` disp8 after it
' (confirmed directly: `mov [ebp-8],1` for `n` in the original vs `mov [ebp-4],1` under the
' split spelling -- one slot too shallow, freed up by not giving `ch` its own slot).
' This body therefore reuses `inp` (its name for the dispatch Local) via plain reassignment
' everywhere the original reuses iVar3, exactly the same "one Local, many purposes" idiom
' already established for TEngine.CheckInput's `iVar1`/`hit`.
' Case 0's hit-search loop stores `g_activegadget = b` BEFORE
' `hit = n`, not after -- confirmed by the refcount traffic (retain b / release+maybe-free
' old g_activegadget) preceding the `hit=n` store in the original disasm.
'
' UNCERTAINTIES (flagged, not hidden)
'   - Dispatch shape: CONFIRMED `Select inp`, not If/ElseIf -- the byte oracle's own
'     capstone window (status/score/TCombo.Update.txt onward) shows the six `cmp eax,N`
'     compares back to back before any Case body, the flat-dispatch tell from
'     codegen-patterns.md #10.2.
'   - `If Self.btn_head.MouseOver() = 0` (explicit compare, mirroring
'     `g_chanclick.Playing() = 0`) vs `If Not Self.btn_head.MouseOver()` (bare negate,
'     mirroring `If b.MouseOver() Then sel = b` in TCombo.DrawItems): went with the
'     bare-negate form below since the corpus's only other MouseOver() precedent uses a
'     bare truth test, but this is a judgement call, not solver evidence.
'   - `b.hidden = 0 And inp = Self.selecteditem` in the trailing highlight loop (inp
'     reused as the counter, see the note above) vs `Not b.hidden And ...`:
'     transcribed as the literal `== 0` the decompilation shows (TCombo.Activate's
'     sibling loop sets, rather than tests, hidden, so it gives no precedent either way).
'   - The trailing loop's `g_activegadget` store reads, in the decompilation, as an
'     unconditional store of a conditionally-merged value (old-or-`b`) every iteration,
'     not a store guarded by the `If`, unlike the byte-identical guarded store in Case
'     0's own loop just above it. Left as the plain `If cond Then g_activegadget = b`
'     shown below on the working theory that this is a loop-body compaction the compiler
'     applies to an Object store repeated across iterations (avoiding a skip-branch each
'     time), not a different source shape -- unconfirmed, flag if the byte oracle
'     disagrees once the rest of this body is realigned.
'
'!Global g_screen_int03:Int
'!Global g_curscreen:TScreen
'!Global g_table_int02:Int
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
Local inp:Int = TScreen.GetInput()
Select inp
Case 0
	inp = GetChar()
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
		If hit <> 0
			If hit < Self.selecteditem
				If hit < Self.selecteditem - Self.itemoffset Then rep = 0
				If g_combo_int03 + rep < g_player_int50
					Self.ScrollUp()
					g_combo_int03 = g_player_int50
				EndIf
			ElseIf Self.selecteditem < hit Or hit - Self.itemoffset = Self.GetNoofDisplayItems()
				If Self.selecteditem + 1 < hit Then rep = 0
				If g_combo_int03 + rep < g_player_int50
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
	Local cnt:Int = Self.GetNoofDisplayItems()
	For Local i:Int = 1 To cnt
		Self.ScrollUp()
	Next
Case 4
	If g_chanclick.Playing() = 0 Then PlaySound(g_snd_move, g_chanclick)
	Local cnt2:Int = Self.GetNoofDisplayItems()
	For Local i:Int = 1 To cnt2
		Self.ScrollDown()
	Next
Case 5
	PlaySound(g_sndclick, g_chanclick)
	inp = 1
	If g_screen_int03 And g_curscreen <> Null
		If Not Self.btn_head.MouseOver()
			For Local b:TButton = EachIn Self.buttons
				If Self.itemoffset < inp And b.MouseOver()
					Self.selecteditem = inp
					Exit
				EndIf
				inp :+ 1
			Next
		Else
			Self.selecteditem = 0
		EndIf
	EndIf
	Self.Deactivate()
	Return 0
Default
	Return 0
End Select
inp = 1
For Local b:TButton = EachIn Self.buttons
	If b.hidden = 0 And inp = Self.selecteditem Then g_activegadget = b
	inp :+ 1
Next
Return 0

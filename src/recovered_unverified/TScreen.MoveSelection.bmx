' TScreen.MoveSelection
' byte-identical vs NSS5.exe
' VA 0x00511ea5   1231 bytes   vtable slot 0x84   sig (i)i   KIND=Method
' Body-only format: statements only; parameters are a0, a1, ...
'
' CODEGEN NOTES (byte-verified against NSS5.exe -- see docs/reference/codegen-patterns.md
' 10.2/10.3 for the general patterns cited below).
'  * The a0 dispatch in both passes is a `Select a0 / Case 1..4 / End Select`, not
'    `If a0=1 ... ElseIf`: the disassembly is a run of `cmp eax,N / je` back to back, every
'    target past the last compare, with no Default (no-match falls straight into the shared
'    tail after End Select) -- the ElseIf shape is shorter and does not match.
'  * `If Not g_activegadget ... Return 0 ... EndIf` (no Else) is an early return, not an
'    If/Else: the original preloads `eax,0` before jumping to the shared epilogue, which only
'    happens when a `Return 0` is actually compiled at that point in the source.
'  * Each Case's position guard is TWO independent one-line `If Not (...) Then Continue`
'    statements (not a combined `And`/`Or` on one line). A lone comparison feeding a Continue
'    fuses straight into `cmp reg,mem / setcc / movzx / cmp / jcc` with no extra materialize
'    step; combining two terms with `And`/`Or` forces a separate materialize-then-test pass
'    that costs extra bytes and is not present here.
'  * The list-filter loop is `If g.hidden <> 0 Then Continue` followed by a separate
'    `If g.alive <> 0 ... EndIf` -- not one nested/And'd condition. The hidden guard alone
'    fuses to `cmp [x+0x3c],0 / je / jmp`; wrapping it around the alive check instead changes
'    that fused encoding and does not match.
'  * `g_activegadget`/`best` null checks use `If Not X`, which disassembles as the DANCE
'    (`mov eax,[..] ; cmp ..,NullConst ; setne al ; movzx eax,al ; cmp eax,0 ; jne`) --
'    including `Not best` inside `d < bestd Or Not best` (both passes), which double-negates
'    (`setne` then `sete`) exactly like every other `Not <object>` in this body. Only
'    `best <> Null Then g_activegadget = best` (a plain one-line Then, no block) keeps its
'    explicit `<>`, confirmed direct (`cmp [mem],NullConst ; je`) at the tail.
'  * The Dist2D call's centre-point arguments are `desx + w / 2.0` (offset term first, the
'    half-dimension second), not `w / 2.0 + desx`: the offset field loads and stays on the
'    FPU stack while the halved dimension is computed on top and merged with `faddp`.
'
' What it does: keyboard/joystick-driven gadget navigation. a0 is the direction code from
' TScreen.GetInput (1=up, 2=down, 3=left, 4=right); TScreen.CheckInput's Default case calls
' Self.MoveSelection(inp) for any GetInput() result that isn't 0/5/6. It plays the shared UI
' "select" sound if the shared channel isn't already busy, then, if there is no active
' gadget yet, defers entirely to Self.FindNewActiveGadget(); otherwise it collects every
' visible, alive gadget on the screen into a scratch list and looks for the nearest one that
' shares the active gadget's column/row in the requested direction, using each gadget's
' centre point (field/2.0 + desx or desy). If that pass finds nothing, it falls back to a
' second pass over the SAME list that drops the column/row requirement -- but that fallback
' pass tests the threshold against the candidate's raw x/y while still measuring distance
' with desx/desy, exactly as decompiled (the mismatch is preserved, not fixed).
'
' ASSUMPTIONS
'  * 0x00C6F088 g_chanclick:TChannel and 0x00C61CF8 g_activegadget:TGadget are both CERTAIN
'    in explain_global.py (TScreen.CheckInput, TScreen.MouseSelection, TScreen.TabToGadget,
'    TScreen.FindNewActiveGadget, TCombo.Activate, TScreen.RemoveGadget, ... all agree).
'  * 0x00C61720 g_snd_select:TSound -- explain_global.py resolves 0 names for this exact
'    address (not yet CERTAIN/STRONG), but TScreen.SetUp (byte-verified, already in
'    src/recovered) loads Click.ogg into 0x00C6171C (g_sndclick, CERTAIN elsewhere) and
'    Select.ogg into 0x00C61720 immediately after, in that source order -- so 0x00C61720 is
'    the Select.ogg TSound. src/recovered/TTable.UpdateActivated.bmx names this same address
'    g_snd_move and puts "g_snd_select" on 0x00C6171C instead, which is backwards relative to
'    SetUp's verified load order. g_snd_select is used here to agree with the verified
'    TScreen.SetUp evidence, not the unverified TTable body's naming.
'  * 0x00C7DBF8 g_screen_float09:Float -- untouched by any other body in the corpus
'    (explain_global.py: 0 names resolved at this address). This is the "no candidate found
'    yet" distance sentinel; first claimed here, name follows the existing g_screen_float01
'    .. g_screen_float08 numbering already used by TScreen.GetInput and friends.
'  * TChannel vtable slot 0x48 = Playing() (matches g_chan_ui.Playing() in
'    TTable.UpdateActivated, same call shape: `(**(code**)(*(int*)chan+0x48))(chan)`).
'  * FUN_0059b25e = PlaySound(sound, channel) (matches TScreen.CheckInput / TInputBox.Update,
'    both already in src/recovered).
'  * FUN_005b40bf = CreateList(); FUN_004a8f60 is the implicit EachIn downcast;
'    FUN_004a8590 is the implicit BBRELEASE free folded into a Global object assignment --
'    all standard idiom across the corpus (see TClub.SelectListByNationId, TButton.
'    SetButtonStyle).
'  * FUN_00505da2 = Dist2D(x1,y1,x2,y2):Float, src/recovered_module/Dist2D.bmx.
'  * TScreen.FindNewActiveGadget is vtable slot 0x64 (100 decimal) -- confirmed by its own
'    decomp header (SLOT=0x64) and called here as `(**(code**)(*param_1+100))()`.
'    TScreen.GetGadgetList is slot 0x50 (per TScreen.TabToGadget's notes).
'  * TGadget field offsets, from object_model.json: x 0x20, y 0x24, h 0x28, w 0x2c (all
'    Float), alive 0x38, hidden 0x3c (both Int), desx 0x54, desy 0x58 (both Float).
'  * The four float divisors inside the centre-point Dist2D call are each the raw literal
'    2.0 (extracted/decomp_annotated/TScreen.MoveSelection@00511ea5.c confirms all four RAW
'    dwords = 0x40000000 = 2.0f); each occurrence is its own literal in source, which is why
'    they live at four different .rdata addresses.
'!Global g_chanclick:TChannel
'!Global g_snd_select:TSound
'!Global g_activegadget:TGadget
'!Global g_screen_float09:Float
If g_chanclick.Playing() = 0
	PlaySound(g_snd_select, g_chanclick)
End If
If Not g_activegadget
	Self.FindNewActiveGadget()
	Return 0
EndIf
Local l:TList = CreateList()
For Local g:TGadget = EachIn Self.GetGadgetList()
	If g.hidden <> 0 Then Continue
	If g.alive <> 0
		l.AddLast(g)
	EndIf
Next
Local bestd:Float = g_screen_float09
Local best:TGadget = Null
For Local g:TGadget = EachIn l
	If g <> g_activegadget
		Select a0
		Case 1
			If Not (g.desy < g_activegadget.desy) Then Continue
			If Not (g.desx = g_activegadget.desx) Then Continue
		Case 2
			If Not (g.desy > g_activegadget.desy) Then Continue
			If Not (g.desx = g_activegadget.desx) Then Continue
		Case 3
			If Not (g.desx < g_activegadget.desx) Then Continue
			If Not (g.desy = g_activegadget.desy) Then Continue
		Case 4
			If Not (g.desx > g_activegadget.desx) Then Continue
			If Not (g.desy = g_activegadget.desy) Then Continue
		End Select
		Local d:Float = Dist2D(g_activegadget.desx + g_activegadget.w / 2.0, g_activegadget.desy + g_activegadget.h / 2.0, g.desx + g.w / 2.0, g.desy + g.h / 2.0)
		If d < bestd Or Not best
			bestd = d
			best = g
		EndIf
	EndIf
Next
If Not best
	For Local g:TGadget = EachIn l
		If g <> g_activegadget
			Select a0
			Case 1
				If Not (g.y < g_activegadget.desy) Then Continue
			Case 2
				If Not (g.y > g_activegadget.desy) Then Continue
			Case 3
				If Not (g.x < g_activegadget.desx) Then Continue
			Case 4
				If Not (g.x > g_activegadget.desx) Then Continue
			End Select
			Local d:Float = Dist2D(g_activegadget.desx, g_activegadget.desy, g.desx, g.desy)
			If d < bestd Or Not best
				bestd = d
				best = g
			EndIf
		EndIf
	Next
EndIf
If best <> Null Then g_activegadget = best
Return 0

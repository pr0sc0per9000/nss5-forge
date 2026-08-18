' TScreen.MoveSelection
' VA 0x00511ea5   1231 bytes   vtable slot 0x84   sig (i)i   KIND=Method
' Body-only format: statements only; parameters are a0, a1, ...
'
' REFINE PASS (score was 7.6%, first diff at byte 13, length delta -1): the length delta
' traced to a genuine codegen-shape mismatch, not a whole-program-layout artifact. Fixed by
' cross-referencing the byte-VERIFIED TScreen.CreateScreen.bmx (381/381), which contains both
' an explicit `If s.bg = Null ... EndIf` (compiles DIRECT: `cmp [mem],NullConst ; jne`) and an
' implicit `If Not g_curscreen ... EndIf` (compiles as a DANCE: `mov eax,[mem] ; cmp
' eax,NullConst ; setne al ; movzx eax,al ; cmp eax,0 ; jne`) side by side in the SAME
' function -- proving BCC picks direct-vs-dance codegen from the SOURCE SYNTAX (explicit
' `X = Null` vs implicit `Not X` / bare `If X`), not from Else-presence or type. The
' original's `g_activegadget` check and the `best` guard both disassemble as the dance
' (`mov eax,[..] ; cmp ..,0x5c9c80 ; setne al ; movzx eax,al ; cmp eax,0 ; jne`,
' byte-for-byte the same shape as CreateScreen's `Not g_curscreen`), so both are written here
' as `If Not X`, not `If X = Null`/`If X = Null Then...`. The two `g And` prefixes on the
' inner list-filter conditions are dropped for the same reason: original's disassembly shows
' only the field/identity checks (hidden=0/alive<>0, and g<>g_activegadget) with NO extra
' Null test at all -- `g` is already proven non-Null by the EachIn fetch immediately above it
' (a compiler-synthesized check, direct, distinct from a user `If g`/`Not g`), so a redundant
' user-written `g And` would show up as an extra dance block the original does not have. Only
' `best <> Null Then g_activegadget = best` (line 107, a plain one-line Then, no block) keeps
' its explicit `<>` -- confirmed direct (`cmp [mem],NullConst ; je`) at the original's tail.
' `best = Null` inside the `d < bestd Or best = Null` Or-conditions (both passes) is left as
' explicit `=`: Or-chains always compile via the same materialize-and-merge shape regardless
' of `=`/`Not` phrasing (confirmed against the Or's own float operand, which is forced through
' an identical dance by FPU compare mechanics alone), so this Or is not evidence either way.
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
Else
	Local l:TList = CreateList()
	For Local g:TGadget = EachIn Self.GetGadgetList()
		If g.hidden = 0 And g.alive <> 0
			l.AddLast(g)
		EndIf
	Next
	Local bestd:Float = g_screen_float09
	Local best:TGadget = Null
	For Local g:TGadget = EachIn l
		If g <> g_activegadget
			If a0 = 1
				If g_activegadget.desy <= g.desy Or g.desx <> g_activegadget.desx Then Continue
			ElseIf a0 = 2
				If g.desy <= g_activegadget.desy Or g.desx <> g_activegadget.desx Then Continue
			ElseIf a0 = 3
				If g_activegadget.desx <= g.desx Or g.desy <> g_activegadget.desy Then Continue
			ElseIf a0 = 4
				If g.desx <= g_activegadget.desx Or g.desy <> g_activegadget.desy Then Continue
			EndIf
			Local d:Float = Dist2D(g_activegadget.w / 2.0 + g_activegadget.desx, g_activegadget.h / 2.0 + g_activegadget.desy, g.w / 2.0 + g.desx, g.h / 2.0 + g.desy)
			If d < bestd Or best = Null
				bestd = d
				best = g
			EndIf
		EndIf
	Next
	If Not best
		For Local g:TGadget = EachIn l
			If g <> g_activegadget
				If a0 = 1
					If g_activegadget.desy <= g.y Then Continue
				ElseIf a0 = 2
					If g.y <= g_activegadget.desy Then Continue
				ElseIf a0 = 3
					If g_activegadget.desx <= g.x Then Continue
				ElseIf a0 = 4
					If g.x <= g_activegadget.desx Then Continue
				EndIf
				Local d:Float = Dist2D(g_activegadget.desx, g_activegadget.desy, g.desx, g.desy)
				If d < bestd Or best = Null
					bestd = d
					best = g
				EndIf
			EndIf
		Next
	EndIf
	If best <> Null Then g_activegadget = best
EndIf
Return 0

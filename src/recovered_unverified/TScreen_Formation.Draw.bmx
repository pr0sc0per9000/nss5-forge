' TScreen_Formation.Draw
' VA 0x0054C38B   1704 bytes   mode=reloc   KIND=Function, SIG ()i, class-table slot 0x40
'
' Reconstructed from extracted/decomp/TScreen_Formation.Draw@0054c38b.c PLUS a manual
' re-disassembly of the original bytes (harness.disasm_original) -- Ghidra's pseudocode drops
' or misattributes several call arguments in this body (guide traps 1 and 2), so the shapes
' below were checked against the raw instructions, not just the decompiler's printed C.
'
' MODULE GLOBALS (address is fact; for every address the solver already reports more than
' one resolved name, none dominant enough to be unambiguous -- picked the reading below and
' recorded the runner-up):
'   0x00C677A0 g_formscreen:TScreen, 0x00C677A4 g_formbtn:TButton, 0x00C677A8 g_formlist:TList,
'     0x00C677AC g_imgArrow, 0x00C677B4 g_imgStar, 0x00C677B8 g_imgStar52,
'     0x00C677BC g_imgStar52Grey, 0x00C677C0 g_imgPitch:TImage, 0x00C677CC g_lblName,
'     0x00C677D0 g_lblValue:TLabel -- all SAME names/addresses as
'     src/recovered/TScreen_Formation.CreateScreen.bmx (that file's own header is the
'     strongest evidence for every one of these).
'   0x00C677B0 -- CERTAIN tier reports THREE names at this address (g_myteam 1 body,
'     g_playerteam 5 bodies unanimous, g_team 1 body); picked g_playerteam, the one with
'     the most supporting bodies (three of which are this SAME Type: AskBoss, ButtonPlay,
'     CheckPosition).
'   0x00C677D4 -- STRONG tier, THREE names each forced in exactly 1 body (g_fmt_sel,
'     g_formation_newstarselno, g_screen_formation_selno) -- a genuine 3-way tie. Picked
'     g_screen_formation_selno: the "g_screen_formation_*" prefix is the majority style
'     across this Type's OTHER globals (AskBoss/ButtonFormation/ButtonPlay/CancelRequest/
'     CheckPosition/RefreshButtons all use it; only ChangePosition and UpdatePosition use
'     the other two spellings).
'   0x00C677D8 -- STRONG tier, TWO names each forced in 1 body (g_fmt_lock,
'     g_screen_formation_ready). Picked g_screen_formation_ready for the same
'     majority-style reason.
'   0x00C677DC g_screen_formation_int06:Int -- STRONG, forced in 1 body but corroborated by
'     3 declaring bodies (ButtonPlay, CancelRequest, RefreshButtons) vs. 1 each for the two
'     runners-up (g_formation_selno, g_screen_formation_selno2) -- the clear winner here.
'   0x00C5DEAC -- CERTAIN g_player_arr01:Int[] (9 bodies, unanimous) vs. STRONG
'     g_defaultanim:Int[] (1 body) -- picked g_player_arr01. Read here as a bare Int
'     array index (see SHAPE NOTES).
'
' TYPE MEMBERS USED (already recovered/typed elsewhere, no pragma needed):
'   TTeam.squad :TList (+0x1C), TTeam.formation :TFormation (+0x24),
'     TTeam.newstarselno :Int (+0x3C) -- all per src/recovered/TScreen_Formation.
'     RefreshButtons.bmx / CheckPosition.bmx headers.
'   TFormation.m_TacPos :Int[] (+0x20, array data at +0x18) -- per
'     src/recovered/TFormation.LoadTactics.bmx header ("Self.m_TacPos +0x20 []i (array data
'     at +0x18)"); a 35-element flat grid (5 rows * 7 cols) of 0/1 "is this cell a valid
'     formation slot" flags, index = row-loop-count * 7 + col-loop-count (both 0-based).
'   TPlayer.selectionno :Int (+0xBC), .name :$ (+0x1C), .value :$ (+0x28),
'     .imgPlayer :TImage (+0x0C) -- object_model.json.
'   TDrawOb.x/.y/.z :Float, .img :TImage, .txt/.txt2 :String -- object_model.json /
'     src/recovered/TDrawOb.RenderAll.bmx. g_formlist is this Type's TList (only ever
'     created/cleared in CreateScreen/this body; consumed nowhere else in the Type).
'   TGadget.x/.y :Float (+0x20/+0x24), .txt :$ (+0x10), slot 0x44 = Draw()i -- object_model
'     .json; g_lblName/g_lblValue are floating TLabels never AddGadget-ed (per CreateScreen's
'     own header), positioned and drawn by hand here every frame.
' MODULE FUNCTIONS: AngleTo (src/recovered_module/AngleTo.bmx, 0x0050639D), Dist2D
'   (0x00505DA2, per src/recovered/TTeam.GetPlayerNearestToXY.bmx), SetDrawStateHex
'   (0x00506456, per src/recovered/TScreen_ReportPhysio.Draw.bmx).
' BRL: SetColor 0x005ADB6F, SetAlpha 0x005ADC28, SetScale 0x005AE0A8, SetRotation 0x005AE079,
'   DrawImage 0x005AD711, DrawImageRect 0x005AD7C8, ImageHeight 0x005AE3D4 (confirmed 1-arg
'   here by call_arity.tsv, NOT the 2-arg form some sibling headers assume), CreateList
'   0x005B40BF, Int() 0x005B9690.
'
' SHAPE NOTES
'   * The g_formlist reuse-or-create block: direct `cmp [g_formlist],<null>` (not
'     setne/movzx) is the `= Null` / plain-Else form (guide 10.3), and the raw bytes show
'     the post-branch `g_formlist = ...` store ONLY on the null path -- the Else path
'     (`.Clear()`) jumps straight past it. Ghidra's pseudocode shows an unconditional
'     store after the if/else; that is the decompiler folding two equal-valued paths, not
'     a byte the Else arm actually writes.
'   * `g_playerteam` / `g_playerteam.formation` truthiness in the AND-chain use the
'     setne/movzx "object truthiness" shape (guide 10.3 again) -- bare `g_playerteam`,
'     not `<> Null` -- while `d.img <> Null` later (direct cmp) IS the explicit-Null form,
'     matching TDrawOb.RenderAll's own `If d.img <> Null`.
'   * `g_playerteam.formation` is reloaded from scratch for the truthiness test AND again
'     for the m_TacPos read two lines later -- no CSE (documented elsewhere in this
'     project, e.g. CreateScreen.bmx's shape notes) -- so the dot-chain is written out
'     twice rather than cached in a Local.
'   * The frame argument to the sprite-drawing DrawImage is NOT part of TDrawOb at all --
'     Ghidra drops it completely. Raw bytes: `mov edx,[g_player_arr01]; mov
'     edx,[edx+0x18]; add edx,0x80` = `g_player_arr01[0] + 128`, read fresh every
'     iteration (not hoisted out of the loop, matching one instruction sequence per pass).
'   * The final arrow block's AngleTo() result is NOT dead despite Ghidra showing no
'     assignment -- raw bytes spill it to its own stack slot (`fstp [ebp-0x34]`) and
'     reload it several statements later for SetRotation, across an intervening SetAlpha
'     call. Declared as a Local for the same reason fVar11/Dist2D's result is (also
'     spilled, also reloaded across several statements).
'   * DrawImageRect's height argument is `ImageHeight(g_imgArrow)` (1 arg, not 2) --
'     confirmed against extracted/call_arity.tsv (30 call sites, all 4 bytes / 1 arg).
'     The literal frame arg (0) for that same call is pushed BEFORE the nested
'     ImageHeight() call in the raw bytes (evaluated right-to-left, nested call first),
'     which is why Ghidra's flat argument list drops it.
'   * Loop math: x = col*82-16, y = row*78+94 (0x52/0x10/0x4E/0x5E). Outer loop tests
'     `>= 1` (jge) i.e. `For row = 5 To 1 Step -1`; inner tests `<= 7` (jle) i.e.
'     `For col = 1 To 7`.
'   * BUG, preserved: raw disasm from 0x0054C842 (g_lblValue.txt = d.txt2 store) falls
'     straight through to the EachIn loop's HasNext check at 0x0054C860 -- there is NO
'     call to vtable+0x44 (Draw) on g_lblValue anywhere in the function. g_lblName IS
'     drawn by hand (call [eax+0x44] right after its .txt store, VA 0x0054C817), but
'     g_lblValue is positioned and text-set every frame and never rendered. Do not add
'     a g_lblValue.Draw() call here even though it looks symmetric with g_lblName.
'!Global g_formlist:TList
'!Global g_playerteam:TTeam
'!Global g_imgStar52:TImage
'!Global g_imgStar52Grey:TImage
'!Global g_imgPitch:TImage
'!Global g_imgArrow:TImage
'!Global g_lblName:TLabel
'!Global g_lblValue:TLabel
'!Global g_screen_formation_selno:Int
'!Global g_screen_formation_ready:Int
'!Global g_screen_formation_int06:Int
'!Global g_player_arr01:Int[]
	SetColor(255, 255, 255)
	SetAlpha(1.0)
	SetScale(1.0, 1.0)
	DrawImage(g_imgPitch, 10.0, 120.0, 0)

	If g_formlist <> Null Then
		g_formlist.Clear()
	Else
		g_formlist = CreateList()
	EndIf

	Local selno:Int = 1
	Local idx:Int = 0
	For Local row:Int = 5 To 1 Step -1
		For Local col:Int = 1 To 7
			Local x:Int = col * 82 + -16
			Local y:Int = row * 78 + 94
			If g_playerteam And g_playerteam.formation And g_playerteam.formation.m_TacPos[idx] = 1
				If selno = g_screen_formation_selno And g_screen_formation_ready = 0
					If g_playerteam.newstarselno < 11
						DrawImage(g_imgStar52, x, y, 0)
					Else
						DrawImage(g_imgStar52Grey, x, y, 0)
					EndIf
				EndIf
				Local ob:TDrawOb = New TDrawOb
				ob.x = x
				ob.y = y
				ob.z = selno
				For Local p:TPlayer = EachIn g_playerteam.squad
					If p.selectionno = selno
						ob.txt = p.name
						If Len(ob.txt) > 16 Then ob.txt = ob.txt[0..16]
						ob.txt2 = p.value
						ob.img = p.imgPlayer
					EndIf
				Next
				g_formlist.AddLast(ob)
				selno = selno + 1
			EndIf
			idx = idx + 1
		Next
	Next

	Local zoom:Float = 0.7
	SetScale(zoom, zoom)
	g_formlist.Sort()
	For Local d:TDrawOb = EachIn g_formlist
		If d.img <> Null
			DrawImage(d.img, d.x, d.y, g_player_arr01[0] + 128)
		EndIf
	Next

	SetScale(1.0, 1.0)
	For Local d:TDrawOb = EachIn g_formlist
		If d.txt <> ""
			Local px:Int = Int(d.x - 40.0)
			Local py:Int = Int(d.y + 5.0)
			g_lblName.x = px
			g_lblName.y = py
			g_lblName.txt = d.txt
			g_lblName.Draw()
			g_lblValue.x = px
			g_lblValue.y = py + 14
			g_lblValue.txt = d.txt2
		EndIf
	Next

	If g_screen_formation_ready = 0 And g_screen_formation_int06 > 0 And g_screen_formation_int06 <> g_screen_formation_selno
		Local sx:Float = 0.0
		Local sy:Float = 0.0
		Local tx:Float = 0.0
		Local ty:Float = 0.0
		For Local d:TDrawOb = EachIn g_formlist
			If d.z = g_screen_formation_selno
				sx = d.x
				sy = d.y
			EndIf
			If d.z = g_screen_formation_int06
				tx = d.x
				ty = d.y
			EndIf
		Next
		Local ang:Float = AngleTo(sx, sy, tx, ty)
		Local dist:Float = Dist2D(sx, sy, tx, ty)
		SetAlpha(0.25)
		SetRotation(ang)
		SetColor(255, 255, 255)
		DrawImageRect(g_imgArrow, sx, sy, dist, ImageHeight(g_imgArrow), 0)
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	EndIf

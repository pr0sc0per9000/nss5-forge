' UNVERIFIED -- TEngine.UpdateOffset
' VA 0x004CFB35   2004 bytes (Ghidra-authoritative)   slot 0x58   sig (f)i   KIND=Function (no Self)
' byte-identical vs NSS5.exe
' NOTE: this is a static Function on TEngine (declared with the Function keyword inside the
' Type body) -- per codegen-patterns.md 11.5 it is verified with harness.try_method, NOT
' try_function. This file is WRAPPED format; feed it through localise_diff._body_of() /
' reverify.body_of() before handing it to try_method/localise_body, or you get the
' "our_len 14" empty-stub trap (STATUS.md, codegen-patterns.md intro) because the pasted
' `Function ... End Function` wrapper nests inside the probe's own auto-generated wrapper.
'
' STATE: our_len 1999 vs orig 2004, delta -5, matched 1001/2004 via harness.try_method,
' first_diff=79. 13 length-changing gaps and 16 same-length substitutions remain
' (scripts/localise_diff.py), delta fully accounted for by the gaps. The prologue
' (`sub esp,0x4c`) matches the original's frame size exactly. NOT a MATCH; do not promote
' to src/recovered/.
'
' OPEN DISCREPANCIES (localise_diff offsets are ORIGINAL-relative):
'   * `+12/-12 @1623/1626`: in the pitch-edge clamp section (`basea`/`limita`/`baseb`/
'     `limitb`/`limitc`), the reload-add-store / reload-multiply-store sequence for `limita`
'     lands at a different position than the original's, even though every byte before it
'     matches. This is a register-allocation ordering question (codegen-patterns.md section
'     22, "the spill victim formula"), not a textual one -- some value used later in the
'     function is winning a different priority in the allocator's cost ranking than in the
'     original, without changing any bytes emitted before this point.
'   * `-3 @1198` and `+1 @1228/1283`: in the human-follow zoom recompute
'     (`g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * rate`), the
'     original keeps `basef` live on the x87 stack across the `g_options_int06` branch and
'     consumes it via `fxch st(1)` (2 bytes) in each arm; ours reloads it from memory
'     (`fld [mem]`, 3 bytes) instead. `basef` and `distf` also sit at very different slot
'     depths than the original's (SUBs at +1153/+1170/+1193), consistent with the same
'     allocator-ordering question above rather than a wrong expression shape.
'   * `-3 @760/816`, `+3 @772/828`: inside the setpiece `dx`/`dy` (Double) Cos/Sin
'     accumulation, the `Local dx:Double`/`dy:Double` slots sit 4 bytes deeper than the
'     original's (SUBs at +724/755/780/811) even though the instruction stream leading up to
'     them is byte-identical. Same allocator-ordering class as above; merging `dx`/`dy` into
'     one shared Double was tried and drops the frame by a whole qword (too much -- both
'     Doubles are genuinely separately live), so that is not the lever.
'   * `-3 @1330`, `+1 @1345/1365`: the human-follow X/Y target's own internal add
'     (`(human.x-bx)*ratex + bx`) uses `fadd [ebp-4]` (3B) where the original uses
'     `faddp st(1)` (2B) against the `bx`/`by` Locals; addend-first rewrites of this
'     expression (mirroring the zoom-recompute Globals above) only lengthen the body, so the
'     lever that closes it is not a simple operand-order swap.
'   * `p:TPlayer`/`winner:TTeam` (the `EachIn winner.squad` loop, camera mode 11) has not
'     been tested as a contributor to the allocator-ordering questions above: `winner` is
'     read twice (the Null guard, then `.squad`) and the decompiled call site is a single
'     call, so there is no behaviour-preserving way to drop the Local and re-test.
'
' The full register allocator (spill-cost formula, frame layout) is in this repo at
' tools/blitzmax-legacy-src/_src/codegen/cgallocregs.cpp and cgframe_x86.cpp; the open
' items above are all instances of its whole-function cost ranking choosing a different
' spill order than the original for a value whose own emitted bytes already match.
'
' Camera target/offset/zoom update, called once per match tick from TEngine.Update(0.1).
' Computes a target look-at point (campointx/y) from one of several sources selected by
' g_player_int01 (camera mode: 0..11), smooths TEngine's scroll offset toward it by a0 (dt),
' and clamps the offset to the pitch edges.
'
' FIELDS: TBall.x/y=0x18/0x1c, TBall.controlledby=0x70, TBall.setpiecetaker=0x80 (all verified
' via object_model.json). TPlayer.x/y=0x4c/0x50, TPlayer.selectionno=0xbc,
' TPlayer.directiontogoal_opp=0xe0 (verified). TTeam.newstarselno=0x3c (verified, matches the
' TTeam.New field-initialiser = -1 precedent already in the corpus).
'
' GLOBALS (all from extracted/globals_final.tsv unless noted):
'   g_engine_float01 0x00c5b1d4 zoom  g_engine_float02/03 0x00c5b1d8/dc offsetX/Y
'   g_engine_float04/05/06 0x00c5b1e0/e4/e8 prev-offsetX/Y/zoom (save-only, unread elsewhere in body)
'   g_engine_float10/11 0x00c73d3c/40 default target X/Y   g_engine_float12/13 0x00c73d44/48
'   g_campan_ratezoom2/ratezoomdefault 0x00c73d4c/50 and g_campan_ratex/ratey 0x00c73d54/58 --
'     OURS, not in globals_final.tsv (that table stops at g_engine_float13/0x00c73d48; these four
'     are the next 4 floats in the same contiguous block, unsurveyed). Type Float confirmed by
'     the disasm (all x87 dword loads).
'   g_player_int01 0x00c5b1fc mode (verified elsewhere as TPlayer's row, reused here as camera mode)
'   g_player_int16/17/19 0x00c5d634/38/58 (int19 is 0x00c5d658)
'   g_player_tplayer01 0x00c5b248 (verified TPlayer usage row)
'   g_hometeam/g_awayteam 0x00c5b218/1c (majority name in corpus; globals_typed.tsv confirms TTeam)
'   g_options_int06 0x00c5d24c   g_engine_int14/15/16 0x00c5b1ec/f0/f4
'   g_engine_int162/163 0x00c6efe4/e8 (pitch width/height)   g_training_int03 0x00c6cf90
'
' CALLS: TBall.GetActiveBall (slot 0x44), TEngine.GetWinningClub (0xf8), TEngine.SetPiece (0x74),
'   TPlayer.GetHumanPlayer (0x164), TTraining.GetFocus(:TPlayer,*f,*f)i (0xa8), TPitch.YardsToPixels
'   (0x6c), TPlayer.GetShootingDirection (0x160) -- all class-table-slot calls, masked by the
'   oracle. AngleTo/Dist2D/ClampFloat are the already-verified module Functions
'   (src/recovered_module/). _bbFloatToInt/_bbCos/_bbSin resolve via helper_map for the
'   Int()/Cos()/Sin() casts (_bbSin confirmed at 0x004A1F00).
'
' Run (feed through localise_diff._body_of() first -- this file is WRAPPED, see top-of-file note):
'   import localise_diff as L
'   r = L.localise_body('TEngine','UpdateOffset', L._body_of(THIS_FILE_PATH), max_gaps=30)
'   print(L.report(r))
' to get fresh disassembly windows for each open item above.
' (Passing the raw WRAPPED file text straight to localise_diff's CLI reads as our_len=14 --
' the empty-stub trap; do not let that read as a fresh regression.)
	Function UpdateOffset:Int(a0:Float)
		'!Global g_engine_float01:Float
		'!Global g_engine_float02:Float
		'!Global g_engine_float03:Float
		'!Global g_engine_float04:Float
		'!Global g_engine_float05:Float
		'!Global g_engine_float06:Float
		'!Global g_engine_float10:Float
		'!Global g_engine_float11:Float
		'!Global g_engine_float12:Float
		'!Global g_engine_float13:Float
		'!Global g_campan_ratezoom2:Float
		'!Global g_campan_ratezoomdefault:Float
		'!Global g_campan_ratex:Float
		'!Global g_campan_ratey:Float
		'!Global g_player_int01:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		'!Global g_player_int19:Int
		'!Global g_player_tplayer01:TPlayer
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_opt_playercam:Int
		'!Global g_engine_int14:Int
		'!Global g_engine_int15:Int
		'!Global g_engine_int16:Int
		'!Global g_engine_int162:Int
		'!Global g_engine_int163:Int
		'!Global g_training_int03:Int
		g_engine_float04 = g_engine_float02
		g_engine_float05 = g_engine_float03
		g_engine_float06 = g_engine_float01
		Local campointx:Float = g_engine_float10
		Local campointy:Float = g_engine_float11
		Local ball:TBall = TBall.GetActiveBall()
		If ball <> Null Then
			campointx = ball.x * g_engine_float01
			campointy = ball.y * g_engine_float01
			If g_player_int01 = 2 Then
				If ball.setpiecetaker <> Null Then
					campointx = ball.setpiecetaker.x * g_engine_float01
					campointy = ball.setpiecetaker.y * g_engine_float01
				EndIf
			ElseIf g_player_int01 = 8 Then
				If g_player_tplayer01 <> Null Then
					campointx = g_player_tplayer01.x * g_engine_float01
					campointy = g_player_tplayer01.y * g_engine_float01
				EndIf
			ElseIf g_player_int01 = 0 Then
				campointx = Float(-g_player_int16) * g_engine_float01
				campointy = g_engine_float12
			ElseIf g_player_int01 = 11 Then
				Local winner:TTeam = TEngine.GetWinningClub()
				If winner <> Null Then
					For Local p:TPlayer = EachIn winner.squad
						If p.selectionno = 5 Then
							campointx = p.x * g_engine_float01
							campointy = p.y * g_engine_float01
						EndIf
					Next
				Else
					campointx = Float(-g_player_int16) * g_engine_float01
					campointy = g_engine_float13
				EndIf
			Else
				If TEngine.SetPiece() And (ball.setpiecetaker <> Null) And (ball.controlledby = ball.setpiecetaker) Then
					Local distance:Int = 0
					Local angle:Int = ball.setpiecetaker.directiontogoal_opp
					Select g_player_int01
						Case 4
							distance = Int(TPitch.YardsToPixels(10.0))
						Case 6
							distance = Int(TPitch.YardsToPixels(10.0))
						Case 5
							distance = Int(TPitch.YardsToPixels(20.0))
							angle = Int(AngleTo(ball.setpiecetaker.x, ball.setpiecetaker.y, 0.0, Float(g_player_int19 * ball.setpiecetaker.GetShootingDirection())))
					End Select
					Local dx:Double = ball.x
					dx = dx + Cos(angle) * distance
					campointx = Float(dx * g_engine_float01)
					Local dy:Double = ball.y
					dy = dy + Sin(angle) * distance
					campointy = Float(dy * g_engine_float01)
				EndIf
			EndIf
			If (g_hometeam.newstarselno > -1 Or g_awayteam.newstarselno > -1) And g_opt_playercam > 0 Then
				Local human:TPlayer = TPlayer.GetHumanPlayer()
				If human <> Null And human.selectionno < 11 Then
					If TEngine.SetPiece() And (human = ball.setpiecetaker) Then
					Else
						If g_player_int01 <> 0 And g_player_int01 <> 7 And g_player_int01 <> 9 And g_player_int01 <> 10 Then
							If g_opt_playercam = 1 Then
								campointx = human.x * g_engine_float01
								campointy = human.y * g_engine_float01
							Else
								Local bx:Float = ball.x
								Local by:Float = ball.y
								If g_training_int03 <> 0 Then TTraining.GetFocus(human, Varptr bx, Varptr by)
								Local basef:Float = Float(g_engine_int163 - 100) / (TPitch.YardsToPixels(15.0) + Dist2D(bx, by, human.x, human.y))
								If g_opt_playercam = 2 Then
									g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoom2
									ClampFloat(Varptr g_engine_float01, 0.75, 1.75)
								Else
									g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoomdefault
									ClampFloat(Varptr g_engine_float01, 0.5, 1.25)
								EndIf
								campointx = bx + (human.x - bx) * g_campan_ratex
								campointy = by + (human.y - by) * g_campan_ratey
								campointx = campointx * g_engine_float01
								campointy = campointy * g_engine_float01
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If g_training_int03 <> 0 Then
				Local human2:TPlayer = TPlayer.GetHumanPlayer()
				If human2 <> Null Then
					Local fx:Float = human2.x
					Local fy:Float = human2.y
					TTraining.GetFocus(human2, Varptr fx, Varptr fy)
					campointx = fx * g_engine_float01
					campointy = fy * g_engine_float01
				EndIf
			EndIf
		EndIf
		campointx = campointx - (g_engine_int162 / 2)
		campointy = campointy - (g_engine_int163 / 2)
		g_engine_float02 = g_engine_float02 + (campointx - g_engine_float02) * a0
		g_engine_float03 = g_engine_float03 + (campointy - g_engine_float03) * a0
		Local basea:Float = Float(g_player_int16)
		Local limita:Float = (basea + TPitch.YardsToPixels(Float(g_engine_int14))) * g_engine_float01
		Local baseb:Float = Float(g_player_int17)
		Local limitb:Float = (baseb + TPitch.YardsToPixels(Float(g_engine_int15))) * g_engine_float01
		Local limitc:Float = (Float(g_player_int17) + TPitch.YardsToPixels(Float(g_engine_int16))) * g_engine_float01
		If -limita < limita - g_engine_int162 Then
			ClampFloat(Varptr g_engine_float02, -limita, limita - g_engine_int162)
		Else
			g_engine_float02 = Float(-(g_engine_int162 / 2))
		EndIf
		If -limitb < limitb - g_engine_int163 Then
			ClampFloat(Varptr g_engine_float03, -limitb, limitc - g_engine_int163)
		Else
			g_engine_float03 = Float(-(g_engine_int163 / 2))
		EndIf
	End Function

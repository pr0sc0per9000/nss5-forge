' TPrivateBitmapFont.DrawShadowText
' VA 0x00591DC2   666 bytes   vtable slot 0x38   sig ($,f,f,:TBitmapFont)i
' UNVERIFIED -- MISMATCH under NSS5_NO_LEARN=1. This body has never been moved out of
' src/recovered_unverified/ and must not be, and it carries no matched marker.
'
' DISPOSITION: EQUIVALENT, NOT MATCHING -- FINAL. Not an unfinished reconstruction and
' not a source defect. The emitted instruction stream IS the original's; the entire
' residual is 4 single-byte ebp displacements, three spilled locals landing in a
' different order inside an identical stack frame, decided by floating-point rounding
' inside bcc.exe that no BlitzMax source can reach. Do not run another variant sweep.
'     Disposition : docs/reference/fontmachine-drawtext-disposition.md
'     Mechanism   : docs/reference/spill-tie-x87-precision.md
'
' RE-MEASURED INDEPENDENTLY, worker 384, NSS5_NO_LEARN=1, 2026-08-22:
'   harness.try_method -> MISMATCH, mode=diff, length 666 = 666 exact, first_diff=+87,
'   positional matched=604/666. Both images disassembled in full and aligned:
'     * 210 instructions on each side, identical boundaries, and ZERO mnemonic or
'       instruction-length differences anywhere in the body. No gap, no realignment.
'     * all 62 differing bytes classified, none left over:
'          4  ebp displacement bytes
'         31  call/jmp rel32 operand bytes, over 14 call sites -- EVERY target
'             adjudicated by name on both sides: 0 disagreements, 0 unproven
'         27  absolute in-image address bytes, 3 distinct address pairs -- all three
'             resolve to the same pointee on both sides (bbNullObject, the
'             TDrawingPoint class table, the TDrawCharAction class table)
'     * `sub esp, 0x24` is among the bytes that AGREE, so the frame is the same size.
'       Two of its slots are swapped, nothing else.
'   Deterministic: rebuilt into a second work directory, our bytes identical.
'   Behaviour therefore cannot differ: same instructions, same callees, same data.
'
' TWO NUMBERS, BOTH HONEST. "662 of 666" is the count AFTER relocations and calls are
' masked; harness's positional matched is 604/666 because it counts raw byte equality
' and every relocated address counts against it. They measure different things.
'
' OFFSET CONVENTION. The list below (+85 +101 +378 +640) is INSTRUCTION START offsets.
' The byte that actually differs is the disp8 two bytes later, at +87 +103 +380 +642,
' which is why first_diff is +87 and not +85. Both readings are correct.
'
' THE RESIDUAL IS x87 EXCESS PRECISION INSIDE bcc.exe. NOT THIS SOURCE, AND NOT THE HEAP.
' Length is exact, there are no gaps, and every instruction is the original's. The whole
' difference is 4 single-byte ebp displacements, at ORIGINAL offsets +85, +101, +378 and +640,
' and they are three values landing in a different SPILL ORDER:
'   ours   -0x1c hasfx   -0x18 origin  -0x14 limit
'   orig   -0x1c limit   -0x18 origin  -0x14 hasfx
' (`limit` is the For loop's cached a0.Length temp. The DEEPEST slot belongs to the value
' spilled FIRST: allocLocal hands out -4 first and selectRegs pops `_selected` from pred.)
'
' Full write-up, with the disassembly and the controlled experiment:
'     docs/reference/spill-tie-x87-precision.md
'
' 1. THE TIE IS EXACT, AND IT IS EXACT AT THE DECISION POINT. Read off the compiler's own
'    WALLOC_SPILLCAND lines, which print degree LIVE as spill() saw it, not createGraph's
'    starting degree:
'        limit, origin AND hasfx all carry usage=11 degree=43 block_count=26,
'        i.e. cost 11/1118 for each -- a THREE-WAY exact tie on all three inputs.
'    This CORRECTS what this header used to say. The old claim that `origin` is "not tied,
'    it carries exactly three more interference edges" is a reading of WALLOC_NODE, taken
'    at graph build; by the time spill() runs decDegree has equalised all three.
'
' 2. THE TIE-BREAK IS A ROUNDING DIRECTION. bin/bcc.exe's own spill() cost loop, at VA
'    0x0041eddb, is:
'        fild [edi+0x1c] / fild [edi+0x24] / fmulp / fdivr [edi+0x20]  -> st(0), EXTENDED
'        fcom dword [esp+0x14]                                          -> min, a FLOAT32 slot
'        ... fstp dword [esp+0x14]                                      -> min = (float)cost
'    `cost` is never rounded; `min` always is. So on an exact tie the comparison is q
'    (extended) against float32(q), and it is decided by which way q rounds:
'        rounds UP   -> `cost < min` true  -> the LAST tied candidate wins
'        rounds DOWN -> false              -> the FIRST tied candidate wins
'    Here the _spill list order is limit, origin, hasfx, and 11/1118 rounds UP while the
'    follow-on call's 11/1092 rounds UP. Predicted pick order: hasfx, origin, limit. That is
'    exactly the slot map our build produces, and the same rule predicts all nine slot
'    assignments across the three Draw*Text bodies correctly.
'
' 3. CONTROLLED EXPERIMENT, no I/O involved. One private-tree bcc, one env var apart, the
'    gated line being `if( fp32On() ){ volatile float _r32=cost; cost=_r32; }` -- i.e.
'    force the float32 round and nothing else. Differing ebp displacements for this body:
'        4 -> 0 (the original's exact frame layout)
'    Gate OFF reproduces the shipped compiler byte for byte at the same offsets, so the
'    patched binary is its own control. This also explains the old WALLOC_TRACE=1
'    "deciding experiment" in this header: `cerr << cost` forces cost through a 32-bit
'    slot before the compare, so the trace was measuring this rounding all along.
'
' 4. REFUTED: the heap-layout story this header used to tell. cgallocregs.cpp holds nodes
'    in `static vector<Node> nodes;` and every NodeSet member is `&nodes[k]`, so
'    set<Node*> iterates in INDEX order, which is register-id order, on every run. There
'    is no heap-order dependence in the allocator.
'
' 5. REFUTED as a fix: making the comparison float32 on both sides (the genuine 1.49 bcc's
'    SSE semantics). Control sample, same tree, serial: 12/12 matched bodies 14..1321
'    bytes hold, but only 10 of the 16 LARGEST matched bodies do -- it breaks
'    TScreen_Stats.UpdateStatTable, TPlayer.RecordPlayerStats,
'    TTeam.UpdatePlayerDestinations, TEngine.RenderScoreboard,
'    TScreen_Controls.CreateScreen and TPitch.SetUp. The shipped x87 build is CLOSER to
'    the original than a float32-exact one is.
'
' 6. NO SOURCE LEVER EXISTS. usage, degree and block_count are all fixed by the emitted CG
'    stream, and that stream is already the original's. Measured on DrawShadowText, the
'    liveness/statement-placement axis included:
'      * origin computed immediately before the For: length exact, tie UNCHANGED,
'        first_diff +87 -> +39 (worse).
'      * limit hoisted to `Local n` + `While i <= n`: length exact, bytes identical to the
'        committed form, block_count 26 -> 25 FOR ALL THREE TIED VALUES AT ONCE, tie intact.
'      * hasfx defined inside the loop body: 664 bytes (-2). Tie broken, code wrong.
'      * hasfx read at the loop top through a copy: 668 (+2). Tie broken, code wrong.
'      * origin read at the loop top through a copy: 667 (+1). Tie broken, code wrong.
'    The reason is structural: a value defined before a loop and read inside it is live-in
'    AND live-out of every block of that loop, because the back edge reaches the read again
'    from anywhere in the body. Its block_count is the loop's block count wherever the read
'    sits, and it is the SAME number for every value in that position -- which is why the
'    While rewrite moved block_count for all three at once and left the tie exactly as it
'    was. codegen-patterns 22.3's "block_count is a statement-placement lever" does not
'    apply to a value in this position.
'    Earlier passes also measured inert: declaration order of hasfx (4 variants),
'    declaration position of the loop limit (moves its register id 27 -> 20, changes
'    nothing), loop form (3 variants), node-count perturbation (5 variants), Local names,
'    three spellings of the New TDrawingPoint pair, and a determinism re-run.
'    docs/reference/allocator-knob-sweep.md rules out all six allocator knobs.
'
' 7. A SECOND, INDEPENDENT BLOCKER, invisible until the first is removed. helper_map.py's
'    orig_functions() scans src/recovered_module/ for `' VA 0x...` headers and never scans
'    src/recovered_thirdparty/. Fontmachine's four module-level helpers -- 0x00592A13,
'    0x00592A37, 0x00592B79, 0x00592B87, two of which every glyph goes through -- are
'    therefore unnameable on the original side, so their E8 rel32 operands cannot mask
'    under NSS5_NO_LEARN=1. With the allocator gate on, DrawShadowText still reports
'    MISMATCH at +369, and its only remaining differing bytes are 21 absolute-address and
'    29 call-rel32 bytes. Adding those four rows IN MEMORY from the files' own headers
'    (a diagnostic, not a verification, and nothing was changed on disk) takes the same
'    build to MATCH, mode=reloc, 666/666. Fix that before attacking the allocator again.
'
' CONSEQUENCE FOR walloc_report.py. Its usage/degree/block_count readings are sound, but
' WALLOC_TRACE=1 changes the compilation it is reporting on: the trace's own `cerr << cost`
' rounds the spill cost to float32 and can therefore flip a tie. Read the numbers, do not
' read the outcome. Its docstring's `std::set<Node*>` heap-order hypothesis is refuted by
' point 4 above.
'
' VERDICT: not reachable from source with any toolchain available to this project.
' Re-measured 2026-08-22, worker 276; the residual independently re-measured and
' the whole body adjudicated byte by byte 2026-08-22, worker 384. Dispositioned as
' EQUIVALENT, NOT MATCHING -- docs/reference/fontmachine-drawtext-disposition.md.
' THIRD-PARTY MODULE (fontmachine) -- do not move this into src/recovered/ even if it
' ever matches. src/recovered_thirdparty is its home.
'
' WHAT IT DOES. Walks the string a character at a time and blits Shadow[c].Image at the
' running pen position, rotated about the line start by RenderStatus.Rotation. Character
' 10 is a hard line break: it advances y by one line and TAIL-RECURSES on the remainder
' from the saved left margin. Unlike its Border and Face siblings it has no
' PhisicalPixelRounding path and never touches SetScale.
'
' ASSUMPTIONS AND SHAPE NOTES (each of these changes the bytes):
'  * a0=text, a1=x, a2=y, a3=the owning TBitmapFont. a1 and a2 are the running pen and
'    are written through as parameters; only the line-start x is copied to a Local.
'  * The DOUBLE `New TDrawingPoint` is the original's. The first result is discarded --
'    a dead Local -- and bcc does not eliminate it because bbObjectNew has side effects.
'    Written as one New the body is 13 bytes short.
'  * `a2 = a2 + ... + ...` in the newline branch but `a1 :+ ... + ...` at the end. The
'    two are not interchangeable: `:+` computes the whole right side first and then adds,
'    the plain form loads the accumulator first (codegen-patterns 16.1), and the original
'    uses one of each.
'  * The Shadow[c] / Shadow[c].Image guards are NESTED Ifs, not an `And` chain. An `And`
'    materialises its operands through setcc/movzx; only `c >= 0 And c < Face.Length`
'    does that here.
'
' BUG (original): the FX path re-reads `act.Char` and then tests `Face[c] <> Null` before
' drawing `Shadow[c].Image` -- the wrong array for the guard. Preserved.

	Method DrawShadowText:Int(a0:String, a1:Float, a2:Float, a3:TBitmapFont)
		Local startx:Float = a1
		Local sx:Float = RenderStatus.ScaleX
		Local sy:Float = RenderStatus.ScaleY
		Local origin:TDrawingPoint = Fn_00592A13(a1, a2)
		Local rot:Float = RenderStatus.Rotation
		Local hasfx:Int = a3.RenderFX <> Null
		For Local i:Int = 1 To a0.Length
			Local c:Int = Asc(Mid(a0, i, 1))
			If c >= 0 And c < Face.Length
				If c = 10
					a2 = a2 + Face[32].DrawHeight * sy + a3.Kerning.PrivateData.VKF * sy
					DrawShadowText(Mid(a0, i + 1, -1), startx, a2, a3)
					Return 0
				End If
				If Shadow[c] <> Null
					If Shadow[c].Image <> Null
						Local dead:TDrawingPoint = New TDrawingPoint
						Local p:TDrawingPoint = New TDrawingPoint
						p.X = a1
						p.Y = a2
						Local pt:TDrawingPoint = Fn_00592A37(rot, p, origin)
						If hasfx = 0
							DrawImage(Shadow[c].Image, pt.X, pt.Y, 0)
						Else
							Local act:TDrawCharAction = New TDrawCharAction
							act.Char = c
							act.font = a3
							act.Handled = 0
							act.Status = 4
							act.X = pt.X
							act.Y = pt.Y
							Local fx:iTextRendererFXBase = a3.RenderFX
							While fx <> Null
								fx.DrawShadowChar(act)
								fx = fx.ChainFX
							Wend
							c = act.Char
							If act.Handled = 0
								If Face[c] <> Null
									DrawImage(Shadow[c].Image, act.X, act.Y, 0)
								End If
							End If
						End If
						If Face[c] <> Null
							a1 :+ Face[c].Charwidth * sx + a3.Kerning.PrivateData.HKF * sx
						End If
					End If
				End If
			End If
		Next
	End Method

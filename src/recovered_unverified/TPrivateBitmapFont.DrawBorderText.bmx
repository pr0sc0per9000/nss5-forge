' TPrivateBitmapFont.DrawBorderText
' VA 0x00591917   1195 bytes   vtable slot 0x34   sig ($,f,f,:TBitmapFont)i
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
'   harness.try_method -> MISMATCH, mode=diff, length 1195 = 1195 exact, first_diff=+87,
'   positional matched=1086/1195. Both images disassembled in full and aligned:
'     * 375 instructions on each side, identical boundaries, and ZERO mnemonic or
'       instruction-length differences anywhere in the body. No gap, no realignment.
'     * all 109 differing bytes classified, none left over:
'          4  ebp displacement bytes
'         78  call/jmp rel32 operand bytes, over 32 call sites -- EVERY target
'             adjudicated by name on both sides: 0 disagreements, 0 unproven
'         27  absolute in-image address bytes, 3 distinct address pairs -- all three
'             resolve to the same pointee on both sides (bbNullObject, the
'             TDrawingPoint class table, the TDrawCharAction class table)
'     * the prologue's frame-size immediate is among the bytes that AGREE, so the frame
'       is the same size. Two of its slots are swapped, nothing else.
'   Deterministic: rebuilt into a second work directory, our bytes identical.
'   Behaviour therefore cannot differ: same instructions, same callees, same data.
'
' TWO NUMBERS, BOTH HONEST. "1191 of 1195" is the count AFTER relocations and calls are
' masked; harness's positional matched is 1086/1195 because it counts raw byte equality
' and every relocated address counts against it. They measure different things.
'
' OFFSET CONVENTION. The list below (+85 +101 +384 +1169) is INSTRUCTION START offsets.
' The byte that actually differs is the disp8 two bytes later, at +87 +103 +386 +1171,
' which is why first_diff is +87 and not +85. Both readings are correct.
'
' THE RESIDUAL IS x87 EXCESS PRECISION INSIDE bcc.exe. NOT THIS SOURCE, AND NOT THE HEAP.
' Length is exact, there are no gaps, and every instruction is the original's. The whole
' difference is 4 single-byte ebp displacements, at ORIGINAL offsets +85, +101, +384 and +1169,
' and they are three values landing in a different SPILL ORDER:
'   ours   -0x54 limit   -0x50 hasfx   -0x4c origin
'   orig   -0x54 hasfx   -0x50 limit   -0x4c origin
' (`limit` is the For loop's cached a0.Length temp. The DEEPEST slot belongs to the value
' spilled FIRST: allocLocal hands out -4 first and selectRegs pops `_selected` from pred.)
'
' Full write-up, with the disassembly and the controlled experiment:
'     docs/reference/spill-tie-x87-precision.md
'
' 1. THE TIE IS EXACT, AND IT IS EXACT AT THE DECISION POINT. Read off the compiler's own
'    WALLOC_SPILLCAND lines, which print degree LIVE as spill() saw it, not createGraph's
'    starting degree:
'        limit, origin AND hasfx all carry usage=11 degree=73 block_count=29,
'        i.e. cost 11/2117 for each -- a THREE-WAY exact tie on all three inputs.
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
'    Here the _spill list order is limit, origin, hasfx, and 11/2117 rounds DOWN while the
'    follow-on call's 11/2088 rounds UP. Predicted pick order: limit, hasfx, origin. That is
'    exactly the slot map our build produces, and the same rule predicts all nine slot
'    assignments across the three Draw*Text bodies correctly.
'
' 3. CONTROLLED EXPERIMENT, no I/O involved. One private-tree bcc, one env var apart, the
'    gated line being `if( fp32On() ){ volatile float _r32=cost; cost=_r32; }` -- i.e.
'    force the float32 round and nothing else. Differing ebp displacements for this body:
'        4 -> 34 (worse)
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
' 8. THE MIRROR VARIANT WAS BUILT AND MEASURED, 2026-08-23. It is REFUTED as a fix, and
'    it is the last of the candidate semantics -- there is nothing further to try here.
'    spill-tie-x87-precision.md section 6 conjectured that the bcc.exe which built
'    NSS5.exe gave `cost` and `min` the OPPOSITE treatment from ours: cost ROUNDED to
'    float32, min kept UNROUNDED at x87 extended precision, so a later tied candidate
'    wins iff the quotient rounds DOWN -- the exact complement of our build's rule. That
'    variant had never been built. It has now been, gated behind WALLOC_MIRROR in a
'    private worker copy of cgallocregs.cpp, written explicitly rather than left to the
'    host compiler:
'        volatile float _c32=cost;                       // the compared value, rounded
'        long double costx=(long double)t->usage
'            /((long double)t->degree*(long double)t->block_count);
'        if( (long double)_c32 < minx ){ node=t; minx=costx; }   // incumbent UNROUNDED
'    Assigning costx and not _c32 to the incumbent is the whole point; assigning _c32
'    degenerates to float32-on-both-sides, which is WALLOC_FP32 and already refuted.
'
'    GATE OFF IS A PROVEN CONTROL. The rebuilt bcc with WALLOC_MIRROR unset reproduces the
'    shipped compiler's codegen on every body measured: 12/12 small matched bodies
'    (14..1,395 bytes), 16/16 of the largest matched bodies (5,021..16,301), and all three
'    Draw*Text residuals at their exact documented lengths, first_diff and matched counts.
'
'    ON THE THREE TRACKED SPILL SLOTS THE MIRROR IS RIGHT, AND EXACTLY AS PREDICTED --
'    7 of 9, scoring Shadow 3/3, Border 3/3, Face 1/3, which is what the analytic grid in
'    scratch/spill-semantics-grid.md predicted before the build. The grid's open question,
'    whether the pick-2 cost denominators shift on the mirror's own trajectory, is now
'    measured and the answer is NO: the WALLOC_SPILLCAND degrees at pick 2 are 42/72/89
'    under both gates, unchanged, because the three tied values all interfere with one
'    another and decDegree therefore decrements the survivors equally whichever is
'    removed. DrawFaceText's pick 2 is consequently NOT reachable by any rule whose
'    deciding quantity is a float32 rounding direction: 11/2088 (Border) and 11/2759
'    (Face) present the same two candidates in the same order and BOTH round UP in
'    float32, so any such rule must answer them the same way, and the original answers
'    them differently. Only the binary64 direction separates them. An exhaustive search
'    over 400 semantics -- every pair of values built from the quotient by composing at
'    most two roundings drawn from {float32, binary64, x87-extended, exact}, both
'    comparison operators, both list orders -- scores 0 at 9/9 and tops out at exactly the
'    mirror's 7/9. See scripts/probes/spilltie_semantics.py and spilltie_exhaustive.py.
'
'    AND IT IS STILL A NET LOSS, for a reason the arithmetic could not have shown. The
'    mirror does not only move the tie among these three values; it moves every other tie
'    in the program the same way. Measured, same tree, one env var apart:
'        12/12 small matched bodies hold under both gates.
'        16/16 of the largest matched bodies hold with the gate OFF; only 10/16 with it
'        ON. Broken: TScreen_Stats.UpdateStatTable, TPlayer.RecordPlayerStats,
'        TEngine.RenderScoreboard, TScreen_Controls.CreateScreen, TPitch.SetUp,
'        TPlayer.CheckBallContact -- five of them the same bodies WALLOC_FP32 broke.
'    Closing at most one body while breaking six of the sixteen that matter most is the
'    same verdict allocator-knob-sweep.md's scoring rule returns for WALLOC_FP32. THE
'    SHIPPED COMPILER STAYS. The patched compiler was reverted and the worker slot's
'    bcc.exe restored to the shipped binary, md5 confirmed, build intermediates removed.
'
'    FOR THIS BODY SPECIFICALLY: the mirror gets all three of the tracked integer slots
'    right -- the 4 ebp bytes at +87, +103, +386 and +1171 all become the original's --
'    and the body still does not match, because the same rule simultaneously rotates a
'    SECOND group of spilled values that was already correct: the float temporaries at
'    -0x30/-0x2c/-8/-4 and the doubles at -0x20/-0x18/-0x10. Differing ebp bytes go from
'    4 (gate OFF) to 28 (gate ON), first_diff +87 -> +444. That second group is the part
'    no arithmetic on the three published quotients could have predicted, and it is why
'    "the mirror closes Border outright" was wrong.
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
' The same walk as DrawShadowText over the Border layer, plus the PhisicalPixelRounding
' path: when the font asks for it the glyph is placed on whole DEVICE pixels by
' temporarily dropping the virtual resolution, rounding both the scale factors and the
' destination, drawing, then putting resolution and scale back.
'
' ASSUMPTIONS AND SHAPE NOTES (each of these changes the bytes):
'  * Fn_00592B87 is the round-half-away-from-zero helper; see its own file.
'  * The rounding path's arithmetic is DOUBLE and the casts have to be written out. Both
'    operands of `Fn_00592B87(...) / Image.width` are Int, so without `Double(...)` bcc
'    emits `idiv` where the original has fild/fild/fdivp; and `Double(sx) * GraphicsWidth()`
'    must be Double at the multiply or the spill across the call is a 4-byte `fstp dword`
'    instead of the original's 8-byte `fstp qword`. `Double(x) * y` and `x / Double(y)`
'    are interchangeable spellings -- the bytes cannot say which side the original cast.
'  * `a1 = startx` is an explicit statement here and the recursive call passes a1;
'    DrawShadowText passes the saved margin directly instead. The difference is visible.
'  * act.CurrentScaleY is assigned BEFORE act.CurrentScaleX (offsets 0x18 then 0x14).
'    DrawFaceText does it the other way round.
'
' BUG (original): as in DrawShadowText, the FX path guards on `Face[c]` and draws
' `Border[c].Image`. Preserved.

	Method DrawBorderText:Int(a0:String, a1:Float, a2:Float, a3:TBitmapFont)
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
					a1 = startx
					a2 = a2 + Face[32].DrawHeight * sy + a3.Kerning.PrivateData.VKF * sy
					DrawBorderText(Mid(a0, i + 1, -1), a1, a2, a3)
					Return 0
				End If
				If Border[c] <> Null
					If Border[c].Image <> Null
						Local dead:TDrawingPoint = New TDrawingPoint
						Local p:TDrawingPoint = New TDrawingPoint
						p.X = a1
						p.Y = a2
						Local pt:TDrawingPoint = Fn_00592A37(rot, p, origin)
						If hasfx = 0
							If a3.PhisicalPixelRounding = 0
								DrawImage(Border[c].Image, pt.X, pt.Y, 0)
							Else
								Local vrw:Float = VirtualResolutionWidth()
								Local vrh:Float = VirtualResolutionHeight()
								Local sxpos:Float = pt.X * (GraphicsWidth() / vrw)
								Local sypos:Float = pt.Y * (GraphicsHeight() / vrh)
								SetVirtualResolution(GraphicsWidth(), GraphicsHeight())
								Local xscale:Double = Double(sx) * GraphicsWidth() / vrw
								Local yscale:Double = Double(sy) * GraphicsHeight() / vrh
								xscale = Double(Fn_00592B87(xscale * Border[c].Image.width)) / Border[c].Image.width
								yscale = Double(Fn_00592B87(yscale * Border[c].Image.height)) / Border[c].Image.height
								SetScale(xscale, yscale)
								DrawImage(Border[c].Image, Fn_00592B87(sxpos), Fn_00592B87(sypos), 0)
								SetVirtualResolution(vrw, vrh)
								SetScale(sx, sy)
							End If
						Else
							Local act:TDrawCharAction = New TDrawCharAction
							act.Char = c
							act.font = a3
							act.Handled = 0
							act.Status = 2
							act.X = pt.X
							act.Y = pt.Y
							act.CurrentScaleY = RenderStatus.ScaleY
							act.CurrentScaleX = RenderStatus.ScaleX
							Local fx:iTextRendererFXBase = a3.RenderFX
							While fx <> Null
								fx.DrawBorderChar(act)
								fx = fx.ChainFX
							Wend
							c = act.Char
							If act.Handled = 0
								If Face[c] <> Null
									DrawImage(Border[c].Image, act.X, act.Y, 0)
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

' TEngine.UpdateOffsetReplay -- verified MATCH (1088/1088, mode=reloc, reloc_masked=65) via
' harness.try_method against a private probe build. Ready to move to
' src/recovered/ once this pass's other in-flight bodies are reconciled (left in
' recovered_unverified/ per this task's file-ownership rule -- only this file was touched).
' VA 0x004D4F09   orig length 1088 bytes (Ghidra-authoritative).
' KIND=Function (static, no Self), SIG (f)i, class-table slot 0xac.
'
' THIS PASS: re-derived the whole tail (everything from the sx/sy target computation
' onward) directly from a full disassembly of the original (scripts/disasm.py 0x004D4F09..end)
' plus scripts/localise_diff.py's gap alignment, instead of trusting the previous pass's
' "confirmed correct" claim for that region -- it was not correct; 9 of the 10 gaps the tool
' reported sat inside it. Went in at 50/1066 (4.7%), 10 gaps, delta -22.
'
' HEAD (untouched, genuinely gap-free per localise_diff -- do not touch without re-diffing):
'   g_oldcamx=g_camx (0x00C5B1E0=0x00C5B1D8); g_oldcamy=g_camy (E4=DC); g_oldcamz=g_camz (E8=D4)
'   Local tx:Float = g_cam_offx (0x00C74298); Local ty:Float = g_cam_offy (0x00C7429C)
'   If g_player_int01(0x00C5B1FC) = 8 And g_players(0x00C5DE10) <> Null
'       For Local p:TPlayer = EachIn g_players
'           For Local rf:TReplayFrame = EachIn p.replayframes   ' TPlayer+0x160
'               If rf.frametime = g_replayframe(0x00C5B2C8) And rf.active   ' +8, +0x58
'                   tx = p.x ; ty = p.y   ' TPlayer+0x4C/+0x50
'                   Exit
'   ElseIf g_balls(0x00C5A4C0) <> Null   ' identical shape, TBall+0xAC replayframes,
'                                          TBall+0x18/0x1C = x/y
'
' TAIL -- REWRITTEN this pass. Traced by hand off the raw x87 opcode sequence (not the
' Ghidra C, which normalises commutative-add order per codegen-patterns.md 10.1/23.4):
'   * `_DAT_00c5b1d8 = ((local_24*camz - half) - _DAT_00c5b1d8)*a0 + _DAT_00c5b1d8` is Ghidra's
'     canonical printing. The ACTUAL bytes `fld[camx]; fxch st(2); fsub[camx]; fmul[a0];
'     faddp st(2); fxch st(1); fstp[camx]` push g_camx FIRST (before sx/sy are even computed),
'     then reuse that SAME stack slot for the final add via `faddp` instead of a fresh
'     `fld[camx]`/`fadd`. That is the ADD-FIRST source form `g_camx = g_camx + (sx-g_camx)*a0`,
'     confirmed independently against the (unverified, but far along) sibling
'     src/recovered_unverified/TEngine.UpdateOffset.bmx, which needed the identical lever for
'     its own g_engine_float02/03 smoothing and documents it at length (its FIX #7/#8).
'   * sx/sy (tx*camz-halfw, ty*camz-halfh) are two Float Locals with NO explicit name in the
'     decompile -- they never get an ebp-relative store, they just live on the x87 stack across
'     both the g_camx AND g_camy statements (sx pushed, then sy pushed on top, then camx's
'     block reaches under sy via `fxch st(2)`). Declaring them as ordinary `Local sx:Float=...`/
'     `Local sy:Float=...` right before the two assignments reproduces this: nothing here
'     forces a spill (only 2 live values, 8 x87 registers).
'   * boundx/boundy1/boundy2 (fVar1/fVar2/fVar3): globals_final.tsv resolves 0x00C6EFE4/E8 to
'     g_engine_int162/163 and 0x00C5D634/638 to g_player_int16/17 (the previous pass's
'     g_screenw/g_screenh/g_pitch_halfw/g_pitch_halfh/g_cam_marginx/y1/y2 do not exist in any
'     name table -- minted, per the task's own warning against that). boundy1 and boundy2 each
'     do their OWN fresh `mov eax,[0xc5d638]` (11-byte Int->Float conversion, store to a new
'     slot) rather than sharing one Local -- bcc has no CSE, so a single shared `baseb` Local
'     referenced twice would show as a 3-byte `fld [slot]` the second time, which is not what
'     the original does. UpdateOffset.bmx's shared-`baseb` version of this exact idiom is
'     therefore not being copied here; this body's own bytes settle it directly.
'   * The two final If/Else guards: codegen-patterns.md section 21 "solo relational If/Else
'     branch-swap rule" -- a lone `setae` test guarding two DIFFERENT branches compiles from
'     `If x < y Then <false-branch> Else <true-branch>`, not the naive `If x>=y Then T Else F`.
'     The original's real branch order (confirmed straight off the bytes: the FALLTHROUGH after
'     `jne` runs the ClampFloat call, the jump target is the `-(half)` default) is
'     `If -boundx < boundx-g_engine_int162 Then ClampFloat(...) Else g_camx=Float(-(half))`,
'     the mirror of the previous draft's `If boundx-scr<=-boundx Then default Else Clamp` --
'     same truth table, opposite physical branch order, and bcc is not indifferent to that.
'   * The `-(half)` default is computed as Int (div-by-2-with-sign-correction, then `neg`) and
'     ONLY THEN converted with `fild` -- i.e. `Float(-(g_engine_int162 / 2))`, matching the
'     `neg eax` sitting BEFORE `fild` in the original.
'
' GAP 7 SOLVED this pass (the last -12 bytes, at ORIGINAL+45 / VA 0x004D4F36, right after the
' three g_oldcam* stores and before the tx/ty defaults):
'     A1 E4 EF C6 00   mov eax, [g_engine_int162]      (0x00C6EFE4)
'     99               cdq
'     A1 E8 EF C6 00   mov eax, [g_engine_int163]      (0x00C6EFE8)
'     99               cdq
'   Two hypotheses tested and disproven empirically before this one (harness.try_method /
'   localise_diff, private probe): a bare `Local x:Int = g_engine_int162`
'   (unused) is eliminated ENTIRELY by bcc's front end -- 0 bytes, not 6. `Local x:Long =
'   g_engine_int162` (unused) is not inline at all -- Int->Long goes through a runtime helper
'   call (`call 0x4f62a0`), nothing like cdq alone. The one that reproduced the bytes exactly
'   (CLEAN / MATCH, confirmed via harness.try_method): a DIVISION, still unused --
'       Local hw:Int = g_engine_int162 / 2
'       Local hh:Int = g_engine_int163 / 2
'   -- i.e. bcc's dead-Local elimination only special-cases a bare copy (no operation); once
'   the initialiser is a real computation, it evaluates through `mov eax,[G]; cdq` (loading the
'   dividend and sign-extending it for the correction) and THEN drops the rest (`and edx,1;
'   add eax,edx; sar eax,1` and the store) because the destination is dead -- an oddly surgical
'   half-elimination, but confirmed byte-for-byte, twice (`hw` mirrors the g_camx-block half-
'   width and `hh` the g_camy-block half-height, i.e. genuinely vestigial declarations of the
'   SAME two Locals the function computes for real, twice more, later).
'
' RESULT: 1088/1088, MATCH, mode=reloc, reloc_masked=65 (harness.try_method,
' private probe). Re-verify with a fresh isolated build before promoting out of
' recovered_unverified/, per this task's own instructions -- this was checked in isolation,
' not against the shared assembled.exe.
	'!Global g_camx:Float
	'!Global g_camy:Float
	'!Global g_camz:Float
	'!Global g_oldcamx:Float
	'!Global g_oldcamy:Float
	'!Global g_oldcamz:Float
	'!Global g_cam_offx:Float
	'!Global g_cam_offy:Float
	'!Global g_player_int01:Int
	'!Global g_players:TList
	'!Global g_balls:TList
	'!Global g_replayframe:Int
	'!Global g_engine_int162:Int
	'!Global g_engine_int163:Int
	'!Global g_player_int16:Int
	'!Global g_player_int17:Int
	'!Global g_engine_int14:Int
	'!Global g_engine_int15:Int
	'!Global g_engine_int16:Int
	g_oldcamx = g_camx
	g_oldcamy = g_camy
	g_oldcamz = g_camz
	Local hw:Int = g_engine_int162 / 2
	Local hh:Int = g_engine_int163 / 2
	Local tx:Float = g_cam_offx
	Local ty:Float = g_cam_offy
	If g_player_int01 = 8 And g_players <> Null
		For Local p:TPlayer = EachIn g_players
			For Local rf:TReplayFrame = EachIn p.replayframes
				If rf.frametime = g_replayframe And rf.active
					tx = p.x
					ty = p.y
					Exit
				EndIf
			Next
		Next
	ElseIf g_balls <> Null
		For Local b:TBall = EachIn g_balls
			For Local rf2:TReplayFrame = EachIn b.replayframes
				If rf2.frametime = g_replayframe And rf2.active
					tx = b.x
					ty = b.y
					Exit
				EndIf
			Next
		Next
	EndIf
	Local sx:Float = tx * g_camz - g_engine_int162 / 2
	Local sy:Float = ty * g_camz - g_engine_int163 / 2
	g_camx = g_camx + (sx - g_camx) * a0
	g_camy = g_camy + (sy - g_camy) * a0
	Local basea:Float = Float(g_player_int16)
	Local boundx:Float = (basea + TPitch.YardsToPixels(Float(g_engine_int14))) * g_camz
	Local boundy1:Float = (Float(g_player_int17) + TPitch.YardsToPixels(Float(g_engine_int15))) * g_camz
	Local boundy2:Float = (Float(g_player_int17) + TPitch.YardsToPixels(Float(g_engine_int16))) * g_camz
	If -boundx < boundx - g_engine_int162
		ClampFloat(Varptr g_camx, -boundx, boundx - g_engine_int162)
	Else
		g_camx = Float(-(g_engine_int162 / 2))
	EndIf
	If -boundy1 < boundy1 - g_engine_int163
		ClampFloat(Varptr g_camy, -boundy1, boundy2 - g_engine_int163)
	Else
		g_camy = Float(-(g_engine_int163 / 2))
	EndIf

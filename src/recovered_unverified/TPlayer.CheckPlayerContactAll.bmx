' TPlayer.CheckPlayerContactAll
' VA 0x004F458A   1577 bytes   KIND=Function, SIG=()i, class-table slot 0xD0
'
' ASSUMPTIONS (module Global names are ours; the originals are unrecoverable)
'   g_player_int01    0x00C5B1FC : Int    -- match state, gate value 1 = live play. This
'                     address also carries the name g_matchstate elsewhere in the corpus
'                     (same slot, two spellings in the corpus); extracted/
'                     globals_final.tsv hand-verifies g_player_int01 as the high-confidence
'                     pick, and it is the name TPlayer.CheckBallContact.bmx already uses for
'                     the identical `= 1`/`= 10`/`= 8` match-state comparisons.
'   g_hometeam        0x00C5B218 : TTeam
'   g_awayteam        0x00C5B21C : TTeam  (both CERTAIN/unanimous across 15+ bodies already
'                     in src/recovered/, e.g. TBall.Render, TEngine.SetUpMatch; the weaker
'                     globals_final.tsv "construction-site" guess for this pair is flagged
'                     CONFLICT there and loses to the address-level consensus.)
'   g_players         0x00C5DE10 : TList  -- every player, both teams (CERTAIN, 28 bodies;
'                     used directly by the third loop below, same as TPlayer.CleanThrough).
'   g_player_float02  0x00C5DE44 : Float  -- the shared draw scale (also named this way in
'                     TPlayer.CheckBallContact.bmx).
'   g_player_int34    0x00C5DE74 : Int    -- the player-to-player collision radius (also
'                     used, same address, by the very next function in the image,
'                     TPlayer.DoCollision at VA 0x004F4BB3).
'   g_player_arr05    0x00C5DEBC : Int[]  -- currentanim compare target (slide tackle)
'   g_player_arr22    0x00C5DF00 : Int[]  -- currentanim compare target (keeper-dive family)
'   g_player_arr23    0x00C5DF04 : Int[]  --   "
'   g_player_arr28    0x00C5DF18 : Int[]  --   "
'   All four g_player_arrNN picks are globals_final.tsv "verified/high" and match the
'   spellings already used by TPlayer.CheckBallContact.bmx.
'
' NOT GLOBALS (class-table interior, per extracted/globals_final.tsv)
'   0x00C5AEDC = TBall class table + 0x44   = GetActiveBall():TBall
'   0x00C5D998 = TPitch class table + 0x6C  = YardsToPixels(f)f
'   0x00C5FA20 = TPlayer class table + 0xD4 = DoCollision(:TPlayer,:TPlayer)i
'   Dist2D    = recovered module Function at 0x00505DA2, sig (f,f,f,f)f.
'   AngleDiff = recovered module Function at 0x00506049, sig (f,f,i)f.
'   0x005B9690 = _bbFloatToInt (Int()); 0x005AE59E = _brl_max2d_ImagesCollide2.
'   Float literals read out of NSS5.exe .rdata: 0x00C798E8 = 10.0, 0x00C798EC = 10.0,
'   0x00C798F0 = 115.0; the immediate 0x3FA00000 pushed before the YardsToPixels call is
'   1.25 (all four confirmed by reading the raw bytes, not assumed).
'   Field offsets (object_model.json): TTeam.squad 0x1C; TBall.controlledby 0x70;
'   TPlayer .imgPlayer 0xC .teamid 0x14 .x 0x4C .y 0x50 .z 0x54 .facing 0x128
'   .direction 0x78 .tackling 0x16C .selectionno 0xBC .currentanim 0x130
'   .imageframenumber 0x13C .spriterotation 0x12C; TPlayer.PlayerOnFeet slot 0x1A0,
'   .CheckFoul(:TPlayer)i slot 0xD8, .BlockTackle slot 0x110, .BlockSave slot 0x114.
'
' CODEGEN NOTES -- found by reading scripts/disasm.py output, not the decompiled text
'   * Ghidra's C drops or merges several call arguments that the raw bytes still carry:
'     - The AngleDiff call's literal third argument never prints at all; the raw bytes at
'       0x004F4A02 are a plain `push 1` immediately before the two `push [reg+0x78]`
'       (direction) pushes, i.e. `AngleDiff(p.direction, q.direction, 1)`.
'     - Both Dist2D calls print with only 3 of their 4 arguments in the decompiled text,
'       even though the raw bytes at 0x004F4721-2D and 0x004F499E-AA are a clean run of
'       four `push [reg+0x4C/0x50]` pairs followed by `add esp,0x10` (4 dwords) -- the
'       fourth argument (the second player's Y) is silently missing from the printed call.
'     - The two `(**(code**)(*piVar5+0xd8))(piVar5)` "CheckFoul" call-prints in the
'       decompiled text are wrong about their argument: the raw bytes at 0x004F47FE and
'       0x004F4939 are `push esi` (the other player) THEN `push eax` (self, p) THEN the
'       vtable call -- i.e. `p.CheckFoul(q)`, not a call carrying only p.
'   * Ghidra's decompiled text also silently drops a THIRD Float Local. Three back-to-back
'     `fld [g_player_float02] / fstp` stores at 0x004F46BB / 0x004F46C4 / 0x004F46CD
'     initialise three separate stack slots (ebp-0x10, ebp-8, ebp-0xc), not the two the
'     printed C shows (local_14, local_c). The third is conditioned on `p.y < q.y` (not on
'     either player's facing) and feeds ImagesCollide2's final (second player's Y-scale)
'     argument, where the first two feed the X-scale of each player.
'   * Both `If ImagesCollide2(...)` sites are the OPPOSITE polarity from Ghidra's printed
'     `if (iVar9 == 0) {A} else {B}`: the raw `cmp eax,0 / je` at each site jumps to the
'     Ghidra-labelled "if-true" body (A) on a MISS and falls straight through to the
'     Ghidra-labelled "else" body (B) on a HIT -- which only compiles from source written as
'     `If ImagesCollide2(...) Then B Else A`. Reproduced that way below.
'   * The two ImagesCollide2 calls are asymmetric on purpose: the first offsets the other
'     player's Y by +10.0 before Int(); the second does not. Preserved, not "fixed".
'   * Dist2D(p,q) is computed twice -- once cached in a Local for the slide-tackle gate,
'     once again fresh for the block-tackle radius gate later. The original recomputes
'     rather than reusing the first result; preserved.
'   * The `side` dispatch (`cmp eax,1/je .. ; cmp eax,2/je .. ; jmp default`, all compares
'     back-to-back before any body) is the Select shape documented in
'     src/recovered/TEngine.WaitForSetpiece.bmx, not an If/ElseIf (which would interleave a
'     case body between the two compares).
'
' REFINEMENT PASS (byte oracle, this round) -- started at 24.2% (382/1577), first
' difference at byte 5: `sub esp,0x3C` (orig) vs `sub esp,0x40` (ours), i.e. one whole
' extra 4-byte stack slot -- a frame-shape bug, not a cosmetic one. Diagnosed by reading
' the ORIGINAL's raw machine code directly (scripts/disasm.py against binary/NSS5.exe,
' VA 0x004F458A) rather than trusting Ghidra's C a second time, and by building this exact
' body through scripts/harness.py's try_method (per-worker private tree, no shared state
' touched) to see our own compiled bytes side by side with the original's.
'   * ROOT CAUSE: `hit1`/`hit2` were materialised as real `Local hit1:Int` / `Local
'     hit2:Int`, assigned inside a nested `If`, then tested in a second `If hit1` /
'     `If hit2`. The raw bytes prove this is wrong: at both ImagesCollide2 call sites
'     (0x004F47F4 and 0x004F48F9) the very next instruction is `cmp eax,0` on the call's
'     raw return value -- there is no intervening store to any stack slot or callee-saved
'     register. That is only reachable from a SINGLE compound condition, e.g.
'     `If p.currentanim = g_player_arr05 And dist < YardsToPixels(1.25) And
'     ImagesCollide2(...) Then <CheckFoul-path> Else <hit2/blocktackle-path>` -- no
'     separate `hit1`/`hit2` Local at all (same for the `arr22 Or arr23 Or arr28) And
'     p.z < 10.0 And ImagesCollide2(...)` gate). Rewritten that way below; this alone
'     dropped the frame from 0x40 to 0x3C (15 dwords, matching the original exactly) and
'     fixed the whole control-flow shape -- `localise_diff.py` afterwards showed zero real
'     logic gaps, only register/slot-identity substitutions (see below).
'   * `0 < ball.controlledby.selectionno` was written operand-first; the original's raw
'     bytes are `cmp eax,0 / setg` (i.e. `selectionno > 0`, guide 10.1 -- operand order is
'     byte-observable and Ghidra normalises it away). Flipped to match.
'   * REMAINING GAP (delta -12, `our_len` 1565 vs `orig_len` 1577; every byte of the
'     residual traces to this one thing -- `scripts/localise_diff.py` shows no other
'     length-changing gap and no genuine logic substitution): the original SPILLS `ball`
'     to `[ebp-0x14]` and reloads it at both later use sites (`mov eax,[ebp-0x14]`, 3
'     bytes, at each of ~5 read sites), while our build's register allocator instead
'     colours `ball` into a callee-saved register (edi) for its whole life and spills a
'     *different*, unrelated value instead (the `Int(115.0 - p.tackling)` widen-scratch
'     used by the block-tackle `AngleDiff` gate, which the original keeps in `ebx` across
'     that call and ours spills to `[ebp-4]`). Both are valid graph-colourings of the same
'     liveness graph (`ball`, `p`, `q` and that widen temp all mutually interfere across
'     the whole loop nest, and only 3 non-`eax/edx/ecx` colours exist -- see
'     docs/reference/codegen-patterns.md sec 18, `cgallocregs.cpp`'s Chaitin/Briggs
'     allocator) with the SAME total spill count (15 dwords both sides) but a DIFFERENT
'     choice of which node is the odd one out. Tried and empirically ruled out (via
'     harness.try_method rebuilds, not guessing): hoisting `Int(115.0-p.tackling)` into
'     its own `Local` before the `If` (to force it to be computed, and therefore to
'     interfere, earlier); splitting `Local ball:TBall = TBall.GetActiveBall()` into a
'     bare declaration plus a separate assignment statement. Neither changed the outcome.
'     This looks like it needs the same live-range-level technique codegen-patterns.md
'     sec 22 used on `TTable.Draw` (reshaping a branch's block structure to change one
'     value's `block_count`), not a source reordering; leaving it for a follow-up pass
'     rather than guess further. The frame size, argument order/count, Select-vs-If
'     shape, ImagesCollide2 polarity and every branch condition are otherwise verified
'     directly against the original's raw disassembly, not just the decompile.
'
' RE-REVIEW PASS (byte oracle, later round): re-verified this file's REMAINING GAP claim
' from scratch by disassembling both nss5_assembled.exe's current compiled bytes and the
' original's raw machine code (scripts/bytematch.py's disasm_original() against both
' binaries, addresses/branch-displacements blanked to align the streams by hand -- the
' localise_diff.py technique, applied without running localise_diff.py itself since it
' calls harness.try_method and would trigger a build). Confirms: every content difference
' still traces to the single `ball`-register-vs-spill choice described above (the `edi`
' register that holds `ball` in our build instead of a stack spill cascades into every
' downstream register/stack-slot substitution: p/q end up in esi/ebx here vs edi/esi in the
' original, xs1/xs2/ys2's stack slots shift by one, and even a same-length `setb+je` vs
' `setae+jne` polarity swap on the final loop's Dist2D-vs-g_player_int34 test is a
' consequence of it, not a separate bug -- that comparison is the tail of an AND-chain with
' no Else to swap and no short-circuit-materialisation saving available, so unlike the
' Knock/Cross fix applied to TPlayer.TapKickAdvanced.bmx this pass, there is no source-text
' lever that predictably moves it). No new fix attempted: identical reasoning to the
' existing REMAINING GAP note, and this is exactly the class of live-range/register-
' colouring question that needs a build-and-inspect loop (forbidden this pass) to resolve
' safely, not another guess. Also re-checked for the project's "missing Global assignment"
' defect class: every Global this body touches (g_player_int01, g_hometeam, g_awayteam,
' g_players, g_player_float02, g_player_int34, g_player_arr05/22/23/28) is only ever WRITTEN
' by other functions and only ever READ here in both the decompilation and this body --
' correct, not a case of a dropped assignment.

'!Global g_player_int01:Int
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_players:TList
'!Global g_player_float02:Float
'!Global g_player_int34:Int
'!Global g_player_arr05:Int[]
'!Global g_player_arr22:Int[]
'!Global g_player_arr23:Int[]
'!Global g_player_arr28:Int[]
If g_player_int01 <> 1 Then Return 0
Local ball:TBall = TBall.GetActiveBall()
For Local side:Int = 1 To 2
	Local team:TTeam
	Local otherteam:TTeam
	Select side
		Case 1
			team = g_hometeam
			otherteam = g_awayteam
		Case 2
			team = g_awayteam
			otherteam = g_hometeam
	End Select
	For Local p:TPlayer = EachIn team.squad
		If p.selectionno < 11
			For Local q:TPlayer = EachIn otherteam.squad
				If q.selectionno < 11 And q.PlayerOnFeet()
					Local xs1:Float = g_player_float02
					Local xs2:Float = g_player_float02
					Local ys2:Float = g_player_float02
					If p.facing = 0 Then xs1 = -g_player_float02
					If q.facing = 0 Then xs2 = -g_player_float02
					If p.y < q.y Then ys2 = -g_player_float02
					Local dist:Float = Dist2D(p.x, p.y, q.x, q.y)
					If p.currentanim = g_player_arr05 And dist < TPitch.YardsToPixels(1.25) And ImagesCollide2(p.imgPlayer, Int(p.x), Int(p.y), p.imageframenumber, p.spriterotation, xs1, g_player_float02, q.imgPlayer, Int(q.x), Int(q.y + 10.0), q.imageframenumber, q.spriterotation, xs2, ys2)
						If p.CheckFoul(q) Then Return 0
					Else
						If (p.currentanim = g_player_arr22 Or p.currentanim = g_player_arr23 Or p.currentanim = g_player_arr28) And p.z < 10.0 And ImagesCollide2(p.imgPlayer, Int(p.x), Int(p.y), p.imageframenumber, p.spriterotation, xs1, g_player_float02, q.imgPlayer, Int(q.x), Int(q.y), q.imageframenumber, q.spriterotation, xs2, ys2)
							If ball <> Null And ball.controlledby = q
								p.BlockSave()
							Else
								p.CheckFoul(q)
							EndIf
						Else
							If ball <> Null And ball.controlledby = q And p.PlayerOnFeet() And ball.controlledby.selectionno > 0 And Dist2D(p.x, p.y, q.x, q.y) < g_player_int34
								If p.facing <> q.facing And Int(115.0 - p.tackling) < AngleDiff(p.direction, q.direction, 1)
									p.BlockTackle()
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			Next
		EndIf
	Next
Next

For Local p:TPlayer = EachIn g_players
	For Local q:TPlayer = EachIn g_players
		If p <> q And p.teamid <> q.teamid And Dist2D(p.x, p.y, q.x, q.y) < g_player_int34
			If p.PlayerOnFeet() And q.PlayerOnFeet()
				TPlayer.DoCollision(p, q)
			EndIf
		EndIf
	Next
Next
Return 0

' NOT VERIFIED -- MISMATCH, but now byte-close. Do NOT copy into src/recovered/ without
' closing the final gap below.
'
' TBall.UpdateMovement   (KIND=Method, SIG=()i, SLOT=0x5c)
' VA 0x004C871F   1711 bytes   (Ghidra-authoritative)
'
' RESULT (this pass): ours 1714 of 1711 (delta +3). Measured with scripts/bytematch.py's
'   own comparator (matched/compared over the full aligned length, the same denominator
'   status/score reports use): 1443/1711 = 84.3% byte agreement, up from 6.7% at the start
'   of this pass. Exactly ONE length-changing gap remains (localise_diff.py, +3 bytes at
'   original offset +1601 -- see "STILL OPEN" below); everything else in the function is
'   byte-identical modulo that gap's downstream branch-displacement shifts.
'
' THE KEY INSIGHT THIS PASS ADDED: `Local x:Int = False : If g_int = CONST Then x = <value>`
'   (a Local defaulted to False, then conditionally overwritten by a guard that compares a
'   Global/Int against a NON-ZERO constant) reads naturally but is NOT what bcc emits. The
'   ORIGINAL instead compiles the guard as a materialised boolean -- `mov eax,[g] / cmp
'   eax,CONST / sete al / movzx eax,al` -- immediately RE-TESTED (`cmp eax,0 / je`) before
'   falling into the assignment, i.e. 10 bytes longer than the direct `cmp [g],CONST / jne`
'   our nested-If phrasing produces. This is bcc's lowering of chained/short-circuit `And`:
'   writing the SAME logic as a single expression --
'       Local x:Int = (g_int = CONST) And <value-or-next-term> [And <term> ...]
'   -- reproduces the exact materialise+retest shape, because bcc always computes each
'   operand of a stored `And` chain into a clean 0/1 (or, for the LAST term, the term's own
'   raw value) rather than fusing the comparison directly into the branch. This is distinct
'   from a guard of the exact shape `X <> 0` / `X = 0` (a truthiness test against literal
'   zero): that one DOES compile as a direct `cmp reg,0 / je` even when read out of the same
'   loaded register later, because the loaded value already equals 0 in the false case with
'   no normalisation needed -- see TBall.UpdateMovement's two `Self.active <> 0` sites,
'   which stay direct-branch in every phrasing tried, versus every `g_player_int01 = N`
'   guard-gating-an-assignment in this body, which needed the `And`-chain rewrite.
'
'   Applied to close FOUR sites that were separate `Local=False:If...Then...`
'   pairs/singles (all confirmed by getting scripts/localise_diff.py's gap list to shrink
'   or disappear at that exact offset, one edit at a time, via the private per-worker bmk
'   toolchain -- `NSS5_WORKER=<id>` copy, never scripts/assemble.py's shared tree):
'     * `sp8`/`sp9` (the SetPiece reset-position guard) merged into ONE Local:
'       `Local sp9:Int = g_player_int01 = 3 And Self.controlledby <> Null And
'       Self.controlledby.currentanim = g_player_arr08` -- closed a -5/+7 byte pair of gaps
'       at the function's very first branch (this was "ROOT CAUSE A" in the prior draft's
'       notes below; the fix was the And-chain, not a register-allocator workaround).
'     * `kh` (KeeperHolding gate for the ClampFloat call): `Local kh:Int = g_player_int01 =
'       1 And Self.KeeperHolding()` -- the guarded value here is a CALL, not a comparison,
'       and it still needed the And-chain treatment; "guard gates a call-valued assignment"
'       is not exempt the way "guard is a truthiness test" is.
'     * `bounced` (z-bounce/KeeperHoldingBall gate): `Local bounced:Int = Self.controlledby
'       <> Null And Self.z > 0.0`.
'     * `farkick`/`curlpos` (the trailing curl-reset gate, "ROOT CAUSE B" in the prior
'       draft): collapsed from TWO chained Locals into one, keeping the OUTER `Self.active
'       <> 0` as a genuine separate `If` (it is a truthiness-vs-zero test and must NOT be
'       folded into the And-chain -- folding it in was tried and made things worse, see
'       STILL OPEN) with the value itself And-chained: `If Self.active <> 0 Then curlpos =
'       (g_player_int01 = 10) And (Self.velocity > 0.0) And (Sin(Self.direction) > 0.0)`.
'
'   Two more independent fixes, unrelated to the And-chain insight:
'     * KeeperHandHeight compare: was `If nz < Self.z`, decompile-literal but wrong operand
'       spelling (codegen-patterns.md 10.1 -- never trust decompile's printed order, read
'       the raw setcc). The original's `fld Self.z ; fucomp st(1) ; setbe` is byte-produced
'       by `If Self.z > nz`, NOT `If nz < Self.z` (logically identical, differently spelled;
'       confirmed exact via the harness -- this closed the last SUB and an 8-byte gap).
'     * `py`'s narrow-to-Float cast was missing its own Local. `px` already had `Local
'       nx:Float = px` (confirmed correct by the prior draft); `py` needed the identical
'       treatment -- `Local ny:Float = py` before the `Self.y = ... (ny - Self.y) ...` line
'       -- so BOTH position accumulators get an explicit Double->Float narrowing Local, not
'       just the x one. This single change closed two gaps at once (+5 at +885, -3 at +859)
'       because it let the original's x87-stack scheduling (py stays resident across the
'       Self.x assignment and gets `fxch`'d back in for Self.y, instead of being reloaded
'       from its spill slot) fall out naturally.
'     * The ClampFloat call's second argument was `5 - g_player_int17`; bcc compiles that
'       as `mov eax,5 / sub eax,[g]`. The original is `mov eax,[g] / neg eax / add eax,5`,
'       which is what `-g_player_int17 + 5` (same value, different operand grouping)
'       produces. One byte, but it was the last gap before the `curlpos` region and
'       fixing it collapsed a long run of downstream branch-displacement noise --
'       agreement jumped from 51.8% to 84.3% off this one change.
'
' STILL OPEN (+3 bytes, the only remaining gap, at original +1601): the `curlpos` Local's
'   own default-initialisation. Original: `mov eax,[esi+0xc] (Self.active) / cmp eax,0 / je`
'   -- NO separate "curlpos = 0" instruction at all; the compiler reuses the just-loaded
'   Self.active register as curlpos's implicit false-case value (it is already exactly 0
'   when the branch is not taken). Ours: `mov eax,0 (curlpos default) / cmp dword
'   [esi+0xc],0 / je` -- a separate materialised default PLUS a memory-direct compare.
'   Tried and REJECTED (each made the total delta worse, confirmed via the harness, not
'   guessed): folding `Self.active <> 0` into the And-chain as its first term (materialises
'   Self.active too, +8 to +20 bytes depending on how many terms follow); dropping the
'   explicit `= False` initialiser (byte-identical to keeping it -- bcc's implicit
'   zero-init compiles the same as an explicit one here); spelling the guard as bare `If
'   Self.active` instead of `If Self.active <> 0` (no change). This looks like the same
'   whole-function register/spill interference the prior draft's "ROOT CAUSE A/B" notes
'   described (codegen-patterns.md 18.4/22) -- a cost-ranking question, not a phrasing one
'   -- and was not solved this pass either. Next lever to try: statement reordering
'   elsewhere in the function to change `curlpos`'s live range (22.3), not more rephrasing
'   of this statement itself.
'
' TOOLS: scripts/localise_diff.py's `L.localise_body('TBall','UpdateMovement', body,
'   max_gaps=25)` under a private `NSS5_WORKER=<id>` (NOT scripts/assemble.py, which writes
'   shared state) is how every gap above -- old and new -- was found and closed.
'
' CLASS-TABLE SLOTS used (all receiver-typed, resolved via vtable_map.tsv): TEngine
'   Function SetPiece()i (classtable+0x74, static cross-Type call `TEngine.SetPiece()`);
'   TPlayer Function GetPlayerById(i):TPlayer (classtable+0x168); TPlayer Method
'   KeeperHoldingBall()i (slot 0x1c0), GetKeeperHandHeight()f (slot 0x1cc),
'   GetPlayerRunningHandHeight(*f)i (slot 0x1d0, a Var Float arg -- Varptr at the call site);
'   TBall Method KeeperHolding()i (Self's own slot 0x88, no `Self.`/`TBall.` prefix needed
'   codegen-wise but written explicitly for clarity), ResetPosition(i,i,i)i (slot 0x9c).
'
' MODULE FUNCTIONS called (already recovered): Dist2D (src/recovered_module/Dist2D.bmx,
'   0x00505DA2, Euclidean distance) and ClampFloat (src/recovered_module/ClampFloat.bmx,
'   0x00505F90, clamps a Float Var into [lo,hi]).
'
' GLOBALS -- names ours except where an address is already established elsewhere in the
'   corpus (kept identical for consistency):
'   g_player_int01:Int (0x00C5B1FC) -- match-state code, already Int project-wide.
'   g_player_int33:Int (0x00C5DE70) -- established by TBall.UpdateMetaBall / TBall.Kick.
'   g_player_int17:Int (0x00C5D638) -- pitch half-height, established by TBall.CheckSideLines
'     (there named g_pitchhalfheight; kept as g_player_int17 here to match TBall.Kick.bmx's
'     naming of the SAME address, since this project already carries divergent per-file names
'     for shared Globals).
'   g_player_tplayer01:TPlayer (0x00C5B248).
'   g_player_arr08:Int[] (0x00C5DEC8) -- goalkeeper-holding animation-index array, compared
'     by reference against Self.controlledby.currentanim.
'   g_ball_float01/02/03/04:Float (0x00C5A4CC/D0/D4/D8) -- already established, TBall.Kick.
'   g_ball_channel:TChannel (0x00C5A510) -- SAME address TBall.Kick.bmx (g_chan_kick) and
'     TBall.HitPost.bmx (g_ball_postchannel) already name; one physical Global, reused across
'     files under different local names in this corpus already.
'   g_ball_bouncesound:TSound (0x00C5A514) -- UNCERTAIN name/exact role: globals_final.tsv
'     lists this address only as a low-confidence untyped `Object` with no construction-site
'     evidence. Typed TSound here purely from being the first PlaySound(...) argument
'     alongside g_ball_channel; no prior file in the corpus references this exact address.
'     Semantic guess ("bounce") comes from context (this call fires only when the ball's
'     z-bounce produces zvelocity > 1.0) and is UNCERTAIN.
'   g_ball_int05:Int (0x00C5B244) -- already established, TBall.Kick.bmx.
'
' STRING LITERALS: none in this body (no LogLine / text calls).
		'!Global g_player_int01:Int
		'!Global g_player_int33:Int
		'!Global g_player_int17:Int
		'!Global g_player_tplayer01:TPlayer
		'!Global g_player_arr08:Int[]
		'!Global g_ball_float01:Float
		'!Global g_ball_float02:Float
		'!Global g_ball_float03:Float
		'!Global g_ball_float04:Float
		'!Global g_ball_channel:TChannel
		'!Global g_ball_bouncesound:TSound
		'!Global g_ball_int05:Int

		Self.oldx = Self.x
		Self.oldy = Self.y
		Self.oldz = Self.z
		If Self.active <> 0
			If TEngine.SetPiece() <> 0
				Local sp9:Int = g_player_int01 = 3 And Self.controlledby <> Null And Self.controlledby.currentanim = g_player_arr08
				If sp9
					If Self.controlledby.x < 0.0
						Self.ResetPosition(Int(Self.controlledby.x - 2.0), Int(Self.controlledby.y - 1.0), g_player_int33 - 5)
					Else
						Self.ResetPosition(Int(Self.controlledby.x + 2.0), Int(Self.controlledby.y - 1.0), g_player_int33 - 5)
					End If
				Else
					Self.ResetPosition(Self.setpiecex, Self.setpiecey, 0)
				End If
				Return 0
			End If
			If g_player_int01 = 8
				If Self.controlledby <> g_player_tplayer01 Then Self.controlledby = Null
			Else If g_player_int01 <> 1
				Self.controlledby = Null
			End If
			If Self.controlledby <> Null
				Self.passtoid = 0
				Self.teaminpossession = Self.controlledby.teamid
				Self.lastkickedby = Self.controlledby
				Self.lastkickedby.kickx = Int(Self.x)
				Self.lastkickedby.kicky = Int(Self.y)
				Self.lasttouchedby = Self.controlledby
				Self.direction = Self.controlledby.direction
				Local mv:Float = 6.0 + Self.controlledby.speed * 3.0
				If Self.controlledby.KeeperHoldingBall() <> 0
					mv = mv * 1.5
					Local nz:Float = Self.controlledby.GetKeeperHandHeight()
					If Self.z > nz
						Self.z = nz
						Self.oldx = Self.x
						Self.oldy = Self.y
						Self.oldz = Self.z
					End If
				End If
				If g_player_int01 = 8
					Self.controlledby.GetPlayerRunningHandHeight(Varptr Self.z)
					mv = mv * 0.8
					If Self.controlledby.speed < 1.0 Then mv = mv * 0.6
					Self.direction = Self.direction + 10.0
				End If
				Local px:Double = Self.controlledby.x
				px = px + Cos(Self.direction) * (mv * 1.25)
				Local nx:Float = px
				Local py:Double = Self.controlledby.y
				py = py + Sin(Self.direction) * mv
				Local ny:Float = py
				Self.x = Self.x + (nx - Self.x) * 0.25
				Self.y = Self.y + (ny - Self.y) * 0.25
				Self.velocity = Self.controlledby.speed
				Local kh:Int = g_player_int01 = 1 And Self.KeeperHolding()
				If kh <> 0 Then ClampFloat(Varptr Self.y, -g_player_int17 + 5, g_player_int17 - 5)
				If g_player_int01 = 8 Then Return 0
			End If
		End If
		If Not Self.controlledby
			Self.teaminpossession = 0
			If Self.lastkickedby <> Null Then Self.teaminpossession = Self.lastkickedby.teamid
			If Self.lasttouchedby <> Null Then Self.teaminpossession = Self.lasttouchedby.teamid
			Self.direction = Self.direction + Self.curlamount
			If Self.z > 0.0
				If Self.velocity <> 0.0 Then Self.velocity = Self.velocity * g_ball_float02
			Else
				If Self.velocity <> 0.0 Then Self.velocity = Self.velocity * g_ball_float01
			End If
			Self.x = Self.x + Cos(Self.direction) * Self.velocity
			Self.y = Self.y + Sin(Self.direction) * Self.velocity
		End If
		Self.zvelocity = Self.zvelocity - g_ball_float03
		Local bounced:Int = Self.controlledby <> Null And Self.z > 0.0
		If bounced
			If Self.controlledby.KeeperHoldingBall() <> 0
				Self.zvelocity = 0.0
			Else
				Self.zvelocity = Self.zvelocity - g_ball_float03
				If Self.z > g_player_int33 Then Self.z = g_player_int33
			End If
		End If
		Self.z = Self.z + Self.zvelocity
		If Self.z <= 0.0
			Self.z = 0.0
			Self.zvelocity = -Self.zvelocity * g_ball_float04
			If Self.zvelocity > 1.0 Then PlaySound(g_ball_bouncesound, g_ball_channel)
		End If
		Local target:TPlayer = TPlayer.GetPlayerById(Self.passtoid)
		If target <> Null
			Local d:Float = Dist2D(Self.x, Self.y, target.x, target.y)
			If d > Self.disttoreciever
				Self.passtoid = 0
			Else
				Self.disttoreciever = d
			End If
		End If
		Local curlpos:Int = False
		If Self.active <> 0 Then curlpos = (g_player_int01 = 10) And (Self.velocity > 0.0) And (Sin(Self.direction) > 0.0)
		If curlpos Then g_ball_int05 = 0
		Return 0

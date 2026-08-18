' TBall.UpdateMovement   (KIND=Method, SIG=()i, SLOT=0x5c)
' VA 0x004C871F   1711 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe (1711/1711)
'
' SHAPE NOTES the oracle forced (do not "simplify" these back -- each costs real bytes):
'   * Every guard that gates a Local's own assignment is written as ONE And-chained
'     expression, not a separately-defaulted Local followed by a nested If. bcc computes
'     each operand of a stored `And` chain into a clean 0/1 via `sete/movzx`, immediately
'     re-tested (`cmp eax,0 / je`), except the LAST operand, which keeps its own raw value:
'       - `sp9` (SetPiece reset-position guard): `Local sp9:Int = g_player_int01 = 3 And
'         Self.controlledby <> Null And Self.controlledby.currentanim = g_player_arr08`.
'       - `kh` (KeeperHolding gate for the ClampFloat call): `Local kh:Int = g_player_int01
'         = 1 And Self.KeeperHolding()` -- the guarded value is a CALL, not a comparison,
'         and still takes the And-chain shape.
'       - `bounced` (z-bounce/KeeperHoldingBall gate): `Local bounced:Int =
'         Self.controlledby <> Null And Self.z > 0.0`.
'       - `curlpos` (the trailing curl-reset gate): `Local curlpos:Int = Self.active And
'         (g_player_int01 = 10) And (Self.velocity > 0.0) And (Sin(Self.direction) > 0.0)`.
'         The bare `Self.active` (not `Self.active <> 0`) is load-bearing here: as the
'         FIRST operand of a stored And-chain, an explicit `<> 0` comparison still gets
'         materialised via `setne/movzx` (9 bytes), but a raw Int operand used directly for
'         its truthiness does not -- bcc just loads it, compares to 0, and branches,
'         letting the tested register double as curlpos's implicit zero default in the
'         false case. `Self.active <> 0` elsewhere in this body, used only as a plain
'         (unstored) If-guard, compiles as a direct `cmp [mem],0 / je` with no register
'         load at all -- a third, narrower shape from the same underlying rule that a
'         zero-test does not need normalising unless it is itself a chained-And operand.
'   * KeeperHandHeight compare is spelled `If Self.z > nz`, not the decompile-literal
'     `If nz < Self.z` (logically identical, differently spelled -- codegen-patterns.md
'     10.1: never trust decompile's printed operand order, read the raw setcc).
'   * `px` and `py` both get an explicit Double->Float narrowing Local (`nx`/`ny`) before
'     the position assignments that read them back, letting the original's x87-stack
'     scheduling (`py`/`ny` staying resident and `fxch`'d back in for `Self.y` rather than
'     reloaded from a spill slot) fall out naturally.
'   * The ClampFloat call's second argument is written `-g_player_int17 + 5`, which
'     compiles as `mov eax,[g] / neg eax / add eax,5`; the equal-value `5 - g_player_int17`
'     compiles as `mov eax,5 / sub eax,[g]` instead -- same value, different operand
'     grouping, and only one of the two byte-matches.
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
		Local curlpos:Int = Self.active And (g_player_int01 = 10) And (Self.velocity > 0.0) And (Sin(Self.direction) > 0.0)
		If curlpos Then g_ball_int05 = 0
		Return 0

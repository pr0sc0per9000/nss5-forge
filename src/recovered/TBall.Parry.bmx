' TBall.Parry  -- KIND=Method, sig (:TPlayer)i, slot 0x94
' VA 0x004CB6C5   1206 bytes
' byte-identical vs NSS5.exe (1206/1206, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=66)
'
' ASSUMPTIONS
'   Globals declared (names ours, per globals_final.tsv where present):
'     '!Global g_ball_parrysound:TSound     = 0x00C5A518 (usage=low, init=bbNullObject)
'     '!Global g_ball_postchannel:TChannel  = 0x00C5A510 (SAME address TBall.HitPost.bmx
'         names g_ball_postchannel -- reused verbatim for consistency, confirmed identical
'         Global by address)
'     '!Global g_player_int50:Int           = 0x00C6EFD4 (globals_final 'verified')
'     '!Global g_engine_int31:Int           = 0x00C5B26C (globals_final, 5 writes)
'     '!Global g_engine_int32:Int           = 0x00C5B270 (globals_final, 5 writes)
'     '!Global g_Object17:TTeam             = 0x00C5B218 (globals_final types it TKit with a
'         CONFLICT note "TKit=2;TTeam=1"; the access here is field+8 compared against
'         a0.teamid, and TTeam.id is the field at +8 -- TKit's +8 is pixmap:TPixmap, which
'         cannot compare equal to an Int teamid. Read as TTeam here; name kept generic
'         per the table since the type disagreement is unresolved project-wide.)
'     '!Global g_player_int33:Int           = 0x00C5DE70 (globals_final, 1 write; only used
'         here, multiplied by the Float literal 0x00C72970=0.8)
'     '!Global g_player_arr23:Int[]         = 0x00C5DF04 (globals_corrections: Int[], not
'         Object[] -- corrects globals_final.tsv)
'     '!Global g_player_arr24:Int[]         = 0x00C5DF08 (globals_corrections: Int[])
'   Fields from object_model.json (TBall): velocity @0x54, zvelocity @0x58, direction @0x5C,
'     x @0x18, y @0x1C, z @0x20, controlledby:TPlayer @0x70, teaminpossession @0x60,
'     lastkickedby:TPlayer @0x74, lasttouchedby:TPlayer @0x78, backpass @0x88,
'     curlamount @0x98, passtoid @0x9C, kicktime @0x64. TPlayer: teamid @0x14, x @0x4C,
'     y @0x50, z @0x54, xvel @0x64, direction @0x78, currentanim []i @0x130, frame @0x134.
'   Slot 0xD0 = TBall.CheckLongShotRating()i (vtable_map.tsv). a0.KeeperDiving() resolved via
'     object_model.json TPlayer member at vtable slot 0x1C4 (decimal 452) -- TPlayer has no
'     rows in vtable_map.tsv (known project gap; class_tables.tsv doesn't cover it), so this
'     is read directly off the reflected Method's `offset` field instead.
'   Runtime/BRL: 0x00505B91 LogLine (module Function, src/recovered_module/), 0x0059B25E
'     _brl_audio_PlaySound, 0x004A1F10 _bbCos, 0x004A1F00 _bbSin, 0x004A79D0
'     _bbStringFromFloat (implicit, from "..." + Self.velocity), 0x0059F048 _brl_random_Rnd,
'     0x0059F089 _brl_random_Rand, 0x00506184 WrapAngle (module Function,
'     src/recovered_module/), 0x00505DA2 Dist2D (module Function, src/recovered_module/).
'   0x004A1F90 was UNNAMED in runtime_helpers.tsv before this recovery -- confirmed by
'     reading its disassembly (fpatan then `fmul qword [0x00CD26A0]`) against
'     tools/blitzmax-legacy-src/mod/brl.mod/math.mod/math.c line 34
'     (`double bbATan2(y,x){ return atan2(y,x)*RAD_TO_DEG; }`): exact match. Added as
'     `0x004a1f90 _bbATan2 18` to extracted/runtime_helpers.tsv (18 witnesses in
'     call_sites.tsv) so all 18 callers can now mask this E8. NAME IS the legacy builtin
'     `ATan2:Double(y:Double,x:Double)`, called directly (no Import needed beyond the
'     project's existing BRL.Math use, confirmed working from src/recovered/TBall.HitPost.bmx
'     which already calls `ATan2(sn, c)` and MATCHES).
'   0x00C5D998 is flagged in globals_corrections/globals_final as
'     "classtable-slot, TPitch+0x6c = YardsToPixels(f)f" -- a compile-time-resolved Function
'     slot call (TPitch statically known, no Self needed), one of the oracle's four masked
'     categories, so the exact call shape only needs to be a class-table-slot call, not a
'     byte-exact address; written as `TPitch.YardsToPixels(1.0)`.
'   Float/double literals read directly from NSS5.exe (all confirmed by dtype from the
'     `fld`/`fld qword` instruction width in the original disassembly, not guessed):
'     0x00C72970 (Float) = 0.8; 0x00C72928/0x00C72920 and 0x00C72968/0x00C72960 (Double
'     pairs) = 0.3/0.4 (used twice, in both Dive branches); 0x00C72A18 (Float) = 2.0;
'     0x00C72A10/0x00C72A08 (Double pair) = 0.45/0.65; 0x00C729A8 (Float) = 0.1;
'     0x00C729A0/0x00C72998 (Double pair) = 2.5/3.5 (used twice, Punch and default Parry
'     branches); 0x00C729D8 (Float) = 0.7; 0x00C729E0/0x00C729E8 (Double pair) = 3.5/2.5.
'   Debug strings read from .rdata: "Parry: v=", "Dive: Tip left", "Dive: Tip right",
'     "Parry: Tip over", "Parry: Punch", "Parry".
'
' CODEGEN NOTES
'   The `Cos(Self.direction)` calls in the Punch and "Tip over"-fallback branches: in the
'     Punch branch the result IS used (stored to a Local, then reassigned `c = c * 0.1`
'     before use -- writing `c * 0.1` inline in the ATan2 call compiles 6 bytes SHORTER
'     because bcc skips the redundant store+reload round trip; the reassignment statement is
'     load-bearing). In the "Tip over"-fallback branch (the outer Else arm reached when
'     `Self.z <= a0.z + g_player_int33*0.8`) the Cos result is a genuine ORIGINAL BUG: called
'     and its result discarded (`fstp st(0)`, no store) -- written here as a bare statement
'     call with no assignment, which BlitzMax permits for a Function used as a statement.
'   `ATan2(-sn, ...)`: the negation is applied INLINE at the call site (`fchs` appears right
'     before the push, reloading the plain `Sin(...)` Local), NOT baked into the Local's own
'     initialiser the way TBall.HitPost.bmx's sibling code does -- two different call
'     contexts genuinely compile the unary minus at different points; do not assume one
'     pattern transfers to the other without checking.
'   The outer `Self.z <= a0.z + g_player_int33*0.8` test is written NEGATED AND SWAPPED
'     (`If Self.z > ... Then <Punch/default> Else <Tip over>`) versus the natural reading of
'     the decompilation -- this is codegen-patterns section 21's branch-swap rule: the
'     original places the Punch/default block FIRST (fall-through) and the "Tip over" block
'     SECOND (reached by a forward jump); writing the condition in its "natural" `<=` sense
'     with `Tip over` in the Then-arm put the blocks in the wrong physical order and used the
'     wrong `setcc` (`seta`/`setae` instead of `setbe`) at three sites.
'   The second Dive test compiles differently depending on operand order even though it is
'     logically identical: `a0.xvel > 0.0` matches (loads `a0.xvel` before the `fldz`,
'     `setbe`); `0.0 < a0.xvel` does not (swaps the `fld`/`fldz` order, emits `setae`).
'!Global g_ball_parrysound:TSound
'!Global g_ball_postchannel:TChannel
'!Global g_player_int50:Int
'!Global g_engine_int31:Int
'!Global g_engine_int32:Int
'!Global g_Object17:TTeam
'!Global g_player_int33:Int
'!Global g_player_arr23:Int[]
'!Global g_player_arr24:Int[]
	Method Parry:Int(a0:TPlayer)
		LogLine("Parry: v=" + Self.velocity)
		PlaySound(g_ball_parrysound, g_ball_postchannel)
		Self.CheckLongShotRating()
		Self.controlledby = Null
		Self.teaminpossession = a0.teamid
		Self.lasttouchedby = a0
		Self.passtoid = -1
		Self.kicktime = g_player_int50
		Self.backpass = 0
		Self.curlamount = 0
		If a0.teamid = g_Object17.id Then
			g_engine_int32 :+ 1
		Else
			g_engine_int31 :+ 1
		EndIf
		If a0.KeeperDiving() Then
			If a0.xvel < 0.0 Then
				LogLine("Dive: Tip left")
				Self.velocity = Self.velocity * Rnd(0.3, 0.4)
				Self.direction = a0.direction + Rand(-25, 25)
				WrapAngle(Self.direction)
				Return 0
			EndIf
			If a0.xvel > 0.0 Then
				LogLine("Dive: Tip right")
				Self.velocity = Self.velocity * Rnd(0.3, 0.4)
				Self.direction = a0.direction + Rand(-25, 25)
				WrapAngle(Self.direction)
				Return 0
			EndIf
		EndIf
		If Self.z > a0.z + g_player_int33 * 0.8 Then
			If a0.currentanim = g_player_arr24 And Self.lastkickedby <> Null And Dist2D(Self.x, Self.y, Self.lastkickedby.x, Self.lastkickedby.y) < TPitch.YardsToPixels(1.0) Then
				LogLine("Parry: Punch")
				Local c:Float = Cos(Self.direction)
				Local sn2:Float = Sin(Self.direction)
				Self.zvelocity = Rnd(2.5, 3.5)
				c = c * 0.1
				Self.direction = ATan2(-sn2, c)
				WrapAngle(Self.direction)
				Return 0
			Else
				LogLine("Parry")
				Self.velocity = Self.velocity * 0.7
				Self.zvelocity = Rnd(2.5, 3.5)
				Self.direction = Self.direction + Rand(-15, 15)
				WrapAngle(Self.direction)
				a0.currentanim = g_player_arr23
				a0.frame = 0
				Return 0
			EndIf
		Else
			LogLine("Parry: Tip over")
			Cos(Self.direction)
			Local sn:Float = Sin(Self.direction)
			a0.currentanim = g_player_arr23
			Self.velocity = Self.velocity * Rnd(0.45, 0.65)
			Self.direction = ATan2(-sn, a0.xvel * 2.0)
			WrapAngle(Self.direction)
			Return 0
		EndIf
	End Method

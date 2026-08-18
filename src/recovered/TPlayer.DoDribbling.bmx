' TPlayer.DoDribbling
' VA 0x004F97F8   912 bytes   sig ()i   slot 0x130
' byte-identical vs NSS5.exe (912/912, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=30)
'
' ASSUMPTIONS
'   Globals (names ours):
'     0x00C5D64C -> g_engine_int103:Int (usage-typed, globals_final.tsv)
'     0x00C5B210 -> g_engine_int20:Int (usage-typed; `Mod 2 = 0` parity check)
'     0x00C5D628 -> g_pitch_float01:Float (already used/named in TPlayer.DoRepulsion.bmx)
'     0x00C5D634 -> g_player_int16:Int, 0x00C5D638 -> g_player_int17:Int (usage-typed)
'     0x00C5DE10 -> g_Object79:TList (EachIn evidence: slot 0x8c = TList.ObjectEnumerator)
'   TPitch+0x6c = YardsToPixels(f)f (class-table interior slot).
'   0x004A7FE0 = _bbFloatAbs (runtime_helpers.tsv) -> Abs(x).
'   TPlayer slots (vtable_map.tsv): 0x160 GetShootingDirection, 0x170 GetDistanceToByLine(i)f,
'     0x1a0 PlayerOnFeet, 0x1b0 PlayerSliding, 0x134 DoRepulsion(f,f,*f,*f,d)i.
'   TPlayer fields (object_model.json): +0x4c x, +0x50 y, +0x7c desx, +0x80 desy (all Float),
'     +0x14 teamid, +0xe8 distancetogoal_opp.
'   Literal args recovered from the exe's own immediates (Ghidra hides args on classtable
'   calls): YardsToPixels(60.0), YardsToPixels(30.0), YardsToPixels(10.0);
'   GetDistanceToByLine(0) for the opponent, GetDistanceToByLine(1) for Self;
'   DoRepulsion's Double strength args are 20.0/10.0/10.0/10.0/10.0, each * g_pitch_float01
'   (constants read at 0x00C7A078/7C/80/84/88).
'
' Shape notes, established via localise_diff.py + harness.try_method (NSS5_NO_LEARN=1):
'   - the outer distance guard is `> YardsToPixels(60.0)` with the SIMPLE assignment as the
'     If-body (fallthrough) and the complex attack logic as the Else (jump target) -- the
'     original places the shorter branch inline and jumps to the longer one, the reverse of
'     the naive reading of the decompiled C.
'   - `attack`/`same` are never given a separate `= False` initialiser: each is DEFINED by
'     the first comparison that produces it (`Local attack:Int = Abs(x) < threshold`), and
'     every later use just reassigns the SAME local via `If attack Then attack = ...` /
'     `If Not attack Then attack = ...`. An explicit `= False` before the first branch adds a
'     real `mov reg,0` the original does not have.
'   - the whole per-candidate loop body (team check, on-feet/sliding, distance-to-byline,
'     Dist2D-to-goalmouth) is ONE accumulator, not three nested named booleans: `same` is
'     reassigned by up to four sequential `If same <> 0 Then same = ...` gates, letting a
'     `same = 0` from any earlier gate short-circuit every later one for free (the original
'     shares ONE `je` target across the team/on-feet/sliding skip and the distance-check
'     skip). Nesting the distance checks inside their own `If` blocks costs bytes because it
'     forces a separate skip target instead of reusing the leftover zero in the accumulator.
'   - DoRepulsion's Var (Float Ptr) parameters are passed with an explicit `Varptr`.
'!Global g_engine_int103:Int
'!Global g_engine_int20:Int
' g_pitch_float01's original data-section value is 10.0 (0x00C5D628), read
' directly from NSS5.exe -- same address as TPitch.SetUp.bmx's g_pitchscale. See
' codegen-patterns 21.1/21.3.
'!Global g_pitch_float01:Float = 10.0
'!Global g_player_int16:Int
'!Global g_player_int17:Int
'!Global g_Object79:TList
If Self.distancetogoal_opp > TPitch.YardsToPixels(60.0)
	Self.desx = Self.x
	Self.desy = g_player_int17 * Self.GetShootingDirection()
Else
	Local attack:Int = Abs(Self.x) < g_engine_int103
	If attack
		attack = Self.distancetogoal_opp < TPitch.YardsToPixels(30.0)
	EndIf
	If Not attack
		attack = (g_engine_int20 Mod 2 = 0)
	EndIf
	If attack
		Self.desx = Self.x
		Self.desy = g_player_int17 * Self.GetShootingDirection()
	Else
		Self.desx = 0
		Self.desy = g_player_int17 * Self.GetShootingDirection()
	EndIf
EndIf

Local closest:TPlayer = Null
For Local p:TPlayer = EachIn g_Object79
	Local same:Int = (p.teamid <> Self.teamid)
	If same
		same = p.PlayerOnFeet()
		If same = 0
			same = p.PlayerSliding()
		EndIf
	EndIf
	If same <> 0
		same = p.GetDistanceToByLine(0) < Self.GetDistanceToByLine(1)
	EndIf
	If same <> 0
		same = Dist2D(Self.x, Self.y, p.x, p.y) < TPitch.YardsToPixels(10.0)
	EndIf
	If same <> 0
		closest = p
	EndIf
Next

If closest <> Null
	Self.DoRepulsion(closest.x, closest.y, Varptr Self.desx, Varptr Self.desy, 20.0 * g_pitch_float01)
EndIf
Self.DoRepulsion(-g_player_int16, Self.y, Varptr Self.desx, Varptr Self.desy, 10.0 * g_pitch_float01)
Self.DoRepulsion(g_player_int16, Self.y, Varptr Self.desx, Varptr Self.desy, 10.0 * g_pitch_float01)
Self.DoRepulsion(Self.x, -g_player_int17, Varptr Self.desx, Varptr Self.desy, 10.0 * g_pitch_float01)
Self.DoRepulsion(Self.x, g_player_int17, Varptr Self.desx, Varptr Self.desy, 10.0 * g_pitch_float01)
Return 0

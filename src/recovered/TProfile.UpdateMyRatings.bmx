' TProfile.UpdateMyRatings  -- KIND=Method, SLOT=0x134
' VA 0x0056C449   479 bytes   sig ()i
' byte-identical vs NSS5.exe (479/479, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=20)
'
' ASSUMPTIONS
'   * GLOBAL NAME IS OURS: 0x00C6F028 g_profile:TProfile. globals_final.tsv types it
'     TProfile from 3 construction sites (confidence high); its note flags an unsound
'     usage guess, but the construction-site typing is what is used here.
'     The clamps really do go through that Global and NOT through Self, even though this
'     is a Method on TProfile -- the original emits `push 0xc6f028 / add <off>`, not
'     `[ebp+8]`.
'   * FUN_00505F6D = ClampInt (src/recovered_module/ClampInt.bmx, sig (*i,i,i)i). The
'     original almost certainly wrote a `Var` parameter; the recovered file uses the
'     byte-identical `Int Ptr` form, so the call sites here need `Varptr`.
'   * Field offsets from object_model.json: crossing 0xC4 .. penalties 0xE8 and
'     temp_crossing 0x1F4 .. temp_penalties 0x218.
'
' FORM NOTE
'   * The ten ClampInt calls are NOT in the same order as the ten accumulate statements.
'     Measured call order is freekicks(0xC8), corners(0xCC), crossing(0xC4), then
'     positioning(0xD0) onward in field order. Reordering them to match the accumulate
'     block still gives 479 bytes but different bytes, so the order is load-bearing.

'!Global g_profile:TProfile
	Method UpdateMyRatings()
		Self.crossing = Self.crossing + Self.temp_crossing
		Self.freekicks = Self.freekicks + Self.temp_freekicks
		Self.corners = Self.corners + Self.temp_corners
		Self.positioning = Self.positioning + Self.temp_positioning
		Self.shortpassing = Self.shortpassing + Self.temp_shortpassing
		Self.longpassing = Self.longpassing + Self.temp_longpassing
		Self.aggression = Self.aggression + Self.temp_aggression
		Self.longshots = Self.longshots + Self.temp_longshots
		Self.finishing = Self.finishing + Self.temp_finishing
		Self.penalties = Self.penalties + Self.temp_penalties
		ClampInt(Varptr g_profile.freekicks, 0, 100)
		ClampInt(Varptr g_profile.corners, 0, 100)
		ClampInt(Varptr g_profile.crossing, 0, 100)
		ClampInt(Varptr g_profile.positioning, 0, 100)
		ClampInt(Varptr g_profile.shortpassing, 0, 100)
		ClampInt(Varptr g_profile.longpassing, 0, 100)
		ClampInt(Varptr g_profile.aggression, 0, 100)
		ClampInt(Varptr g_profile.longshots, 0, 100)
		ClampInt(Varptr g_profile.finishing, 0, 100)
		ClampInt(Varptr g_profile.penalties, 0, 100)
		Self.temp_crossing = 0
		Self.temp_freekicks = 0
		Self.temp_corners = 0
		Self.temp_positioning = 0
		Self.temp_shortpassing = 0
		Self.temp_longpassing = 0
		Self.temp_aggression = 0
		Self.temp_longshots = 0
		Self.temp_finishing = 0
		Self.temp_penalties = 0
	End Method

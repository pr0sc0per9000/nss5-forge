' TPitch.Render
' VA 0x004E6625   2492 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (f,f,f)i, class-table slot 0x44
' 2492/2492, original length from Ghidra's inventory. reloc_masked=158.
' Re-verified with NSS5_NO_LEARN=1: still 2492/2492, so nothing here was masked by a name
' this probe taught the table -- every callee below was already named before this body
' compiled.
'
' Draws the pitch: the tiled grass/condition base (TileDrawFrame, below), the whole-pitch
' background variant, the centre-circle markers, the four corner-flag/marking quadrants
' (mirrored by sign), the goal sprites, the corner flags (with a blink phase), and, outside
' training, the dugouts/ad-hoarding boards plus DrawStadium/DrawBosses/RenderAll.
'
' This body depends on TileDrawFrame (0x005066AB, module Function,
' src/recovered_module/TileDrawFrame.bmx) -- see that file's header for the algorithm it
' needs to reach MATCH. Given TileDrawFrame, five further shapes are load-bearing, each
' localised with scripts/localise_diff.py (everything else -- every Global, every call
' target, every literal -- is right on the first build):
'   1. `AddDrawOb` needed the `TDrawOb.` prefix -- it is a Function on a DIFFERENT Type
'      (TPitch.Render is not TDrawOb), so the "sibling call, no prefix" shortcut (patterns
'      3d) does not apply here the way it does inside TDrawOb.AddDrawOb itself.
'   2. The whole-pitch-background chooser (g_pitch_int07 = 0/1/else) is a `Select`, not an
'      `If/ElseIf` -- the original loads the Global into `eax` ONCE and reuses it for both
'      compares (patterns 10.2); written as If/ElseIf it re-reads the Global from memory for
'      every branch and comes out longer.
'   3. `hw`/`hh` (the centre-circle marker offsets) must be computed in the ORIGINAL's
'      order -- `hw` (from g_player_int16) FIRST, `hh` (from g_player_int17 +
'      YardsToPixels(4.0), all in ONE expression, times a0) SECOND, with no intermediate
'      named `Int` Local for g_player_int17. Computing them in the other order, or via an
'      intermediate `Local w:Int = g_player_int17`, reads the two Globals in the wrong
'      sequence and/or adds a spurious store/reload.
'   4. The per-corner sign selection (i = 0..3 picking sx/sy in {1,1}/{-1,1}/{1,-1}/{-1,-1})
'      is also a `Select i` (Case 0 empty, Case 1/2/3 each override one or both signs), not
'      a nested If-chain -- same tell as point 2 (patterns 10.2).
'   5. The training guard is an EARLY RETURN -- `If g_training_int03 <> 0 Then Return 0`
'      followed by the body unindented, sharing the function's own trailing `Return 0` --
'      not an `If g_training_int03 = 0 Then <body> EndIf` wrapping the whole tail (patterns
'      3f/10.9: guard shape is per-function, and this one is 6 bytes shorter as an early
'      return because it reuses the existing epilogue instead of allocating its own).
'   6. Three small pointer-arithmetic terms compile shorter written as `-g_player_int16 - N`
'      (`neg eax` / `sub eax,N` -- N an 8-bit immediate) than as `-N - g_player_int16`
'      (`mov eax,-N` / `sub eax,[g_player_int16]`, a full 32-bit immediate load): the two
'      `AddDrawOb(g_dugoutimg, ...)` dugout x-offsets (`-g_player_int16 - 70`) and the
'      ad-hoarding loop's x-offset (`-g_player_int16 - 114`). Likewise `(...) - 2` compiles
'      shorter than `(...) + -2` (`sub eax,2` vs `add eax,-2`) for the far-goal-net offset.
'      All six are the SAME value either way -- purely a codegen-cost difference from how
'      the subtraction is spelled, per codegen-patterns.md sec. 6 ("bcc does no CSE" and
'      operand-order is byte-observable throughout).
'
' ASSUMPTIONS -- all confirmed against extracted/globals_final.tsv or against sibling
' bodies already in src/recovered/ that reference the same address (cited below); several
' entries here CORRECT globals_final.tsv, which typed every g_Object* as low-confidence
' Object with "no call-site typing". Direct evidence: every one is passed as the first
' argument either to DrawImage (needs TImage), TileDrawFrame (needs TImage), or
' TDrawOb.AddDrawOb (needs :TImage) -- so all are TImage.
'   0x00C5D594 g_grassimg : TImage   -- the pitch/grass base tile image
'   0x00C5D598 g_mow0img : TImage   -- pitch-type-0 whole-pitch image
'   0x00C5D59C g_mow1img : TImage   -- pitch-type-1 whole-pitch image
'   0x00C5D5A0 g_mowsimg : TImage   -- tiled pitch-type>=2 base image
'   0x00C5D5A4 g_pitchimg1 : TImage   -- corner marking, top row
'   0x00C5D5A8 g_pitchimg2 : TImage   -- corner marking, top row (2nd)
'   0x00C5D5AC g_pitchimg1b : TImage   -- corner marking, bottom row
'   0x00C5D5B0 g_pitchimg2b : TImage   -- corner marking, bottom row (2nd)
'   0x00C5D5B4 g_pitchimg3 : TImage   -- corner marking, drawn every corner
'   0x00C5D5B8 g_pitchimg4 : TImage   -- corner marking, drawn every corner (2nd)
'   0x00C5D5BC g_nsgimg : TImage   -- centre-circle / halfway markers (4x around centre)
'   0x00C5D5C0 g_goal1img : TImage   -- goal/net AddDrawOb sprite (near end)
'   0x00C5D5C4 g_goal1netimg : TImage   -- goal/net AddDrawOb sprite (far end)
'   0x00C5D5C8 g_goal1shadowimg : TImage   -- goal/net AddDrawOb sprite, blend 2 (near end)
'   0x00C5D5CC g_goal2img : TImage   -- goal/net AddDrawOb sprite, blend 3 (far end)
'   0x00C5D5D0 g_goal2shadowimg : TImage   -- goal/net AddDrawOb sprite, blend 2 (far end)
'   0x00C5D5D4 g_flagimg : TImage   -- corner-flag sprite, drawn at all 4 corners
'   0x00C5D5E0 g_adboardimg : TImage[]  -- ad-hoarding/pitch-side board images, indexed 0..8
'   0x00C5D5E4 g_dugoutimg : TImage   -- ad-hoarding end-board sprite (both goal ends)
'   0x00C5D62C g_pitch_int06 : Int   -- pitch-type variant passed to TileDrawFrame; ALREADY
'                                       Int elsewhere (src/recovered/TEngine.SaveReplay.bmx);
'                                       globals_final.tsv's "TNation, 1 construction site"
'                                       is wrong (section 11.2 pattern -- single weak witness).
'   0x00C5D630 g_pitch_int07 : Int   -- which of the 3 whole-pitch backgrounds to draw
'   0x00C5D634 g_player_int16 : Int  -- half-pitch-width in pixels. NAME COLLISION, NOT
'                                       INTRODUCED HERE: this address is `g_sideline` in
'                                       src/recovered/TPitch.SetUp.bmx and `g_pitchleft` in
'                                       src/recovered/TPlayer.Render.bmx, but `g_player_int16`
'                                       in 11 other verified files (by grep count).
'                                       Uses the majority name for consistency;
'                                       flagging for a future consolidation pass rather than
'                                       renaming any of the 13 files touching it.
'   0x00C5D638 g_player_int17 : Int  -- half-pitch-height in pixels, same provenance/collision
'                                       risk as g_player_int16 (not cross-checked against
'                                       TPitch.SetUp.bmx's `g_goalline`).
'   0x00C5D648 g_pitch_int10 : Int   -- already Int (src/recovered/TPlayer.UpdateMovement.bmx)
'   0x00C5D660 g_pitch_int12 : Int   -- ad-hoarding board vertical offset
'   0x00C600C4 g_weather_int01 : Int   -- 1 = rain/overlay weather active
'   0x00C600E4 g_weather_float01 : Float -- overlay alpha
'   0x00C6CF90 g_training_int03 : Int  -- 0 = normal match (draw floodlights + stadium)
'   0x00C6EFD4 g_player_int50 : Int    -- hand-verified elsewhere (globals_corrections.tsv)
'   0x00C5B1CC g_engine_int13 : Int    -- which clock drives corner-flag flap phase
'   0x00C5B2C8 g_engine_int52 : Int    -- frame counter, alt phase source
'   PTR_PTR_00C5D680 = "FFFFFF" (confirmed via harness.read_string)
'   PTR_PTR_005C7D40 = ""  (empty string; harness.read_string returns None for it, matches
'                            bcc's own empty-string constant -- see codegen-patterns.md 3d)
'
' NOTES
'   The four-corner loop (i 0..3) walks sign pairs (+1,+1)(-1,+1)(+1,-1)(-1,-1) for sx/sy --
'   written as two Float locals reused exactly like TPitch.DrawStadium reuses `h`.
'   `If sy = 1.0` after `sy = sy * a0` is a literal equality against the SCALED value, not
'   against the raw sign -- reproduced verbatim per law 3 (do not "fix" it even though it
'   only ever fires when a0 = 1.0 in practice).
'   g_pitch_float02..08 are declared Globals per globals_final.tsv (high confidence, x87
'   dword access) even though they sit in the same .data run as several RAW float literals
'   (226.0, 301.0) -- the two kinds are simply adjacent in the constant pool; only the
'   ones independently written elsewhere are Globals. Values immaterial to codegen.
'   bVar1 (corner-flag flap flag): `500 < (g_player_int50 Mod 1000)`, overridden to
'   `20 < (g_engine_int52 Mod 40)` when g_engine_int13 = 3 -- kept as the ORIGINAL's odd
'   double-assignment rather than folded into one expression.
'   AddDrawOb argument order/names taken from src/recovered/TDrawOb.AddDrawOb.bmx:
'   (img, x, y, z, frame, level, alph, rot, col, sclx, scly, blend, z2, txt, imgrectw, imgrecth).
Function Render:Int(a0:Float, a1:Float, a2:Float)
	'!Global g_grassimg:TImage
	'!Global g_mow0img:TImage
	'!Global g_mow1img:TImage
	'!Global g_mowsimg:TImage
	'!Global g_pitchimg1:TImage
	'!Global g_pitchimg2:TImage
	'!Global g_pitchimg1b:TImage
	'!Global g_pitchimg2b:TImage
	'!Global g_pitchimg3:TImage
	'!Global g_pitchimg4:TImage
	'!Global g_nsgimg:TImage
	'!Global g_goal1img:TImage
	'!Global g_goal1netimg:TImage
	'!Global g_goal1shadowimg:TImage
	'!Global g_goal2img:TImage
	'!Global g_goal2shadowimg:TImage
	'!Global g_flagimg:TImage
	'!Global g_dugoutimg:TImage
	'!Global g_adboardimg:TImage[]
	'!Global g_pitch_int06:Int
	'!Global g_pitch_int07:Int
	'!Global g_player_int16:Int
	'!Global g_player_int17:Int
	'!Global g_pitch_int10:Int
	'!Global g_pitch_int12:Int
	'!Global g_weather_int01:Int
	'!Global g_weather_float01:Float
	'!Global g_training_int03:Int
	'!Global g_player_int50:Int
	'!Global g_engine_int13:Int
	'!Global g_engine_int52:Int
	'!Global g_pitch_float02:Float
	'!Global g_pitch_float03:Float
	'!Global g_pitch_float04:Float
	'!Global g_pitch_float05:Float
	'!Global g_pitch_float06:Float
	'!Global g_pitch_float07:Float
	'!Global g_pitch_float08:Float

	SetScale a0 * 0.5, a0 * 0.5
	TileDrawFrame(g_grassimg, -a1, -a2, g_pitch_int06)
	If g_weather_int01 = 1
		SetAlpha g_weather_float01
		TileDrawFrame(g_grassimg, -a1, -a2, 3)
	EndIf
	SetBlend 4
	SetAlpha 0.05
	Select g_pitch_int07
	Case 0
		SetScale a0 * 2.0, a0 * 2.0
		DrawImage g_mow0img, -a1, -a2, 0
	Case 1
		SetScale a0 * 2.0, a0 * 2.0
		DrawImage g_mow1img, -a1, -a2, 0
	Default
		SetScale a0, a0
		TileDrawFrame(g_mowsimg, -a1, -a2, g_pitch_int07 - 2)
	End Select
	SetScale a0, a0
	Local hw:Float = g_player_int16 * 0.5 * a0
	Local hh:Float = (g_player_int17 + YardsToPixels(4.0)) * a0
	DrawImage g_nsgimg, hw - a1, hh - a2, 0
	DrawImage g_nsgimg, -hw - a1, hh - a2, 0
	DrawImage g_nsgimg, hw - a1, -hh - a2, 0
	DrawImage g_nsgimg, -hw - a1, -hh - a2, 0
	SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	For Local i:Int = 0 To 3
		Local sx:Float = 1.0
		Local sy:Float = 1.0
		Select i
		Case 0
		Case 1
			sx = -1.0
		Case 2
			sy = -1.0
		Case 3
			sx = -1.0
			sy = -1.0
		End Select
		SetScale a0 * 0.5 * sx, a0 * 0.5 * sy
		sx = sx * a0
		sy = sy * a0
		If sy = 1.0
			DrawImage g_pitchimg1, g_pitch_float03 * sx - a1, g_pitch_float02 * sy - a2, 0
			DrawImage g_pitchimg2, 226.0 * sx - a1, g_pitch_float04 * sy - a2, 0
		Else
			DrawImage g_pitchimg1b, g_pitch_float06 * sx - a1, g_pitch_float05 * sy - a2, 0
			DrawImage g_pitchimg2b, 226.0 * sx - a1, g_pitch_float07 * sy - a2, 0
		EndIf
		DrawImage g_pitchimg3, g_pitch_float08 * sx - a1, 301.0 * sy - a2, 0
		DrawImage g_pitchimg4, 226.0 * sx - a1, 301.0 * sy - a2, 0
	Next
	TDrawOb.AddDrawOb(g_goal1shadowimg, 0, -g_player_int17, 0, 0, 2, 0.3, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_goal1img, 0, -g_player_int17, 0, 0, 3, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_goal1netimg, 0, (-g_pitch_int10 - g_player_int17) - 2, 0, 0, 3, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_goal2shadowimg, 0, g_player_int17 + g_pitch_int10 + 4, 0, 0, 2, 0.3, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_goal2img, 0, g_player_int17 + g_pitch_int10 + 4, 0, 0, 3, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	Local flap:Int = (g_player_int50 Mod 1000) > 500
	If g_engine_int13 = 3
		flap = (g_engine_int52 Mod 40) > 20
	EndIf
	TDrawOb.AddDrawOb(g_flagimg, -g_player_int16, -g_player_int17, 0, flap, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_flagimg, g_player_int16, -g_player_int17, 0, flap, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_flagimg, g_player_int16, g_player_int17, 0, flap, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_flagimg, -g_player_int16, g_player_int17, 0, flap, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
	If g_training_int03 <> 0 Then Return 0
	TDrawOb.AddDrawOb(g_dugoutimg, -g_player_int16 - 70, -140.0, 0, 0, 2, 1.0, 0, "FFFFFF", 0.6, 0.6, 3, 0, "", 0, 0)
	TDrawOb.AddDrawOb(g_dugoutimg, -g_player_int16 - 70, 140.0, 0, 0, 2, 1.0, 0, "FFFFFF", 0.6, 0.6, 3, 0, "", 0, 0)
	For Local j:Int = 0 To 8
		TDrawOb.AddDrawOb(g_adboardimg[j], (-g_player_int16 - 114) + j * 128, -g_pitch_int12, 0, 0, 3, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(g_adboardimg[j], (-g_player_int16 - 114) + j * 128, g_pitch_int12 + 18, 0, 0, 3, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
	Next
	DrawStadium(a0, a1, a2)
	DrawBosses()
	TCameraMan.RenderAll()
	TPhotographer.RenderAll()
	Return 0
End Function

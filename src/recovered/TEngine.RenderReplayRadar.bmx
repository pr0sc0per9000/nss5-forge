' TEngine.RenderReplayRadar
' VA 0x004D54A9   1821 bytes   mode=reloc   byte-identical vs NSS5.exe (matched 1821/1821)
' KIND=Function (STATIC method on TEngine), SIG ()i, class-table slot 0xB8
' THE SHAPE THAT MATTERS: the per-player block must NOT be wrapped in an explicit
' `If p <> Null ... EndIf`. `For ... EachIn` ALREADY emits its own null-skip after the
' `bbObjectDowncast` call (codegen-patterns.md 10.6) -- an explicit guard compiles a
' SECOND, redundant `cmp esi,<Null>; je` right where `p.matchstats` is first read, and
' that duplicate is worth +6 bytes. It is easy to misread as a defensive per-field
' null-check. Relying solely on EachIn's own skip removes that duplicate
' check outright. Two more small shape fixes were then needed to close the residual few
' bytes, both confirmed by rebuilding and re-diffing with scripts/localise_diff.py:
'   1. `p.matchstats` is read TWICE in source, once for the `<> Null` test and again (as
'      `p.matchstats.reds`) inside the `If hidden <> 0` arm -- NOT cached in a `ms` Local.
'      bcc has no CSE (codegen-patterns.md 6), so the original's second field read is a
'      second textual `p.matchstats` in source, matching the disassembly's second
'      `mov eax,[esi+0x188]` at VA 0x004D595E.
'   2. The `If hidden = 0 Then <draw block> EndIf` (no Else) at the end of the loop body is
'      written as an early-exit guard instead: `If hidden <> 0 Then Continue` followed by
'      flat, unindented draw code. An enclosing `If hidden = 0 ... EndIf` with no Else
'      compiles to a single inverted near-Jcc around the block (6 bytes); the original's
'      `je short / jmp near` two-instruction shape (7 bytes) is what the early-Continue
'      guard produces instead (codegen-patterns.md 10.9's guard-shape family).
' All three fixes were required together; each one alone left a smaller but still nonzero
' delta (tried in order: -6, then -1, then 0). Confirmed CLEAN by localise_diff.py (zero
' gaps, zero subs) and MATCH by harness.try_method (mode=reloc, 1821/1821,
' NSS5_NO_LEARN=1).
'
' GLOBALS (module Globals carry no debug record; addresses are fact, names ours except
' where an established name already exists elsewhere in the corpus -- reused verbatim):
'   g_options_int02:Int   0x00C5D22C  radar size 0=off/1=small/2=large (TScreen_Options.
'     ButtonRadar.bmx, TOptions.LoadOptions.bmx, TScreen_Options.RefreshButtons.bmx)
'   g_sideline:Int    0x00C5D634   g_goalline:Int  0x00C5D638   (TPitch.SetUp.bmx: these are
'     `Int(ReadSettingFloat(...))` of Engine.ini keys "sideline"/"goalline")
'   g_penboxside:Int  0x00C5D64C   g_penboxd:Int   0x00C5D650   (TPitch.SetUp.bmx names these
'     from the Engine.ini keys "penboxside"/"penboxd". NOTE: TPitch.InsideCrossZone.bmx names
'     these SAME two addresses g_crosszone_x/g_crosszone_y -- a pre-existing corpus naming
'     conflict, not introduced here. Global names are cosmetic -- only address+type are
'     load-bearing -- so this does not affect byte-matching either way.)
'   g_engine_gfxh:Int 0x00C6EFE8   graphics height (established in TEngine.RenderReplayGUI.bmx)
'   g_team_home:TTeam 0x00C5B218   (TEngine.SetUpRadarColours.bmx)
'   g_radarcol_home:String 0x00C5B2A8   g_radarcol_away:String 0x00C5B2AC   (same file)
'   g_img_radarplayer:TImage 0x00C5B2A4   (TEngine.SetUp.bmx: LoadAnimImageChecked, the
'     8x8-frame "RadarPlayer.png" sprite; frame 0 = normal player dot, frame 1 = the
'     highlighted "which ball is live" marker used at the very end of this function)
'   g_players:TList 0x00C5DE10   (TPlayer.RenderAll.bmx)
'   g_balls:TList   0x00C5A4C0   (TBall.GetActiveBall.bmx)
'   g_replayframe:Int 0x00C5B2C8   (TEngine.UpdateReplay.bmx / TPitchMark.RenderReplay.bmx)
'   SetColourHex($)i is the already-recovered module Function at 0x00505CEA (see
'     src/recovered/TPitch.DrawStadium.bmx, TDrawOb.RenderAll.bmx, etc.) -- FUN_00505CEA in
'     the decompile. Ghidra shows it called with ZERO arguments in the pseudo-C; the raw
'     disassembly (`push [g_radarcol_home]; call 0x505cea; add esp,4`) proves it really
'     takes the one String argument. Same under-counting bug in Ghidra's signature recovery
'     hit SetBlend/SetScale/SetAlpha/SetColor/DrawImage below -- cross-check argument counts
'     against the raw disassembly's push/add-esp bytes, never trust the decompiled C's
'     argument list alone.
'
' FIELDS (object_model.json, byte offsets confirmed against the disassembly's [reg+N]):
'   TPlayer: teamid+0x14 i, x+0x4c f, y+0x50 f, selectionno+0xbc i, matchstats+0x188 :TStats_Match
'   TStats_Match: reds+0x10 i
'   TTeam: id+0x8 i
'   TBall: x+0x18 f, y+0x1c f, replayframes+0xac :TList
'   TReplayFrame: frametime+0x8 i, active+0x58 i
'
' FLOAT CONSTANTS -- read directly out of NSS5.exe's data section at every masked fld/fmul/
' fadd/fsub operand in the function (never assumed from source alone, per codegen-patterns.md
' 21): 0.1 and 0.2 (sc), 0.45 (depthpx factor), 10.0 (eight separate literal sites) and 2.0
' (six separate literal sites, all in the DrawRect/DrawLine box geometry), plus the
' immediate-encoded call arguments 0.5 (SetAlpha, SetScale), 0.8 (SetAlpha) and 1.0
' (SetScale, SetBlend's sibling calls). All confirm the source below exactly.
'
' SHAPE NOTES, each byte-observable and confirmed against the raw disassembly (not the
' decompiled C, which reorders commutative float addition and drops call arguments):
'   * The whole body is ONE early return: `If g_options_int02 = 0 Then Return 0` followed by
'     unindented body all the way to a final `Return 0` -- NOT an enclosing `If <>0 ... EndIf`
'     (that shape costs 6 bytes: je-direct-to-epilogue vs the original's jne-into-body /
'     mov eax,0+jmp pattern).
'   * EVERY "+10.0" appearing bare in the pitch/goal-box wireframe expressions is evaluated
'     FIRST, then the variable term: source is `10.0 + sidepx * 2.0`, not `sidepx * 2.0 +
'     10.0` -- confirmed from the FLD ordering (fld [10.0-const] precedes fld [sidepx]).
'   * Likewise every `p.x*sc + cx` / `p.y*sc + cy` style position is actually `cx + p.x*sc` /
'     `cy + p.y*sc` (constant/variable-holding-cx-or-cy loaded first via FLD, term computed
'     second, FADDP).
'   * `sc` is 0.1, or 0.2 when `g_options_int02 = 2`.
'   * The 11 DrawLine calls: 5 with `draw_last_pixel=0` draw the green-rect outline + halfway
'     line; 6 with `draw_last_pixel=1` draw the two open-ended penalty-box markers. All six
'     box lines recompute `10.0 + sidepx - boxpx` / `10.0 + sidepx + boxpx` from scratch at
'     every call site rather than reusing the already-computed `cx` Local -- an
'     original-source quirk, not tidied here.
'   * SetAlpha is called THREE times with three different values in sequence: 0.5 (before the
'     green DrawRect), 0.8 (before the 11 white DrawLine calls), 1.0 (after them, before
'     SetScale(0.5,0.5)). Do not collapse or reorder.
'   * The player-hidden test is short-circuit VALUE code, not nested jump-code Ifs:
'     `hidden = (p.matchstats <> Null)` first; then `If hidden <> 0 Then hidden =
'     p.matchstats.reds` (note: ALWAYS reassigns hidden when matchstats is non-null,
'     regardless of what reds is); then `If hidden = 0 Then hidden = (p.selectionno > 10)`.
'     A player is hidden from the radar when matchstats<>Null AND (reds<>0 OR
'     selectionno>10); Null matchstats never hides a player.
'   * Same short-circuit VALUE-code pattern for the ball/replay-frame search: `Local
'     found:Int = (rf.frametime = g_replayframe)` then `If found <> 0 Then found =
'     rf.active` then `If found <> 0 Then hit = ball; Exit`.
'   * The final marker: `If hit <> Null` is the FOUND branch (fallthrough in the original,
'     not `If hit = Null`); draws frame=1 of g_img_radarplayer at the matched ball's own
'     x/y (not any player's), in white. The NOT-FOUND branch is the `Else` and is JUST
'     `SetColor(255,255,255)` with no draw. `SetScale(1.0,1.0)` unconditionally afterward
'     resets scale for whatever renders next.
'   * DrawImage's optional `frame` parameter is ALWAYS passed explicitly (0 for the per-player
'     dots, 1 for the highlighted-ball marker) -- confirmed by the push/add-esp byte count
'     (0x10 = 4 dwords each time), even though Ghidra's decompile under-counts to 3 args.

	Function RenderReplayRadar:Int()
		'!Global g_options_int02:Int
		'!Global g_sideline:Int
		'!Global g_goalline:Int
		'!Global g_penboxside:Int
		'!Global g_penboxd:Int
		'!Global g_engine_gfxh:Int
		'!Global g_team_home:TTeam
		'!Global g_radarcol_home:String
		'!Global g_radarcol_away:String
		'!Global g_img_radarplayer:TImage
		'!Global g_players:TList
		'!Global g_balls:TList
		'!Global g_replayframe:Int
		If g_options_int02 = 0 Then Return 0
		Local sc:Float = 0.1
		If g_options_int02 = 2 Then sc = 0.2
		Local sidepx:Float = g_sideline * sc
		Local goalpx:Float = g_goalline * sc
		Local boxpx:Float = g_penboxside * sc
		Local depthpx:Float = g_penboxd * 0.45 * sc
		Local cx:Float = 10.0 + sidepx
		Local cy:Float = g_engine_gfxh / 2
		SetBlend(3)
		SetScale(1.0, 1.0)
		SetAlpha(0.5)
		SetColor(153, 255, 153)
		DrawRect(10.0, cy - goalpx, sidepx * 2.0, goalpx * 2.0)
		SetAlpha(0.8)
		SetColor(255, 255, 255)
		DrawLine(10.0, cy - goalpx, 10.0 + sidepx * 2.0, cy - goalpx, 0)
		DrawLine(10.0, cy - goalpx, 10.0, cy + goalpx, 0)
		DrawLine(10.0, cy + goalpx, 10.0 + sidepx * 2.0, cy + goalpx, 0)
		DrawLine(10.0 + sidepx * 2.0, cy + goalpx, 10.0 + sidepx * 2.0, cy - goalpx, 0)
		DrawLine(10.0, cy, 10.0 + sidepx * 2.0, cy, 0)
		DrawLine((10.0 + sidepx) - boxpx, cy - goalpx, (10.0 + sidepx) - boxpx, (cy - goalpx) + depthpx, 1)
		DrawLine(10.0 + sidepx + boxpx, cy - goalpx, 10.0 + sidepx + boxpx, (cy - goalpx) + depthpx, 1)
		DrawLine((10.0 + sidepx) - boxpx, (cy - goalpx) + depthpx, 10.0 + sidepx + boxpx, (cy - goalpx) + depthpx, 1)
		DrawLine((10.0 + sidepx) - boxpx, cy + goalpx, (10.0 + sidepx) - boxpx, (cy + goalpx) - depthpx, 1)
		DrawLine(10.0 + sidepx + boxpx, cy + goalpx, 10.0 + sidepx + boxpx, (cy + goalpx) - depthpx, 1)
		DrawLine((10.0 + sidepx) - boxpx, (cy + goalpx) - depthpx, 10.0 + sidepx + boxpx, (cy + goalpx) - depthpx, 1)
		SetAlpha(1.0)
		SetScale(0.5, 0.5)
		If g_options_int02 = 2 Then SetScale(1.0, 1.0)
		For Local p:TPlayer = EachIn g_players
			Local hidden:Int = (p.matchstats <> Null)
			If hidden <> 0
				hidden = p.matchstats.reds
				If hidden = 0 Then hidden = (p.selectionno > 10)
			EndIf
			If hidden <> 0 Then Continue
			Local ix:Int = cx + p.x * sc
			Local iy:Int = cy + p.y * sc
			If p.teamid = g_team_home.id
				SetColourHex(g_radarcol_home)
			Else
				SetColourHex(g_radarcol_away)
			EndIf
			DrawImage(g_img_radarplayer, ix, iy, 0)
		Next
		Local hit:TBall = Null
		If g_balls <> Null
			For Local ball:TBall = EachIn g_balls
				For Local rf:TReplayFrame = EachIn ball.replayframes
					Local found:Int = (rf.frametime = g_replayframe)
					If found <> 0 Then found = rf.active
					If found <> 0
						hit = ball
						Exit
					EndIf
				Next
				If hit <> Null Then Exit
			Next
		EndIf
		If hit <> Null
			Local ix2:Int = cx + hit.x * sc
			Local iy2:Int = cy + hit.y * sc
			SetColor(255, 255, 255)
			DrawImage(g_img_radarplayer, ix2, iy2, 1)
		Else
			SetColor(255, 255, 255)
		EndIf
		SetScale(1.0, 1.0)
		Return 0
	End Function

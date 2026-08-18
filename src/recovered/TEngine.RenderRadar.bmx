' TEngine.RenderRadar
' VA 0x004D0423   1680 bytes   KIND=Function (STATIC method on TEngine), sig ()i, slot 0x60
' byte-identical vs NSS5.exe (1680/1680, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=86). Verified w21_L15, NSS5_NO_LEARN=1. localise_diff.py: CLEAN,
' 0 gaps, 0 subs.
'
' This is the LIVE-MATCH radar (the on-pitch minimap during normal play). Its replay twin,
' TEngine.RenderReplayRadar (0x004D54A9, already recovered), shares the SAME wireframe-drawing
' float-constant block byte-for-byte -- same 0x00C73D68..0x00C73DD4 addresses in the same
' order -- so the pitch/goal-box geometry code below was transcribed from that verified body
' and reproduces exactly. The two functions differ in: the guard (four separate early
' returns here vs one there), the player "hidden" test (no explicit matchstats<>Null check
' here -- see below), the "newstar" flash-colour override (present here, absent there), and
' the "hit ball" lookup (a single TBall.GetActiveBall() call here vs a manual replay-frame
' search there).
'
' GUARD (four independent early returns, each its own cmp/jne/mov eax,0/jmp-epilogue --
' confirmed from raw disassembly, NOT a compound And condition, which would cost fewer bytes):
'   g_options_int02 = 0            radar off
'   g_player_int01 = 8/0/11        excluded match-clock states (halftime/pre-match/etc. --
'                                   g_player_int01 is the established "game-mode selector",
'                                   see TPlayer.UpdateAnimation.bmx; the numeric states beyond
'                                   1=match/3=set-piece are not separately named here)
'
' GLOBALS (module Globals carry no debug record; names reused verbatim from prior art where
' an established name already exists elsewhere in the corpus):
'   g_options_int02:Int   0x00C5D22C   radar size 0=off/1=small/2=large (TEngine.
'     RenderReplayRadar.bmx and others)
'   g_player_int01:Int    0x00C5B1FC   game-mode selector (globals_final.tsv verified;
'     TPlayer.UpdateAnimation.bmx)
'   g_sideline / g_goalline / g_penboxside / g_penboxd : Int   0x00C5D634/638/64C/650
'     (TPitch.SetUp.bmx: Int(ReadSettingFloat(...)) of Engine.ini keys, same addresses as
'     TEngine.RenderReplayRadar.bmx)
'   g_engine_gfxh:Int      0x00C6EFE8   graphics height (TEngine.RenderReplayGUI.bmx)
'   g_team_home:TTeam      0x00C5B218   (TEngine.SetUpRadarColours.bmx)
'   g_radarcol_home:String 0x00C5B2A8   g_radarcol_away:String 0x00C5B2AC   (same file)
'   g_img_radarplayer:TImage 0x00C5B2A4   (TEngine.SetUp.bmx; RadarPlayer.png, frame 0 = dot,
'     frame 1 = the highlighted "which ball is live" marker)
'   g_players:TList        0x00C5DE10   (TPlayer.RenderAll.bmx)
'   g_player_int50:Int     0x00C6EFD4   current match clock in ms (globals_final.tsv verified;
'     TPlayer.UpdateAnimation.bmx) -- used here as a flash-cycle timer (Mod 500 < 250 is the
'     "on" half of the cycle)
'   TBall.GetActiveBall() is the already-recovered sibling Function (src/recovered/
'     TBall.GetActiveBall.bmx, class-table 0x00C5AE98 + slot 0x44 = 0x00C5AEDC, confirmed by
'     address arithmetic against the raw `call dword ptr [0xc5aedc]`) -- replaces the manual
'     replay-frame search the replay twin performs.
'   SetColourHex($)i is the already-recovered module Function at 0x00505CEA (see
'     src/recovered/TPitch.DrawStadium.bmx etc.) -- FUN_00505CEA in the decompile, called with
'     one String argument (Ghidra's decompiled signature under-counts to zero args; the raw
'     disassembly's push/add-esp bytes prove one arg, same under-counting bug noted in
'     TEngine.RenderReplayRadar.bmx).
'
' FIELDS (object_model.json, byte offsets confirmed against the disassembly's [reg+N]):
'   TPlayer: newstar+0x8 i, teamid+0x14 i, x+0x4c f, y+0x50 f, selectionno+0xbc i,
'            matchstats+0x188 :TStats_Match
'   TStats_Match: reds+0x10 i
'   TTeam: id+0x8 i
'   TBall: x+0x18 f, y+0x1c f
'
' FLOAT CONSTANTS -- read directly out of NSS5.exe's data section (never assumed from source
' alone, per codegen-patterns.md 21): 0.1 and 0.2 (sc), 0.45 (depthpx factor), and the sixteen
' 10.0/2.0 literal sites in the wireframe geometry -- all confirmed identical, at the identical
' addresses, to the already-verified TEngine.RenderReplayRadar.bmx.
'
' SHAPE NOTES, each byte-observable and confirmed against the raw disassembly:
'   * The player "hidden" test has NO `<> Null` guard on p.matchstats (unlike the replay
'     twin) -- the disassembly reads [esi+0x188] then immediately derefs [+0x10] with no
'     intervening Null compare. So here: `Local hidden:Int = p.matchstats.reds` directly
'     (matchstats is guaranteed non-null for every player during a live match). Then
'     `If hidden = 0 Then hidden = (p.selectionno > 10)`; `If hidden <> 0 Then Continue`.
'   * Player colour selection is short-circuit VALUE code: `col = g_radarcol_away` by default,
'     overridden to `g_radarcol_home` `If p.teamid = g_team_home.id`.
'   * The "new star" flash override applies to ANY player (home or away) with `newstar<>0`
'     during the "on" half of a `g_player_int50 Mod 500 < 250` cycle: it unconditionally sets
'     `col = "000000"`, then re-examines `g_radarcol_home` (NOT the player's own team colour --
'     an original-source quirk, preserved as-is, not tidied) `= col` (i.e. `= "000000"`) and
'     if so overrides to `"FFFFFF"` -- i.e. "flash black, unless the home strip is already
'     black, then flash white". The second compare is written against the `col` LOCAL, not a
'     fresh `"000000"` literal -- confirmed byte-exactly: comparing against a fresh literal
'     costs 4 extra bytes (`push <imm>` = 5 bytes vs `push ebx` = 1 byte reusing the register
'     that already holds "000000"; found via scripts/localise_diff.py, a single `replace` gap
'     at +1392, delta +4, closed by switching the literal to the `col` reference).
'   * The final marker uses `TBall.GetActiveBall()` (a single Function call, class-table+slot
'     address 0x00C5AEDC) rather than the twin's manual per-replay-frame search: `If hit <>
'     Null` is the FOUND branch (fallthrough, not `If hit = Null`); draws frame=1 of
'     g_img_radarplayer at the ball's own x/y, in white. The NOT-FOUND branch (`Else`) is
'     just `SetColor(255,255,255)` with no draw. `SetScale(1.0,1.0)` unconditionally resets
'     scale afterward.
'   * `ix`/`ix2` truncate via implicit `Int` assignment (`Local ix:Int = cx + p.x*sc`, not an
'     explicit `Int(...)` call) -- same idiom as the verified replay twin; `iy`/`iy2` truncate
'     the same way but the allocator keeps them in a register rather than a frame slot (a
'     byte-neutral allocation detail, not a source difference -- see codegen-patterns.md 18).

	Function RenderRadar:Int()
		'!Global g_options_int02:Int
		'!Global g_player_int01:Int
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
		'!Global g_player_int50:Int
		If g_options_int02 = 0 Then Return 0
		If g_player_int01 = 8 Then Return 0
		If g_player_int01 = 0 Then Return 0
		If g_player_int01 = 11 Then Return 0
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
			Local hidden:Int = p.matchstats.reds
			If hidden = 0 Then hidden = (p.selectionno > 10)
			If hidden <> 0 Then Continue
			Local ix:Int = cx + p.x * sc
			Local iy:Int = cy + p.y * sc
			Local col:String = g_radarcol_away
			If p.teamid = g_team_home.id Then col = g_radarcol_home
			If p.newstar <> 0
				If (g_player_int50 Mod 500) < 250
					col = "000000"
					If g_radarcol_home = col Then col = "FFFFFF"
				EndIf
			EndIf
			SetColourHex(col)
			DrawImage(g_img_radarplayer, ix, iy, 0)
		Next
		Local hit:TBall = TBall.GetActiveBall()
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
